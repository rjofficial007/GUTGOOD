import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/chat_attachment.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/services/ai_classifier_service.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/internet_connection_checker.dart';
import 'package:gutgood/core/services/off_service.dart';
import 'package:gutgood/core/services/prompts.dart';
import 'package:gutgood/core/services/storage_service.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';
import 'package:gutgood/features/chat/domain/usecases/persist_ai_response_usecase.dart';
import 'package:gutgood/features/chat/domain/usecases/process_chat_tag_usecase.dart';
import 'package:gutgood/features/chat/domain/usecases/send_message_stream_usecase.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_history_notifier.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:uuid/uuid.dart';

enum ChatSendError { offline, busy, empty, uploadFailed }

class ChatComposerNotifier with ChangeNotifier {
  ChatComposerNotifier({
    required ChatRepository repository,
    required ChatHistoryNotifier historyNotifier,
    required StorageService storageService,
    required OffService offService,
    required AiClassifierService aiClassifierService,
    required FirebaseAuth auth,
    required InternetConnectionChecker connectionChecker,
    required SendMessageStreamUseCase sendMessageStreamUseCase,
    required ProcessChatTagUseCase processChatTagUseCase,
    required PersistAiResponseUseCase persistAiResponseUseCase,
    required AnalyticsService analyticsService,
    required AppStateService appStateService,
  }) : _repository = repository,
       _historyNotifier = historyNotifier,
       _storageService = storageService,
       _offService = offService,
       _aiClassifierService = aiClassifierService,
       _auth = auth,
       _connectionChecker = connectionChecker,
       _sendMessageStreamUseCase = sendMessageStreamUseCase,
       _processChatTagUseCase = processChatTagUseCase,
       _persistAiResponseUseCase = persistAiResponseUseCase,
       _analyticsService = analyticsService,
       _appStateService = appStateService {
    _appStateService.sessionReset.addListener(_onSessionReset);
  }

  final ChatRepository _repository;
  final ChatHistoryNotifier _historyNotifier;
  final StorageService _storageService;
  final OffService _offService;
  final AiClassifierService _aiClassifierService;
  final FirebaseAuth _auth;
  final InternetConnectionChecker _connectionChecker;
  final SendMessageStreamUseCase _sendMessageStreamUseCase;
  final ProcessChatTagUseCase _processChatTagUseCase;
  final PersistAiResponseUseCase _persistAiResponseUseCase;
  final AnalyticsService _analyticsService;
  final AppStateService _appStateService;

  bool _isLoading = false;
  bool _isStreaming = false;
  final List<ChatAttachment> _attachments = [];
  static const int maxAttachments = 1;

  String? _activeAiLocalId;
  StreamSubscription<String>? _aiSubscription;
  Timer? _flushTimer;
  String _chunkBuffer = '';
  String _fullAiText = '';
  bool _generationCancelled = false;
  final Set<String> _persistedTags = {};
  bool _persistTagsForActiveTurn = true;
  String? _pendingHiddenContext;

  // Last request
  bool _hasLastRequest = false;
  String? _lastUserText;
  String? _lastHiddenContext;
  String? _lastSource;
  List<Uint8List> _lastSentImages = const [];
  String? _lastSentImageUrl;

  List<ChatAttachment> get pendingAttachments => List.unmodifiable(_attachments);
  bool get isLoading => _isLoading;
  bool get isStreaming => _isStreaming;
  bool get canRegenerate => !_isLoading && _hasLastRequest;
  bool get isOffline => !_connectionChecker.isInternetAvailable.value;
  String? get pendingHiddenContext => _pendingHiddenContext;

  @override
  void dispose() {
    _flushTimer?.cancel();
    _aiSubscription?.cancel();
    _appStateService.sessionReset.removeListener(_onSessionReset);
    super.dispose();
  }

  void _onSessionReset() {
    _flushTimer?.cancel();
    _aiSubscription?.cancel();
    _attachments.clear();
    _hasLastRequest = false;
    _lastUserText = null;
    _lastHiddenContext = null;
    _lastSentImages = const [];
    _lastSentImageUrl = null;
    _isLoading = false;
    _isStreaming = false;
    notifyListeners();
  }

