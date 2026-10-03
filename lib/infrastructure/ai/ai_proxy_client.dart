import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gutgood/core/ai/client/ai_client.dart';
import 'package:gutgood/core/ai/client/ai_exceptions.dart';
import 'package:gutgood/core/ai/prompts/prompt_catalog.dart';
import 'package:gutgood/core/models/chat/chat_message.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/model_utils.dart';
import 'package:gutgood/infrastructure/firebase/analytics_service.dart';
import 'package:gutgood/infrastructure/firebase/crashlytics_service.dart';
import 'package:gutgood/infrastructure/firebase/remote_config_service.dart';
import 'package:uuid/uuid.dart';

/// Secure OpenAI client talking exclusively to the `aiProxy` Cloud Function.
///
/// PRD §3d compliance:
///  - The OpenAI API key never exists on-device (replaces the previous
///    Remote-Config-delivered key, which was extractable from the client).
///  - Every request carries a Firebase ID token; the function verifies it and
///    meters the free-tier limits server-side. Note: enforcement is bounded by
///    accepted risks R1–R3 (client-authoritative premium, unvalidated timezone
///    offset, guest profile-delete reset) — see docs/ACCEPTED_RISKS.md.
class AiProxyClient implements AiClient {
  AiProxyClient({required Dio dio, required FirebaseAuth auth, required RemoteConfigService config, required AnalyticsService analyticsService, required CrashlyticsService crashlyticsService})
    : _dio = dio,
      _auth = auth,
      _config = config,
      _analyticsService = analyticsService,
      _crashlyticsService = crashlyticsService;
  final Dio _dio;
  final FirebaseAuth _auth;
  final RemoteConfigService _config;
  final AnalyticsService _analyticsService;
  final CrashlyticsService _crashlyticsService;

  static const int _maxRetries = 3;

  bool _lastResponseTruncated = false;
  String? _lastTruncationKind;
  int? _lastPromptVersion;
  String? _lastServedModel;

  @override
  bool get lastResponseTruncated => _lastResponseTruncated;

  @override
  int? get lastPromptVersion => _lastPromptVersion;

  @override
  String? get lastServedModel => _lastServedModel;

  Future<Map<String, String>> _buildHeaders(String idempotencyKey) async {
    final user = _auth.currentUser;
    if (user == null) throw const AiAuthException();
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw const AiAuthException();
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json', 'Idempotency-Key': idempotencyKey};
  }

  /// 🟢 FIXED (Finding #5): previously this only forwarded `m.text`, so once
  /// a scan's `[SCAN]` JSON block was stripped out of the displayed bubble
  /// text (by `_processChatTagUseCase`), the structured product details
  /// (score, nutriscore, flagged ingredients, etc.) were PERMANENTLY
  /// invisible to the model on every subsequent turn — directly hurting
  /// the "why do I feel bloated after this?" / "what should I eat
  /// instead?" quick-reply chips, which depend on the model still knowing
  /// what "this" refers to. `scanData` is now serialized inline via the
  /// existing (previously unused) `ChatMessage.toAiMap()` helper.
  ///
  /// 🟢 NEW (Production Audit Update): Now includes `mealLogs` and
  /// `symptomLogs` context via the enhanced `toAiMap()` to ensure follow-up
  /// questions about specific nutritional values or symptom severities are
  /// grounded in the structured truth, not just the natural language summary.
  List<Map<String, dynamic>> _historyToPayload(List<ChatMessage> history) =>
      history.where((m) => m.text.isNotEmpty || m.scanData != null || m.mealLogs.isNotEmpty || m.symptomLogs.isNotEmpty).map((m) => m.toAiMap()).toList();

