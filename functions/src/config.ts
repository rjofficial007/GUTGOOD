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
export const SMTP_HOST = defineSecret('SMTP_HOST');
export const SMTP_PORT = defineSecret('SMTP_PORT');
export const SMTP_USER = defineSecret('SMTP_USER');
export const SMTP_PASS = defineSecret('SMTP_PASS');
export const SMTP_FROM = defineSecret('SMTP_FROM');

export const REGION = 'us-central1';

export const OPENAI_CHAT_URL = 'https://api.openai.com/v1/chat/completions';

export const DEFAULT_MODEL = 'gpt-4o-mini';

// Safety rails (mirror client-side validation; client can never raise these).
export const MAX_IMAGES_PER_REQUEST = 4;
export const MAX_IMAGE_BASE64_CHARS = 1_600_000; // ≈1.2 MB decoded
export const MAX_HISTORY_MESSAGES = 30;
export const MAX_TEXT_CHARS = 8_000;
export const MAX_SYSTEM_CHARS = 16_000;

// Free-tier limits, enforced server-side (PRD §10: 3-5 chats/day, 3 scans/day;
// guests get 1-2 free actions before being asked to create an account - PRD §4).
export const LIMITS = {
  registered: { chat: 5, scan: 3, system: 20 },
  guest: { chat: 2, scan: 2, system: 10 },
} as const;

export type UsageType = 'chat' | 'scan' | 'system';

// ---------------------------------------------------------------------------
// Per-intent token budgets (audit §C.5 / §O item 11).
//
// Previously a single flat ceiling (2048 text / 4096 vision) was applied to
// every request regardless of intent, even though the app already knows the
// user's intent before calling the model. Short-by-design replies (a rating,
// a swap suggestion, a head-to-head comparison) don't need the same ceiling
// as a full breakdown — right-sizing saves cost with no quality loss.
//
// Vision turns (images present) always keep the larger budget: the model
// needs room to describe what it sees *and* emit the full [GUTGOOD_DATA]
// block, regardless of the conversational intent of that turn.
// ---------------------------------------------------------------------------
const DEFAULT_TEXT_MAX_TOKENS = 2048;
const VISION_MAX_TOKENS = 4096;

const SHORT_INTENTS = new Set([
  'MEAL_RATING',
  'RATE_MEAL',
  'SWAP_REQUEST',
  'MEAL_SWAPS',
  'IMPROVEMENT_REQUEST',
  'IMPROVE',
  'NUTRITION_COMPARISON',
  'PRODUCT_COMPARISON',
  'GENERAL_CHAT',
]);
const SHORT_INTENT_MAX_TOKENS = 900;

const MEDIUM_INTENTS = new Set([
  'HEALTH_ASSESSMENT',
  'IS_HEALTHY',
  'SYMPTOM_ANALYSIS',
  'GENERAL_WELLNESS',
  'GENERAL_FOOD_QUESTION',
  'NUTRITION_ANALYSIS',
  'MEAL_RECOGNITION',
]);
const MEDIUM_INTENT_MAX_TOKENS = 1536;

/**
 * Resolve the `max_tokens` ceiling for a single OpenAI request.
 * `intent` is the free-form intent string forwarded by the client (already
 * classified before the model call); unknown/absent intents fall back to the
 * previous flat behavior so this is purely additive for recognized intents.
 */
export function resolveMaxTokens(intent: string | undefined | null, hasImages: boolean): number {
  if (hasImages) return VISION_MAX_TOKENS;

  const normalized = (intent ?? '').toUpperCase().trim();
  if (!normalized) return DEFAULT_TEXT_MAX_TOKENS;

  if (SHORT_INTENTS.has(normalized)) return SHORT_INTENT_MAX_TOKENS;
  if (MEDIUM_INTENTS.has(normalized)) return MEDIUM_INTENT_MAX_TOKENS;
  return DEFAULT_TEXT_MAX_TOKENS;
}

// How long an idempotency key stays deduplicated inside the daily usage doc.
export const IDEMPOTENCY_KEY_RETENTION = 25;