  Future<bool> handleImageAttachment(Uint8List bytes, {required String type}) async {
    final added = await addAttachment(bytes, source: type);
    if (added) {
      _pendingHiddenContext = type;
      notifyListeners();
    }
    return added;
  }

  void clearPendingHiddenContext() {
    _pendingHiddenContext = null;
    notifyListeners();
  }

  String getPromptForType(String type) => switch (type) {
    'menu' => AppStrings.menuPhotoPrompt,
    'label' => AppStrings.labelPhotoPrompt,
    'food' => AppStrings.mealPhotoPrompt,
    _ => AppStrings.galleryPhotoPrompt,
  };

  Future<bool> addAttachment(Uint8List bytes, {String source = 'gallery'}) async {
    if (_isLoading) return false;
    _attachments.clear();
    final compressed = await _storageService.compressImage(bytes);
    _attachments.add(ChatAttachment(id: const Uuid().v4(), bytes: compressed, source: source));
    await _analyticsService.logEvent(name: 'attachment_added', parameters: {'source': source});
    notifyListeners();
    return true;
  }

  void removeAttachment(String id) {
    _attachments.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void clearAttachments() {
    if (_attachments.isEmpty) return;
    _attachments.clear();
    notifyListeners();
  }

  Future<ChatSendError?> send({String text = '', String? hiddenContext, String? source, String? providedUserMsgId}) async {
    if (_isLoading) return ChatSendError.busy;

    final displayText = text.trim();
    final sending = List<ChatAttachment>.of(_attachments);

    if (displayText.isEmpty && sending.isEmpty) return ChatSendError.empty;
    if (!_connectionChecker.isInternetAvailable.value) {
      return ChatSendError.offline;
    }

    _hasLastRequest = true;
    _lastUserText = displayText;
    _lastHiddenContext = hiddenContext;
    _lastSource = source;
    _lastSentImages = sending.map((a) => a.bytes).toList(growable: false);
    _lastSentImageUrl = null;

    _attachments.clear();
    _generationCancelled = false;

    final userMsg = ChatMessage(
      localId: providedUserMsgId ?? const Uuid().v4(),
      role: 'user',
      text: displayText,
      localImages: sending.isEmpty ? null : _lastSentImages,
      isSending: sending.isNotEmpty,
      isSwap: false,
      source: source ?? (sending.isNotEmpty ? sending.first.source : 'chat'),
      createdAt: DateTime.now(),
    );

    final aiPlaceholder = ChatMessage(localId: const Uuid().v4(), role: 'ai', text: '', isSwap: false, source: userMsg.source, createdAt: DateTime.now().add(const Duration(milliseconds: 1)));

    _historyNotifier
      ..addOptimisticMessage(userMsg)
      ..addOptimisticMessage(aiPlaceholder);
    _activeAiLocalId = aiPlaceholder.localId;

    _isLoading = true;
    _isStreaming = false;
    notifyListeners();

    await _analyticsService.logEvent(name: 'message_sent', parameters: {'has_attachments': sending.isNotEmpty, 'text_length': displayText.length, 'source': userMsg.source ?? 'chat'});

    var imageUrls = const <String>[];
    if (sending.isNotEmpty) {
      if (_auth.currentUser == null) {
        _historyNotifier
          ..replaceMessage(userMsg.localId, userMsg.copyWith(isSending: false, sendFailed: true))
          ..removeMessage(aiPlaceholder.localId);
        _finishTurn();
        return ChatSendError.uploadFailed;
      }
      try {
        imageUrls = await Future.wait(
          _lastSentImages.map((bytes) async {
            final url = await _storageService.uploadFoodImage(bytes);
            if (url == null) throw StateError('upload returned null');
            return url;
          }),
        );
      } catch (e) {
        AppLogger.ai('Image upload failed', error: e);
        _historyNotifier
          ..replaceMessage(userMsg.localId, userMsg.copyWith(isSending: false, sendFailed: true))
          ..removeMessage(aiPlaceholder.localId);
        _finishTurn();
        return ChatSendError.uploadFailed;
      }

      final uploaded = userMsg.copyWith(imageUrls: imageUrls, isSending: false, clearLocalImages: false);
      _lastSentImageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;
      _historyNotifier.replaceMessage(userMsg.localId, uploaded);

      final saved = await _repository.saveMessage(uploaded);
      _historyNotifier.replaceMessage(uploaded.localId, saved.copyWith(clearLocalImages: true));
    } else {
      final saved = await _repository.saveMessage(userMsg);
      _historyNotifier.replaceMessage(userMsg.localId, saved);
    }

    final aiText = _effectiveAiText(displayText: displayText, hiddenContext: hiddenContext, hasImages: sending.isNotEmpty);

    String? detectedMode;
    String? detectedIntent;

    if (sending.isNotEmpty) {
      try {
        final classification = await _aiClassifierService.classifyImage(imageBytes: sending.first.bytes, userText: displayText);
        detectedMode = classification.imageMode;
        detectedIntent = classification.intent;
        AppLogger.ai('ChatComposer: AI classified image as $detectedMode with intent $detectedIntent');
      } catch (e) {
        AppLogger.warning('ChatComposer: Image classification failed, falling back to source');
      }
    }

    await _streamReply(
      userText: aiText,
      images: sending.isEmpty ? null : _lastSentImages,
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
      source: detectedMode ?? userMsg.source,
      detectedIntent: detectedIntent,
    );

    return null;
  }

  String _effectiveAiText({required String displayText, String? hiddenContext, required bool hasImages}) {
    if (displayText.isNotEmpty) {
      return hiddenContext != null && hiddenContext.isNotEmpty ? '$displayText\n\n$hiddenContext' : displayText;
    }
    return hiddenContext ?? 'Analyze this image for gut health.';
  }

  Future<void> regenerateLastResponse() async {
    if (_isLoading || !_hasLastRequest) return;
    if (!_connectionChecker.isInternetAvailable.value) return;

    if (_historyNotifier.messages.isNotEmpty && _historyNotifier.messages.first.role == 'ai') {
      final old = _historyNotifier.messages.first;
      await _historyNotifier.deleteMessage(old);
    }

    final placeholder = ChatMessage(localId: const Uuid().v4(), role: 'ai', text: '', isSwap: false, source: _lastSource, createdAt: DateTime.now());
    _historyNotifier.addOptimisticMessage(placeholder);
    _activeAiLocalId = placeholder.localId;

    _generationCancelled = false;
    _isLoading = true;
    _isStreaming = false;
    notifyListeners();

    await _analyticsService.logEvent(name: 'message_regenerated', parameters: {'has_images': _lastSentImages.isNotEmpty});

    String? detectedMode;
    String? detectedIntent;

    if (_lastSentImages.isNotEmpty) {
      try {
        final classification = await _aiClassifierService.classifyImage(imageBytes: _lastSentImages.first, userText: _lastUserText);
        detectedMode = classification.imageMode;
        detectedIntent = classification.intent;
      } catch (e) {
        AppLogger.warning('ChatComposer: Regeneration classification failed');
      }
    }

    final aiText = _effectiveAiText(displayText: _lastUserText ?? '', hiddenContext: _lastHiddenContext, hasImages: _lastSentImages.isNotEmpty);
    await _streamReply(
      userText: aiText,
      images: _lastSentImages.isEmpty ? null : _lastSentImages,
      imageUrl: _lastSentImageUrl,
      source: detectedMode ?? _lastSource,
      detectedIntent: detectedIntent,
      isRegenerate: true,
    );
  }

  Future<ChatSendError?> retryMessage(ChatMessage failedMessage) async {
    if (_isLoading) return ChatSendError.busy;
    if (!failedMessage.sendFailed) return null;

    await _historyNotifier.deleteMessage(failedMessage);

    final images = failedMessage.localImages ?? const <Uint8List>[];
    for (final bytes in images) {
      await addAttachment(bytes, source: failedMessage.source ?? 'gallery');
    }

    return send(text: failedMessage.text, source: failedMessage.source);
  }

  void stopGeneration() {
    if (!_isLoading) return;
    _generationCancelled = true;
    _aiSubscription?.cancel();
    _finalizeStream();
  }

  void _finishTurn() {
    _isLoading = false;
    _isStreaming = false;
    _activeAiLocalId = null;
    notifyListeners();

    sl<ProfileNotifier>().triggerPendingCelebration();
  }

  List<ChatMessage> _buildHistory() {
    final all = _historyNotifier.messages.reversed.toList();
    final activeId = _activeAiLocalId;

    final filtered = all.where((m) {
      if (m.localId == activeId) return false;
      if (m.sendFailed) return false;
      if (m.role == 'ai' && m.text.isEmpty && m.scanData == null) return false;
      if (m.role == 'ai' && m.errorKind == ChatErrorKind.quota) return false;
      return m.text.isNotEmpty || m.scanData != null;
    }).toList();

    var chronological = filtered.map((m) {
      final cleanText = m.text
          .replaceAll(RegExp(r'\[SCAN\].*?\[/SCAN\]', dotAll: true), '')
          .replaceAll(RegExp(r'\[MEAL\].*?\[/MEAL\]', dotAll: true), '')
          .replaceAll(RegExp(r'\[SYMPTOM\].*?\[/SYMPTOM\]', dotAll: true), '')
          .replaceAll(RegExp(r'\[SWAPS\].*?\[/SWAPS\]', dotAll: true), '')
          .trim();

      if (cleanText.isEmpty && m.scanData != null) {
        return m.copyWith(text: 'I scanned ${m.scanData!.productName}.');
      }
      return m.copyWith(text: cleanText);
    }).toList();

    if (chronological.isNotEmpty && chronological.last.role == 'user' && chronological.last.text == _lastUserText) {
      chronological = chronological.sublist(0, chronological.length - 1);
    }

    const maxContextMessages = 25;
    if (chronological.length > maxContextMessages) {
      chronological = chronological.sublist(chronological.length - maxContextMessages);
    }
    return chronological;
  }

  Future<void> _streamReply({required String userText, List<Uint8List>? images, String? imageUrl, String? source, String? detectedIntent, bool isRegenerate = false}) async {
    final aiLocalId = _activeAiLocalId;
    if (aiLocalId == null) {
      _finishTurn();
      return;
    }

    _chunkBuffer = '';
    _fullAiText = '';
    _persistedTags.clear();
    _persistTagsForActiveTurn = !isRegenerate;

    // 🟢 AI-BASED INTENT: Use detected intent if available, otherwise fallback to quick regex
    final quickIntent = _getQuickIntent(userText.toLowerCase());
    final intent = detectedIntent ?? quickIntent ?? source ?? 'full_analysis';

    AppLogger.ai('Final intent for prompt: "$intent" (detected: "$detectedIntent", source: "$source", quickDetected: "$quickIntent")');

    await _aiSubscription?.cancel();

    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(milliseconds: 60), (_) => _flushChunkBuffer(imageUrl: imageUrl, source: source));

    try {
      final stream = _sendMessageStreamUseCase(
        systemInstruction: Prompts.chatSystemInstruction(
          userGoals: _historyNotifier.userGoals,
          userSensitivities: _historyNotifier.userSensitivities,
          userLifestyle: _historyNotifier.userLifestyle,
          cyclePhase: _historyNotifier.cyclePhase,
          communicationStyle: _historyNotifier.commStyle,
          historySummary: _historyNotifier.cachedSummary,
          currentTime: DateTime.now().toIso8601String(),
          mode: source,
          intent: intent,
        ),
        history: _buildHistory(),
        userText: userText,
        images: images,
      );

      var hapticTriggered = false;

      _aiSubscription = stream.listen(
        (chunk) {
          if (_generationCancelled) return;
          if (!hapticTriggered && chunk.isNotEmpty) {
            HapticHelper.medium();
            hapticTriggered = true;
          }
          if (chunk.isNotEmpty && !_isStreaming) {
            _isStreaming = true;
          }
          _chunkBuffer += chunk;
        },
        onError: (e) {
          AppLogger.ai('AI stream error', error: e);
          _handleStreamError(e, aiLocalId);
        },
        onDone: () {
          if (_generationCancelled) return;
          _finalizeStream();
        },
        cancelOnError: false,
      );
    } catch (e, st) {
      AppLogger.ai('Stream setup failed', error: e, stackTrace: st);
      await _handleStreamError(e, aiLocalId);
    }
  }

