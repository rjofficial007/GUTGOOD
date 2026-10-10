/**
 * counters — server-maintained history totals (audit P0-1).
 *
 * The client used to count history with full-collection `.get()` + `.size`
 * (one billed read per document, on every dashboard open and every insight
 * run) and kept live snapshots of whole collections open for realtime counts.
 * These triggers maintain `user_profiles/{uid}/counters/totals` instead:
 *
 *   { scans, meals, symptoms, foodScoreSum, foodScoreCount, updatedAt }
 *
 * so the dashboard reads exactly one document. Clients have read-only access
 * (see firestore.rules, same model as `daily_usage`).
 *
 * No backfill job is needed: the next create trigger seeds a missing counters
 * doc with a one-time full recompute. Delete triggers never seed, so cleanup
 * cannot recreate a deleted profile's counters; clients fall back to count().
 * Until then, the client falls back to cheap `count()` aggregations.
 */
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';

const COUNTERS_DOC = 'totals';

function countersRef(uid: string): admin.firestore.DocumentReference {
  return admin.firestore().doc(`user_profiles/${uid}/counters/${COUNTERS_DOC}`);
}

function counterEventRef(uid: string, eventKey: string): admin.firestore.DocumentReference {
  // ponytail: receipts grow with trigger events; add TTL only after choosing a retry-safe retention window.
  return countersRef(uid).collection('events').doc(encodeURIComponent(eventKey));
}

function timestampAtOrBefore(a: admin.firestore.Timestamp, b: admin.firestore.Timestamp): boolean {
  return a.seconds < b.seconds || (a.seconds === b.seconds && a.nanoseconds <= b.nanoseconds);
}

function wasIncludedInSeed(counters: admin.firestore.DocumentSnapshot, eventAt: admin.firestore.Timestamp): boolean {
  const seededAt = counters.data()?.seededAt as admin.firestore.Timestamp | undefined;
  return seededAt != null && timestampAtOrBefore(eventAt, seededAt);
}

function isGenericName(name: string): boolean {
  const n = name.toLowerCase().trim();
  if (n === '' || n === 'unknown' || n === 'food' || n === 'product' || n === 'item' || n === 'meal') return true;
  const isMenu = n.includes('menu') && !n.includes('meal') && !n.includes('combo');
  const isLabelOnly = n.includes('ingredients list') || n.includes('nutrition label') || n.includes('ingredients only');
  const isGeneric = new Set(['menu', 'ingredients', 'label', 'nutrition', 'facts']).has(n);
  return isMenu || isLabelOnly || isGeneric;
}

/**
 * Mirrors `ScanResult.isLoggableProduct` (lib/core/models/scan_result.dart).
 * Decides whether a scan contributes to the food-score average. Keep in sync.
 */
export function isLoggableForAverage(data: Record<string, unknown>): boolean {
  const barcode = typeof data.barcode === 'string' ? data.barcode : '';
  if (barcode.length > 0) return true;

  const category = typeof data.category === 'string' ? data.category.toLowerCase() : '';
  if (category === 'food' || category === 'meal' || category === 'product' || category === 'packaging') return true;
  if (category === 'menu' || category === 'non-food') return false;

  const source = typeof data.source === 'string' ? data.source : '';
  if (source === 'food' || source === 'meal' || source === 'vision' || source === 'chat') return true;

  if (Array.isArray(data.ingredients) && data.ingredients.length > 0) return true;
  if (data.nutrients !== null && data.nutrients !== undefined) return true;
  // Legacy-docs-only: new scans strip rawData at persistence (P0-2), keeping
  // just rawDataHash. Old docs still carry the blob, so keep reading it.
  const rawData = (data.rawData ?? {}) as Record<string, unknown>;
  if (rawData.meal !== null && rawData.meal !== undefined) return true;

  const name = typeof data.productName === 'string' ? data.productName : '';
  return !isGenericName(name);
}

