/**
 * mergeAnonymousAccount — atomic, idempotent anonymous→permanent account merge.
 *
 * Why server-side (per auth/firestore audit §1.2): after the conflict branch of
 * `_linkOrMerge`, the client's Auth session has ALREADY switched to the permanent
 * account, so the client can no longer read its own anonymous subtree under the
 * security rules (request.auth.uid != anonymousUid) → every client-side merge
 * attempt fails with PERMISSION_DENIED. The Admin SDK bypasses rules, performs
 * the whole migration atomically, and is idempotent via merge markers.
 */
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { REGION } from './config';

const BATCH_LIMIT = 400;
const READ_LIMIT = 500;

const ID_COLLECTIONS = ['chat_history', 'journal_logs', 'health_alerts'];
const SCAN_COLLECTIONS = ['scan_history', 'saved_foods'];
const INSIGHT_COLLECTION = 'insights';
const PATTERN_COLLECTION = 'pattern_data';
const USAGE_COLLECTION = 'daily_usage';

const URL_FIELDS = new Set(['imageUrl', 'userImageUrl', 'photoUrl']);
const URL_LIST_FIELDS = new Set(['imageUrls']);

function encodedUserPrefix(uid: string): string {
  return `users%2F${uid}%2F`;
}

/** Recursively rewrites Storage download URLs from the old uid to the new uid. */
function rewriteUrls(value: unknown, fromUid: string, toUid: string, depth = 0): unknown {
  if (depth > 6 || value == null) return value;
  if (typeof value === 'string') {
    return value.includes(encodedUserPrefix(fromUid))
      ? value.split(encodedUserPrefix(fromUid)).join(encodedUserPrefix(toUid))
      : value;
  }
  if (Array.isArray(value)) {
    return value.map((v) => rewriteUrls(v, fromUid, toUid, depth + 1));
  }
  if (typeof value === 'object') {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
      out[k] = rewriteUrls(v, fromUid, toUid, depth + 1);
    }
    return out;
  }
  return value;
}

/** Natural-key hash used for content-based dedupe across collections. */
function naturalKey(collection: string, data: admin.firestore.DocumentData): string {
  if (ID_COLLECTIONS.includes(collection)) {
    if (data.localId) return `lid:${data.localId}`;
    const items = Array.isArray(data.items) ? data.items.join(',') : '';
    const body = (data.text || data.message || '').toString();
    const time = (data.createdAt || data.time || data.timestamp || '').toString();
    return `${data.role ?? ''}|${body}|${items}|${data.symptom ?? ''}|${data.title ?? ''}|${time}`;
  }
  if (SCAN_COLLECTIONS.includes(collection)) {
    const barcode = (data.barcode ?? '').toString();
    return barcode ? `bc:${barcode}` : `pn:${(data.productName ?? '').toString().toLowerCase()}`;
  }
  if (collection === INSIGHT_COLLECTION) {
    const title = data.topInsight?.title ?? data.title ?? '';
    return `${data.type ?? ''}|${title}|${data.gutScore ?? ''}`;
  }
  return JSON.stringify(data).slice(0, 512);
}

async function migrateStorage(fromUid: string, toUid: string): Promise<number> {
  const bucket = admin.storage().bucket();
  const [files] = await bucket.getFiles({ prefix: `users/${fromUid}/` });
  let copied = 0;
  for (const file of files) {
    const destination = file.name.replace(`users/${fromUid}/`, `users/${toUid}/`);
    try {
      await file.copy(destination);
      copied++;
    } catch (e) {
      functions.logger.error(`merge: failed to copy ${file.name}`, e);
    }
  }
  return copied;
}

async function mergeSubcollection(
  db: admin.firestore.Firestore,
  anonRef: admin.firestore.DocumentReference,
  permRef: admin.firestore.DocumentReference,
  sourceCollection: string,
  targetCollection: string,
  fromUid: string,
  toUid: string,
  extraFields: Record<string, unknown> = {},
): Promise<number> {
  // Load ALL target keys first (content-addressed dedupe).
  const target = await permRef.collection(targetCollection).orderBy(admin.firestore.FieldPath.documentId()).limit(READ_LIMIT).get();
  const existingKeys = new Set(target.docs.map((d) => naturalKey(targetCollection, d.data())));

  let moved = 0;
  let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;

  while (true) {
    let query = anonRef.collection(sourceCollection).orderBy(admin.firestore.FieldPath.documentId()).limit(READ_LIMIT);
    if (lastDoc) query = query.startAfter(lastDoc);

    const source = await query.get();
    if (source.empty) break;

    let batch = db.batch();
    let pending = 0;

    for (const doc of source.docs) {
      const raw = doc.data();
      const key = naturalKey(targetCollection, raw);
      if (existingKeys.has(key)) continue;
      existingKeys.add(key);

      let data: admin.firestore.DocumentData = { ...raw, ...extraFields, migratedFrom: fromUid };
      for (const field of Object.keys(data)) {
        if (URL_FIELDS.has(field) || URL_LIST_FIELDS.has(field)) {
          data[field] = rewriteUrls(data[field], fromUid, toUid);
        }
      }

      batch.set(permRef.collection(targetCollection).doc(), data);
      pending++;
      moved++;

      if (pending >= BATCH_LIMIT) {
        await batch.commit();
        batch = db.batch();
        pending = 0;
      }
    }

    if (pending > 0) await batch.commit();
    lastDoc = source.docs[source.docs.length - 1];

    if (source.size < READ_LIMIT) break;
  }

  return moved;
}