  String? _getQuickIntent(String text) {
    final lowerText = text.toLowerCase();

    // 🟢 Exact Suggestion Chip Matches (Zero Latency Fast-Path)
    if (lowerText == AppStrings.suggestRateMeal.toLowerCase()) return 'meal_rating';
    if (lowerText == AppStrings.suggestBetterSwap.toLowerCase()) return 'meal_swaps';
    if (lowerText == AppStrings.suggestBloatCheck.toLowerCase()) return 'symptom_analysis';
    if (lowerText == AppStrings.suggestIsThisHealthy.toLowerCase()) return 'health_assessment';
    if (lowerText == AppStrings.suggestMealPlan.toLowerCase()) return 'meal_planning';
    if (lowerText == AppStrings.suggestExplainIngredients.toLowerCase()) return 'label';

    // 🔍 Robust Regex Detection (Non-AI Fast-Path)
    // Priority: Specific keywords should always override generic photo tags
    if (RegExp(r'\b(rate|score|grade|how did I do|feedback|how is my)\b').hasMatch(lowerText)) return 'meal_rating';
    if (RegExp(r'\b(swap|instead|better|alternative|healthier|replace|substitution)\b').hasMatch(lowerText)) return 'meal_swaps';
    if (RegExp(r'\b(bloat|bloating|bloated|pain|hurt|headache|tired|gas|cramp|nausea|stomachache)\b').hasMatch(lowerText)) return 'symptom_analysis';
    if (RegExp(r'\b(healthy|balanced|good for me|gut-friendly|gut friendly|is this okay)\b').hasMatch(lowerText)) return 'health_assessment';
    if (RegExp(r'\b(full analysis|breakdown|everything|details|all info|complete|tell me more|details please)\b').hasMatch(lowerText)) return 'full_analysis';
    if (RegExp(r'\b(vs|versus|compare|difference between|which one is better)\b').hasMatch(lowerText)) return 'product_comparison';
    if (RegExp(r'\b(plan|eat next|tomorrow|dinner idea|lunch idea|snack idea|what should i eat)\b').hasMatch(lowerText)) return 'meal_planning';
    if (RegExp(r'\b(menu|order|restaurant|eat here)\b').hasMatch(lowerText)) return 'menu';
    if (RegExp(r'\b(label|ingredients|ingredient|gums|emulsifier|additive|e-number)\b').hasMatch(lowerText)) return 'label';

    // 📸 Photo Prompt Matches
    if (lowerText.contains(AppStrings.menuPhotoPrompt.toLowerCase())) return 'menu';
    if (lowerText.contains(AppStrings.labelPhotoPrompt.toLowerCase())) return 'label';
    if (lowerText.contains(AppStrings.mealPhotoPrompt.toLowerCase())) return 'full_analysis';
    if (lowerText.contains(AppStrings.galleryPhotoPrompt.toLowerCase())) return 'gallery';

    // Casual meal mentions
    if (lowerText.contains("i'm having a") || lowerText.contains('i ate') || lowerText.contains('for dinner')) return 'meal_overview';
    return null;
  }

