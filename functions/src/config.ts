/**
 * Shared configuration & secrets for GutGood Cloud Functions.
 *
 * Secrets are managed via Google Cloud Secret Manager and bound at deploy time:
 *   firebase functions:secrets:set OPENAI_API_KEY
 *
 * NOTE: There is intentionally no RevenueCat server integration. Premium is
 * determined on-device by the purchases_flutter SDK and mirrored into
 * user_profiles/{uid}.isPremium by the app (client-side premium model).
 *
 * Accepted risks register: docs/ACCEPTED_RISKS.md (R1 client-authoritative
 * premium, R2 unvalidated timezoneOffset, R5/R6 email flows, R7 no App Check).
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

/**
 * Model allowlist.
 *
 * The client sends `model` (currently via Remote Config). Forwarding an
 * arbitrary string means a tampered client — or a typo in Remote Config — can
 * silently move every user onto an expensive model. Unknown values fall back to
 * [DEFAULT_MODEL] instead of reaching OpenAI.
 */
const ALLOWED_MODELS = new Set(['gpt-4o-mini', 'gpt-4o']);

export function resolveModel(requested: string | undefined | null): string {
  const model = (requested ?? '').trim();
  return ALLOWED_MODELS.has(model) ? model : DEFAULT_MODEL;
}

// Safety rails (mirror client-side validation; client can never raise these).
export const MAX_IMAGES_PER_REQUEST = 4;
export const MAX_IMAGE_BASE64_CHARS = 1_600_000; // ≈1.2 MB decoded
export const MAX_HISTORY_MESSAGES = 30;
export const MAX_TEXT_CHARS = 8_000;   // per-turn user text
export const MAX_PROMPT_CHARS = 32_000; // one-shot prompts (insights, analysis)
// The chat system instruction measures 15.9k chars for a light profile and
// 16.4k for a power user, so 16k truncated real requests mid-instruction.
// Keep this above the worst case and log whenever it is hit (see ai_proxy).
export const MAX_SYSTEM_CHARS = 24_000;

// Free-tier limits, enforced server-side (PRD §10: 3-5 chats/day, 3 scans/day;
// guests get 1-2 free actions before being asked to create an account - PRD §4).
// `tokens` is a daily backstop on total tokens for non-premium users.
export const LIMITS = {
  registered: { chat: 5, scan: 3, system: 20, tokens: 120_000 },
  guest: { chat: 2, scan: 2, system: 10, tokens: 40_000 },
} as const;

export type UsageType = 'chat' | 'scan' | 'system';

// ---------------------------------------------------------------------------
// Response ceiling.
//
// Policy: NO artificial limit on the AI's reply. Per-intent budgets (900 / 1536
// / 2048 tokens) were tried and removed — they silently cut good answers off
// mid-sentence, and unfinished JSON breaks [GUTGOOD_DATA] parsing outright.
// Unused headroom costs nothing: you are only billed for tokens generated.
//
// This is the model's own output ceiling (gpt-4o-mini / gpt-4o), used purely as
// a guard against a runaway generation.
// ---------------------------------------------------------------------------
export const MAX_OUTPUT_TOKENS = 16_384;

// How long an idempotency key stays deduplicated inside the daily usage doc.
export const IDEMPOTENCY_KEY_RETENTION = 25;
