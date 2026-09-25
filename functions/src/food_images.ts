/**
 * Food-image registry workers (audit §E).
 *
 *   generateFoodThumb     Storage  1024px original -> 320px thumb + doc backfill
 *   sweepUnlinkedFoodImages Cron    Deletes unlinked originals+thumbs after 30d grace
 *
 * Only canonical §E objects (`users/{uid}/food_images/<sha256_16>.jpg`) are
 * touched. Legacy timestamp-named uploads keep working untouched: they have
 * no registry doc, and the sweeper only deletes docs it can age.
 */
import { randomUUID } from 'node:crypto';
import * as admin from 'firebase-admin';
import { onObjectFinalized } from 'firebase-functions/v2/storage';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as logger from 'firebase-functions/logger';
import sharp from 'sharp';
import { REGION } from './config';

const FOOD_IMAGE_RE = /^users\/([^/]+)\/food_images\/([0-9a-f]{16})\.jpg$/;
const GRACE_MS = 30 * 24 * 3600 * 1000;

/** Derives the 320px thumb for a newly uploaded original and backfills the registry doc. */
export const generateFoodThumb = onObjectFinalized({ region: 'us-central1' }, async (event) => {
  const path = event.data.name ?? '';
  const match = FOOD_IMAGE_RE.exec(path);
  if (!match) return; // avatars, thumbs/, legacy timestamp names — not ours
  const [, uid, hash] = match;

  const bucket = admin.storage().bucket(event.data.bucket);
  try {
    const [bytes] = await bucket.file(path).download();
    const meta = await sharp(bytes).metadata();
    const thumb = await sharp(bytes).resize(320, 320, { fit: 'inside', withoutEnlargement: true }).jpeg({ quality: 72 }).toBuffer();

    // Permanent download URL via an embedded token (same shape the client SDK mints).
    const token = randomUUID();
    const thumbPath = `users/${uid}/food_images/thumbs/${hash}.jpg`;
    await bucket.file(thumbPath).save(thumb, {
      contentType: 'image/jpeg',
      metadata: { metadata: { firebaseStorageDownloadTokens: token } },
    });
    const thumbUrl = `https://firebasestorage.googleapis.com/v0/b/${event.data.bucket}/o/${encodeURIComponent(thumbPath)}?alt=media&token=${token}`;

    await admin
      .firestore()
      .collection('user_profiles')
      .doc(uid)
      .collection('food_images')
      .doc(hash)
      .set(
        { thumbPath, thumbUrl, width: meta.width ?? 0, height: meta.height ?? 0, bytes: bytes.length, backfilledAt: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true },
      );
    logger.info(`food_images: thumb generated for ${uid}/${hash}`);
  } catch (e) {
    logger.error(`food_images: thumb generation failed for ${path}`, e);
  }
});

function millis(value: unknown): number {
  if (value instanceof admin.firestore.Timestamp) return value.toMillis();
  if (typeof value === 'number') return value;
  return 0;
}

/**
 * Deletes registry docs (plus their Storage objects) that have been
 * unlinked for 30+ days. Single-field `linkCount == 0` query — no composite
 * index needed; the 30d grace filter runs client-side. Docs without a known
 * age are never swept.
 */
export const sweepUnlinkedFoodImages = onSchedule({ schedule: 'every day 03:00', region: REGION }, async () => {
  const db = admin.firestore();
  const bucket = admin.storage().bucket();
  const cutoff = Date.now() - GRACE_MS;

  const snap = await db.collectionGroup('food_images').where('linkCount', '==', 0).get();
  let swept = 0;
  for (const doc of snap.docs) {
    const data = doc.data();
    const created = millis(data.createdAt);
    if (created === 0) continue; // un-ageable: never sweep
    const anchored = Math.max(created, millis(data.lastUnlinkedAt));
    if (anchored > cutoff) continue; // still in grace

    for (const key of ['storagePath', 'thumbPath'] as const) {
      const path = data[key];
      if (typeof path !== 'string' || path.length === 0) continue;
      try {
        await bucket.file(path).delete({ ignoreNotFound: true });
      } catch (e) {
        logger.warn(`food_images: Storage delete failed for ${path}`, e);
      }
    }
    try {
      await doc.ref.delete();
      swept++;
    } catch (e) {
      logger.warn(`food_images: doc delete failed for ${doc.ref.path}`, e);
    }
  }
  logger.info(`food_images: swept ${swept} unlinked image(s)`);
});