/** One-time full recompute used to seed the counters doc (lazy backfill). */
async function seedCounters(uid: string): Promise<void> {
  // ponytail: one transaction reads the complete history to get a consistent snapshot; replace with a paged checkpointed backfill if users can exceed Firestore's transaction request limit.
  const db = admin.firestore();
  const userRef = db.doc(`user_profiles/${uid}`);
  const counterRef = countersRef(uid);
  const seeded = await db.runTransaction(async (tx) => {
    const [user, counters, scans, meals, symptoms] = await Promise.all([
      tx.get(userRef),
      tx.get(counterRef),
      tx.get(userRef.collection('scan_history')),
      tx.get(userRef.collection('journal_logs').where('type', '==', 'meal')),
      tx.get(userRef.collection('journal_logs').where('type', '==', 'symptom')),
    ]);
    if (!user.exists || (counters.exists && counters.data()?.seededAt != null)) return null;

    let foodScoreSum = 0;
    let foodScoreCount = 0;
    for (const doc of scans.docs) {
      const data = doc.data();
      if (!isLoggableForAverage(data)) continue;
      const score = Number(data.score);
      if (!Number.isFinite(score)) continue;
      foodScoreSum += Math.round(score);
      foodScoreCount += 1;
    }

    const seed = {
      scans: scans.size,
      meals: meals.size,
      symptoms: symptoms.size,
      foodScoreSum,
      foodScoreCount,
      // Query readTime is the consistent snapshot boundary for all transaction reads.
      seededAt: scans.readTime,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (counters.exists) tx.set(counterRef, seed);
    else tx.create(counterRef, seed);
    return { scans: scans.size, meals: meals.size, symptoms: symptoms.size, foodScoreCount };
  });
  if (seeded) functions.logger.info(`counters: seeded for ${uid} (scans=${seeded.scans} meals=${seeded.meals} symptoms=${seeded.symptoms} scores=${seeded.foodScoreCount})`);
}

async function applyIncrement(
  uid: string,
  delta: Record<string, number>,
  eventAt: admin.firestore.Timestamp,
  eventKey: string,
): Promise<void> {
  const db = admin.firestore();
  const userRef = db.doc(`user_profiles/${uid}`);
  const ref = countersRef(uid);
  const eventRef = counterEventRef(uid, eventKey);
  const shouldSeed = await db.runTransaction(async (tx) => {
    const [user, counters, event] = await Promise.all([tx.get(userRef), tx.get(ref), tx.get(eventRef)]);
    if (!user.exists || event.exists) return false;
    if (!counters.exists || counters.data()?.seededAt == null) return true;

    if (!wasIncludedInSeed(counters, eventAt)) {
      const update: Record<string, unknown> = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };
      for (const [field, amount] of Object.entries(delta)) {
        if (amount !== 0) update[field] = admin.firestore.FieldValue.increment(amount);
      }
      tx.set(ref, update, { merge: true });
    }
    tx.create(eventRef, { processedAt: admin.firestore.FieldValue.serverTimestamp() });
    return false;
  });

  if (shouldSeed) {
    // Lazy backfill: the triggering write is already in the collections, so a
    // straight recompute includes it — applying a delta on top would double it.
    await seedCounters(uid);

    // A concurrent seed may have won using a snapshot taken before this event.
    // Apply its delta only when the snapshot boundary says it was not included.
    await db.runTransaction(async (tx) => {
      const [user, counters, event] = await Promise.all([tx.get(userRef), tx.get(ref), tx.get(eventRef)]);
      if (!user.exists || !counters.exists || event.exists) return;
      if (!wasIncludedInSeed(counters, eventAt)) {
        const update: Record<string, unknown> = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };
        for (const [field, amount] of Object.entries(delta)) {
          if (amount !== 0) update[field] = admin.firestore.FieldValue.increment(amount);
        }
        tx.set(ref, update, { merge: true });
      }
      tx.create(eventRef, { processedAt: admin.firestore.FieldValue.serverTimestamp() });
    });
  }
}