  DateTime? _lastPersistTime;

  void _flushChunkBuffer({String? imageUrl, String? source}) {
    if (_chunkBuffer.isEmpty) return;
    final aiLocalId = _activeAiLocalId;
    if (aiLocalId == null) {
      _chunkBuffer = '';
      return;
    }

    _fullAiText += _chunkBuffer;
    _chunkBuffer = '';

    final result = _processChatTagUseCase(_fullAiText, imageUrl: imageUrl, source: source, chatMessageId: aiLocalId, isFinal: false);

    var finalToDisplay = _applySafetyGuardrails(result.text);
    if (finalToDisplay.isEmpty && (result.scan != null || result.swaps.isNotEmpty)) {
      finalToDisplay = AppStrings.resultsFound;
    }

    final currentMsg = _historyNotifier.messages.firstWhere((m) => m.localId == aiLocalId);
    final updatedMsg = currentMsg.copyWith(
      text: finalToDisplay,
      scanData: result.scan,
      imageUrl: imageUrl,
      imageUrls: imageUrl != null ? [imageUrl] : null,
      mealLogs: result.meal != null ? [result.meal!] : const [],
      symptomLogs: result.symptoms,
      swapData: result.swaps,
      isSwap: result.swaps.isNotEmpty,
      analysisResult: result,
      foodMentions: [if (result.meal != null) ...result.meal!.items, if (result.scan != null) result.scan!.productName].whereType<String>().toList(),
      symptomMentions: result.symptoms.map((e) => e.symptom).toList(),
    );

    _historyNotifier.replaceMessage(aiLocalId, updatedMsg);

    // 🟢 UI PERSISTENCE: Periodically persist the MESSAGE during streaming.
    // Domain events (meals/symptoms) are now ATOMIC and only persist once
    // at the end in _finalizeStream to prevent partial/corrupt data.
    final now = DateTime.now();
    if (_lastPersistTime == null || now.difference(_lastPersistTime!).inSeconds >= 3) {
      _lastPersistTime = now;
      unawaited(_persistAiMessage(aiLocalId));
    }

    notifyListeners();
  }

