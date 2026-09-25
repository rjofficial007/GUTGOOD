import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { REGION, SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM } from './config';
import { sendMagicLinkEmail } from './email';

/**
 * HTTPS Callable: Generates a sign-in link and sends it via custom SMTP.
 *
 * ACCEPTED RISK R5 (docs/ACCEPTED_RISKS.md): intentionally no authentication
 * (pre-login flow), no per-email/per-IP rate limiting, and no App Check — an
 * unauthenticated script could relay branded sign-in emails to arbitrary
 * addresses through our SMTP. Add throttling + App Check before public launch.
 */
export const sendCustomMagicLink = functions
  .region(REGION)
  .runWith({
    secrets: [SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM],
  })
  .https.onCall(async (data, context) => {
    const { email, name } = data;

    if (!email) {
      throw new functions.https.HttpsError('invalid-argument', 'Email is required');
    }

    // These settings must match your Firebase project's configuration
    const actionCodeSettings = {
      url: 'https://gutgood-app-9242d.firebaseapp.com/auth-completed',
      handleCodeInApp: true,
      android: {
        packageName: 'com.gutgood.app',
        installApp: true,
        minimumVersion: '1',
      },
      iOS: {
        bundleId: 'com.gutgood.app',
      },
    };

    try {
      const link = await admin.auth().generateSignInWithEmailLink(email, actionCodeSettings);
      await sendMagicLinkEmail(email, link, name);
      return { success: true };
    } catch (error) {
      functions.logger.error('sendCustomMagicLink: failed', error);
      throw new functions.https.HttpsError('internal', 'Failed to send login link');
    }
  });

/**
 * HTTPS Callable: Deletes the current user's Firebase Auth account using Admin SDK.
 *
 * Bypasses the client-side `requires-recent-login` re-authentication check while
 * ensuring the caller is authenticated. Account deletion automatically triggers
 * `onUserDeleted` in lifecycle.ts to purge Firestore profile and Storage files.
 */
export const deleteAccount = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated to delete account.');
    }

    const uid = context.auth.uid;
    functions.logger.info(`deleteAccount: deleting user ${uid}`);

    try {
      await admin.auth().deleteUser(uid);
      return { success: true };
    } catch (error) {
      functions.logger.error(`deleteAccount: failed for ${uid}`, error);
      throw new functions.https.HttpsError('internal', 'Failed to delete user account.');
    }
  });
