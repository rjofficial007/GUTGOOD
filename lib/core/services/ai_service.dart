import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/crashlytics_service.dart';
import 'package:gutgood/core/services/prompts.dart';
import 'package:gutgood/core/services/remote_config_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:uuid/uuid.dart';

/// Thrown when the server-side free-tier gate rejects the request (HTTP 429).
/// The UI maps this to the paywall — the single source of truth for limits is
/// now the backend, which removes the old client-tampering vector.
class AiQuotaExceededException implements Exception {
  const AiQuotaExceededException({required this.type, this.message = 'Daily free limit reached.'});
  final String type; // 'chat' | 'scan'
  final String message;

  @override
  String toString() => 'AiQuotaExceededException($type): $message';
}

/// Generic AI proxy failure (network, upstream, or protocol errors).
class AiServiceException implements Exception {
  const AiServiceException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'AiServiceException($statusCode): $message';
}

/// The caller has no active Firebase session to authenticate the proxy with.
class AiAuthException implements Exception {
  const AiAuthException();

  @override
  String toString() => 'AiAuthException: no authenticated user.';
}

abstract class AiService {
  Stream<String> sendMessageStream({required String systemInstruction, required List<ChatMessage> history, required String userText, List<Uint8List>? images, String mode = 'stream'});

  Future<String> generateContent({required String prompt, String? systemInstruction, Uint8List? imageBytes, String usageType});

  Future<String> summarizeHistory(List<ChatMessage> history, {String? previousSummary});
}

/// Secure OpenAI client talking exclusively to the `aiProxy` Cloud Function.
///
/// PRD §3d compliance:
///  - The OpenAI API key never exists on-device (replaces the previous
///    Remote-Config-delivered key, which was extractable from the client).
///  - Every request carries a Firebase ID token; the function verifies it and
///    enforces the free-tier limits server-side (tamper-proof).
class AiServiceImpl implements AiService {
  AiServiceImpl({required Dio dio, required FirebaseAuth auth, required RemoteConfigService config, required AnalyticsService analyticsService, required CrashlyticsService crashlyticsService})
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

  static const int _maxRetries = 2;

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
  /// existing (previously unused) `ChatMessage.toAiMap()`/`ScanResult.toAiMap()`
  /// helpers.
  List<Map<String, String>> _historyToPayload(List<ChatMessage> history) => history.where((m) => m.text.isNotEmpty || m.scanData != null).map((m) {
    final role = m.role == 'user' ? 'user' : 'assistant';
    if (m.scanData == null) {
      return {'role': role, 'content': m.text};
    }

    final scanContext = jsonEncode(m.scanData!.toAiMap());
    final content = m.text.isNotEmpty ? '${m.text}\n\n[SCAN_CONTEXT]$scanContext[/SCAN_CONTEXT]' : '[SCAN_CONTEXT]$scanContext[/SCAN_CONTEXT]';
    return {'role': role, 'content': content};
  }).toList();

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
  Stream<String> sendMessageStream({required String systemInstruction, required List<ChatMessage> history, required String userText, List<Uint8List>? images, String mode = 'stream'}) async* {
    final idempotencyKey = const Uuid().v4();
    final headers = await _buildHeaders(idempotencyKey);

    final body = jsonEncode({
      'mode': mode,
      'systemInstruction': systemInstruction,
      'messages': _historyToPayload(history),
      'userText': userText,
      if (images != null && images.isNotEmpty) 'images': images.map(base64Encode).toList(),
      'model': _config.openAIModel,
      'usageType': (images != null && images.isNotEmpty) ? 'scan' : 'chat',
      'idempotencyKey': idempotencyKey,
      'timezoneOffset': DateTime.now().timeZoneOffset.inMinutes,
    });

    AppLogger.debug('AiService: streaming via proxy (history: ${history.length}, images: ${images?.length ?? 0})');
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
          options: Options(responseType: ResponseType.stream, headers: headers, sendTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(minutes: 4), validateStatus: (_) => true),
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
      if (e != null) await _crashlyticsService.recordError(e, e.stackTrace, reason: 'AI Stream connection failed');
      throw AiServiceException(e?.message ?? 'Connection failed.', statusCode: e?.response?.statusCode);
    }

