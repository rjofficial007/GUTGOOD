/**
 * GutGood Cloud Functions — secure backend per PRD §3d.
 *
 *   aiProxy               HTTPS    OpenAI proxy: key protection, auth, usage limits, SSE streaming
 *   mergeAnonymousAccount Callable Atomic + idempotent guest→account data migration
 *   onUserDeleted         Trigger  Guaranteed cascade delete (Firestore + Storage)
 *   cleanupAnonymousUsers Cron     Purges abandoned guest accounts after 14 days
 *   generateFoodThumb     Storage  1024px original -> 320px thumb + registry backfill
 *   sweepUnlinkedFoodImages Cron    Deletes unlinked food images after 30d grace
 *
 * NOTE: Premium is managed CLIENT-SIDE with the RevenueCat SDK
 * (purchases_flutter). The app mirrors the entitlement into
 * user_profiles/{uid}.isPremium so the aiProxy quota check can read it;
 * there is intentionally no server-side RevenueCat integration here.
 *
 * Read ../docs/ACCEPTED_RISKS.md before changing any quota/premium/email
 * behavior — several "soft" behaviors below are deliberate, registered
 * decisions (R1–R9), not latent bugs.
 */
import * as admin from 'firebase-admin';

admin.initializeApp();

export { aiProxy } from './ai_proxy';
export { mergeAnonymousAccount } from './merge';
export { onProfileWritten, onUserDeleted, cleanupAnonymousUsers } from './lifecycle';
export { sendCustomMagicLink } from './auth';
export { onScanCreated, onScanDeleted, onJournalEntryCreated, onJournalEntryDeleted, onInsightCreated } from './triggers';
export { generateFoodThumb, sweepUnlinkedFoodImages } from './food_images';