  Future<void> _handleStreamError(Object error, String aiLocalId) async {
    _flushTimer?.cancel();

    final currentMsg = _historyNotifier.messages.firstWhere(
      (m) => m.localId == aiLocalId,
      orElse: () => ChatMessage(localId: '', role: '', text: '', createdAt: DateTime.now()),
    );
    if (currentMsg.localId.isEmpty) {
      _finishTurn();
      return;
    }

    if (_chunkBuffer.isNotEmpty || _fullAiText.isNotEmpty) {
      _fullAiText += _chunkBuffer;
      _chunkBuffer = '';
      final result = _processChatTagUseCase(_fullAiText, imageUrl: currentMsg.imageUrl, source: currentMsg.source, chatMessageId: aiLocalId, isFinal: true);
      final finalMsg = currentMsg.copyWith(
        text: _applySafetyGuardrails(result.text),
        scanData: result.scan,
        mealLogs: result.meal != null ? [result.meal!] : const [],
        symptomLogs: result.symptoms,
        swapData: result.swaps,
        isSwap: result.swaps.isNotEmpty,
        analysisResult: result,
        foodMentions: [if (result.meal != null) ...result.meal!.items, if (result.scan != null) result.scan!.productName].whereType<String>().toList(),
        symptomMentions: result.symptoms.map((e) => e.symptom).toList(),
      );
      _historyNotifier.replaceMessage(aiLocalId, finalMsg);

      // Persist any partial but valid results if we at least got the tags
      if (_persistTagsForActiveTurn) {
        final hydratedResult = await _persistAiResponseUseCase(result, chatMessageId: aiLocalId, imageUrl: currentMsg.imageUrl, source: currentMsg.source, persistedTagBlocks: _persistedTags);

        final updatedMsgWithIds = currentMsg.copyWith(scanData: hydratedResult.scan, mealLogs: hydratedResult.meal != null ? [hydratedResult.meal!] : null, symptomLogs: hydratedResult.symptoms);
        _historyNotifier.replaceMessage(aiLocalId, updatedMsgWithIds);
      }
    }

    final kind = error is AiQuotaExceededException ? ChatErrorKind.quota : ChatErrorKind.connection;

    final updatedMsg = _historyNotifier.messages.firstWhere((m) => m.localId == aiLocalId);
    if (updatedMsg.text.isNotEmpty && kind != ChatErrorKind.quota) {
      await _persistAiMessage(aiLocalId, errorKind: kind);
      _finishTurn();
      await _historyNotifier.precomputeSummary();
      return;
    }

    _historyNotifier.replaceMessage(aiLocalId, updatedMsg.copyWith(text: '', errorKind: kind));
    _finishTurn();
  }

