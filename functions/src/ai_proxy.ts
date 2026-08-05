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
 *     mode: 'stream' | 'json' | 'plain',
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
 */
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import {
  DEFAULT_MODEL,
  MAX_HISTORY_MESSAGES,
  MAX_IMAGE_BASE64_CHARS,
  MAX_IMAGES_PER_REQUEST,
  MAX_SYSTEM_CHARS,
  MAX_TEXT_CHARS,
  OPENAI_API_KEY,
  OPENAI_CHAT_URL,
  REGION,
} from './config';
import { checkAndConsume, isPremiumUser } from './usage';

interface HistoryMessage {
  role: 'user' | 'assistant';
  content: string;
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

function buildOpenAIMessages(body: ProxyRequest): OpenAIMessage[] {
  const messages: OpenAIMessage[] = [];

  const system = (body.systemInstruction ?? '').slice(0, MAX_SYSTEM_CHARS);
  if (system) messages.push({ role: 'system', content: system });

  const history = Array.isArray(body.messages) ? body.messages.slice(-MAX_HISTORY_MESSAGES) : [];
  for (const m of history) {
    if (!m || typeof m.content !== 'string' || m.content.length === 0) continue;
    if (m.role === 'user') messages.push({ role: 'user', content: m.content.slice(0, MAX_TEXT_CHARS) });
    else messages.push({ role: 'assistant', content: m.content.slice(0, MAX_TEXT_CHARS) });
  }

  const userText = (body.userText ?? body.prompt ?? '').slice(0, MAX_TEXT_CHARS);
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

  return messages;
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
  // Cold-start sensitivity: this endpoint is on the chat latency path. If
  // production analytics show cold starts, add `minInstances: 1` here.
  .runWith({ timeoutSeconds: 300, memory: '512MB', secrets: [OPENAI_API_KEY] })
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
    if (!['stream', 'json', 'plain'].includes(mode)) {
      fail(res, 400, 'invalid_argument', { message: `Unsupported mode '${mode}'.` });
      return;
    }

    const images = Array.isArray(body.images) ? body.images : [];
    const usageType = (body.usageType ?? (images.length > 0 ? 'scan' : 'chat')).toString();
    const timezoneOffset = Number(body.timezoneOffset ?? 0);

    // Whitelist usageType and reject unknown.
    if (!['chat', 'scan', 'system'].includes(usageType)) {
      fail(res, 400, 'invalid_argument', { message: `Unsupported usageType '${usageType}'.` });
      return;
    }

    // Server-side free-tier enforcement (idempotent on retries).
    // Metering includes 'system' usage.
    try {
      const usage = await checkAndConsume(
        auth.uid,
        auth.isAnonymous,
        usageType as any,
        body.idempotencyKey,
        timezoneOffset,
      );
      if (!usage.allowed) {
        fail(res, 429, 'quota_exceeded', {
          type: usageType,
          limit: usage.limit,
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

    const messages = buildOpenAIMessages(body);
    if (messages.length === 0) {
      fail(res, 400, 'invalid_argument', { message: 'Empty message payload.' });
      return;
    }

    const payload: Record<string, unknown> = {
      model: (body.model ?? DEFAULT_MODEL).slice(0, 64),
      messages,
      stream: mode === 'stream',
      max_tokens: images.length > 0 ? 2048 : 1600, // Higher limit for full responses and vision analysis
    };
    if (mode === 'json') {
      payload.response_format = { type: 'json_object' };
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
      fail(res, 502, 'upstream_unreachable', { message: 'Could not reach the AI service. Please retry.' });
      return;
    }

    if (!upstream.ok) {
      const text = await upstream.text().catch(() => '');
      functions.logger.error(`OpenAI ${upstream.status}: ${text.slice(0, 500)}`);
      fail(res, upstream.status === 429 ? 503 : 502, 'upstream_error', {
        message: 'The AI service returned an error. Please retry.',
      });
      return;
    }

    if (mode !== 'stream') {
      try {
        const json = (await upstream.json()) as {
          choices?: Array<{ message?: { content?: string } }>;
        };
        const text = json.choices?.[0]?.message?.content ?? '';
        if (!text) {
          functions.logger.error('OpenAI returned empty content');
          fail(res, 502, 'upstream_error', { message: 'The AI service returned an empty response.' });
          return;
        }
        res.status(200).json({ text });
      } catch (e) {
        functions.logger.error('Failed to parse OpenAI response', e);
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

    try {
      const reader = (upstream.body as unknown as ReadableStream<Uint8Array>).getReader();
      const decoder = new TextDecoder();
      let buffer = '';
      let sawContent = false;

      // Aggregated SSE line parser for the upstream OpenAI stream.
      const processLine = (line: string): { done: boolean } => {
        const trimmed = line.trim();
        if (!trimmed.startsWith('data:')) return { done: false };
        const data = trimmed.slice(5).trim();
        if (data === '[DONE]') return { done: true };
        try {
          const event = JSON.parse(data) as {
            choices?: Array<{ delta?: { content?: string } }>;
          };
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
        send({ error: 'The AI service returned an empty response. Please retry.' });
      }
      res.write('data: [DONE]\n\n');
      res.end();
    } catch (e) {
      functions.logger.error('Streaming failure', e);
      send({ error: 'The connection to the AI service dropped. Please retry.' });
      res.end();
    }
  });
