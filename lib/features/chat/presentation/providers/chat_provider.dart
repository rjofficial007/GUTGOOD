import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/chat_attachment.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/internet_connection_checker.dart';
import 'package:gutgood/core/services/off_service.dart';
import 'package:gutgood/core/services/prompts.dart';
import 'package:gutgood/core/services/storage_service.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';
import 'package:gutgood/features/chat/domain/usecases/process_chat_tag_usecase.dart';
import 'package:gutgood/features/chat/domain/usecases/send_message_stream_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/app_state_service.dart';
import '../../../../core/services/firestore_service.dart';

/// Why a send attempt was rejected before any network traffic.
enum ChatSendError { offline, busy, empty, uploadFailed }

class ChatNotifier with ChangeNotifier {
  final ChatRepository _repository;
  final FirestoreService _firestoreService;
  final AiService _aiService;
  final StorageService _storageService;
  final OffService _offService;
  final SharedPreferences _prefs;
  final FirebaseAuth _auth;
  final InternetConnectionChecker _connectionChecker;
  final SendMessageStreamUseCase _sendMessageStreamUseCase;
  final ProcessChatTagUseCase _processChatTagUseCase;
  final AppStateService _appStateService;

  // ---- Message list state (newest first, matching the reversed list UI) ----
  final List<ChatMessage> _messages = [];

  /// localIds of messages created on-device that aren't confirmed in the
  /// Firestore snapshot yet — the core of the race-free optimistic merge.
  final Set<String> _optimisticIds = {};

  bool _isLoading = false; // busy: uploading and/or streaming
  bool _isStreaming = false; // tokens actively arriving
  bool _historyLoading = true;
  final int _pageSize = 50;

  // ---- Composer attachments (ChatGPT model: preview first, send later) ----
  final List<ChatAttachment> _attachments = [];
  static const int maxAttachments = 4;

  // ---- Personalization context ----
  List<String> _userGoals = [];
  List<String> _userSensitivities = [];
  List<String> _userLifestyle = [];
  String _commStyle = AppStrings.friendlySupportive;
  String _cyclePhase = AppStrings.notSpecified;
  bool _cycleSyncEnabled = false;

  // ---- Summarized long-term memory ----
  String? _cachedSummary;
  String? _summarizedThroughMessageId;
  bool _isSummarizing = false;

  // ---- Streaming machinery ----
  StreamSubscription<String>? _aiSubscription;
  StreamSubscription<List<ChatMessage>>? _chatStreamSub;
  Timer? _flushTimer;
  String _chunkBuffer = '';
  String _fullAiText = '';
  String? _activeAiLocalId;
  bool _generationCancelled = false;
  final Set<String> _persistedTags = {};

  /// False while regenerating: the original response already persisted its
  /// [MEAL]/[SYMPTOM] tags, so the replacement response must not re-log them.
  bool _persistTagsForActiveTurn = true;

  // ---- Last request (powers regenerate) ----
  bool _hasLastRequest = false;
  String? _lastUserText;
  String? _lastHiddenContext;
  String? _lastSource;
  List<Uint8List> _lastSentImages = const [];
  String? _lastSentImageUrl;

