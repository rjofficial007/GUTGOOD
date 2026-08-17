import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { REGION, SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM } from './config';
import { sendMagicLinkEmail } from './email';

/**
 * HTTPS Callable: Generates a sign-in link and sends it via custom SMTP.
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