  Never _throwForStatus(int status, String body) {
    var message = 'Unexpected AI proxy error ($status).';
    var type = 'chat';
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      message = (decoded['message'] ?? decoded['error'] ?? message).toString();
      type = (decoded['type'] ?? type).toString();
      if (status == 429 || decoded['error'] == 'quota_exceeded') {
        throw AiQuotaExceededException(type: type, message: message);
      }
    } catch (e) {
      if (e is AiQuotaExceededException) rethrow;
    }
    if (status == 401 || status == 403) throw const AiAuthException();
    throw AiServiceException(message, statusCode: status);
  }

  bool _isRetryable(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError || e.type == DioExceptionType.sendTimeout) {
      return true;
    }
    // 🟢 Also retry on transient server errors (502 Bad Gateway, 503 Service Unavailable, 504 Gateway Timeout)
    final status = e.response?.statusCode;
    if (status == 502 || status == 503 || status == 504) {
      return true;
    }
    return false;
  }

  @override
  Stream<String> sendMessageStream({
    required String systemInstruction,
    required List<ChatMessage> history,
    required String userText,
    List<Uint8List>? images,
    String mode = 'stream',
    String? intent,
    int? promptVersion,
  }) async* {
    _lastResponseTruncated = false;
    _lastTruncationKind = null;
    _lastPromptVersion = null;
    _lastServedModel = null;
    final idempotencyKey = const Uuid().v4();
    final headers = await _buildHeaders(idempotencyKey);

    final body = ModelUtils.safeJsonEncode({
      'mode': mode,
      'systemInstruction': systemInstruction,
      'messages': _historyToPayload(history),
      'userText': userText,
      if (images != null && images.isNotEmpty) 'images': images.map(base64Encode).toList(),
      'model': _config.openAIModel,
      'usageType': (images != null && images.isNotEmpty) ? 'scan' : 'chat',
      'idempotencyKey': idempotencyKey,
      'timezoneOffset': DateTime.now().timeZoneOffset.inMinutes,
      'intent': ?intent,
      'promptVersion': ?promptVersion,
    });

    AppLogger.ai('streaming via proxy (history: ${history.length}, images: ${images?.length ?? 0})');
    final startTime = DateTime.now();

    // 🟢 NEW: previously a single connection failure (timeout/reset) here
    // threw immediately with zero retry, even though `generateContent`
    // below already retries the exact same class of transient errors.
    // Streaming can't safely retry mid-stream (partial tokens may already
    // be yielded), but the initial connection attempt — before any bytes
    // are read — safely can and now does, using the same backoff policy.
    Response<ResponseBody>? response;
    var attempts = 0;
    DioException? lastError;
    while (attempts < _maxRetries) {
      attempts++;
      try {
        response = await _dio.post<ResponseBody>(
          _config.aiProxyUrl,
          data: body,
          options: Options(
            responseType: ResponseType.stream,
            headers: headers,
            connectTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(minutes: 4),
            // 🟢 Removed validateStatus so _isRetryable can catch 5xx and retry the initial connection.
          ),
        );
        lastError = null;
        break;
      } on DioException catch (e) {
        lastError = e;
        if (!_isRetryable(e) || attempts >= _maxRetries) break;
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }

    if (lastError != null || response == null) {
      final e = lastError;
      await _analyticsService.logEvent(name: 'ai_stream_failed', parameters: {'error': e.toString(), 'type': images != null ? 'scan' : 'chat'});

      if (e?.response != null) {
        final errorBody = await _readErrorBody(e!.response!.data as ResponseBody?);
        _throwForStatus(e.response!.statusCode ?? 500, errorBody);
      }

      if (e != null) await _crashlyticsService.recordError(e, e.stackTrace, reason: 'AI Stream connection failed');
      throw AiServiceException(e?.message ?? 'Connection failed.', statusCode: e?.response?.statusCode);
    }

    final stream = response.data?.stream;
    if (stream == null) throw const AiServiceException('Empty response stream.');

    // Parse the SSE frames emitted by the proxy: data: {"d":"delta"}\n\n
    final buffer = StringBuffer();
    final fullResponseBuffer = StringBuffer(); // 🟢 NEW: For logging the full result
    var sawDone = false;

    await for (final chunk in stream) {
      if (buffer.isEmpty && chunk.isNotEmpty) {
        final firstTokenLatency = DateTime.now().difference(startTime).inMilliseconds;
        unawaited(_analyticsService.logEvent(name: 'ai_stream_first_token', parameters: {'latency_ms': firstTokenLatency, 'type': images != null ? 'scan' : 'chat'}));
      }
      buffer.write(utf8.decode(chunk, allowMalformed: true));

      var content = buffer.toString();
      int newlineIndex;
      while ((newlineIndex = content.indexOf('\n')) != -1) {
        final line = content.substring(0, newlineIndex).trim();
        content = content.substring(newlineIndex + 1);

        if (!line.startsWith('data:')) continue;
        final data = line.substring(5).trim();
        if (data.isEmpty) continue;
        if (data == '[DONE]') {
          sawDone = true;
          break;
        }

        try {
          final decoded = jsonDecode(data) as Map<String, dynamic>;
          if (decoded['error'] != null) {
            throw AiServiceException(decoded['error'].toString());
          }
          if (decoded['truncated'] == true) {
            _lastResponseTruncated = true;
            _lastTruncationKind = decoded['truncation'] as String?;
          }
          // J-4: version echo rides the meta frame (sent on every response).
          final echoedVersion = decoded['promptVersion'];
          if (echoedVersion is int) _lastPromptVersion = echoedVersion;
          final served = decoded['model'];
          if (served is String && served.isNotEmpty) _lastServedModel = served;
          final delta = decoded['d'];
          if (delta is String && delta.isNotEmpty) {
            fullResponseBuffer.write(delta); // 🟢 Accumulate for log
            yield delta;
          }
        } catch (e) {
          if (e is AiServiceException) rethrow;
          // Incomplete JSON frame — ignore; the next chunk completes it.
        }
      }
      buffer
        ..clear()
        ..write(content);
      if (sawDone) break;
    }

    // Flush any trailing frame that arrived without a newline terminator.
    final tail = buffer.toString().trim();
    if (!sawDone && tail.startsWith('data:')) {
      final data = tail.substring(5).trim();
      if (data.isNotEmpty && data != '[DONE]') {
        try {
          final decoded = jsonDecode(data) as Map<String, dynamic>;
          if (decoded['error'] != null) throw AiServiceException(decoded['error'].toString());
          if (decoded['truncated'] == true) {
            _lastResponseTruncated = true;
            _lastTruncationKind = decoded['truncation'] as String?;
          }
          final echoedVersion = decoded['promptVersion'];
          if (echoedVersion is int) _lastPromptVersion = echoedVersion;
          final served = decoded['model'];
          if (served is String && served.isNotEmpty) _lastServedModel = served;
          final delta = decoded['d'];
          if (delta is String && delta.isNotEmpty) {
            fullResponseBuffer.write(delta);
            yield delta;
          }
        } catch (e) {
          if (e is AiServiceException) rethrow;
        }
      }
    }

    // 🟢 Log the full stream result once finished
    AppLogger.data('AI_STREAM_RESULT', fullResponseBuffer.toString());
  }

  Future<String> _readErrorBody(ResponseBody? body) async {
    if (body == null) return '';
    try {
      final bytes = await body.stream.expand((c) => c).toList();
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return '';
    }
  }

  @override
  Future<String> generateContent({required String prompt, String? systemInstruction, Uint8List? imageBytes, String usageType = 'system', String mode = 'json', int? promptVersion}) async {
    _lastResponseTruncated = false;
    _lastTruncationKind = null;
    _lastPromptVersion = null;
    _lastServedModel = null;
    AppLogger.ai('generating content (mode: $mode, usageType: $usageType)');
    final startTime = DateTime.now();

    final idempotencyKey = const Uuid().v4();
    final headers = await _buildHeaders(idempotencyKey);

    final body = ModelUtils.safeJsonEncode({
      'mode': mode,
      'systemInstruction': systemInstruction,
      'prompt': prompt,
      if (imageBytes != null) 'images': [base64Encode(imageBytes)],
      'model': _config.openAIModel,
      'usageType': usageType,
      'idempotencyKey': idempotencyKey,
      'timezoneOffset': DateTime.now().timeZoneOffset.inMinutes,
      'promptVersion': ?promptVersion,
    });

    var attempts = 0;
    while (true) {
      attempts++;
      try {
        final response = await _dio.post<String>(
          _config.aiProxyUrl,
          data: body,
          options: Options(
            headers: headers,
            connectTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 90),
            // 🟢 REMOVED validateStatus: (_) => true to let Dio throw DioException on non-200.
            // This allows _isRetryable() to trigger retries for transient 5xx errors.
          ),
        );

        final duration = DateTime.now().difference(startTime).inMilliseconds;
        await _analyticsService.logEvent(name: 'ai_json_success', parameters: {'latency_ms': duration, 'usage_type': usageType});

        final decoded = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;

        // 🟢 Log the JSON response for debugging
        AppLogger.data('AI_JSON_RESULT ($usageType)', decoded);

        // P3-4: one-shot callers are system calls (insights/summaries) with no
        // user-visible surface — log + meter so truncation stays observable.
        _lastResponseTruncated = decoded['truncated'] == true;
        _lastTruncationKind = decoded['truncation'] as String?;
        if (_lastResponseTruncated) {
          AppLogger.ai('proxy truncated this response (kind: $_lastTruncationKind, usageType: $usageType)');
          unawaited(_analyticsService.logEvent(name: 'ai_response_truncated', parameters: {'kind': _lastTruncationKind ?? 'unknown', 'usage_type': usageType}));
        }

        // J-4: version echo for artifact stamping (§17).
        final echoedVersion = decoded['promptVersion'];
        if (echoedVersion is int) _lastPromptVersion = echoedVersion;
        final served = decoded['model'];
        if (served is String && served.isNotEmpty) _lastServedModel = served;

        return (decoded['text'] ?? '').toString();
      } on DioException catch (e, st) {
        if (attempts < _maxRetries && _isRetryable(e)) {
          AppLogger.ai('content generation transient error (attempt $attempts/$_maxRetries, status: ${e.response?.statusCode}). Retrying in ${attempts * 2}s...');
          await Future.delayed(Duration(seconds: attempts * 2));
          continue;
        }

        AppLogger.error('content generation failed after $attempts attempt(s)', error: e, stackTrace: st);

        if (e.response != null) {
          _throwForStatus(e.response!.statusCode ?? 500, e.response!.data?.toString() ?? '');
        }

        throw AiServiceException(e.message ?? 'Connection failed.', statusCode: e.response?.statusCode);
      }
    }
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> history, {String? previousSummary}) async {
    if (history.isEmpty) return previousSummary ?? '';

    // 🟢 Fix: Use toAiMap() to avoid payload-too-large (502) errors.
    final historyMaps = history.map((m) => m.toAiMap()).toList();
    final historyJson = ModelUtils.safeJsonEncode(historyMaps);

    final prompt = '${Prompts.summarizationInstruction(previousSummary: previousSummary)}\n\n$historyJson';

    final idempotencyKey = const Uuid().v4();
    try {
      final headers = await _buildHeaders(idempotencyKey);
      final response = await _dio.post<String>(
        _config.aiProxyUrl,
        data: ModelUtils.safeJsonEncode({
          'mode': 'plain',
          'prompt': prompt,
          'model': _config.openAIModel,
          'usageType': 'system',
          'idempotencyKey': idempotencyKey,
          'timezoneOffset': DateTime.now().timeZoneOffset.inMinutes,
        }),
        options: Options(
          headers: headers,
          connectTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          validateStatus: (_) => true,
        ),
      );

      if (response.statusCode != 200) {
        AppLogger.warning('summarize failed with status ${response.statusCode}');
        return previousSummary ?? '';
      }
      final decoded = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      final result = (decoded['text'] ?? previousSummary ?? '').toString();

      // 🟢 Log the summary result
      AppLogger.ai('History summary generated: $result');

      return result;
    } catch (e) {
      AppLogger.error('History summarization failed', error: e);
      return previousSummary ?? '';
    }
  }
}
