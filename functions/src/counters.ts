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
 * No backfill job is needed: when the counters doc is missing, the next
 * create/delete trigger seeds it with a one-time full recompute (which
 * already reflects the triggering write, so no delta is applied on top).
 * Until then, the client falls back to cheap `count()` aggregations.
 */
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';

const COUNTERS_DOC = 'totals';

function countersRef(uid: string): admin.firestore.DocumentReference {
  return admin.firestore().doc(`user_profiles/${uid}/counters/${COUNTERS_DOC}`);
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
  const userRef = admin.firestore().doc(`user_profiles/${uid}`);
  const [scansSnap, mealsSnap, symptomsSnap] = await Promise.all([
    userRef.collection('scan_history').get(),
    userRef.collection('journal_logs').where('type', '==', 'meal').get(),
    userRef.collection('journal_logs').where('type', '==', 'symptom').get(),
  ]);

  let foodScoreSum = 0;
  let foodScoreCount = 0;
  for (const doc of scansSnap.docs) {
    const data = doc.data();
    if (!isLoggableForAverage(data)) continue;
    const score = Number(data.score);
    if (!Number.isFinite(score)) continue;
    foodScoreSum += Math.round(score);
    foodScoreCount += 1;
  }

  await countersRef(uid).set({
    scans: scansSnap.size,
    meals: mealsSnap.size,
    symptoms: symptomsSnap.size,
    foodScoreSum,
    foodScoreCount,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  functions.logger.info(
    `counters: seeded for ${uid} (scans=${scansSnap.size} meals=${mealsSnap.size} symptoms=${symptomsSnap.size} scores=${foodScoreCount})`,
  );
}

async function applyIncrement(uid: string, delta: Record<string, number>): Promise<void> {
  const ref = countersRef(uid);
  const snap = await ref.get();
  if (!snap.exists) {
    // Lazy backfill: the triggering write is already in the collections, so a
    // straight recompute includes it — applying a delta on top would double it.
    await seedCounters(uid);
    return;
  }
  const update: Record<string, unknown> = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };
  for (const [field, amount] of Object.entries(delta)) {
    if (amount !== 0) update[field] = admin.firestore.FieldValue.increment(amount);
  }
  await ref.set(update, { merge: true });
}

async function applyDecrement(uid: string, delta: Record<string, number>): Promise<void> {
  const ref = countersRef(uid);
  const userRef = admin.firestore().doc(`user_profiles/${uid}`);
  // Never seed counters from a delete trigger: recursive account cleanup can
  // fire these triggers after removing the profile, and seeding would recreate
  // an otherwise empty parent document. A missing counter can be rebuilt by a
  // later create trigger; clients also fall back to count() while absent.
  await admin.firestore().runTransaction(async tx => {
    const user = await tx.get(userRef);
    if (!user.exists) return;

    const fresh = await tx.get(ref);
    if (!fresh.exists) return;

    // Decrements run transactionally so concurrent deletes can't drive totals
    // below zero (e.g. batch message deletion racing a late-arriving create).
    const data = fresh.data() ?? {};
    const update: Record<string, unknown> = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };
    for (const [field, amount] of Object.entries(delta)) {
      update[field] = Math.max(0, Number(data[field] ?? 0) + amount);
    }
    tx.set(ref, update, { merge: true });
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

/** Called from onScanCreated (after the streak update). Never throws. */
export async function onScanWrite(uid: string, data: Record<string, unknown> | undefined): Promise<void> {
  try {
    const delta: Record<string, number> = { scans: 1 };
    const score = scanScore(data);
    if (score !== null) {
      delta.foodScoreSum = score;
      delta.foodScoreCount = 1;
    }
    await applyIncrement(uid, delta);
  } catch (e) {
    functions.logger.error(`counters: onScanWrite failed for ${uid}`, e);
  }
}

/** Called from onScanDeleted. Never throws. */
export async function onScanRemoved(uid: string, data: Record<string, unknown> | undefined): Promise<void> {
  try {
    const delta: Record<string, number> = { scans: -1 };
    const score = scanScore(data);
    if (score !== null) {
      delta.foodScoreSum = -score;
      delta.foodScoreCount = -1;
    }
    await applyDecrement(uid, delta);
  } catch (e) {
    functions.logger.error(`counters: onScanRemoved failed for ${uid}`, e);
  }
}

/** Called from onJournalEntryCreated. Never throws. */
export async function onJournalWrite(uid: string, data: Record<string, unknown> | undefined): Promise<void> {
  try {
    const type = journalType(data);
    if (type !== 'meal' && type !== 'symptom') return;
    await applyIncrement(uid, type === 'meal' ? { meals: 1 } : { symptoms: 1 });
  } catch (e) {
    functions.logger.error(`counters: onJournalWrite failed for ${uid}`, e);
  }
}

/** Called from onJournalEntryDeleted. Never throws. */
export async function onJournalRemoved(uid: string, data: Record<string, unknown> | undefined): Promise<void> {
  try {
    const type = journalType(data);
    if (type !== 'meal' && type !== 'symptom') return;
    await applyDecrement(uid, type === 'meal' ? { meals: -1 } : { symptoms: -1 });
  } catch (e) {
    functions.logger.error(`counters: onJournalRemoved failed for ${uid}`, e);
  }
}