  Future<void> _finalizeStream() async {
    _flushTimer?.cancel();
    final aiLocalId = _activeAiLocalId;
    if (aiLocalId == null) {
      _finishTurn();
      return;
    }

    final currentMsg = _historyNotifier.messages.firstWhere(
      (m) => m.localId == aiLocalId,
      orElse: () => ChatMessage(localId: '', role: '', text: '', createdAt: DateTime.now()),
    );
    if (currentMsg.localId.isEmpty) {
      _finishTurn();
      return;
    }

    _fullAiText += _chunkBuffer;
    _chunkBuffer = '';
    final result = _processChatTagUseCase(_fullAiText, imageUrl: currentMsg.imageUrl, source: currentMsg.source, chatMessageId: aiLocalId, isFinal: true);

    final finalMsg = currentMsg.copyWith(
      text: _applySafetyGuardrails(result.text),
      scanData: result.scan,
      mealLogs: result.meal != null ? [result.meal!] : const [],
      symptomLogs: result.symptoms,
      swapData: result.swaps,
      isSwap: result.swaps.isNotEmpty,
      analysisResult: result,
      foodMentions: [if (result.meal != null) ...result.meal!.items, if (result.scan != null) result.scan!.productName].whereType<String>().toList(),
      symptomMentions: result.symptoms.map((e) => e.symptom).toList(),
    );
    _historyNotifier.replaceMessage(aiLocalId, finalMsg);

    if (finalMsg.text.isEmpty && finalMsg.scanData == null) {
      _historyNotifier.replaceMessage(aiLocalId, finalMsg.copyWith(errorKind: _generationCancelled ? ChatErrorKind.none : ChatErrorKind.connection));
      if (_generationCancelled) _historyNotifier.removeMessage(aiLocalId);
      _finishTurn();
      return;
    }

    // 🟢 ATOMIC PERSISTENCE: Now that the AI turn is finished and validated,
    // persist all domain logs (meals, symptoms, scans) to history.
    var finalToPersist = finalMsg;
    if (_persistTagsForActiveTurn && !_generationCancelled) {
      final hydratedResult = await _persistAiResponseUseCase(result, chatMessageId: aiLocalId, imageUrl: currentMsg.imageUrl, source: currentMsg.source, persistedTagBlocks: _persistedTags);

      // Update final message with IDs (firestoreId) so they can be saved as references in chat_history
      finalToPersist = finalMsg.copyWith(
        scanData: hydratedResult.scan,
        mealLogs: hydratedResult.meal != null ? [hydratedResult.meal!] : null,
        symptomLogs: hydratedResult.symptoms,
        swapData: hydratedResult.swaps,
        analysisResult: hydratedResult,
      );
      _historyNotifier.replaceMessage(aiLocalId, finalToPersist);
    }

    await _persistAiMessage(aiLocalId);
    _finishTurn();
    await _historyNotifier.precomputeSummary();
  }