    final status = response.statusCode ?? 500;
    if (status != 200) {
      final errorBody = await _readErrorBody(response.data);
      await _analyticsService.logEvent(name: 'ai_stream_error', parameters: {'status': status, 'type': images != null ? 'scan' : 'chat'});
      _throwForStatus(status, errorBody);
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
  Future<String> generateContent({required String prompt, String? systemInstruction, Uint8List? imageBytes, String usageType = 'system'}) async {
    AppLogger.debug('AiService: generating content (mode: json, usageType: $usageType)');
    final startTime = DateTime.now();

    final idempotencyKey = const Uuid().v4();
    final headers = await _buildHeaders(idempotencyKey);

    final body = jsonEncode({
      'mode': 'json',
      'systemInstruction': systemInstruction,
      'prompt': prompt,
      if (imageBytes != null) 'images': [base64Encode(imageBytes)],
      'model': _config.openAIModel,
      'usageType': usageType,
      'idempotencyKey': idempotencyKey,
      'timezoneOffset': DateTime.now().timeZoneOffset.inMinutes,
    });

    var attempts = 0;
    while (true) {
      attempts++;
      try {
        final response = await _dio.post<String>(
          _config.aiProxyUrl,
          data: body,
          options: Options(headers: headers, sendTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 90), validateStatus: (_) => true),
        );

        final status = response.statusCode ?? 500;
        if (status != 200) _throwForStatus(status, response.data ?? '');

        final duration = DateTime.now().difference(startTime).inMilliseconds;
        await _analyticsService.logEvent(name: 'ai_json_success', parameters: {'latency_ms': duration, 'usage_type': usageType});

        final decoded = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;

        // 🟢 Log the JSON response for debugging
        AppLogger.data('AI_JSON_RESULT ($usageType)', decoded);

        return (decoded['text'] ?? '').toString();
      } on DioException catch (e, st) {
        // Retry only when the request provably never reached / completed at the
        // server; the idempotency key guards the rare ambiguous case.
        AppLogger.error('AiService: content generation failed (attempt $attempts/$_maxRetries)', error: e, stackTrace: st);
        if (attempts >= _maxRetries || !_isRetryable(e)) {
          throw AiServiceException(e.message ?? 'Connection failed.', statusCode: e.response?.statusCode);
        }
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> history, {String? previousSummary}) async {
    if (history.isEmpty) return previousSummary ?? '';

    // 🟢 Fix: Use toAiMap() to avoid payload-too-large (502) errors.
    final historyMaps = history.map((m) => m.toAiMap()).toList();
    final historyJson = jsonEncode(historyMaps);

    final prompt = '${Prompts.summarizationInstruction(previousSummary: previousSummary)}\n\n$historyJson';

    final idempotencyKey = const Uuid().v4();
    try {
      final headers = await _buildHeaders(idempotencyKey);
      final response = await _dio.post<String>(
        _config.aiProxyUrl,
        data: jsonEncode({
          'mode': 'plain',
          'prompt': prompt,
          'model': _config.openAIModel,
          'usageType': 'system',
          'idempotencyKey': idempotencyKey,
          'timezoneOffset': DateTime.now().timeZoneOffset.inMinutes,
        }),
        options: Options(headers: headers, sendTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 60), validateStatus: (_) => true),
      );

      if (response.statusCode != 200) {
        AppLogger.warning('AiService: summarize failed with status ${response.statusCode}');
        return previousSummary ?? '';
      }
      final decoded = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      final result = (decoded['text'] ?? previousSummary ?? '').toString();

      // 🟢 Log the summary result
      AppLogger.debug('AiService: History summary generated: $result');

      return result;
    } catch (e) {
      AppLogger.error('AiService: History summarization failed', error: e);
      return previousSummary ?? '';
    }
  }
}
