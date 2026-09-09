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
  /** Why a request was rejected ('quota' = daily/lifetime action limit). */
  reason: 'ok' | 'quota';
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
export function getLocalDate(timestamp: any, timezoneOffsetMinutes: number = 0): string {
  try {
    let date: Date;
    if (typeof timestamp === 'string') {
      date = new Date(timestamp);
    } else if (timestamp instanceof Date) {
      date = timestamp;
    } else if (timestamp && typeof timestamp.toDate === 'function') {
      date = timestamp.toDate();
    } else {
      date = new Date();
    }

    const offset = (timezoneOffsetMinutes === undefined || isNaN(timezoneOffsetMinutes)) ? 0 : timezoneOffsetMinutes;
    const localTime = new Date(date.getTime() + (offset * 60000));
    return localTime.toISOString().slice(0, 10);
  } catch (e) {
    return (typeof timestamp === 'string' ? timestamp : new Date().toISOString()).slice(0, 10);
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
        reason: 'ok',
      };
    }

    // 2. Check Allowance (only for non-premium)
    const dailyCount = ((data[field] as number) ?? 0);

    if (!isPremium) {
      if (isAnonymous) {
        // 🟢 LIFETIME GUEST CHECK: PRD §4 requires guests to sign up after 2 actions total.
        const lifetimeCount = (userData[`${field}_lifetime`] as number) ?? 0;
        if (lifetimeCount >= limit) {
          return { allowed: false, premium: false, count: lifetimeCount, limit, alreadyCounted: false, reason: 'quota' };
        }
      } else if (dailyCount >= limit) {
        return { allowed: false, premium: false, count: dailyCount, limit, alreadyCounted: false, reason: 'quota' };
      }
    }

    // NOTE: token counters (tokens_in / tokens_out) are recorded for cost
    // visibility only — they are deliberately NOT used to gate requests.

    // 3. Prepare Updates
    const nextIds = idempotencyKey
      ? [...recentIds, idempotencyKey].slice(-IDEMPOTENCY_KEY_RETENTION)
      : recentIds;

    // 4. Streak Logic
    // 🟢 PRD §10: Only 'chat' and 'scan' activities count toward a streak.
    // 'system' usage (summaries, background tasks) is excluded.
    const streakUpdate = (type === 'chat' || type === 'scan')
      ? calculateStreakUpdate(userData, today)
      : null;

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
      reason: 'ok',
    };
  });
}

/**
 * Gives a credit back when the request was counted but the model never
 * produced anything usable (upstream 5xx, empty content, dropped stream).
 *
 * The README promises "usage counters only increment on confirmed successful
 * operations"; without this a failed AI call still costs the user a chat/scan.
 * Only requests we actually counted (identified by their idempotency key) are
 * refunded, and removing the key means a legitimate retry is counted afresh.
 */
export async function refund(
  uid: string,
  isAnonymous: boolean,
  type: UsageType,
  idempotencyKey?: string,
  timezoneOffsetMinutes: number = 0,
): Promise<void> {
  if (!idempotencyKey) return;

  const field = fieldFor(type);
  const today = todayKey(timezoneOffsetMinutes);
  const ref = admin.firestore().doc(`user_profiles/${uid}/daily_usage/${today}`);
  const userRef = admin.firestore().doc(`user_profiles/${uid}`);

  try {
    await admin.firestore().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const data = snap.data() ?? {};
      const recentIds: string[] = Array.isArray(data.recentIds) ? data.recentIds : [];

      if (!recentIds.includes(idempotencyKey)) return; // not counted, or already refunded

      tx.set(
        ref,
        {
          [field]: admin.firestore.FieldValue.increment(-1),
          recentIds: recentIds.filter((id) => id !== idempotencyKey),
        },
        { merge: true },
      );

      if (isAnonymous) {
        tx.set(userRef, { [`${field}_lifetime`]: admin.firestore.FieldValue.increment(-1) }, { merge: true });
      }
    });
  } catch (e) {
    console.error('refund failed', e);
  }
}

/**
 * Records real token consumption on the (client-write-protected) usage doc.
 *
 * Without this there is no cost attribution at all: analytics logs latency and
 * failures, but nothing answers "what does this user cost per day?" or flags a
 * single account burning an outlier number of tokens.
 */
export async function recordTokens(
  uid: string,
  timezoneOffsetMinutes: number,
  inputTokens: number,
  outputTokens: number,
): Promise<void> {
  if (!Number.isFinite(inputTokens) && !Number.isFinite(outputTokens)) return;

  const today = todayKey(timezoneOffsetMinutes);
  const ref = admin.firestore().doc(`user_profiles/${uid}/daily_usage/${today}`);

  try {
    await ref.set(
      {
        tokens_in: admin.firestore.FieldValue.increment(Math.max(0, Math.round(inputTokens) || 0)),
        tokens_out: admin.firestore.FieldValue.increment(Math.max(0, Math.round(outputTokens) || 0)),
        requests: admin.firestore.FieldValue.increment(1),
      },
      { merge: true },
    );
  } catch (e) {
    console.error('recordTokens failed', e);
  }
}

/**
 * Shared streak calculation logic.
 * Returns an update object if the streak needs to be updated, or null.
 */
export function calculateStreakUpdate(userData: any, today: string): any {
  const lastDate = (userData.lastActivityDate ?? '').toString();
  let currentStreak = Number(userData.streak ?? 0);
  let longestStreak = Number(userData.longestStreak ?? 0);

  // 🟢 Safety Guard: Prevent corrupted negative values
  if (currentStreak < 0) currentStreak = 0;
  if (longestStreak < 0) longestStreak = 0;

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
