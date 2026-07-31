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

function fieldFor(type: UsageType): 'chat_count' | 'scan_count' {
  return type === 'chat' ? 'chat_count' : 'scan_count';
}

/**
 * Reads the premium flag the app mirrors into the profile after the RevenueCat
 * SDK entitlement check (client-side premium model — there is no server-side
 * RevenueCat integration, by product decision).
 *
 * Accepted trade-off: because clients can write their own `isPremium` flag
 * (rules shape-validate it), a tampered client could self-grant unlimited AI
 * quota. The blast radius is OpenAI spend on that account only; bound it with
 * an OpenAI dashboard budget cap (PRD cost strategy). If that ever becomes a
 * problem in practice, re-introduce server-side entitlement verification.
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
  const limit = type === 'chat' ? limits.chat : limits.scan;
  const field = fieldFor(type);
  const ref = admin.firestore().doc(`user_profiles/${uid}/daily_usage/${todayKey()}`);

  return admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data() ?? {};
    const recentIds: string[] = Array.isArray(data.recentIds) ? data.recentIds : [];

    // Dedup: a retry with the same key must not consume twice.
    if (idempotencyKey && recentIds.includes(idempotencyKey)) {
      return {
        allowed: true,
        premium: false,
        count: (data[field] as number) ?? 0,
        limit,
        alreadyCounted: true,
      };
    }

    const count = ((data[field] as number) ?? 0);
    if (count >= limit) {
      return { allowed: false, premium: false, count, limit, alreadyCounted: false };
    }

    const nextIds = idempotencyKey
      ? [...recentIds, idempotencyKey].slice(-IDEMPOTENCY_KEY_RETENTION)
      : recentIds;

    tx.set(
      ref,
      { [field]: admin.firestore.FieldValue.increment(1), ...(idempotencyKey ? { recentIds: nextIds } : {}) },
      { merge: true },
    );

    return { allowed: true, premium: false, count: count + 1, limit, alreadyCounted: false };
  });
}

/**
 * Read-only usage peek (used by tests / diagnostics; not a gate).
 */
export async function getUsage(uid: string): Promise<Record<string, number>> {
  const snap = await admin.firestore().doc(`user_profiles/${uid}/daily_usage/${todayKey()}`).get();
  const data = snap.data() ?? {};
  return { chat_count: (data.chat_count as number) ?? 0, scan_count: (data.scan_count as number) ?? 0 };
}

/** Merges usage counters during an anonymous→permanent account merge. */
export function usageFieldFor(type: UsageType): string {
  return fieldFor(type);
}
