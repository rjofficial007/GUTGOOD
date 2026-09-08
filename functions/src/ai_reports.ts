/**
 * ai_reports — closes the Google Play AI-content reporting loop.
 *
 * Play requires that apps which generate AI content let users flag it
 * "without needing to exit the app". GutGood writes those reports to the
 * create-only `ai_reports` collection — but a report no human ever reads does
 * not satisfy the intent of the policy, only its letter.
 *
 * This trigger makes every report actually visible:
 *
 *   1. ALWAYS structured-logged to Cloud Logging, so reports are searchable
 *      and can drive a log-based metric/alert with zero extra infrastructure.
 *   2. `unsafe` reports additionally escalate by email, because a safety claim
 *      about food deserves a faster path than a correctness complaint.
 *
 * Design rules:
 *
 *   - NEVER throws. A failing Firestore trigger retries and costs money, and a
 *     report must never be lost because the email transport happened to be down.
 *   - Works with zero configuration. Email is opt-in: if AI_REPORT_ALERT_TO is
 *     unset the function logs only, so deploying this cannot break a build.
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { REGION } from './config';
import { getTransporter } from './email';

/**
 * Where escalation emails are sent.
 *
 * Set it before deploying the alerting path:
 *   firebase functions:config:set aireports.alert_to="safety@gutgood.app"
 * (or use an env/.env file — both surface as process.env for v1 functions once
 * configured through the Firebase CLI).
 * Empty ⇒ log-only mode.
 */
const ALERT_TO = process.env.AI_REPORT_ALERT_TO || '';

/** Reason → how loudly to shout. Drives both log severity and escalation. */
const SEVERITY: Record<string, 'critical' | 'high' | 'medium' | 'low'> = {
  unsafe: 'critical', // a safety claim about food
  offensive: 'high',
  inaccurate: 'medium',
  off_topic: 'low',
  other: 'medium',
};

/** Only these reasons page a human by email. Keep it narrow or it is just noise. */
const EMAIL_ESCALATION = new Set(['unsafe']);

/** Reason → human label for the email subject/body. */
const REASON_LABEL: Record<string, string> = {
  unsafe: 'Unsafe advice',
  offensive: 'Offensive content',
  inaccurate: 'Inaccurate',
  off_topic: 'Off topic',
  other: 'Other',
};

/** Keep logged payloads small: Cloud Logging bills by size and this is a hot path. */
const MAX_LOG_EXCERPT = 500;

function trim(value: unknown, max: number): string {
  if (typeof value !== 'string') return '';
  const clean = value.replace(/\s+/g, ' ').trim();
  return clean.length > max ? `${clean.slice(0, max)}…` : clean;
}

/**
 * Fires when a user reports an AI response.
 */
export const onAiReportCreated = functions
  .region(REGION)
  .firestore.document('ai_reports/{reportId}')
  .onCreate(async (snap, context) => {
    const reportId = context.params.reportId as string;

    try {
      const data = snap.data() || {};
      const reason = typeof data.reason === 'string' ? data.reason : 'other';
      const severity = SEVERITY[reason] ?? 'medium';
      const createdAt = data.createdAt;

      // Structured log: queryable as
      //   jsonPayload.type="ai_report" AND jsonPayload.severity="critical"
      // which is enough to build a log-based alert in the console.
      functions.logger.warn('[ai_report] new report', {
        type: 'ai_report',
        reportId,
        reason,
        severity,
        label: REASON_LABEL[reason] ?? reason,
        reportedBy: data.reportedBy ?? null,
        messageId: data.messageId ?? null,
        details: trim(data.details, MAX_LOG_EXCERPT),
        excerpt: trim(data.excerpt, MAX_LOG_EXCERPT),
        createdAt: createdAt?.toDate ? createdAt.toDate().toISOString() : null,
      });

      // Escalate safety reports by email. Optional, and failure is non-fatal.
      if (!EMAIL_ESCALATION.has(reason) || !ALERT_TO) return;

      try {
        const db = admin.firestore();

        // Include a little context so the alert is actionable without a console
        // round-trip: how often has this user reported, and how recently?
        const recent = await db
          .collection('ai_reports')
          .where('reportedBy', '==', data.reportedBy ?? null)
          .limit(20)
          .get();

        const transporter = getTransporter();
        await transporter.sendMail({
          from: process.env.SMTP_FROM || undefined,
          to: ALERT_TO,
          subject: `[GutGood] ${REASON_LABEL[reason] ?? reason} — AI response reported`,
          text: [
            `Severity : ${severity.toUpperCase()}`,
            `Reason   : ${REASON_LABEL[reason] ?? reason} (${reason})`,
            `Report   : ${reportId}`,
            `User     : ${data.reportedBy ?? 'unknown'}`,
            `Message  : ${data.messageId ?? 'n/a'}`,
            `Reports from this user (recent sample): ${recent.size}`,
            '',
            'Details:',
            trim(data.details, 1000) || '(none)',
            '',
            'Reported message excerpt:',
            trim(data.excerpt, 1000) || '(none)',
          ].join('\n'),
        });

        functions.logger.info('[ai_report] escalation email sent', { reportId, to: ALERT_TO });
      } catch (emailErr) {
        // The report is already durably stored and logged; a broken inbox must
        // not retry the whole trigger.
        functions.logger.error('[ai_report] escalation email failed', { reportId, error: String(emailErr) });
      }
    } catch (err) {
      // Last-resort guard: never let a malformed report cause retry storms.
      functions.logger.error('[ai_report] handler failed', { reportId, error: String(err) });
    }
  });