async function applyDecrement(uid: string, delta: Record<string, number>, eventAt: admin.firestore.Timestamp, eventKey: string): Promise<void> {
  const db = admin.firestore();
  const ref = countersRef(uid);
  const userRef = db.doc(`user_profiles/${uid}`);
  const eventRef = counterEventRef(uid, eventKey);
  // Never seed counters from a delete trigger: recursive account cleanup can
  // fire these triggers after removing the profile, and seeding would recreate
  // an otherwise empty parent document. A missing counter can be rebuilt by a
  // later create trigger; clients also fall back to count() while absent.
  await db.runTransaction(async tx => {
    const [user, fresh, event] = await Promise.all([tx.get(userRef), tx.get(ref), tx.get(eventRef)]);
    if (!user.exists || !fresh.exists || event.exists) return;
    if (wasIncludedInSeed(fresh, eventAt)) {
      tx.create(eventRef, { processedAt: admin.firestore.FieldValue.serverTimestamp(), skipped: true });
      return;
    }

    // Decrements run transactionally so concurrent deletes can't drive totals
    // below zero (e.g. batch message deletion racing a late-arriving create).
    const data = fresh.data() ?? {};
    const update: Record<string, unknown> = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };
    for (const [field, amount] of Object.entries(delta)) {
      update[field] = Math.max(0, Number(data[field] ?? 0) + amount);
    }
    tx.set(ref, update, { merge: true });
    tx.create(eventRef, { processedAt: admin.firestore.FieldValue.serverTimestamp() });
  });
}

function journalType(data: Record<string, unknown> | undefined): string {
  return typeof data?.type === 'string' ? (data.type as string) : '';
}

function scanScore(data: Record<string, unknown> | undefined): number | null {
  if (!data || !isLoggableForAverage(data)) return null;
  const score = Number(data.score);
  return Number.isFinite(score) ? Math.round(score) : null;
}

/** Called from onScanCreated (after the streak update); failures are retried by the trigger. */
export async function onScanWrite(uid: string, data: Record<string, unknown> | undefined, eventAt: admin.firestore.Timestamp, eventId: string): Promise<void> {
  try {
    const delta: Record<string, number> = { scans: 1 };
    const score = scanScore(data);
    if (score !== null) {
      delta.foodScoreSum = score;
      delta.foodScoreCount = 1;
    }
    await applyIncrement(uid, delta, eventAt, `scan_created:${eventId}`);
  } catch (e) {
    functions.logger.error(`counters: onScanWrite failed for ${uid}`, e);
    throw e;
  }
}

/** Called from onScanDeleted; failures are retried by the trigger. */
export async function onScanRemoved(uid: string, data: Record<string, unknown> | undefined, eventAt: admin.firestore.Timestamp, eventId: string): Promise<void> {
  try {
    const delta: Record<string, number> = { scans: -1 };
    const score = scanScore(data);
    if (score !== null) {
      delta.foodScoreSum = -score;
      delta.foodScoreCount = -1;
    }
    await applyDecrement(uid, delta, eventAt, `scan_deleted:${eventId}`);
  } catch (e) {
    functions.logger.error(`counters: onScanRemoved failed for ${uid}`, e);
    throw e;
  }
}

/** Called from onJournalEntryCreated; failures are retried by the trigger. */
export async function onJournalWrite(uid: string, data: Record<string, unknown> | undefined, eventAt: admin.firestore.Timestamp, eventId: string): Promise<void> {
  try {
    const type = journalType(data);
    if (type !== 'meal' && type !== 'symptom') return;
    await applyIncrement(uid, type === 'meal' ? { meals: 1 } : { symptoms: 1 }, eventAt, `journal_created:${eventId}`);
  } catch (e) {
    functions.logger.error(`counters: onJournalWrite failed for ${uid}`, e);
    throw e;
  }
}

/** Called from onJournalEntryDeleted; failures are retried by the trigger. */
export async function onJournalRemoved(uid: string, data: Record<string, unknown> | undefined, eventAt: admin.firestore.Timestamp, eventId: string): Promise<void> {
  try {
    const type = journalType(data);
    if (type !== 'meal' && type !== 'symptom') return;
    await applyDecrement(uid, type === 'meal' ? { meals: -1 } : { symptoms: -1 }, eventAt, `journal_deleted:${eventId}`);
  } catch (e) {
    functions.logger.error(`counters: onJournalRemoved failed for ${uid}`, e);
    throw e;
  }
}
