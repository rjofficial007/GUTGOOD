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
import { REGION, SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM } from './config';
import { sendWelcomeEmail } from './email';

const ANONYMOUS_TTL_DAYS = 14;

async function purgeUserData(uid: string): Promise<void> {
  const db = admin.firestore();
  const errors: unknown[] = [];
  try {
    await db.recursiveDelete(db.doc(`user_profiles/${uid}`));
  } catch (e) {
    functionsV1.logger.error(`purge: Firestore cleanup failed for ${uid}`, e);
    errors.push(e);
  }
  try {
    await admin.storage().bucket().deleteFiles({ prefix: `users/${uid}/` });
  } catch (e) {
    functionsV1.logger.error(`purge: Storage cleanup failed for ${uid}`, e);
    errors.push(e);
  }
  if (errors.length > 0) throw new Error(`Failed to fully purge user data for ${uid}: ${errors.length} cleanup operation(s) failed.`);
}

export const onUserDeleted = functionsV1
  .region(REGION)
  .runWith({ failurePolicy: true })
  .auth.user()
  .onDelete(async (user) => {
    functionsV1.logger.info(`onUserDeleted: purging data for ${user.uid}`);
    await purgeUserData(user.uid);
  });

/**
 * Triggered when a user profile is created or updated in Firestore.
 * Ensures every new permanent user gets a welcome email exactly once.
 * Covers: direct sign-in, account upgrade (link), and account merge.
 *
 * ACCEPTED RISK R6 (docs/ACCEPTED_RISKS.md): `email`, `displayName` (unescaped
 * in the HTML body), `isAnonymous`, and `welcomeEmailSent` are all
 * client-writable profile fields — a client can direct welcome emails to
 * arbitrary/third-party addresses (with HTML in the name) and re-trigger them.
 * Hardening path: recipient from admin.auth().getUser(), escape displayName,
 * rules-lock the welcomeEmailSent* flags.
 */
export const onProfileWritten = functionsV1
  .region(REGION)
  .runWith({
    secrets: [SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM],
  })
  .firestore.document('user_profiles/{uid}')
  .onWrite(async (change, context) => {
    const { uid } = context.params;
    const newData = change.after.exists ? change.after.data() : null;
    const oldData = change.before.exists ? change.before.data() : null;

    if (!newData) return; // Deleted profile

    // 1. Only send if the user is now permanent (not anonymous)
    if (newData.isAnonymous === true) return;

    // 2. Only send if we have an email address
    const email = newData.email;
    if (!email || email === 'No email synced') return;

    // 3. Throttle: only send if it's a new permanent status OR a brand new profile
    const wasAnonymous = !oldData || oldData.isAnonymous === true;
    if (!wasAnonymous) return;

    // 4. Idempotency: don't send twice
    if (newData.welcomeEmailSent === true) return;

    functionsV1.logger.info(`onProfileWritten: sending welcome email to ${uid} (${email})`);

    try {
      await sendWelcomeEmail(email, newData.displayName || '');

      // Mark as sent in Firestore
      await change.after.ref.update({
        welcomeEmailSent: true,
        welcomeEmailSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (e) {
      functionsV1.logger.error(`onProfileWritten: failed for ${uid}`, e);
    }
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
