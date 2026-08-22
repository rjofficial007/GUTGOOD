import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/chat_attachment.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
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
    required AiService aiService,
    required StorageService storageService,
    required OffService offService,
    required FirebaseAuth auth,
    required InternetConnectionChecker connectionChecker,
    required SendMessageStreamUseCase sendMessageStreamUseCase,
    required ProcessChatTagUseCase processChatTagUseCase,
    required AnalyticsService analyticsService,
    required AppStateService appStateService,
  }) : _repository = repository,
       _historyNotifier = historyNotifier,
       _aiService = aiService,
       _storageService = storageService,
       _offService = offService,
       _auth = auth,
       _connectionChecker = connectionChecker,
       _sendMessageStreamUseCase = sendMessageStreamUseCase,
       _processChatTagUseCase = processChatTagUseCase,
       _analyticsService = analyticsService,
       _appStateService = appStateService {
    _appStateService.sessionReset.addListener(_onSessionReset);
  }

  final ChatRepository _repository;
  final ChatHistoryNotifier _historyNotifier;
  final AiService _aiService;
  final StorageService _storageService;
  final OffService _offService;
  final FirebaseAuth _auth;
  final InternetConnectionChecker _connectionChecker;
  final SendMessageStreamUseCase _sendMessageStreamUseCase;
  final ProcessChatTagUseCase _processChatTagUseCase;
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
      time: DateTime.now(),
    );

    final aiPlaceholder = ChatMessage(localId: const Uuid().v4(), role: 'ai', text: '', isSwap: false, source: userMsg.source, time: DateTime.now().add(const Duration(milliseconds: 1)));

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
    await _streamReply(userText: aiText, images: sending.isEmpty ? null : _lastSentImages, imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null, source: userMsg.source);

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

    final placeholder = ChatMessage(localId: const Uuid().v4(), role: 'ai', text: '', isSwap: false, source: _lastSource, time: DateTime.now());
    _historyNotifier.addOptimisticMessage(placeholder);
    _activeAiLocalId = placeholder.localId;

    _generationCancelled = false;
    _isLoading = true;
    _isStreaming = false;
    notifyListeners();

    await _analyticsService.logEvent(name: 'message_regenerated', parameters: {'has_images': _lastSentImages.isNotEmpty});

    final aiText = _effectiveAiText(displayText: _lastUserText ?? '', hiddenContext: _lastHiddenContext, hasImages: _lastSentImages.isNotEmpty);
    await _streamReply(userText: aiText, images: _lastSentImages.isEmpty ? null : _lastSentImages, imageUrl: _lastSentImageUrl, source: _lastSource, isRegenerate: true);
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

  Future<void> _streamReply({required String userText, List<Uint8List>? images, String? imageUrl, String? source, bool isRegenerate = false}) async {
    final aiLocalId = _activeAiLocalId;
    if (aiLocalId == null) {
      _finishTurn();
      return;
    }

    _chunkBuffer = '';
    _fullAiText = '';
    _persistedTags.clear();
    _persistTagsForActiveTurn = !isRegenerate;

    final intent = (userText.trim().isEmpty && source != null) ? source : (await _detectIntent(userText, source: source)).trim().toLowerCase();

    AppLogger.ai('Final intent for prompt: "$intent" (source: "$source")');

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
      _handleStreamError(e, aiLocalId);
    }
  }

  Future<String> _detectIntent(String userText, {String? source}) async {
    final lowerText = userText.toLowerCase();

    final quickIntent = _getQuickIntent(lowerText);
    if (quickIntent != null) return quickIntent;

    try {
      final history = _buildHistory();
      final minimalHistory = history.length > 5 ? history.sublist(history.length - 5) : history;
      final historyContext = minimalHistory.map((m) => '${m.role.toUpperCase()}: ${m.text}').join('\n');

      final prompt =
          '''
CONVERSATION HISTORY:
$historyContext

USER MESSAGE:
$userText

CLASSIFY INTENT:
''';

      final intent = await _aiService.generateContent(prompt: prompt, systemInstruction: Prompts.intentDetectionInstruction, usageType: 'chat');
      return intent.trim().toLowerCase();
    } catch (e) {
      AppLogger.ai('AI intent detection failed', error: e);
      return _getQuickIntent(lowerText) ?? source ?? 'meal_overview';
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

    // 📸 Photo Prompt Matches (High Priority)
    if (lowerText.contains(AppStrings.menuPhotoPrompt.toLowerCase())) return 'menu';
    if (lowerText.contains(AppStrings.labelPhotoPrompt.toLowerCase())) return 'label';
    if (lowerText.contains(AppStrings.mealPhotoPrompt.toLowerCase())) return 'full_analysis';
    if (lowerText.contains(AppStrings.galleryPhotoPrompt.toLowerCase())) return 'gallery';

    // 🔍 Robust Regex Detection (Non-AI Fast-Path)
    // We use word boundaries (\b) to prevent accidental matches like 'comparison' triggering 'vs'
    if (RegExp(r'\b(rate|score|grade|how did I do|feedback)\b').hasMatch(lowerText)) return 'meal_rating';
    if (RegExp(r'\b(swap|instead|better|alternative|healthier|replace)\b').hasMatch(lowerText)) return 'meal_swaps';
    if (RegExp(r'\b(bloat|bloating|bloated|pain|hurt|headache|tired|gas|cramp|nausea)\b').hasMatch(lowerText)) return 'symptom_analysis';
    if (RegExp(r'\b(healthy|balanced|good for me|gut-friendly|gut friendly)\b').hasMatch(lowerText)) return 'health_assessment';
    if (RegExp(r'\b(full analysis|breakdown|everything|details|all info|complete)\b').hasMatch(lowerText)) return 'full_analysis';
    if (RegExp(r'\b(vs|versus|compare|difference between)\b').hasMatch(lowerText)) return 'product_comparison';
    if (RegExp(r'\b(plan|eat next|tomorrow|dinner idea|lunch idea|snack idea)\b').hasMatch(lowerText)) return 'meal_planning';
    if (RegExp(r'\b(menu|order|restaurant)\b').hasMatch(lowerText)) return 'menu';
    if (RegExp(r'\b(label|ingredient|gums|emulsifier|additive)\b').hasMatch(lowerText)) return 'label';

    // Casual meal mentions
    if (lowerText.contains("i'm having a") || lowerText.contains('i ate') || lowerText.contains('for dinner')) return 'meal_overview';
    return null;
  }

  void _flushChunkBuffer({String? imageUrl, String? source}) {
    if (_chunkBuffer.isEmpty) return;
    final aiLocalId = _activeAiLocalId;
    if (aiLocalId == null) {
      _chunkBuffer = '';
      return;
    }

    _fullAiText += _chunkBuffer;
    _chunkBuffer = '';

    final result = _processChatTagUseCase(_fullAiText, imageUrl: imageUrl, source: source, persistedTagBlocks: _persistedTags, persist: _persistTagsForActiveTurn, isFinal: false);

    var finalToDisplay = _applySafetyGuardrails(result.text);
    if (finalToDisplay.isEmpty && (result.scanData != null || (result.swapData != null && result.swapData!.isNotEmpty))) {
      finalToDisplay = AppStrings.resultsFound;
    }

    final currentMsg = _historyNotifier.messages.firstWhere((m) => m.localId == aiLocalId);
    _historyNotifier.replaceMessage(
      aiLocalId,
      currentMsg.copyWith(
        text: finalToDisplay,
        scanData: result.scanData,
        imageUrl: imageUrl,
        imageUrls: imageUrl != null ? [imageUrl] : null,
        swapData: result.swapData,
        isSwap: result.isSwap,
        foodMentions: result.foodMentions,
        symptomMentions: result.symptomMentions,
      ),
    );
    notifyListeners();
  }

  void _handleStreamError(Object error, String aiLocalId) {
    _flushTimer?.cancel();

    final currentMsg = _historyNotifier.messages.firstWhere(
      (m) => m.localId == aiLocalId,
      orElse: () => ChatMessage(localId: '', role: '', text: '', time: DateTime.now()),
    );
    if (currentMsg.localId.isEmpty) {
      _finishTurn();
      return;
    }

    if (_chunkBuffer.isNotEmpty || _fullAiText.isNotEmpty) {
      _fullAiText += _chunkBuffer;
      _chunkBuffer = '';
      final result = _processChatTagUseCase(
        _fullAiText,
        imageUrl: currentMsg.imageUrl,
        source: currentMsg.source,
        persistedTagBlocks: _persistedTags,
        persist: _persistTagsForActiveTurn,
        isFinal: true,
      );
      _historyNotifier.replaceMessage(aiLocalId, currentMsg.copyWith(text: _applySafetyGuardrails(result.text), scanData: result.scanData, swapData: result.swapData));
    }

    final kind = error is AiQuotaExceededException ? ChatErrorKind.quota : ChatErrorKind.connection;

    final updatedMsg = _historyNotifier.messages.firstWhere((m) => m.localId == aiLocalId);
    if (updatedMsg.text.isNotEmpty && kind != ChatErrorKind.quota) {
      _persistAiMessage(aiLocalId, errorKind: kind);
      _finishTurn();
      _historyNotifier.precomputeSummary();
      return;
    }

    _historyNotifier.replaceMessage(aiLocalId, updatedMsg.copyWith(text: '', errorKind: kind));
    _finishTurn();
  }

  void _finalizeStream() {
    _flushTimer?.cancel();
    final aiLocalId = _activeAiLocalId;
    if (aiLocalId == null) {
      _finishTurn();
      return;
    }

    final currentMsg = _historyNotifier.messages.firstWhere(
      (m) => m.localId == aiLocalId,
      orElse: () => ChatMessage(localId: '', role: '', text: '', time: DateTime.now()),
    );
    if (currentMsg.localId.isEmpty) {
      _finishTurn();
      return;
    }

    _fullAiText += _chunkBuffer;
    _chunkBuffer = '';
    final result = _processChatTagUseCase(_fullAiText, imageUrl: currentMsg.imageUrl, source: currentMsg.source, persistedTagBlocks: _persistedTags, persist: _persistTagsForActiveTurn, isFinal: true);

    final finalMsg = currentMsg.copyWith(text: _applySafetyGuardrails(result.text), scanData: result.scanData, swapData: result.swapData);
    _historyNotifier.replaceMessage(aiLocalId, finalMsg);

    if (finalMsg.text.isEmpty && finalMsg.scanData == null) {
      _historyNotifier.replaceMessage(aiLocalId, finalMsg.copyWith(errorKind: _generationCancelled ? ChatErrorKind.none : ChatErrorKind.connection));
      if (_generationCancelled) _historyNotifier.removeMessage(aiLocalId);
      _finishTurn();
      return;
    }

    _persistAiMessage(aiLocalId);
    _finishTurn();
    _historyNotifier.precomputeSummary();
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
    const forbiddenWords = ['diagnose', 'cure', 'treat', 'medical condition', 'disease', 'prescription'];
    final lowerText = text.toLowerCase();

    var foundForbidden = false;
    for (final word in forbiddenWords) {
      if (lowerText.contains(word)) {
        foundForbidden = true;
        break;
      }
    }

    if (foundForbidden && !text.contains('Disclaimer:')) {
      return '$text\n\n**Disclaimer:** I am an AI, not a doctor. This analysis identifies patterns in your reports and is for educational purposes only. Always consult a healthcare professional for medical advice.';
    }
    return text;
  }

  Future<void> handleSeeMoreSwaps(String prompt, int index) async {
    if (_isLoading) return;
    if (!_connectionChecker.isInternetAvailable.value) return;

    final userMsg = ChatMessage(localId: const Uuid().v4(), role: 'user', text: '${AppStrings.moreSwapsPrompt}$prompt', isSwap: false, isHidden: true, source: 'chat', time: DateTime.now());
    final aiPlaceholder = ChatMessage(localId: const Uuid().v4(), role: 'ai', text: AppStrings.findingSwaps, isSwap: false, source: 'chat', time: DateTime.now().add(const Duration(milliseconds: 1)));

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
        final result = _processChatTagUseCase(fullTextBuffer.toString(), source: 'chat', persistedTagBlocks: persistedTags);

        var finalToDisplay = result.text;
        if (finalToDisplay.isEmpty && result.swapData != null && result.swapData!.isNotEmpty) {
          finalToDisplay = AppStrings.hereAreSomeBetterSwaps;
        }

        final currentAi = _historyNotifier.messages.firstWhere((m) => m.localId == aiLocalId);
        _historyNotifier.replaceMessage(aiLocalId, currentAi.copyWith(text: finalToDisplay, swapData: result.swapData, isSwap: result.isSwap));
        notifyListeners();
      }

      final finalAi = _historyNotifier.messages.firstWhere((m) => m.localId == aiLocalId);
      final savedAi = await _repository.saveMessage(finalAi);
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
