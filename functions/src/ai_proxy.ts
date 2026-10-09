/**
 * aiProxy — the ONLY path between the app and OpenAI.
 *
 * PRD compliance (§3d):
 *   - The OpenAI API key lives exclusively in Cloud Secret Manager.
 *   - Devices never see it (the old Remote-Config-based key delivery is removed).
 *
 * Also owns:
 *   - Auth (Firebase ID token required).
 *   - Server-side free-tier enforcement (429 -> client shows paywall).
 *   - SSE streaming (ChatGPT-style token-by-token rendering).
 *
 * Protocol (all requests are POST + JSON):
 *   {
 *     mode: 'stream' | 'stream-json' | 'json' | 'plain',
 *     systemInstruction?: string,
 *     messages?: [{ role: 'user'|'assistant', content: string }],
 *     userText?: string,             // the current user turn
 *     images?: string[],             // base64 JPEG, <= 4
 *     prompt?: string,               // used by json/plain one-shot modes
 *     model?: string,
 *     usageType?: 'chat' | 'scan' | 'system',
 *     idempotencyKey?: string
 *   }
 *
 * Stream responses are `text/event-stream` with frames:
 *   data: {"d":"delta"}\n\n  ...      data: [DONE]\n\n
 * Fatal errors are reported as the last frame: data: {"error":"..."}\n\n
 * P3-4: when the input was middle-out truncated or the output hit
 * `finish_reason: length`, a meta frame precedes [DONE]:
 * data: {"truncated":true,"truncation":"input"|"output"|"both"}\n\n
 * (`json`/`plain` modes return the same two fields alongside `text`.)
 * J-4: every response also echoes `promptVersion` (as sent) and the serving
 * `model` in the same meta frame / JSON body, for artifact stamping (§17).

 */
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import {
  MAX_HISTORY_MESSAGES,
  MAX_IMAGE_BASE64_CHARS,
  MAX_IMAGES_PER_REQUEST,
  MAX_OUTPUT_TOKENS,
  MAX_PROMPT_CHARS,
  MAX_SYSTEM_CHARS,
  MAX_TEXT_CHARS,
  OPENAI_API_KEY,
  OPENAI_CHAT_URL,
  REGION,
  resolveModel,
  UsageType,
} from './config';
import { checkAndConsume, isPremiumUser, recordTokens, refund } from './usage';

interface HistoryMessage {
  role: 'user' | 'assistant';
  content: string;
}

/** Token counts reported by OpenAI (final stream chunk when include_usage is set). */
interface TokenUsage {
  prompt_tokens?: number;
  completion_tokens?: number;
}

interface ProxyRequest {
  mode?: string;
  systemInstruction?: string;
  messages?: HistoryMessage[];
  userText?: string;
  images?: string[];
  prompt?: string;
  model?: string;
  usageType?: string;
  idempotencyKey?: string;
  timezoneOffset?: number;
  intent?: string;
  promptVersion?: number;
}

function setCors(res: functions.Response): void {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type, Idempotency-Key');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
}

function fail(res: functions.Response, status: number, error: string, extra: Record<string, unknown> = {}): void {
  res.status(status).json({ error, ...extra });
}

type OpenAIMessage =
  | { role: 'system' | 'assistant'; content: string }
  | { role: 'user'; content: string | Array<Record<string, unknown>> };

/**
 * P3-4 middle-out truncation: keeps a head slice plus the tail that fits,
 * joined by a marker. A plain `slice(0, cap)` drops the tail — which for
 * system prompts carries SCHEMA TYPE RULES and for chat carries the user's
 * actual question — so cut prompts produced malformed JSON / confused
 * replies with only a server-side warning. Callers report `truncated` to
 * the client (meta frame / JSON field) for a user-visible notice.
 */
function truncateMiddle(text: string, cap: number): { text: string; truncated: boolean; dropped: number } {
  if (text.length <= cap) return { text, truncated: false, dropped: 0 };
  const marker = '\n\n[\u2026trimmed for length\u2026]\n\n';
  const headKeep = Math.min(1000, Math.floor(cap / 4));
  const tailKeep = cap - headKeep - marker.length;
  if (tailKeep <= 0) return { text: text.slice(0, cap), truncated: true, dropped: text.length - cap };
  return {
    text: text.slice(0, headKeep) + marker + text.slice(text.length - tailKeep),
    truncated: true,
    dropped: text.length - cap,
  };
}