  ChatNotifier({
    required ChatRepository repository,
    required FirestoreService firestoreService,
    required AiService aiService,
    required StorageService storageService,
    required OffService offService,
    required SharedPreferences prefs,
    required FirebaseAuth auth,
    required InternetConnectionChecker connectionChecker,
    required SendMessageStreamUseCase sendMessageStreamUseCase,
    required ProcessChatTagUseCase processChatTagUseCase,
    required AppStateService appStateService,
  }) : _repository = repository,
       _firestoreService = firestoreService,
       _aiService = aiService,
       _storageService = storageService,
       _offService = offService,
       _prefs = prefs,
       _auth = auth,
       _connectionChecker = connectionChecker,
       _sendMessageStreamUseCase = sendMessageStreamUseCase,
       _processChatTagUseCase = processChatTagUseCase,
       _appStateService = appStateService {
    _initChatStream();
    _appStateService.profileUpdated.addListener(_onProfileUpdated);
    _appStateService.sessionReset.addListener(_onSessionReset);

    // 🟢 Reactive Data Loading: Restart stream whenever auth state changes
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _initChatStream();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------
  List<ChatMessage> get messages => _messages;
  List<ChatAttachment> get pendingAttachments => List.unmodifiable(_attachments);
  bool get isLoading => _isLoading;
  bool get isStreaming => _isStreaming;
  bool get historyLoading => _historyLoading;
  bool get canRegenerate => !_isLoading && _hasLastRequest;
  bool get isOffline => !_connectionChecker.isInternetAvailable.value;

  @override
  void dispose() {
    _flushTimer?.cancel();
    _aiSubscription?.cancel();
    _chatStreamSub?.cancel();
    _appStateService.profileUpdated.removeListener(_onProfileUpdated);
    _appStateService.sessionReset.removeListener(_onSessionReset);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Firestore stream: race-free optimistic merge
  // ---------------------------------------------------------------------------
  void _initChatStream() {
    _chatStreamSub?.cancel();
    _historyLoading = true;
    notifyListeners();

    _chatStreamSub = _firestoreService
        .getMessagesStream(limit: _pageSize)
        .listen(
          (serverMessages) {
            final serverLocalIds = serverMessages.map((m) => m.localId).toSet();

            // Keep optimistic messages the server hasn't confirmed yet.
            final pending = _messages.where((m) => _optimisticIds.contains(m.localId) && !serverLocalIds.contains(m.localId)).toList();

            _messages
              ..clear()
              ..addAll(pending)
              ..addAll(serverMessages);

            // Confirmed messages no longer need optimistic protection.
            _optimisticIds.removeAll(serverMessages.map((m) => m.localId).toSet());

            if (_messages.isEmpty && !_isLoading) {
              _createInitialGreeting();
            }

            _historyLoading = false;
            notifyListeners();
            _loadProfileData();
          },
          onError: (e) {
            Log.e('ChatNotifier: Message stream error', error: e);
            _historyLoading = false;
            notifyListeners();
          },
        );
  }

  /// Re-subscribes the message stream (e.g. after an account upgrade).
  void refreshHistory() => _initChatStream();

  Future<void> _createInitialGreeting() async {
    final initialMsg = ChatMessage(localId: const Uuid().v4(), role: 'ai', text: AppStrings.chatInitialGreeting, isSwap: false, time: DateTime.now());
    await _firestoreService.saveMessage(initialMsg);
  }

  void _onProfileUpdated() => _loadProfileData();

  void _onSessionReset() {
    _flushTimer?.cancel();
    _aiSubscription?.cancel();
    _messages.clear();
    _optimisticIds.clear();
    _attachments.clear();
    _cachedSummary = null;
    _summarizedThroughMessageId = null;
    _hasLastRequest = false;
    _lastUserText = null;
    _lastHiddenContext = null;
    _lastSentImages = const [];
    _lastSentImageUrl = null;
    _isLoading = false;
    _isStreaming = false;
    _chatStreamSub?.cancel();
    notifyListeners();
  }

  Future<void> _loadProfileData() async {
    final profile = await _firestoreService.getUserMetadata();

    if (profile != null) {
      _userGoals = profile.goals;
      _userSensitivities = profile.sensitivities;
      _userLifestyle = profile.lifestyle;
      _cycleSyncEnabled = profile.cycleSyncEnabled;
      _cyclePhase = _cycleSyncEnabled ? (profile.cyclePhase ?? _defaultCyclePhase) : AppStrings.notSpecified;
    } else {
      _userGoals = _prefs.getStringList('user_goals') ?? [];
      _userSensitivities = _prefs.getStringList('user_sensitivities') ?? [];
      _userLifestyle = _prefs.getStringList('user_lifestyle') ?? [];
      _cycleSyncEnabled = _prefs.getBool('cycle_sync_enabled') ?? false;
      _cyclePhase = _cycleSyncEnabled ? (_prefs.getString('cycle_phase') ?? _defaultCyclePhase) : AppStrings.notSpecified;
    }

    _commStyle = _prefs.getString('ai_comm_style') ?? AppStrings.friendlySupportive;
  }

  String get _defaultCyclePhase => AppStrings.phaseLuteal;

  // ---------------------------------------------------------------------------
  // Attachments (ChatGPT composer model: preview first, send explicitly)
  // ---------------------------------------------------------------------------

  /// Adds raw image bytes as a pending attachment. Compressed up-front so the
  /// preview, the upload, and the vision request all use the same payload.
  Future<bool> addAttachment(Uint8List bytes, {String source = 'gallery'}) async {
    if (_isLoading) return false;
    if (_attachments.length >= maxAttachments) return false;
    final compressed = await _storageService.compressImage(bytes);
    _attachments.add(ChatAttachment(id: const Uuid().v4(), bytes: compressed, source: source));
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

  // ---------------------------------------------------------------------------
  // Sending
  // ---------------------------------------------------------------------------

  /// Unified ChatGPT-style send: the typed prompt AND all attached images
  /// leave together in a single AI request. Image-only turns (no visible
  /// text) are allowed — the analysis instruction acts as the prompt.
  ///
  /// [hiddenContext] is appended to the AI-bound prompt only (never displayed
  /// or persisted) — used to steer menu/label/vision analysis without putting
  /// machine instructions into the user's visible message.
  Future<ChatSendError?> send({String text = '', String? hiddenContext, String? source}) async {
    if (_isLoading) return ChatSendError.busy;

    final String displayText = text.trim();
    final List<ChatAttachment> sending = List.of(_attachments);

    if (displayText.isEmpty && sending.isEmpty) return ChatSendError.empty;
    if (!_connectionChecker.isInternetAvailable.value) return ChatSendError.offline;

    // Freeze the request for regenerate BEFORE clearing local state.
    _hasLastRequest = true;
    _lastUserText = displayText;
    _lastHiddenContext = hiddenContext;
    _lastSource = source;
    _lastSentImages = sending.map((a) => a.bytes).toList(growable: false);
    _lastSentImageUrl = null;

    _attachments.clear();
    _generationCancelled = false;

    final userMsg = ChatMessage(
      localId: const Uuid().v4(),
      role: 'user',
      text: displayText,
      localImages: sending.isEmpty ? null : _lastSentImages,
      isSending: sending.isNotEmpty,
      isSwap: false,
      source: source ?? (sending.isNotEmpty ? sending.first.source : 'chat'),
      time: DateTime.now(),
    );

    final aiPlaceholder = ChatMessage(localId: const Uuid().v4(), role: 'ai', text: '', isSwap: false, source: userMsg.source, time: DateTime.now().add(const Duration(milliseconds: 1)));

    _optimisticIds.add(userMsg.localId);
    _optimisticIds.add(aiPlaceholder.localId);
    _messages.insert(0, userMsg);
    _messages.insert(0, aiPlaceholder);
    _activeAiLocalId = aiPlaceholder.localId;

    _isLoading = true;
    _isStreaming = false;
    notifyListeners();

    // 1. Upload attachments (needs an auth session for storage paths).
    List<String> imageUrls = const [];
    if (sending.isNotEmpty) {
      if (_auth.currentUser == null) {
        _markUserMessageFailed(userMsg.localId);
        _removeMessage(aiPlaceholder.localId);
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
        Log.e('ChatNotifier: Image upload failed', error: e);
        _markUserMessageFailed(userMsg.localId);
        _removeMessage(aiPlaceholder.localId);
        _finishTurn();
        return ChatSendError.uploadFailed;
      }

      final uploaded = userMsg.copyWith(imageUrls: imageUrls, isSending: false, clearLocalImages: false);
      _lastSentImageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;
      _replaceMessage(userMsg.localId, uploaded);

      // 2. Persist the user turn (offline-tolerant: Firestore queues writes).
      final saved = await _repository.saveMessage(uploaded);
      _replaceMessage(uploaded.localId, saved.copyWith(clearLocalImages: true));
    } else {
      final saved = await _repository.saveMessage(userMsg);
      _replaceMessage(userMsg.localId, saved);
    }

    // 3. Stream the assistant reply. Usage accounting happens server-side.
    final aiText = _effectiveAiText(displayText: displayText, hiddenContext: hiddenContext, hasImages: sending.isNotEmpty);
    await _streamReply(userText: aiText, images: sending.isEmpty ? null : _lastSentImages, imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null, source: userMsg.source);

    return null;
  }

  /// Text sent to the AI for a user turn. Visible text wins when present;
  /// image-only turns fall back to the analysis instruction so the model
  /// knows what to do with the photo (ChatGPT behaves the same way).
  String _effectiveAiText({required String displayText, String? hiddenContext, required bool hasImages}) {
    if (displayText.isNotEmpty) {
      return hiddenContext != null && hiddenContext.isNotEmpty ? '$displayText\n\n$hiddenContext' : displayText;
    }
    return hiddenContext ?? AppStrings.imageUploadInstruction;
  }

  /// Re-runs the last user turn with a fresh assistant response (ChatGPT's
  /// "regenerate"). The previous assistant message is replaced.
  Future<void> regenerateLastResponse() async {
    if (_isLoading || !_hasLastRequest) return;
    if (!_connectionChecker.isInternetAvailable.value) return;

    // Remove the trailing assistant message (error, stopped, or completed).
    if (_messages.isNotEmpty && _messages.first.role == 'ai') {
      final old = _messages.first;
      _messages.removeAt(0);
      _optimisticIds.remove(old.localId);
      if (old.firestoreId != null) {
        await _repository.deleteMessage(old);
      }
    }

    final placeholder = ChatMessage(localId: const Uuid().v4(), role: 'ai', text: '', isSwap: false, source: _lastSource, time: DateTime.now());
    _optimisticIds.add(placeholder.localId);
    _messages.insert(0, placeholder);
    _activeAiLocalId = placeholder.localId;

    _generationCancelled = false;
    _isLoading = true;
    _isStreaming = false;
    notifyListeners();

    final aiText = _effectiveAiText(displayText: _lastUserText ?? '', hiddenContext: _lastHiddenContext, hasImages: _lastSentImages.isNotEmpty);
    await _streamReply(userText: aiText, images: _lastSentImages.isEmpty ? null : _lastSentImages, imageUrl: _lastSentImageUrl, source: _lastSource, isRegenerate: true);
  }

  /// Retries a user message whose attachments failed to upload.
  Future<ChatSendError?> retryMessage(ChatMessage failedMessage) async {
    if (_isLoading) return ChatSendError.busy;
    if (!failedMessage.sendFailed) return null;

    _removeMessage(failedMessage.localId);
    if (failedMessage.firestoreId != null) {
      await _repository.deleteMessage(failedMessage);
    }

    final images = failedMessage.localImages ?? const <Uint8List>[];
    for (final bytes in images) {
      await addAttachment(bytes, source: failedMessage.source ?? 'gallery');
    }

    return send(text: failedMessage.text, source: failedMessage.source);
  }

  /// ChatGPT's stop button: cancels the stream and keeps the partial reply.
  void stopGeneration() {
    if (!_isLoading) return;
    _generationCancelled = true;
    _aiSubscription?.cancel();
    _finalizeStream();
  }

  // ---------------------------------------------------------------------------
  // Streaming internals
  // ---------------------------------------------------------------------------
  int _indexOfLocalId(String localId) => _messages.indexWhere((m) => m.localId == localId);

  void _replaceMessage(String localId, ChatMessage next) {
    final idx = _indexOfLocalId(localId);
    if (idx != -1) _messages[idx] = next;
  }

  void _removeMessage(String localId) {
    _messages.removeWhere((m) => m.localId == localId);
    _optimisticIds.remove(localId);
  }

  void _markUserMessageFailed(String localId) {
    final idx = _indexOfLocalId(localId);
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(isSending: false, sendFailed: true);
      notifyListeners();
    }
  }

  void _finishTurn() {
    _isLoading = false;
    _isStreaming = false;
    _activeAiLocalId = null;
    notifyListeners();
  }

  List<ChatMessage> _buildHistory() {
    // Ascending (oldest → newest), excluding the in-flight user turn (passed
    // separately as userText) and the current AI placeholder.
    final all = _messages.reversed.toList();
    final activeId = _activeAiLocalId;

    final filtered = all.where((m) {
      if (m.localId == activeId) return false;
      if (m.sendFailed) return false;
      if (m.role == 'ai' && m.text.isEmpty && m.scanData == null) return false; // stray placeholders
      if (m.role == 'ai' && m.errorKind == ChatErrorKind.quota) return false;
      return m.text.isNotEmpty || m.scanData != null;
    }).toList();

    var chronological = filtered.map((m) {
      if (m.text.isEmpty && m.scanData != null) {
        return m.copyWith(text: 'I scanned ${m.scanData!.productName}.');
      }
      return m;
    }).toList();

    // Drop the trailing user message if it is exactly the one being sent.
    if (chronological.isNotEmpty && chronological.last.role == 'user' && chronological.last.text == _lastUserText) {
      chronological = chronological.sublist(0, chronological.length - 1);
    }

    const int maxContextMessages = 10;
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

    await _aiSubscription?.cancel();

    // Throttled UI flush: markdown re-parsing per TOKEN caused frame jank.
    // Coalesce to 16 updates/sec — imperceptible to the eye, huge for jank.
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(milliseconds: 60), (_) => _flushChunkBuffer(imageUrl: imageUrl, source: source));

    try {
      final stream = _sendMessageStreamUseCase(
        systemInstruction: Prompts.chatSystemInstruction(
          userGoals: _userGoals,
          userSensitivities: _userSensitivities,
          userLifestyle: _userLifestyle,
          cyclePhase: _cyclePhase,
          communicationStyle: _commStyle,
          historySummary: _cachedSummary,
        ),
        history: _buildHistory(),
        userText: userText,
        images: images,
      );

      bool hapticTriggered = false;

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
          Log.e('ChatNotifier: AI stream error', error: e);
          _handleStreamError(e, aiLocalId);
        },
        onDone: () {
          if (_generationCancelled) return; // stopGeneration already finalized
          _finalizeStream();
        },
        cancelOnError: false,
      );
    } catch (e, st) {
      Log.e('ChatNotifier: Stream setup failed', error: e, stackTrace: st);
      _handleStreamError(e, aiLocalId);
    }
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

