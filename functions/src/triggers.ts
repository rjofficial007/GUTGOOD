/**
 * background triggers for proactive health insights.
 *
 * onScanCreated: watches for new scan history entries and triggers warnings
 * if multiple ultra-processed foods (NOVA 3/4) are scanned within a short window.
 * Also maintains history counters (see counters.ts), as do onScanDeleted,
 * onJournalEntryCreated, and onJournalEntryDeleted.
 */
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { REGION } from './config';
import { calculateStreakUpdate, getLocalDate } from './usage';
import { onScanWrite, onScanRemoved, onJournalWrite, onJournalRemoved } from './counters';

function eventTimestamp(value: string): admin.firestore.Timestamp {
  const milliseconds = Date.parse(value);
  if (!Number.isFinite(milliseconds)) throw new Error(`Invalid Firestore event timestamp: ${value}`);
  const seconds = Math.floor(milliseconds / 1000);
  const fraction = value.match(/\.(\d+)/)?.[1] ?? '';
  const nanoseconds = Number(fraction.padEnd(9, '0').slice(0, 9));
  return new admin.firestore.Timestamp(seconds, nanoseconds);
}

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
  .runWith({ failurePolicy: true })
  .firestore.document('user_profiles/{uid}/scan_history/{docId}')
  .onCreate(async (snapshot, context) => {
    const { uid } = context.params;
    const scanData = snapshot.data();
    if (!scanData) return;
    const db = admin.firestore();
    const userRef = db.doc(`user_profiles/${uid}`);
    if (!(await userRef.get()).exists) return;

    // 1. Update Streak
    await handleActivityStreak(uid, scanData.createdAt);

    // 1b. Bump history counters (dashboard + gating + profile average).
    // Runs for every scan, including non-processed ones (the NOVA guard below
    // returns early — counters must not).
    await onScanWrite(uid, scanData, eventTimestamp(context.timestamp), context.eventId);

    // 2. Process warnings (existing logic)
    const novaGroup = (scanData.novaGroup || '').toString();
    // Only proceed if the current scan is processed (3 or 4)
    if (novaGroup !== '3' && novaGroup !== '4') return;

    // 🛡️ Semantic Check: Skip non-product scans (menus, generic labels) to avoid false alerts
    const source = (scanData.source || '').toLowerCase();
    const category = (scanData.category || '').toLowerCase();
    const name = (scanData.productName || '').toLowerCase();
    if (source === 'menu' || category === 'menu' || name.includes('menu')) return;

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
      const now = new Date();
      const alertData = {
        title: 'Processed Food Alert',
        message: 'You\'ve logged several processed foods lately. These can disrupt your gut microbiome. Try swapping for "Healing Foods" from your Insights.',
        type: 'processed_food',
        isRead: false,
      };
      const alertRef = userRef.collection('health_alerts').doc();
      const fcmToken = await db.runTransaction(async (tx) => {
        const profile = await tx.get(userRef);
        if (!profile.exists) return null;

        // Throttle atomically with the alert write, and never create an alert
        // under a data-less profile if the Auth user was just removed.
        const lastWarningValue = profile.data()?.lastProcessedWarningTime;
        const lastWarning = lastWarningValue?.toDate instanceof Function
          ? lastWarningValue.toDate()
          : new Date(lastWarningValue || 0);
        if (now.getTime() - lastWarning.getTime() < 7 * 24 * 60 * 60 * 1000) return null;

        tx.create(alertRef, { ...alertData, createdAt: admin.firestore.FieldValue.serverTimestamp() });
        tx.update(userRef, {
          lastProcessedWarningTime: admin.firestore.Timestamp.fromDate(now),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return profile.data()?.fcmToken as string | undefined;
      });

      if (fcmToken !== null) {
        functions.logger.info(`onScanCreated: Triggering processed food warning for ${uid}`);
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
 * onJournalEntryCreated: Update streak when a meal or symptom is logged in the consolidated journal.
 */
export const onJournalEntryCreated = functions
  .region(REGION)
  .runWith({ failurePolicy: true })
  .firestore.document('user_profiles/{uid}/journal_logs/{docId}')
  .onCreate(async (snapshot, context) => {
    const { uid } = context.params;
    const data = snapshot.data();
    if (data) {
      await handleActivityStreak(uid, data.createdAt);
      await onJournalWrite(uid, data, eventTimestamp(context.timestamp), context.eventId);
    }
  });

/**
 * onScanDeleted: Decrement history counters when a scan is removed
 * (e.g. chat message deletion cascades via deleteLogsForMessage).
 */
export const onScanDeleted = functions
  .region(REGION)
  .runWith({ failurePolicy: true })
  .firestore.document('user_profiles/{uid}/scan_history/{docId}')
  .onDelete(async (snapshot, context) => {
    const { uid } = context.params;
    await onScanRemoved(uid, snapshot.data(), eventTimestamp(context.timestamp), context.eventId);
  });

/**
 * onJournalEntryDeleted: Decrement history counters when a journal entry is removed.
 */
export const onJournalEntryDeleted = functions
  .region(REGION)
  .runWith({ failurePolicy: true })
  .firestore.document('user_profiles/{uid}/journal_logs/{docId}')
  .onDelete(async (snapshot, context) => {
    const { uid } = context.params;
    await onJournalRemoved(uid, snapshot.data(), eventTimestamp(context.timestamp), context.eventId);
  });

/**
 * Legacy insight mirror. Deterministic gut_scores owns profiles with a score record.
 */
export const onInsightCreated = functions
  .region(REGION)
  .firestore.document('user_profiles/{uid}/insights/{docId}')
  .onCreate(async (snapshot, context) => {
    const { uid } = context.params;
    const data = snapshot.data();
    if (!data) return;
    if (data.hasGutScore === false) return;

    const rawGutScore = Number(data.gutScore);
    if (!Number.isFinite(rawGutScore)) {
      functions.logger.warn(`onInsightCreated: Ignoring non-numeric gutScore for ${uid}`, { rawGutScore: data.gutScore });
      return;
    }

    // Guard against out-of-range values (e.g. a hallucinated 0, a negative
    // number, or something > 100) silently overwriting the user's real
    // profile score. Clamp instead of trusting the AI output verbatim.
    const gutScore = Math.round(Math.min(100, Math.max(0, rawGutScore)));
    if (rawGutScore < 0 || rawGutScore > 100) {
      functions.logger.warn(`onInsightCreated: Clamped out-of-range gutScore ${rawGutScore} to ${gutScore} for ${uid}`);
    }

    const db = admin.firestore();
    const userRef = db.doc(`user_profiles/${uid}`);

    try {
      await db.runTransaction(async (transaction) => {
        const profile = await transaction.get(userRef);
        // The app publishes a score record and this marker atomically. Keep
        // delayed/legacy AI events from replacing the deterministic score.
        if (!profile.exists || profile.data()?.lastScoreCalculationAt) return;
        const updatedAt = profile.data()?.lastInsightScoreAt;
        if (updatedAt && data.updatedAt?.toMillis?.() <= updatedAt.toMillis()) return;
        transaction.update(userRef, {
          gutScore,
          lastInsightScoreAt: data.updatedAt ?? snapshot.createTime,
        });
      });
      functions.logger.info(`Updated gutScore for ${uid} to ${gutScore}`);
    } catch (e) {
      functions.logger.error(`Failed to update gutScore for ${uid}`, e);
    }
  });
