/**
 * GutGood Cloud Functions — secure backend per PRD §3d.
 *
 *   aiProxy               HTTPS    OpenAI proxy: key protection, auth, usage limits, SSE streaming
 *   mergeAnonymousAccount Callable Atomic + idempotent guest→account data migration
 *   onUserDeleted         Trigger  Guaranteed cascade delete (Firestore + Storage)
 *   cleanupAnonymousUsers Cron     Purges abandoned guest accounts after 14 days
 *
 * NOTE: Premium is managed CLIENT-SIDE with the RevenueCat SDK
 * (purchases_flutter). The app mirrors the entitlement into
 * user_profiles/{uid}.isPremium so the aiProxy quota check can read it;
 * there is intentionally no server-side RevenueCat integration here.
 */
import * as admin from 'firebase-admin';

admin.initializeApp();

export { aiProxy } from './ai_proxy';
export { mergeAnonymousAccount } from './merge';
export { onUserDeleted, cleanupAnonymousUsers } from './lifecycle';
export { onScanCreated, onInsightCreated } from './triggers';
