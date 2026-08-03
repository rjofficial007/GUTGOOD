/**
 * Server-side, transactional usage accounting.
 *
 * Why this exists: the Firestore security rules intentionally forbid clients
 * from writing `daily_usage` (a client could otherwise reset its own counters
 * and bypass the paywall). All consumption of the free tier is therefore
 * enforced here, atomically, inside a Firestore transaction.
 *
 * Idempotency: network retries (client or SDK) reuse the same idempotency key,
 * which is recorded in the usage doc — a retried request is never double-counted.
 */
import * as admin from 'firebase-admin';
import { IDEMPOTENCY_KEY_RETENTION, LIMITS, UsageType } from './config';

export interface UsageCheckResult {
  allowed: boolean;
  premium: boolean;
  count: number;
  limit: number;
  alreadyCounted: boolean;
}

function todayKey(): string {
  return new Date().toISOString().slice(0, 10); // YYYY-MM-DD (UTC)
}

function fieldFor(type: UsageType): 'chat_count' | 'scan_count' | 'system_count' {
  if (type === 'chat') return 'chat_count';
  if (type === 'scan') return 'scan_count';
  return 'system_count';
}

/**
 * Reads the premium flag the app mirrors into the profile after the RevenueCat
 * SDK entitlement check (client-side premium model — there is no server-side
 * RevenueCat integration, by product decision).
 */
export async function isPremiumUser(uid: string): Promise<boolean> {
  const snap = await admin.firestore().doc(`user_profiles/${uid}`).get();
  if (!snap.exists) return false;
  const data = snap.data() ?? {};
  if (data.isPremium === true) return true;
  const status = (data.subscriptionStatus ?? 'free').toString();
  return status !== 'free';
}

/**
 * Atomically checks the free-tier allowance and consumes one unit.
 * Returns `{ allowed: false }` (without consuming) when the limit is reached.
 */
export async function checkAndConsume(
  uid: string,
  isAnonymous: boolean,
  type: UsageType,
  idempotencyKey?: string,
): Promise<UsageCheckResult> {
  if (await isPremiumUser(uid)) {
    return { allowed: true, premium: true, count: 0, limit: Number.MAX_SAFE_INTEGER, alreadyCounted: false };
  }

  const limits = isAnonymous ? LIMITS.guest : LIMITS.registered;
  let limit: number;
  if (type === 'chat') limit = limits.chat;
  else if (type === 'scan') limit = limits.scan;
  else limit = limits.system;

  const field = fieldFor(type);
  const ref = admin.firestore().doc(`user_profiles/${uid}/daily_usage/${todayKey()}`);
  const userRef = admin.firestore().doc(`user_profiles/${uid}`);

  return admin.firestore().runTransaction(async (tx) => {
    // 🔴 CRITICAL FIX: All reads must happen BEFORE any writes in a transaction.
    const [snap, userSnap] = await Promise.all([tx.get(ref), tx.get(userRef)]);

    const data = snap.data() ?? {};
    const recentIds: string[] = Array.isArray(data.recentIds) ? data.recentIds : [];

    // 1. Check Idempotency (Deduplication)
    if (idempotencyKey && recentIds.includes(idempotencyKey)) {
      return {
        allowed: true,
        premium: false,
        count: (data[field] as number) ?? 0,
        limit,
        alreadyCounted: true,
      };
    }

    // 2. Check Allowance
    const count = ((data[field] as number) ?? 0);
    if (count >= limit) {
      return { allowed: false, premium: false, count, limit, alreadyCounted: false };
    }

    // 3. Prepare Updates
    const nextIds = idempotencyKey
      ? [...recentIds, idempotencyKey].slice(-IDEMPOTENCY_KEY_RETENTION)
      : recentIds;

    // 4. Streak Logic
    let streakUpdate: any = null;
    if (userSnap.exists) {
      const userData = userSnap.data() ?? {};
      const lastDate = (userData.lastActivityDate ?? '').toString();
      const today = todayKey();
      let currentStreak = Number(userData.streak ?? 0);

      if (lastDate !== today) {
        // Calculate "Yesterday" relative to our UTC "Today" string
        const yesterday = new Date(today);
        yesterday.setUTCDate(yesterday.getUTCDate() - 1);
        const yesterdayKey = yesterday.toISOString().slice(0, 10);

        if (lastDate === yesterdayKey) {
          currentStreak += 1;
        } else {
          currentStreak = 1;
        }
        streakUpdate = { streak: currentStreak, lastActivityDate: today, updatedAt: admin.firestore.FieldValue.serverTimestamp() };
      }
    }

    // 5. Execute Writes
    tx.set(
      ref,
      { [field]: admin.firestore.FieldValue.increment(1), ...(idempotencyKey ? { recentIds: nextIds } : {}) },
      { merge: true },
    );

    if (streakUpdate) {
      tx.update(userRef, streakUpdate);
    }

    return { allowed: true, premium: false, count: count + 1, limit, alreadyCounted: false };
  });
}

/**
 * Read-only usage peek (used by tests / diagnostics; not a gate).
 */
export async function getUsage(uid: string): Promise<Record<string, number>> {
  const snap = await admin.firestore().doc(`user_profiles/${uid}/daily_usage/${todayKey()}`).get();
  const data = snap.data() ?? {};
  return {
    chat_count: (data.chat_count as number) ?? 0,
    scan_count: (data.scan_count as number) ?? 0,
    system_count: (data.system_count as number) ?? 0,
  };
}

/** Merges usage counters during an anonymous→permanent account merge. */
export function usageFieldFor(type: UsageType): string {
  return fieldFor(type);
}