function buildOpenAIMessages(body: ProxyRequest): { messages: OpenAIMessage[]; inputTruncated: boolean } {
  const messages: OpenAIMessage[] = [];

  // P3-4: middle-out (head + tail preserved) and REPORTED — it used to
  // silently slice(0, cap), dropping schema/evidence rules near the end of
  // long instructions and yielding malformed JSON with no error anywhere.
  const rawSystem = body.systemInstruction ?? '';
  const systemCut = truncateMiddle(rawSystem, MAX_SYSTEM_CHARS);
  const system = systemCut.text;
  if (systemCut.truncated) {
    functions.logger.warn(
      `systemInstruction truncated ${rawSystem.length} -> ${MAX_SYSTEM_CHARS} chars (middle-out, dropped ${systemCut.dropped}). Shrink the prompt or raise MAX_SYSTEM_CHARS.`,
    );
  }
  if (system) messages.push({ role: 'system', content: system });

  const history = Array.isArray(body.messages) ? body.messages.slice(-MAX_HISTORY_MESSAGES) : [];
  let historyTruncated = false;
  for (const m of history) {
    if (!m || typeof m.content !== 'string' || m.content.length === 0) continue;
    const cut = truncateMiddle(m.content, MAX_TEXT_CHARS);
    if (cut.truncated) historyTruncated = true;
    if (m.role === 'user') messages.push({ role: 'user', content: cut.text });
    else messages.push({ role: 'assistant', content: cut.text });
  }

  // One-shot analysis prompts may exceed the per-turn user-text cap, so they
  // get their own (larger) ceiling.
  const rawPrompt = body.userText ?? body.prompt ?? '';
  const promptCap = body.userText ? MAX_TEXT_CHARS : MAX_PROMPT_CHARS;
  const promptCut = truncateMiddle(rawPrompt, promptCap);
  const userText = promptCut.text;
  if (promptCut.truncated) {
    functions.logger.warn(`prompt truncated ${rawPrompt.length} -> ${promptCap} chars (middle-out, dropped ${promptCut.dropped}).`);
  }
  const images = Array.isArray(body.images) ? body.images.slice(0, MAX_IMAGES_PER_REQUEST) : [];

  if (userText || images.length > 0) {
    if (images.length > 0) {
      const parts: Array<Record<string, unknown>> = [];
      if (userText) parts.push({ type: 'text', text: userText });
      for (const b64 of images) {
        if (typeof b64 !== 'string' || b64.length === 0 || b64.length > MAX_IMAGE_BASE64_CHARS) continue;
        parts.push({ type: 'image_url', image_url: { url: `data:image/jpeg;base64,${b64}` } });
      }
      messages.push({ role: 'user', content: parts });
    } else {
      messages.push({ role: 'user', content: userText });
    }
  }

  return { messages, inputTruncated: systemCut.truncated || historyTruncated || promptCut.truncated };
}

async function authenticate(req: functions.Request): Promise<{ uid: string; isAnonymous: boolean } | null> {
  const header = (req.headers.authorization ?? '') as string;
  if (!header.startsWith('Bearer ')) return null;
  try {
    const decoded = await admin.auth().verifyIdToken(header.slice(7));
    const isAnonymous = (decoded.firebase as { sign_in_provider?: string } | undefined)?.sign_in_provider === 'anonymous';
    return { uid: decoded.uid, isAnonymous };
  } catch {
    return null;
  }
}