/** Idempotent daily_usage merge: each source uid is folded in at most once. */
async function mergeDailyUsage(
  db: admin.firestore.Firestore,
  anonRef: admin.firestore.DocumentReference,
  permRef: admin.firestore.DocumentReference,
  fromUid: string,
): Promise<number> {
  const source = await anonRef.collection(USAGE_COLLECTION).get();
  if (source.empty) return 0;
  let merged = 0;

  for (const doc of source.docs) {
    const data = doc.data();
    const targetRef = permRef.collection(USAGE_COLLECTION).doc(doc.id);
    const folded = await db.runTransaction(async (tx) => {
      const snap = await tx.get(targetRef);
      const target = snap.data() ?? {};
      const mergedFrom: string[] = Array.isArray(target.mergedFrom) ? target.mergedFrom : [];
      if (mergedFrom.includes(fromUid)) return false;
      tx.set(
        targetRef,
        {
          chat_count: admin.firestore.FieldValue.increment((data.chat_count as number) ?? 0),
          scan_count: admin.firestore.FieldValue.increment((data.scan_count as number) ?? 0),
          system_count: admin.firestore.FieldValue.increment((data.system_count as number) ?? 0),
          mergedFrom: [...mergedFrom, fromUid],
        },
        { merge: true },
      );
      return true;
    });
    if (folded) merged++;
  }
  return merged;
}

/** Unions personalization arrays and carries over onboarding state. */
async function mergeProfileRoot(
  db: admin.firestore.Firestore,
  anonRef: admin.firestore.DocumentReference,
  permRef: admin.firestore.DocumentReference,
): Promise<void> {
  const [anonSnap, permSnap] = await Promise.all([anonRef.get(), permRef.get()]);
  if (!anonSnap.exists) return;
  const anon = anonSnap.data() ?? {};
  const perm = permSnap.data() ?? {};

  const union = (field: string): string[] => {
    const a = Array.isArray(anon[field]) ? (anon[field] as string[]) : [];
    const b = Array.isArray(perm[field]) ? (perm[field] as string[]) : [];
    return [...new Set([...b, ...a])];
  };

  const update: Record<string, unknown> = {
    goals: union('goals'),
    sensitivities: union('sensitivities'),
    lifestyle: union('lifestyle'),
  };
  if (!permSnap.exists || perm.onboarded !== true) {
    if (anon.onboarded === true) update.onboarded = true;
  }
  if (!perm.cycleSyncEnabled && anon.cycleSyncEnabled === true) {
    update.cycleSyncEnabled = true;
    if (anon.cyclePhase) update.cyclePhase = anon.cyclePhase;
  }
  if (anon.notificationPreferences && !perm.notificationPreferences) {
    update.notificationPreferences = anon.notificationPreferences;
  }
  if (anon.timezoneOffset !== undefined && perm.timezoneOffset === undefined) {
    update.timezoneOffset = anon.timezoneOffset;
  }

  // 🟢 Streak Merge Logic: Keep the best streak/date
  const anonStreak = Number(anon.streak ?? 0);
  const permStreak = Number(perm.streak ?? 0);
  if (anonStreak > permStreak) {
    update.streak = anonStreak;
    if (anon.lastActivityDate) update.lastActivityDate = anon.lastActivityDate;
  } else if (anonStreak === permStreak && anonStreak > 0) {
    // If streaks are equal, prefer the one with the latest activity date
    const anonDate = (anon.lastActivityDate ?? '').toString();
    const permDate = (perm.lastActivityDate ?? '').toString();
    if (anonDate > permDate) {
      update.lastActivityDate = anonDate;
    }
  }

  // NEVER copy: isPremium, subscriptionStatus, gutScore, authProvider.
  // Premium is client-side (RevenueCat SDK entitlement): the new account must
  // re-derive it from the SDK on next launch — never inherit it from a guest
  // profile, or a guest could smuggle a premium flag into a paid account.

  await db.runTransaction(async (tx) => {
    tx.set(permRef, update, { merge: true });
  });
}