    final idx = _indexOfLocalId(aiLocalId);
    if (idx == -1) return;

    final result = _processChatTagUseCase(_fullAiText, imageUrl: imageUrl, source: source, persistedTagBlocks: _persistedTags, persist: _persistTagsForActiveTurn);

    _messages[idx] = _messages[idx].copyWith(
      text: _applySafetyGuardrails(result.text),
      scanData: result.scanData,
      imageUrl: imageUrl,
      imageUrls: imageUrl != null ? [imageUrl] : null,
      swapData: result.swapData,
      isSwap: result.isSwap,
      foodMentions: result.foodMentions,
      symptomMentions: result.symptomMentions,
    );
    notifyListeners();
  }

  void _handleStreamError(Object error, String aiLocalId) {
    _flushTimer?.cancel();

    final idx = _indexOfLocalId(aiLocalId);
    if (idx == -1) {
      _finishTurn();
      return;
    }

    // Flush whatever arrived before the failure.
    if (_chunkBuffer.isNotEmpty) {
      _flushChunkBuffer(imageUrl: _messages[idx].imageUrl, source: _messages[idx].source);
    }

    final kind = error is AiQuotaExceededException ? ChatErrorKind.quota : ChatErrorKind.connection;

    // If we already have partial content, keep it (ChatGPT behavior) and flag
    // the turn so Retry/Regenerate is offered — but still persist the partial.
    if (_messages[idx].text.isNotEmpty && kind != ChatErrorKind.quota) {
      _persistAiMessage(idx, errorKind: kind);
      _finishTurn();
      _precomputeSummary();
      return;
    }

    _messages[idx] = _messages[idx].copyWith(text: '', errorKind: kind);
    _finishTurn();
  }

  void _finalizeStream() {
    _flushTimer?.cancel();

    final aiLocalId = _activeAiLocalId;
    if (aiLocalId == null) {
      _finishTurn();
      return;
    }

    final idx = _indexOfLocalId(aiLocalId);
    if (idx == -1) {
      _finishTurn();
      return;
    }

    _flushChunkBuffer(imageUrl: _messages[idx].imageUrl, source: _messages[idx].source);

    if (_messages[idx].text.isEmpty && _messages[idx].scanData == null) {
      // Never persist an empty assistant bubble.
      _messages[idx] = _messages[idx].copyWith(errorKind: _generationCancelled ? ChatErrorKind.none : ChatErrorKind.connection);
      if (_generationCancelled) _removeMessage(aiLocalId);
      _finishTurn();
      return;
    }

    _persistAiMessage(idx);
    _finishTurn();
    _precomputeSummary();
  }

  Future<void> _persistAiMessage(int index, {ChatErrorKind errorKind = ChatErrorKind.none}) async {
    final aiLocalId = _messages[index].localId;
    try {
      final saved = await _repository.saveMessage(_messages[index].copyWith(errorKind: errorKind));
      final currentIndex = _indexOfLocalId(aiLocalId);
      if (currentIndex != -1) {
        _messages[currentIndex] = saved.copyWith(errorKind: errorKind);
      }
    } catch (e) {
      Log.e('ChatNotifier: Saving AI response failed', error: e);
    }
  }

  String _applySafetyGuardrails(String text) {
    const forbiddenWords = ['diagnose', 'cure', 'treat', 'medical condition', 'disease', 'prescription'];
    final lowerText = text.toLowerCase();

    bool foundForbidden = false;
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

  Future<void> _precomputeSummary() async {
    if (_isSummarizing || _messages.length <= 6) return;
    _isSummarizing = true;

    try {
      const int maxContextMessages = 6;
      final chronological = _messages.reversed.where((m) => m.text.isNotEmpty).toList();
      if (chronological.length <= maxContextMessages) return;

      final agedOut = chronological.sublist(0, chronological.length - maxContextMessages);

      final newlyAgedOut = _summarizedThroughMessageId == null
          ? agedOut
          : agedOut.skipWhile((m) => m.firestoreId?.toString() != _summarizedThroughMessageId && m.localId != _summarizedThroughMessageId).toList();

      if (newlyAgedOut.isEmpty) return;

      Log.d('ChatNotifier: Summarizing ${newlyAgedOut.length} messages.');
      _cachedSummary = await _aiService.summarizeHistory(newlyAgedOut, previousSummary: _cachedSummary);
      final last = agedOut.last;
      _summarizedThroughMessageId = last.firestoreId?.toString() ?? last.localId;
    } catch (e, st) {
      Log.e('ChatNotifier: Summary failed', error: e, stackTrace: st);
    } finally {
      _isSummarizing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Feedback & swaps
  // ---------------------------------------------------------------------------
  Future<void> handleFeedback(ChatMessage msg, String type) async {
    final index = _messages.indexOf(msg);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(feedback: type);
      notifyListeners();
    }

    await _repository.updateMessageFeedback(msg, type);
  }

  Future<void> handleSeeMoreSwaps(String prompt, int index) async {
    if (_isLoading) return;
    if (!_connectionChecker.isInternetAvailable.value) return;

    final userMsg = ChatMessage(localId: const Uuid().v4(), role: 'user', text: '${AppStrings.moreSwapsPrompt}$prompt', isSwap: false, source: 'chat', time: DateTime.now());

    final aiPlaceholder = ChatMessage(localId: const Uuid().v4(), role: 'ai', text: AppStrings.findingSwaps, isSwap: false, source: 'chat', time: DateTime.now().add(const Duration(milliseconds: 1)));

    _optimisticIds.add(userMsg.localId);
    _optimisticIds.add(aiPlaceholder.localId);
    _messages.insert(0, userMsg);
    _messages.insert(0, aiPlaceholder);

    _isLoading = true;
    notifyListeners();

    try {
      final savedMsg = await _repository.saveMessage(userMsg);
      _replaceMessage(userMsg.localId, savedMsg);

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
        Log.e('ChatNotifier: Fetch alternatives failed', error: e);
      }

      final stream = _repository.sendMessageStream(
        systemInstruction: Prompts.chatSystemInstruction(
          userGoals: _userGoals,
          userSensitivities: _userSensitivities,
          userLifestyle: _userLifestyle,
          cyclePhase: _cyclePhase,
          communicationStyle: _commStyle,
          historySummary: _cachedSummary,
        ),
        history: _buildHistory(),
        userText: groundedSwaps != null ? '${userMsg.text}\n\n(REAL PRODUCT DATA FOR SUGGESTIONS: ${groundedSwaps.map((s) => s.title).join(', ')})' : userMsg.text,
      );

      final aiLocalId = aiPlaceholder.localId;
      String fullText = '';
      final Set<String> persistedTags = {};

      await for (final chunk in stream) {
        fullText += chunk;

        final idx = _indexOfLocalId(aiLocalId);
        if (idx == -1) break;

        final result = _processChatTagUseCase(fullText, source: 'chat', persistedTagBlocks: persistedTags);
        _messages[idx] = _messages[idx].copyWith(text: result.text, swapData: result.swapData, isSwap: result.isSwap);
        notifyListeners();
      }

      final idx = _indexOfLocalId(aiLocalId);
      if (idx != -1) {
        final savedAi = await _repository.saveMessage(_messages[idx]);
        _replaceMessage(aiLocalId, savedAi);
      }
    } catch (e) {
      Log.e('ChatNotifier: See more swaps failed', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
      _precomputeSummary();
    }
  }
}
