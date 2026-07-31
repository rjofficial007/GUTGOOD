/**
 * Account lifecycle functions.
 *
 * onUserDeleted (audit §2.4): the guaranteed backstop for cascade deletion.
 * If the client deletes the Auth user but the network drops before Firestore /
 * Storage cleanup runs, this trigger ensures the data is purged anyway —
 * otherwise it would be orphaned forever (no client can satisfy the security
 * rules for a uid that no longer exists).
 *
 * cleanupAnonymousUsers (audit §2.3): bounds storage/cost growth and closes the
 * GDPR gap from abandoned guest sessions.
 */
import * as functionsV1 from 'firebase-functions/v1';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { REGION } from './config';

const ANONYMOUS_TTL_DAYS = 14;

async function purgeUserData(uid: string): Promise<void> {
  const db = admin.firestore();
  try {
    await db.recursiveDelete(db.doc(`user_profiles/${uid}`));
  } catch (e) {
    functionsV1.logger.error(`purge: Firestore cleanup failed for ${uid}`, e);
  }
  try {
    await admin.storage().bucket().deleteFiles({ prefix: `users/${uid}/` });
  } catch (e) {
    functionsV1.logger.error(`purge: Storage cleanup failed for ${uid}`, e);
  }
}

export const onUserDeleted = functionsV1
  .region(REGION)
  .auth.user()
  .onDelete(async (user) => {
    functionsV1.logger.info(`onUserDeleted: purging data for ${user.uid}`);
    await purgeUserData(user.uid);
  });

export const cleanupAnonymousUsers = onSchedule(
  { schedule: 'every day 03:00', timeZone: 'Etc/UTC', region: REGION },
  async () => {
    const cutoff = Date.now() - ANONYMOUS_TTL_DAYS * 24 * 60 * 60 * 1000;
    let deleted = 0;
    let nextPageToken: string | undefined;

    do {
      const page = await admin.auth().listUsers(1000, nextPageToken);
      for (const user of page.users) {
        const isAnonymous = user.providerData.length === 0;
        if (!isAnonymous) continue;
        const createdAt = Date.parse(user.metadata.creationTime);
        const lastSignIn = Date.parse(user.metadata.lastSignInTime || user.metadata.creationTime);
        const stale = Number.isFinite(createdAt) && createdAt < cutoff && (!Number.isFinite(lastSignIn) || lastSignIn < cutoff);
        if (stale) {
          // Deleting the auth user cascades via onUserDeleted.
          await admin.auth().deleteUser(user.uid).catch((e) => {
            functionsV1.logger.error(`cleanup: failed to delete ${user.uid}`, e);
          });
          deleted++;
        }
      }
      nextPageToken = page.pageToken;
    } while (nextPageToken);

    functionsV1.logger.info(`cleanupAnonymousUsers: removed ${deleted} abandoned guest accounts`);
  },
);
