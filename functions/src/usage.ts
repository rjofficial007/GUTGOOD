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

function todayKey(timezoneOffsetMinutes: number = 0): string {
  try {
    const now = new Date();
    // Default to 0 if NaN or undefined
    const offset = (timezoneOffsetMinutes === undefined || isNaN(timezoneOffsetMinutes)) ? 0 : timezoneOffsetMinutes;
    const localTime = new Date(now.getTime() + (offset * 60000));
    return localTime.toISOString().slice(0, 10);
  } catch (e) {
    return new Date().toISOString().slice(0, 10);
  }
}

/**
 * Utility to calculate "today" from a specific timestamp and offset.
 */
export function getLocalDate(timestamp: string | Date, timezoneOffsetMinutes: number = 0): string {
  try {
    const date = typeof timestamp === 'string' ? new Date(timestamp) : timestamp;
    const offset = (timezoneOffsetMinutes === undefined || isNaN(timezoneOffsetMinutes)) ? 0 : timezoneOffsetMinutes;
    const localTime = new Date(date.getTime() + (offset * 60000));
    return localTime.toISOString().slice(0, 10);
  } catch (e) {
    return (typeof timestamp === 'string' ? timestamp : timestamp.toISOString()).slice(0, 10);
  }
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
  try {
    const snap = await admin.firestore().doc(`user_profiles/${uid}`).get();
    if (!snap.exists) return false;
    const data = snap.data() ?? {};
    if (data.isPremium === true) return true;
    const status = (data.subscriptionStatus ?? 'free').toString();
    return status !== 'free';
  } catch (e) {
    return false;
  }
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
  timezoneOffsetMinutes: number = 0,
): Promise<UsageCheckResult> {
  const isPremium = await isPremiumUser(uid);
  const limits = isAnonymous ? LIMITS.guest : LIMITS.registered;
  let limit: number;
  if (type === 'chat') limit = limits.chat;
  else if (type === 'scan') limit = limits.scan;
  else limit = limits.system;

  const field = fieldFor(type);
  const today = todayKey(timezoneOffsetMinutes);
  const ref = admin.firestore().doc(`user_profiles/${uid}/daily_usage/${today}`);
  const userRef = admin.firestore().doc(`user_profiles/${uid}`);

  return admin.firestore().runTransaction(async (tx) => {
    // 🔴 CRITICAL FIX: All reads must happen BEFORE any writes in a transaction.
    const [snap, userSnap] = await Promise.all([tx.get(ref), tx.get(userRef)]);

    const data = snap.data() ?? {};
    const userData = userSnap.data() ?? {};
    const recentIds: string[] = Array.isArray(data.recentIds) ? data.recentIds : [];

    // 1. Check Idempotency (Deduplication)
    if (idempotencyKey && recentIds.includes(idempotencyKey)) {
      return {
        allowed: true,
        premium: isPremium,
        count: (data[field] as number) ?? 0,
        limit: isPremium ? Number.MAX_SAFE_INTEGER : limit,
        alreadyCounted: true,
      };
    }

    // 2. Check Allowance (only for non-premium)
    const dailyCount = ((data[field] as number) ?? 0);

    if (!isPremium) {
      if (isAnonymous) {
        // 🟢 LIFETIME GUEST CHECK: PRD §4 requires guests to sign up after 2 actions total.
        const lifetimeCount = (userData[`${field}_lifetime`] as number) ?? 0;
        if (lifetimeCount >= limit) {
          return { allowed: false, premium: false, count: lifetimeCount, limit, alreadyCounted: false };
        }
      } else if (dailyCount >= limit) {
        return { allowed: false, premium: false, count: dailyCount, limit, alreadyCounted: false };
      }
    }

    // 3. Prepare Updates
    const nextIds = idempotencyKey
      ? [...recentIds, idempotencyKey].slice(-IDEMPOTENCY_KEY_RETENTION)
      : recentIds;

    // 4. Streak Logic
    const streakUpdate = calculateStreakUpdate(userData, today);

    // 5. Execute Writes
    const dailyUpdate = { [field]: admin.firestore.FieldValue.increment(1), ...(idempotencyKey ? { recentIds: nextIds } : {}) };
    tx.set(ref, dailyUpdate, { merge: true });

    // 🟢 Persist timezoneOffset so background triggers can use it.
    const timezoneChanged = timezoneOffsetMinutes !== undefined && userData.timezoneOffset !== timezoneOffsetMinutes;

    if (isAnonymous || streakUpdate || timezoneChanged) {
      const userUpdate: any = streakUpdate ?? {};
      if (isAnonymous) {
        userUpdate[`${field}_lifetime`] = admin.firestore.FieldValue.increment(1);
      }
      if (timezoneChanged) {
        userUpdate.timezoneOffset = timezoneOffsetMinutes;
      }
      tx.set(userRef, userUpdate, { merge: true });
    }

    return {
      allowed: true,
      premium: isPremium,
      count: isAnonymous ? ((userData[`${field}_lifetime`] as number ?? 0) + 1) : (dailyCount + 1),
      limit: isPremium ? Number.MAX_SAFE_INTEGER : limit,
      alreadyCounted: false,
    };
  });
}

/**
 * Read-only usage peek (used by tests / diagnostics; not a gate).
 */
export async function getUsage(uid: string, timezoneOffsetMinutes: number = 0): Promise<Record<string, number>> {
  const today = todayKey(timezoneOffsetMinutes);
  const snap = await admin.firestore().doc(`user_profiles/${uid}/daily_usage/${today}`).get();
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

/**
 * Shared streak calculation logic.
 * Returns an update object if the streak needs to be updated, or null.
 */
export function calculateStreakUpdate(userData: any, today: string): any {
  const lastDate = (userData.lastActivityDate ?? '').toString();
  let currentStreak = Number(userData.streak ?? 0);
  let longestStreak = Number(userData.longestStreak ?? 0);

  // 🟢 Fix: Don't allow "time-travel" resets. If the activity date is before
  // or equal to the last recorded activity, ignore it for streak purposes.
  if (lastDate && today <= lastDate) return null;

  // Calculate "Yesterday" relative to our Local "Today" string
  const yesterday = new Date(today);
  yesterday.setUTCDate(yesterday.getUTCDate() - 1);
  const yesterdayKey = yesterday.toISOString().slice(0, 10);

  if (lastDate === yesterdayKey) {
    currentStreak += 1;
  } else {
    currentStreak = 1;
  }

  // Update longest streak if needed
  if (currentStreak > longestStreak) {
    longestStreak = currentStreak;
  }

  return {
    streak: currentStreak,
    longestStreak,
    lastActivityDate: today,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}