export const mergeAnonymousAccount = functions
  .region(REGION)
  .runWith({ timeoutSeconds: 300, memory: '512MB' })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Sign-in required.');
    }

    const permanentUid = context.auth.uid;
    const anonymousUid = (data?.anonymousUid ?? '').toString();

    if (!anonymousUid || anonymousUid === permanentUid) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid anonymousUid.');
    }

    // The caller must be the PERMANENT account (post-session-switch).
    const caller = await admin.auth().getUser(permanentUid).catch(() => null);
    if (!caller || caller.providerData.length === 0) {
      throw new functions.https.HttpsError('failed-precondition', 'Caller must be a non-anonymous account.');
    }

    const db = admin.firestore();
    const permRef = db.doc(`user_profiles/${permanentUid}`);
    const anonRef = db.doc(`user_profiles/${anonymousUid}`);
    const markerRef = permRef.collection('merges').doc(anonymousUid);

    // Idempotency: a retried merge is a no-op.
    const marker = await markerRef.get();
    if (marker.exists) {
      return { alreadyMerged: true, moved: {} };
    }

    // Verify the source really is (was) an anonymous account.
    const anonUser = await admin.auth().getUser(anonymousUid).catch(() => null);
    if (anonUser && anonUser.providerData.length > 0) {
      throw new functions.https.HttpsError('failed-precondition', 'Source account is not anonymous.');
    }

    functions.logger.info(`merge: ${anonymousUid} -> ${permanentUid}`);
    const moved: Record<string, number> = {};

    // 1. Copy Storage files first so rewritten URLs resolve.
    moved.files = anonUser ? await migrateStorage(anonymousUid, permanentUid) : 0;

    // 2. Merge subcollections with mapping support
    const collectionsToMerge = [
      ...ID_COLLECTIONS,
      ...SCAN_COLLECTIONS,
      INSIGHT_COLLECTION,
    ];

    for (const collection of collectionsToMerge) {
      moved[collection] = await mergeSubcollection(db, anonRef, permRef, collection, collection, anonymousUid, permanentUid);
    }

    // 🚀 Consolidated Merge: Migrate legacy collections into new unified homes
    moved.meal_logs_migrated = await mergeSubcollection(db, anonRef, permRef, 'meal_logs', 'journal_logs', anonymousUid, permanentUid, { type: 'meal' });
    moved.symptom_logs_migrated = await mergeSubcollection(db, anonRef, permRef, 'symptom_logs', 'journal_logs', anonymousUid, permanentUid, { type: 'symptom' });
    moved.label_scans_migrated = await mergeSubcollection(db, anonRef, permRef, 'label_scans', 'scan_history', anonymousUid, permanentUid, { source: 'label', category: 'label' });
    moved.restaurant_menu_scans_migrated = await mergeSubcollection(db, anonRef, permRef, 'restaurant_menu_scans', 'scan_history', anonymousUid, permanentUid, { source: 'menu', category: 'menu' });

    // 3. Pattern data: single 'latest' document, safe to overwrite.
    const pattern = await anonRef.collection(PATTERN_COLLECTION).doc('latest').get();
    if (pattern.exists) {
      await permRef.collection(PATTERN_COLLECTION).doc('latest').set(pattern.data() ?? {}, { merge: true });
      moved.pattern_data = 1;
    }

    // 4. Daily usage (idempotent per-source fold).
    moved.daily_usage = await mergeDailyUsage(db, anonRef, permRef, anonymousUid);

    // 5. Profile root (personalization union).
    await mergeProfileRoot(db, anonRef, permRef);

    // 6. Marker LAST: everything before this is naturally idempotent or deduped.
    await markerRef.set({ mergedAt: admin.firestore.FieldValue.serverTimestamp() });

    // 7. Cleanup: wipe the anonymous subtree + reclaim the identity.
    //    The onUserDeleted trigger is the guaranteed backstop for any residue.
    try {
      await db.recursiveDelete(anonRef);
    } catch (e) {
      functions.logger.error('merge: recursiveDelete failed (trigger will retry via onDelete)', e);
    }
    if (anonUser) {
      await admin.auth().deleteUser(anonymousUid).catch((e) => {
        functions.logger.error('merge: deleteUser failed', e);
      });
    }

    functions.logger.info(`merge complete`, moved);
    return { alreadyMerged: false, moved };
  });