  Future<void> _persistAiMessage(String localId, {ChatErrorKind errorKind = ChatErrorKind.none}) async {
    try {
      final msg = _historyNotifier.messages.firstWhere((m) => m.localId == localId);
      final saved = await _repository.saveMessage(msg.copyWith(errorKind: errorKind));
      _historyNotifier.replaceMessage(localId, saved.copyWith(errorKind: errorKind));
    } catch (e) {
      AppLogger.ai('Saving AI response failed', error: e);
    }
  }

  String _applySafetyGuardrails(String text) {
    if (text.contains('Disclaimer:') || text.contains('**Disclaimer:**')) return text;

    const forbiddenWords = ['diagnose', 'cure', 'treat', 'prescription', 'medical condition', 'disease'];
    final lowerText = text.toLowerCase();

    var foundForbidden = false;
    for (final word in forbiddenWords) {
      if (lowerText.contains(word)) {
        foundForbidden = true;
        break;
      }
    }

    if (foundForbidden) {
      return '$text\n\n**Disclaimer:** I am an AI, not a doctor. This analysis identifies patterns in your reports for educational purposes and is not a medical diagnosis. Always consult a healthcare professional for medical advice.';
    }
    return text;
  }

  Future<void> handleSeeMoreSwaps(String prompt, int index) async {
    if (_isLoading) return;
    if (!_connectionChecker.isInternetAvailable.value) return;

    final userMsg = ChatMessage(localId: const Uuid().v4(), role: 'user', text: '${AppStrings.moreSwapsPrompt}$prompt', isSwap: false, isHidden: true, source: 'chat', createdAt: DateTime.now());
    final aiPlaceholder = ChatMessage(
      localId: const Uuid().v4(),
      role: 'ai',
      text: AppStrings.findingSwaps,
      isSwap: false,
      source: 'chat',
      createdAt: DateTime.now().add(const Duration(milliseconds: 1)),
    );

    _historyNotifier
      ..addOptimisticMessage(userMsg)
      ..addOptimisticMessage(aiPlaceholder);
    _isLoading = true;
    notifyListeners();

    await _analyticsService.logEvent(name: 'see_more_swaps_clicked', parameters: {'prompt': prompt});

    try {
      final savedMsg = await _repository.saveMessage(userMsg);
      _historyNotifier.replaceMessage(userMsg.localId, savedMsg);

      List<ProductSwap>? groundedSwaps;
      try {
        final alternatives = await _offService.getBetterAlternatives(null, null);
        if (alternatives.isNotEmpty) {
          groundedSwaps = alternatives
              .take(3)
              .map((p) => ProductSwap(title: p.productName, subtitle: p.brand ?? 'Better Alternative', tag: 'BETTER CHOICE', imageKeyword: p.productName, imageUrl: p.imageUrl, isBlackBadge: true))
              .toList();
        }
      } catch (e) {
        AppLogger.ai('Fetch alternatives failed', error: e);
      }

      final stream = _repository.sendMessageStream(
        systemInstruction: Prompts.chatSystemInstruction(
          userGoals: _historyNotifier.userGoals,
          userSensitivities: _historyNotifier.userSensitivities,
          userLifestyle: _historyNotifier.userLifestyle,
          cyclePhase: _historyNotifier.cyclePhase,
          communicationStyle: _historyNotifier.commStyle,
          historySummary: _historyNotifier.cachedSummary,
          currentTime: DateTime.now().toIso8601String(),
          mode: 'swaps',
          intent: 'meal_swaps',
        ),
        history: _buildHistory(),
        userText: groundedSwaps != null ? '${userMsg.text}\n\n(REAL PRODUCT DATA FOR SUGGESTIONS: ${groundedSwaps.map((s) => s.title).join(', ')})' : userMsg.text,
      );

      final aiLocalId = aiPlaceholder.localId;
      final fullTextBuffer = StringBuffer();
      final persistedTags = <String>{};

      await for (final chunk in stream) {
        fullTextBuffer.write(chunk);
        final result = _processChatTagUseCase(fullTextBuffer.toString(), source: 'chat', chatMessageId: aiLocalId, isFinal: false);

        var finalToDisplay = result.text;
        if (finalToDisplay.isEmpty && result.swaps.isNotEmpty) {
          finalToDisplay = AppStrings.hereAreSomeBetterSwaps;
        }

        final currentAi = _historyNotifier.messages.firstWhere((m) => m.localId == aiLocalId);
        _historyNotifier.replaceMessage(
          aiLocalId,
          currentAi.copyWith(
            text: finalToDisplay,
            scanData: result.scan,
            mealLogs: result.meal != null ? [result.meal!] : const [],
            symptomLogs: result.symptoms,
            swapData: result.swaps,
            isSwap: result.swaps.isNotEmpty,
            analysisResult: result,
            foodMentions: [if (result.meal != null) ...result.meal!.items, if (result.scan != null) result.scan!.productName].whereType<String>().toList(),
            symptomMentions: result.symptoms.map((e) => e.symptom).toList(),
          ),
        );
        notifyListeners();
      }

      // Atomic persistence for See More Swaps
      final finalResult = _processChatTagUseCase(fullTextBuffer.toString(), source: 'chat', chatMessageId: aiLocalId, isFinal: true);
      final hydratedResult = await _persistAiResponseUseCase(finalResult, chatMessageId: aiLocalId, source: 'chat', persistedTagBlocks: persistedTags);

      final finalAi = _historyNotifier.messages.firstWhere((m) => m.localId == aiLocalId);
      final updatedAi = finalAi.copyWith(
        scanData: hydratedResult.scan,
        mealLogs: hydratedResult.meal != null ? [hydratedResult.meal!] : null,
        symptomLogs: hydratedResult.symptoms,
        swapData: hydratedResult.swaps,
        analysisResult: hydratedResult,
      );
      _historyNotifier.replaceMessage(aiLocalId, updatedAi);

      final savedAi = await _repository.saveMessage(updatedAi);
      _historyNotifier.replaceMessage(aiLocalId, savedAi);
    } catch (e) {
      AppLogger.ai('See more swaps failed', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
      unawaited(_historyNotifier.precomputeSummary());
    }
  }
}
