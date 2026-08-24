/**
 * background triggers for proactive health insights.
 *
 * onScanCreated: watches for new scan history entries and triggers warnings
 * if multiple ultra-processed foods (NOVA 3/4) are scanned within a short window.
 */
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { REGION } from './config';
import { calculateStreakUpdate, getLocalDate } from './usage';

/**
 * Shared helper to update user streak based on activity time.
 */
async function handleActivityStreak(uid: string, docTime: any, docOffset?: number) {
  const db = admin.firestore();
  const userRef = db.doc(`user_profiles/${uid}`);

  try {
    await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) return;

      const userData = userSnap.data() || {};

      // 🟢 Fix: Prioritize timezoneOffset from the document, fallback to User Profile.
      // If neither exists (brand new user), skip the update to prevent UTC-based
      // double-counting races with aiProxy.
      const offset = docOffset ?? (userData.timezoneOffset !== undefined ? Number(userData.timezoneOffset) : null);

      if (offset === null) {
        functions.logger.warn(`Skipping streak update for ${uid}: No timezoneOffset available yet.`);
        return;
      }

      const today = getLocalDate(docTime || new Date(), offset);

      const update = calculateStreakUpdate(userData, today);
      if (update) {
        functions.logger.info(`Streak update for ${uid}: ${update.streak} (date: ${today}, offset: ${offset})`);
        tx.set(userRef, update, { merge: true });
      }
    });
  } catch (e) {
    functions.logger.error(`Failed to update streak for ${uid}`, e);
  }
}

export const onScanCreated = functions
  .region(REGION)
  .firestore.document('user_profiles/{uid}/scan_history/{docId}')
  .onCreate(async (snapshot, context) => {
    const { uid } = context.params;
    const scanData = snapshot.data();
    if (!scanData) return;

    // 1. Update Streak
    await handleActivityStreak(uid, scanData.createdAt);

    // 2. Process warnings (existing logic)
    const novaGroup = (scanData.novaGroup || '').toString();
    // Only proceed if the current scan is processed (3 or 4)
    if (novaGroup !== '3' && novaGroup !== '4') return;

    const db = admin.firestore();
    const userRef = db.doc(`user_profiles/${uid}`);

    // Get scans from last 3 days
    const threeDaysAgo = new Date();
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);

    const recentScansSnap = await userRef
      .collection('scan_history')
      .where('createdAt', '>=', threeDaysAgo)
      .get();

    const processedScans = recentScansSnap.docs.filter(doc => {
      const data = doc.data();
      const group = (data.novaGroup || '').toString();
      return group === '3' || group === '4';
    });

    // PRD §13: Trigger warning after 3 processed items in 3 days.
    if (processedScans.length >= 3) {
      const userSnap = await userRef.get();
      const userData = userSnap.data() || {};

      // Throttle: only one warning per week to avoid spamming.
      const lastWarningStr = userData.lastProcessedWarningTime || '';
      const lastWarning = lastWarningStr ? new Date(lastWarningStr) : new Date(0);

      const now = new Date();
      const diffDays = (now.getTime() - lastWarning.getTime()) / (1000 * 3600 * 24);

      if (diffDays >= 7) {
        functions.logger.info(`onScanCreated: Triggering processed food warning for ${uid}`);

        // 1. Log Health Alert (Surfaces in the "Recent Alerts" UI)
        const alertData = {
          title: 'Processed Food Alert',
          message: 'You\'ve logged several processed foods lately. These can disrupt your gut microbiome. Try swapping for "Healing Foods" from your Insights.',
          type: 'processed_food',
          isRead: false,
        };

        await userRef.collection('health_alerts').add({
          ...alertData,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 2. Update throttle timestamp
        await userRef.update({
          lastProcessedWarningTime: admin.firestore.Timestamp.fromDate(now),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 3. Send Push Notification via FCM
        const fcmToken = userData.fcmToken;
        if (fcmToken) {
          try {
            await admin.messaging().send({
              token: fcmToken,
              notification: {
                title: alertData.title,
                body: alertData.message,
              },
              data: {
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                type: 'health_alert',
              },
              android: {
                priority: 'high',
                notification: {
                  channelId: 'gutgood_reminders',
                  color: '#000000',
                },
              },
              apns: {
                payload: {
                  aps: {
                    sound: 'default',
                    badge: 1,
                  },
                },
              },
            });
            functions.logger.info(`onScanCreated: Push sent to ${uid}`);
          } catch (e) {
            functions.logger.error(`onScanCreated: Push failed for ${uid}`, e);
          }
        }
      }
    }
  });

/**
 * onMealCreated: Update streak when a manual meal is logged.
 */
export const onMealCreated = functions
  .region(REGION)
  .firestore.document('user_profiles/{uid}/meal_logs/{docId}')
  .onCreate(async (snapshot, context) => {
    const { uid } = context.params;
    const data = snapshot.data();
    if (data) {
      await handleActivityStreak(uid, data.createdAt);
    }
  });

/**
 * onInsightCreated: Update the profile's aggregate gutScore when a new insight is generated.
 */
export const onInsightCreated = functions
  .region(REGION)
  .firestore.document('user_profiles/{uid}/insights/{docId}')
  .onCreate(async (snapshot, context) => {
    const { uid } = context.params;
    const data = snapshot.data();
    if (!data) return;

    const gutScore = Math.round(Number(data.gutScore));
    if (isNaN(gutScore)) return;

    const db = admin.firestore();
    const userRef = db.doc(`user_profiles/${uid}`);

    try {
      await userRef.update({
        gutScore,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      functions.logger.info(`Updated gutScore for ${uid} to ${gutScore}`);
    } catch (e) {
      functions.logger.error(`Failed to update gutScore for ${uid}`, e);
    }
  });

/**
 * onSymptomCreated: Update streak when a manual symptom check-in is performed.
 */
export const onSymptomCreated = functions
  .region(REGION)
  .firestore.document('user_profiles/{uid}/symptom_logs/{docId}')
  .onCreate(async (snapshot, context) => {
    const { uid } = context.params;
    const data = snapshot.data();
    if (data) {
      await handleActivityStreak(uid, data.createdAt);
    }
  });

