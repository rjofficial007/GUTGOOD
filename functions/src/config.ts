/**
 * Shared configuration & secrets for GutGood Cloud Functions.
 *
 * Secrets are managed via Google Cloud Secret Manager and bound at deploy time:
 *   firebase functions:secrets:set OPENAI_API_KEY
 *
 * NOTE: There is intentionally no RevenueCat server integration. Premium is
 * determined on-device by the purchases_flutter SDK and mirrored into
 * user_profiles/{uid}.isPremium by the app (client-side premium model).
 */
import { defineSecret } from 'firebase-functions/params';

export const OPENAI_API_KEY = defineSecret('OPENAI_API_KEY');

export const REGION = 'us-central1';

export const OPENAI_CHAT_URL = 'https://api.openai.com/v1/chat/completions';

export const DEFAULT_MODEL = 'gpt-4o-mini';

// Safety rails (mirror client-side validation; client can never raise these).
export const MAX_IMAGES_PER_REQUEST = 4;
export const MAX_IMAGE_BASE64_CHARS = 1_600_000; // ≈1.2 MB decoded
export const MAX_HISTORY_MESSAGES = 20;
export const MAX_TEXT_CHARS = 8_000;
export const MAX_SYSTEM_CHARS = 16_000;

// Free-tier limits, enforced server-side (PRD §10: 3-5 chats/day, 3 scans/day;
// guests get 1-2 free actions before being asked to create an account - PRD §4).
export const LIMITS = {
  registered: { chat: 5, scan: 3 },
  guest: { chat: 2, scan: 2 },
} as const;

export type UsageType = 'chat' | 'scan';

// How long an idempotency key stays deduplicated inside the daily usage doc.
export const IDEMPOTENCY_KEY_RETENTION = 25;