export const aiProxy = functions
  .region(REGION)
  // Cold-start sensitivity: this endpoint is on the chat latency path.
  .runWith({ timeoutSeconds: 300, memory: '512MB', secrets: [OPENAI_API_KEY]})
  .https.onRequest(async (req, res) => {
    setCors(res);
    if (req.method === 'OPTIONS') {
      res.status(204).end();
      return;
    }
    if (req.method !== 'POST') {
      fail(res, 405, 'method_not_allowed');
      return;
    }

    const auth = await authenticate(req);
    if (!auth) {
      fail(res, 401, 'unauthenticated', { message: 'A valid Firebase ID token is required.' });
      return;
    }

    const body = (req.body ?? {}) as ProxyRequest;
    const mode = body.mode ?? 'stream';
    if (!['stream', 'json', 'plain', 'stream-json'].includes(mode)) {
      fail(res, 400, 'invalid_argument', { message: `Unsupported mode '${mode}'.` });
      return;
    }

    const images = Array.isArray(body.images) ? body.images : [];
    const usageType = (body.usageType ?? (images.length > 0 ? 'scan' : 'chat')).toString();
    // Accepted risk R2 (docs/ACCEPTED_RISKS.md): the offset is client-supplied
    // and intentionally NOT range-validated. An extreme offset mints a fresh
    // daily_usage doc (zero counter) — daily limits are refillable by design
    // choice; clamp to ±840 here and in usage.ts if this is ever revisited.
    const timezoneOffset = Number(body.timezoneOffset ?? 0);

    // Whitelist usageType and reject unknown.
    if (!['chat', 'scan', 'system'].includes(usageType)) {
      fail(res, 400, 'invalid_argument', { message: `Unsupported usageType '${usageType}'.` });
      return;
    }
    const meteredType = usageType as UsageType;
    const giveCreditBack = () => refund(auth!.uid, auth!.isAnonymous, meteredType, body.idempotencyKey, timezoneOffset);

    // Reject unusable payloads BEFORE consuming a credit: an oversized image
    // used to be skipped silently (leaving the model with no image at all)
    // after the user had already been charged for the scan.
    if (images.length > MAX_IMAGES_PER_REQUEST) {
      fail(res, 400, 'invalid_argument', {
        message: `Too many images (${images.length}); the limit is ${MAX_IMAGES_PER_REQUEST}.`,
      });
      return;
    }
    for (const [index, b64] of images.entries()) {
      if (typeof b64 !== 'string' || b64.length === 0) {
        fail(res, 400, 'invalid_argument', { message: `Image ${index} is empty.` });
        return;
      }
      if (b64.length > MAX_IMAGE_BASE64_CHARS) {
        fail(res, 413, 'image_too_large', {
          message: `Image ${index} is ${b64.length} base64 chars; the limit is ${MAX_IMAGE_BASE64_CHARS}. Compress it on-device before sending.`,
        });
        return;
      }
    }

    // Server-side free-tier enforcement (idempotent on retries).
    // Metering includes 'system' usage.
    try {
      const usage = await checkAndConsume(
        auth.uid,
        auth.isAnonymous,
        meteredType,
        body.idempotencyKey,
        timezoneOffset,
      );
      if (!usage.allowed) {
        if (usage.reason === 'profile_missing') {
          fail(res, 409, 'profile_not_initialized', { message: 'Your account profile is not ready. Please retry shortly.' });
          return;
        }
        fail(res, 429, 'quota_exceeded', {
          type: usageType,
          limit: usage.limit,
          reason: usage.reason,
          message: 'Daily free limit reached.',
        });
        return;
      }
    } catch (e) {
      // Fail closed (503) on usage check errors unless user is premium.
      const premium = await isPremiumUser(auth.uid).catch(() => false);
      if (premium) {
        functions.logger.warn('usage check failed for premium user; failing open', e);
      } else {
        functions.logger.error('usage check failed; failing closed', e);
        fail(res, 503, 'service_unavailable', { message: 'Usage check failed. Please retry.' });
        return;
      }
    }

    const { messages, inputTruncated } = buildOpenAIMessages(body);
    if (messages.length === 0) {
      fail(res, 400, 'invalid_argument', { message: 'Empty message payload.' });
      return;
    }

    const streaming = mode === 'stream' || mode === 'stream-json';

    // J-4: hoisted so the echo below reports the model that actually served
    // (the allowlist may substitute the client's request).
    const servedModel = resolveModel(body.model);
    const payload: Record<string, unknown> = {
      // Allowlisted: the client's model (Remote Config) can no longer select an
      // expensive model by accident or by tampering.
      model: servedModel,
      messages,
      stream: streaming,
      // No per-intent budget: replies are never cut short (see config.ts).
      max_tokens: MAX_OUTPUT_TOKENS,
      temperature: 0.2, // Increased consistency for JSON responses
      // Lets OpenAI flag abusive per-end-user traffic patterns.
      user: auth.uid,
    };
    if (mode === 'json' || mode === 'stream-json') {
      payload.response_format = { type: 'json_object' };
    }
    if (streaming) {
      // Without this the stream never reports token counts, so per-user cost is
      // invisible. The usage object arrives on the final chunk.
      payload.stream_options = { include_usage: true };
    }

    let upstream: globalThis.Response;
    try {
      upstream = await fetch(OPENAI_CHAT_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${OPENAI_API_KEY.value()}`,
        },
        body: JSON.stringify(payload),
      });
    } catch (e) {
      functions.logger.error('OpenAI network error', e);
      await giveCreditBack();
      fail(res, 502, 'upstream_unreachable', { message: 'Could not reach the AI service. Please retry.' });
      return;
    }

    if (!upstream.ok) {
      const text = await upstream.text().catch(() => '');
      functions.logger.error(`OpenAI ${upstream.status}: ${text.slice(0, 500)}`);
      await giveCreditBack();
      fail(res, upstream.status === 429 ? 503 : 502, 'upstream_error', {
        message: 'The AI service returned an error. Please retry.',
      });
      return;
    }

    if (mode === 'json' || mode === 'plain') {
      try {
        const json = (await upstream.json()) as {
          choices?: Array<{ message?: { content?: string }; finish_reason?: string }>;
          usage?: { prompt_tokens?: number; completion_tokens?: number };
        };
        const text = json.choices?.[0]?.message?.content ?? '';
        const outputTruncated = json.choices?.[0]?.finish_reason === 'length';
        if (!text) {
          functions.logger.error('OpenAI returned empty content');
          await giveCreditBack();
          fail(res, 502, 'upstream_error', { message: 'The AI service returned an empty response.' });
          return;
        }
        await recordTokens(
          auth.uid,
          timezoneOffset,
          json.usage?.prompt_tokens ?? 0,
          json.usage?.completion_tokens ?? 0,
        );
        let truncationKind: string | null = null;
        if (inputTruncated && outputTruncated) truncationKind = 'both';
        else if (inputTruncated) truncationKind = 'input';
        else if (outputTruncated) truncationKind = 'output';
        // J-4: echo the builder's prompt version + serving model so writers
        // can stamp the artifact (§17).
        res.status(200).json({
          text,
          promptVersion: body.promptVersion ?? null,
          model: servedModel,
          ...(truncationKind ? { truncated: true, truncation: truncationKind } : {}),
        });
      } catch (e) {
        functions.logger.error('Failed to parse OpenAI response', e);
        await giveCreditBack();
        fail(res, 502, 'upstream_error', { message: 'Malformed AI response.' });
      }
      return;
    }

    // SSE streaming path.
    res.status(200);
    res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
    res.setHeader('Cache-Control', 'no-cache, no-transform');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders();

    const send = (obj: Record<string, unknown>) => {
      res.write(`data: ${JSON.stringify(obj)}\n\n`);
    };

    // Declared outside the try so the catch block can tell whether anything
    // was actually delivered before the stream broke.
    let sawContent = false;
    // Holder object: TypeScript can't see assignments made inside the SSE
    // callback, so a plain `let` would be narrowed to `null` at the read site.
    const usageBox: { value: TokenUsage | null } = { value: null };
    // P3-4: `finish_reason: length` on any chunk means the reply was cut short.
    const outputCut: { value: boolean } = { value: false };

    try {
      const reader = (upstream.body as unknown as ReadableStream<Uint8Array>).getReader();
      const decoder = new TextDecoder();
      let buffer = '';

      // Aggregated SSE line parser for the upstream OpenAI stream.
      const processLine = (line: string): { done: boolean } => {
        const trimmed = line.trim();
        if (!trimmed.startsWith('data:')) return { done: false };
        const data = trimmed.slice(5).trim();
        if (data === '[DONE]') return { done: true };
        try {
          const event = JSON.parse(data) as {
            choices?: Array<{ delta?: { content?: string }; finish_reason?: string }>;
            usage?: { prompt_tokens?: number; completion_tokens?: number };
          };
          if (event.choices?.[0]?.finish_reason === 'length') outputCut.value = true;
          if (event.usage) usageBox.value = event.usage;
          const delta = event.choices?.[0]?.delta?.content ?? '';
          if (delta) {
            sawContent = true;
            send({ d: delta });
          }
        } catch {
          // Partial JSON chunks are re-buffered; ignore incomplete lines.
        }
        return { done: false };
      };

      let upstreamDone = false;
      while (!upstreamDone) {
        const { done, value } = await reader.read();
        if (done) break;
        buffer += decoder.decode(value, { stream: true });

        let newlineIndex: number;
        while ((newlineIndex = buffer.indexOf('\n')) !== -1) {
          const line = buffer.slice(0, newlineIndex);
          buffer = buffer.slice(newlineIndex + 1);
          if (processLine(line).done) {
            upstreamDone = true;
            break;
          }
        }
      }

      // Flush any trailing buffered line.
      if (!upstreamDone && buffer.length > 0) {
        processLine(buffer);
      }

      if (!sawContent) {
        // Nothing was delivered — don't make the user pay for it.
        await giveCreditBack();
        send({ error: 'The AI service returned an empty response. Please retry.' });
      } else if (usageBox.value) {
        await recordTokens(auth.uid, timezoneOffset, usageBox.value.prompt_tokens ?? 0, usageBox.value.completion_tokens ?? 0);
      }
      // J-4: version echo on EVERY response (plus P3-4 truncation keys when cut).
      const meta: Record<string, unknown> = { promptVersion: body.promptVersion ?? null, model: servedModel };
      if (inputTruncated || outputCut.value) {
        let truncationKind = 'output';
        if (inputTruncated && outputCut.value) truncationKind = 'both';
        else if (inputTruncated) truncationKind = 'input';
        meta['truncated'] = true;
        meta['truncation'] = truncationKind;
      }
      send(meta);
      res.write('data: [DONE]\n\n');
      res.end();
    } catch (e) {
      functions.logger.error('Streaming failure', e);
      if (!sawContent) await giveCreditBack();
      send({ error: 'The connection to the AI service dropped. Please retry.' });
      res.end();
    }
  });
