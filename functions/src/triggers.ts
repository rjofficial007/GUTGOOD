/**
 * background triggers for proactive health insights.
 *
 * onScanCreated: watches for new scan history entries and triggers warnings
 * if multiple ultra-processed foods (NOVA 3/4) are scanned within a short window.
 */
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { REGION } from './config';

export const onScanCreated = functions
  .region(REGION)
  .firestore.document('user_profiles/{uid}/scan_history/{docId}')
  .onCreate(async (snapshot, context) => {
    const { uid } = context.params;
    const scanData = snapshot.data();
    if (!scanData) return;

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
      .where('time', '>=', threeDaysAgo.toISOString())
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
          time: now.toISOString(),
          isRead: false,
        };

        await userRef.collection('health_alerts').add({
          ...alertData,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 2. Update throttle timestamp
        await userRef.update({
          lastProcessedWarningTime: now.toISOString(),
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

export const onInsightCreated = functions
  .region(REGION)
  .firestore.document('user_profiles/{uid}/insights/{docId}')
  .onCreate(async (snapshot, context) => {
    const { uid } = context.params;
    const insightData = snapshot.data();
    if (!insightData) return;

    const db = admin.firestore();
    const userRef = db.doc(`user_profiles/${uid}`);
    const userSnap = await userRef.get();
    const userData = userSnap.data() || {};

    const fcmToken = userData.fcmToken;
    if (!fcmToken) return;

    try {
      const title = 'Gut Insight Ready';
      const message = 'Your latest personalized gut health analysis is ready. Open to see your new score!';

      // 1. Log Health Alert
      await userRef.collection('health_alerts').add({
        title,
        message,
        type: 'insight_ready',
        time: new Date().toISOString(),
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2. Send Push
      await admin.messaging().send({
        token: fcmToken,
        notification: { title, body: message },
        data: { click_action: 'FLUTTER_NOTIFICATION_CLICK', type: 'insight_generated' },
        android: { priority: 'high', notification: { channelId: 'gutgood_reminders', color: '#000000' } },
        apns: { payload: { aps: { sound: 'default', badge: 1 } } },
      });
      functions.logger.info(`onInsightCreated: Push sent to ${uid}`);
    } catch (e) {
      functions.logger.error(`onInsightCreated: Notification failed for ${uid}`, e);
    }
  });
