import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/ai_constants.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/chat_attachment.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/food_image.dart';
import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/services/ai_classifier_service.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore/food_image_firestore_service.dart';
import 'package:gutgood/core/services/internet_connection_checker.dart';
import 'package:gutgood/core/services/off_service.dart';
import 'package:gutgood/core/services/prompts.dart';
import 'package:gutgood/core/services/storage_service.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';
import 'package:gutgood/core/utils/image_hash.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/chat/data/services/chat_outbox_service.dart';
import 'package:gutgood/features/chat/data/services/image_upload_outbox.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';
import 'package:gutgood/features/chat/domain/usecases/persist_ai_response_usecase.dart';
import 'package:gutgood/features/chat/domain/usecases/process_chat_tag_usecase.dart';
import 'package:gutgood/features/chat/domain/usecases/send_message_stream_usecase.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_history_notifier.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:uuid/uuid.dart';

/// [ChatSendError.queued] is not a failure: the text was accepted into the
/// offline outbox and will auto-send on reconnect. The UI treats it like a
/// send (clears the composer) but ends the turn immediately — nothing streams.
enum ChatSendError { offline, busy, empty, uploadFailed, queued }

/// Formats entity names salvaged from windowed-out messages (K-4): scan
/// products, mentioned foods, mentioned symptoms. Capped per bucket so pins
/// stay a fixed small cost no matter how long the conversation grows.
/// Returns null when there is nothing worth pinning.
String? buildPinnedEntities(List<ChatMessage> dropped) {
  const maxFoods = 8;
  const maxSymptoms = 6;
  const maxScans = 6;

  final foods = <String>[];
  final symptoms = <String>[];
  final scans = <String>[];
  final seen = <String>{};

  void add(List<String> bucket, int cap, String raw) {
    final name = raw.trim();
    if (name.isEmpty || bucket.length >= cap) return;
    if (seen.add(name.toLowerCase())) bucket.add(name);
  }

  for (final m in dropped) {
    for (final f in m.foodMentions) {
      add(foods, maxFoods, f);
    }
    for (final meal in m.mealLogs) {
      for (final item in meal.items) {
        add(foods, maxFoods, item);
      }
    }
    for (final s in m.symptomMentions) {
      add(symptoms, maxSymptoms, s);
    }
    final product = m.scanData?.productName;
    if (product != null) add(scans, maxScans, product);
  }

  if (foods.isEmpty && symptoms.isEmpty && scans.isEmpty) return null;
  final lines = <String>[];
  if (foods.isNotEmpty) lines.add('foods: ${foods.join(', ')}');
  if (symptoms.isNotEmpty) lines.add('symptoms: ${symptoms.join(', ')}');
  if (scans.isNotEmpty) lines.add('scans: ${scans.join(', ')}');
  return lines.join('\n');
}

/// P2-11: grounding fragment appended to the "see more swaps" prompt. Names +
/// grades + barcodes, with an echo instruction so the model's swap objects
/// round-trip the grounding ([ProductSwap.fromMap] tolerates their absence,
/// so LLM-invented swaps without them still parse).
@visibleForTesting
String swapsGroundingFragment(String userText, List<ProductSwap> grounded) {
  final items = grounded.map((s) {
    final grade = (s.nutriscore == null || s.nutriscore!.isEmpty) ? '?' : s.nutriscore!;
    final code = (s.barcode == null || s.barcode!.isEmpty) ? '?' : s.barcode!;
    return '${s.title} (grade $grade, barcode $code)';
  }).join('; ');
  return '$userText\n\n(REAL PRODUCT DATA — emit exactly 3 swap objects, one per product below, and copy each "barcode" and "nutriscore" value into its swap object: $items)';
}

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
    required ChatOutboxService outboxService,
    required ImageUploadOutbox uploadOutbox,
    required FoodImageService foodImages,
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
       _appStateService = appStateService,
       _outbox = outboxService,
       _uploadOutbox = uploadOutbox,
       _foodImages = foodImages {
    _appStateService.sessionReset.addListener(_onSessionReset);
    _connectivityWasOnline = _connectionChecker.isInternetAvailable.value;
    _connectionChecker.isInternetAvailable.addListener(_onConnectivityChanged);
    _rehydrateOutbox();
    if (_connectivityWasOnline && _outbox.pending.isNotEmpty) {
      AppLogger.ai('ChatComposer: flushing ${_outbox.pending.length} queued message(s) from a previous session');
      unawaited(flushOutbox());
    }
    if (_connectivityWasOnline) {
      unawaited(flushUploads());
    }
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
  final ChatOutboxService _outbox;
  final ImageUploadOutbox _uploadOutbox;
  final FoodImageService _foodImages;

  bool _isLoading = false;
  bool _isStreaming = false;
  bool _flushing = false;
  bool _flushingUploads = false;
  bool _connectivityWasOnline = true;
  final List<ChatAttachment> _attachments = [];

  String? _activeAiLocalId;
  StreamSubscription<String>? _aiSubscription;
  Timer? _flushTimer;
  String _chunkBuffer = '';
  String _fullAiText = '';
  bool _generationCancelled = false;
  final Set<String> _persistedTags = {};
  bool _persistTagsForActiveTurn = true;
  String? _findUserTextForAiMessage(String aiLocalId) {
    final messages = _historyNotifier.messages;
    final index = messages.indexWhere((m) => m.localId == aiLocalId);
    if (index == -1) return null;
    for (var i = index + 1; i < messages.length; i++) {
      if (messages[i].role == 'user') {
        return messages[i].text;
      }
    }
    return null;
  }

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
  String? get pendingHiddenContext => _pendingHiddenContext;

  @override
  void dispose() {
    _flushTimer?.cancel();
    _aiSubscription?.cancel();
    _appStateService.sessionReset.removeListener(_onSessionReset);
    _connectionChecker.isInternetAvailable.removeListener(_onConnectivityChanged);
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
    // Queued texts belong to the old session — drop them (and their bubbles)
    // rather than sending one account's words as another.
    for (final entry in _outbox.pending) {
      _historyNotifier.removeMessage(entry.id);
    }
    unawaited(_outbox.clear());
    unawaited(_uploadOutbox.clear());
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
    // Vision input, not a Storage thumbnail: the AI needs legible text for
    // labels/menus, so this uses compressForAi() (~1280 px) instead of the
    // ~320 px profile that compressImage() was written for.
    final compressed = await _storageService.compressForAi(bytes);
    _attachments.add(ChatAttachment(id: const Uuid().v4(), bytes: compressed, source: source));
    await _analyticsService.logEvent(name: 'attachment_added', parameters: {'source': source});
    notifyListeners();
    return true;
  }

  void removeAttachment(String id) {
    _attachments.removeWhere((a) => a.id == id);
    notifyListeners();
  }


  Future<ChatSendError?> send({String text = '', String? hiddenContext, String? source, String? providedUserMsgId}) async {
    if (_isLoading) return ChatSendError.busy;

    final displayText = text.trim();
    final sending = List<ChatAttachment>.of(_attachments);

    if (displayText.isEmpty && sending.isEmpty) return ChatSendError.empty;
    if (!_connectionChecker.isInternetAvailable.value) {
      // Text-only turns queue for auto-send on reconnect. Image turns stay
      // online-only: bytes never enter the prefs outbox, so the draft
      // (text + attachments) is kept for a manual retry instead.
      if (sending.isNotEmpty) return ChatSendError.offline;
      await _enqueueOffline(displayText, hiddenContext: hiddenContext, source: source, providedId: providedUserMsgId);
      return ChatSendError.queued;
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

    final aiText = _effectiveAiText(displayText: displayText, hiddenContext: hiddenContext, hasImages: sending.isNotEmpty);

    // 🚀 Latency Optimization: Start classification and message saving in parallel.
    // We also prepare the classification future early to avoid sequential blocking.
    final classificationFuture = sending.isNotEmpty
        ? _aiClassifierService.classifyImage(imageBytes: sending.first.bytes, userText: displayText, modeHint: sending.first.source)
        : (displayText.isNotEmpty
              ? _aiClassifierService
                    .classifyTextIntent(userText: displayText, historySummary: _historyNotifier.cachedSummary)
                    .then((intent) => AiClassificationResult(imageMode: 'UNKNOWN', intent: intent, confidence: 1.0))
              : Future.value(const AiClassificationResult(imageMode: 'UNKNOWN', intent: 'COMPLETE_ANALYSIS', confidence: 1.0)));

    String? detectedMode;
    String? detectedIntent;

    if (sending.isNotEmpty) {
      if (_auth.currentUser == null) {
        _historyNotifier
          ..replaceMessage(userMsg.localId, userMsg.copyWith(isSending: false, sendFailed: true))
          ..removeMessage(aiPlaceholder.localId);
        _finishTurn();
        return ChatSendError.uploadFailed;
      }

      // P1-3a: the Storage upload must not gate the AI turn. Classify now
      // (fast, shapes the prompt; defaults on failure), save the user message
      // immediately so the turn is durable, stream from in-memory bytes, and
      // hydrate Storage URLs as a background patch. A failed upload degrades
      // to local-only bytes instead of killing a turn the AI could complete.
      try {
        final classification = await classificationFuture;
        detectedMode = classification.imageMode;
        detectedIntent = classification.intent;
        AppLogger.ai('ChatComposer: AI classified image as $detectedMode with intent $detectedIntent');
      } catch (e) {
        AppLogger.warning('ChatComposer: image classification failed, continuing with defaults. Error: $e');
      }

      final saved = await _repository.saveMessage(userMsg);
      _historyNotifier.replaceMessage(userMsg.localId, saved);

      unawaited(_uploadAndHydrate(sending, userMsg.localId));
    } else {
      try {
        // Parallelize message saving and classification
        final results = await Future.wait([_repository.saveMessage(userMsg), classificationFuture]);

        final saved = results[0] as ChatMessage;
        _historyNotifier.replaceMessage(userMsg.localId, saved);

        final classification = results[1] as AiClassificationResult;
        detectedIntent = classification.intent;
        AppLogger.ai('ChatComposer: AI detected text intent as $detectedIntent');
      } catch (e) {
        AppLogger.warning('ChatComposer: text-turn setup failed, falling back to defaults. Error: $e');
      }
    }

    await _streamReply(
      userText: aiText,
      images: sending.isEmpty ? null : _lastSentImages,
      // Always null here now: the URL arrives via _uploadAndHydrate, which
      // patches the AI message best-effort when the upload wins the race.
      imageUrl: null,
      source: detectedMode ?? userMsg.source,
      detectedIntent: detectedIntent,
    );

    return null;
  }

  /// Immediate upload attempt with outbox fallback (P1-3a + pass C). Never
  /// throws: failures persist to the disk-backed queue and resolve via
  /// [flushUploads] — same turn, reconnect, or next app start. The turn
  /// itself always proceeds on local bytes.
  Future<void> _uploadAndHydrate(List<ChatAttachment> sending, String userLocalId) async {
    final byIndex = <int, RecoveredUpload>{};
    for (var i = 0; i < sending.length; i++) {
      try {
        final url = await _uploadOutbox.uploadOrEnqueue(bytes: sending[i].bytes, chatLocalId: userLocalId, index: i);
        if (url != null) byIndex[i] = RecoveredUpload(url: url, hash: _hashFor(url, sending[i].bytes));
      } catch (e) {
        AppLogger.warning('ChatComposer: upload attempt failed; queued for retry. Error: $e');
      }
    }
    if (byIndex.isEmpty) {
      AppLogger.warning('ChatComposer: all image uploads queued; turn continues on local bytes');
      return; // isSending stays true until flushUploads settles the queue
    }
    _lastSentImageUrl = byIndex.values.first.url;
    await _applyRecovery(userLocalId, byIndex);
  }

  /// Registry identity for an uploaded URL. Canonical URLs always encode it;
  /// the bytes-hash fallback only serves mocked/test storage shapes.
  String _hashFor(String url, Uint8List bytes) => imageHashFromFoodUrl(url) ?? imageHash(bytes);

  /// Retries queued uploads; silent background work — failures simply stay
  /// queued. Skipped while offline so attempts aren't burned on a dead radio.
  Future<void> flushUploads() async {
    if (_flushingUploads || _uploadOutbox.isEmpty) return;
    if (!_connectionChecker.isInternetAvailable.value) return;
    _flushingUploads = true;
    try {
      await _uploadOutbox.flush(onRecovered: _applyRecovery);
    } finally {
      _flushingUploads = false;
    }
  }

  /// Merges [uploadsByIndex] into the message, persists the URL/hash pair,
  /// and links each photo to this message in the registry. Clears local
  /// state once nothing for this message is still queued. Falls back to a
  /// direct Firestore patch when the message isn't in memory (restart case).
  Future<void> _applyRecovery(String chatLocalId, Map<int, RecoveredUpload> uploadsByIndex) async {
    if (uploadsByIndex.isEmpty && _uploadOutbox.pendingFor(chatLocalId).isNotEmpty) return;
    final current = _findMessage(chatLocalId);
    final urlsByIndex = uploadsByIndex.map((i, u) => MapEntry(i, u.url));
    final hashesByIndex = uploadsByIndex.map((i, u) => MapEntry(i, u.hash));
    final merged = _mergeIndexed(current?.imageUrls ?? const <String>[], urlsByIndex, '');
    final mergedHashes = _mergeIndexed(current?.imageHashes ?? const <String>[], hashesByIndex, '');
    if (current == null) {
      // Restart case: patch the Firestore doc directly (doc id == localId).
      // Multi-image restart recovery is last-wins per flush — acceptable:
      // the UI caps attachments at one per turn.
      await _repository.patchMessageImageUrls(localId: chatLocalId, imageUrls: merged.where((u) => u.isNotEmpty).toList());
      await _repository.patchMessageImageHashes(localId: chatLocalId, imageHashes: mergedHashes.where((h) => h.isNotEmpty).toList());
      for (final hash in mergedHashes) {
        if (hash.isNotEmpty) await _foodImages.addLink(hash: hash, kind: FoodImageLinks.kindChat, id: chatLocalId);
      }
      return;
    }
    try {
      final done = _uploadOutbox.pendingFor(chatLocalId).isEmpty;
      final saved = await _repository.saveMessage(current.copyWith(imageUrls: merged, imageHashes: mergedHashes, isSending: !done));
      // Keep local bytes only when there is nothing remote to show (poison /
      // purged entries): the photo stays visible session-locally.
      _historyNotifier.replaceMessage(chatLocalId, merged.any((u) => u.isNotEmpty) ? saved.copyWith(clearLocalImages: true) : saved);

      final docId = saved.firestoreId ?? chatLocalId;
      for (final hash in mergedHashes) {
        if (hash.isNotEmpty) await _foodImages.addLink(hash: hash, kind: FoodImageLinks.kindChat, id: docId);
      }

      String? firstUrl;
      String? firstHash;
      for (var i = 0; i < merged.length; i++) {
        if (merged[i].isNotEmpty) {
          firstUrl = merged[i];
          firstHash = i < mergedHashes.length ? mergedHashes[i] : null;
          break;
        }
      }
      final aiLocalId = _activeAiLocalId;
      if (aiLocalId != null && firstUrl != null) {
        final url = firstUrl;
        final aiMsg = _findMessage(aiLocalId);
        if (aiMsg != null && aiMsg.imageUrl == null) {
          _historyNotifier.replaceMessage(aiLocalId, aiMsg.copyWith(imageUrl: url, imageUrls: [url], imageHashes: firstHash == null ? null : [firstHash]));
        }
      }
    } catch (e) {
      AppLogger.warning('ChatComposer: URL hydration save failed. Error: $e');
    }
  }

  /// Index-aligned merge that tolerates gaps (fill placeholders survive
  /// until their flush fills them; the bubble shows local bytes while any
  /// exist).
  List<T> _mergeIndexed<T>(List<T> existing, Map<int, T> byIndex, T fill) {
    final merged = List<T>.from(existing);
    for (final entry in byIndex.entries) {
      while (merged.length <= entry.key) {
        merged.add(fill);
      }
      merged[entry.key] = entry.value;
    }
    return merged;
  }

  ChatMessage? _findMessage(String localId) {
    for (final m in _historyNotifier.messages) {
      if (m.localId == localId) return m;
    }
    return null;
  }

  String _effectiveAiText({required String displayText, String? hiddenContext, required bool hasImages}) {
    if (displayText.isNotEmpty) {
      return hiddenContext != null && hiddenContext.isNotEmpty ? '$displayText\n\n$hiddenContext' : displayText;
    }
    return hiddenContext ?? 'Analyze this image for gut health.';
  }

  /// Returns [ChatSendError.offline] when refused for connectivity so the UI
  /// can say so — previously a retry tap while offline silently did nothing.
  Future<ChatSendError?> regenerateLastResponse() async {
    if (_isLoading || !_hasLastRequest) return null;
    if (!_connectionChecker.isInternetAvailable.value) return ChatSendError.offline;

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
        final classification = await _aiClassifierService.classifyImage(imageBytes: _lastSentImages.first, userText: _lastUserText, modeHint: _lastSource);
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
    return null;
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

  // ===========================================================================
  // OFFLINE OUTBOX — text-only queue, auto-flushed FIFO on reconnect.
  // ===========================================================================

  /// Sends queued messages oldest-first. Safe to call any time: no-ops while
  /// a flush is already running or a turn is in flight (the [_finishTurn]
  /// hook re-triggers it). Entries dequeue only after a fully successful
  /// turn; failed attempts roll back onto the same message so nothing is
  /// lost or duplicated.
  Future<ChatSendError?> flushOutbox() async {
    if (_flushing || _isLoading) return null;
    if (!_connectionChecker.isInternetAvailable.value) return ChatSendError.offline;
    if (_outbox.isEmpty) return null;
    _flushing = true;
    try {
      while (_outbox.pending.isNotEmpty) {
        if (!_connectionChecker.isInternetAvailable.value || _isLoading) return null;
        final ok = await _attemptQueued(_outbox.pending.first);
        if (!ok) return null; // rolled back; stays queued for a later trigger
      }
      return null;
    } finally {
      _flushing = false;
    }
  }

  /// Sends one queued entry under its stable chat id. Returns true only when
  /// the turn fully succeeded (entry dequeued).
  Future<bool> _attemptQueued(QueuedMessage entry) async {
    try {
      // Stale entry: a previous attempt already completed under this id
      // (e.g. after an idle-timeout stop) — drop it, don't resend.
      final existing = _findMessage(entry.id);
      if (existing != null && !existing.isQueued) {
        await _outbox.dequeue(entry.id);
        return true;
      }
      if (existing != null) _historyNotifier.removeMessage(entry.id);

      final error = await send(text: entry.text, hiddenContext: entry.hiddenContext, source: entry.source, providedUserMsgId: entry.id);
      if (error != null) {
        _restoreQueued(entry);
        return false;
      }
      final aiLocalId = _activeAiLocalId;
      if (aiLocalId == null || !await _waitForIdle()) {
        // Turn still running past the timeout: leave the attempt live and
        // stop — the stale check above prevents a duplicate on retry.
        return false;
      }
      final aiMsg = _findMessage(aiLocalId);
      if (aiMsg == null || aiMsg.errorKind != ChatErrorKind.none || (aiMsg.text.isEmpty && aiMsg.scanData == null && aiMsg.swapData == null)) {
        await _rollbackAttempt(entry, aiLocalId);
        return false;
      }
      await _outbox.dequeue(entry.id);
      return true;
    } catch (e) {
      AppLogger.warning('ChatComposer: queued attempt failed, kept in outbox. Error: $e');
      _restoreQueued(entry);
      return false;
    }
  }

  /// Deletes a failed attempt (user + AI messages, plus any partial logs
  /// linked to them) and re-parks the entry as a queued bubble.
  Future<void> _rollbackAttempt(QueuedMessage entry, String aiLocalId) async {
    final userAttempt = _findMessage(entry.id);
    if (userAttempt != null) await _historyNotifier.deleteMessage(userAttempt);
    final aiAttempt = _findMessage(aiLocalId);
    if (aiAttempt != null) await _historyNotifier.deleteMessage(aiAttempt);
    _restoreQueued(entry);
    AppLogger.ai('ChatComposer: queued attempt rolled back, kept in outbox');
  }

  Future<void> _enqueueOffline(String text, {String? hiddenContext, String? source, String? providedId}) async {
    // The entry IS the chat message id: the UI's scroll anchor and the
    // flush attempt both reuse it, so no duplicates can form.
    final entry = QueuedMessage(id: providedId ?? const Uuid().v4(), text: text, hiddenContext: hiddenContext, source: source ?? 'chat', createdAt: DateTime.now());
    await _outbox.enqueue(entry);
    _restoreQueued(entry);
    AppLogger.ai('ChatComposer: queued offline message (${_outbox.pending.length} pending)');
  }

  void _restoreQueued(QueuedMessage entry) {
    if (_findMessage(entry.id) != null) return;
    _historyNotifier.addOptimisticMessage(ChatMessage(localId: entry.id, role: 'user', text: entry.text, isSwap: false, isQueued: true, source: entry.source, createdAt: entry.createdAt));
  }

  void _rehydrateOutbox() {
    for (final entry in _outbox.pending) {
      _restoreQueued(entry);
    }
  }

  void _onConnectivityChanged() {
    final online = _connectionChecker.isInternetAvailable.value;
    final restored = online && !_connectivityWasOnline;
    _connectivityWasOnline = online;
    if (restored && _outbox.pending.isNotEmpty) {
      AppLogger.ai('ChatComposer: connection restored, flushing ${_outbox.pending.length} queued message(s)');
      unawaited(flushOutbox());
    }
    if (restored) {
      unawaited(flushUploads());
    }
  }

  /// Waits for the in-flight turn to finish. False on timeout — the caller
  /// must leave the attempt alone (it may still complete).
  Future<bool> _waitForIdle() async {
    final stopAt = DateTime.now().add(const Duration(minutes: 10));
    while (_isLoading) {
      if (DateTime.now().isAfter(stopAt)) {
        AppLogger.warning('ChatComposer: flush idle-wait timed out; attempt left live');
        return false;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return true;
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

    // A completed turn may unblock queued messages (e.g. a busy-interrupted
    // flush, or quota that has since reset). Reentrancy-guarded inside.
    if (_outbox.pending.isNotEmpty && _connectionChecker.isInternetAvailable.value) {
      unawaited(flushOutbox());
    }
    // Same for uploads that failed mid-turn on a transient blip.
    if (_connectionChecker.isInternetAvailable.value) {
      unawaited(flushUploads());
    }
  }

  /// Full turns in the model context (K-4/P2-2: cut from 25). What falls out
  /// is covered by the rolling summary (narrative) + pinned entities (nouns).
  static const int _maxContextMessages = 12;

  /// Chronological, sendable messages before windowing. Shared by
  /// [_buildHistory] (keeps the tail) and [_pinnedEntities] (mines the head).
  List<ChatMessage> _contextCandidates() {
    final all = _historyNotifier.messages.reversed.toList();
    final activeId = _activeAiLocalId;

    return all.where((m) {
      if (m.localId == activeId) return false;
      if (m.sendFailed) return false;
      if (m.role == 'ai' && m.text.isEmpty && m.scanData == null) return false;
      if (m.role == 'ai' && m.errorKind == ChatErrorKind.quota) return false;
      return m.text.isNotEmpty || m.scanData != null;
    }).toList();
  }

  List<ChatMessage> _buildHistory() {
    var chronological = _contextCandidates().map((m) {
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

    if (chronological.length > _maxContextMessages) {
      chronological = chronological.sublist(chronological.length - _maxContextMessages);
    }
    return chronological;
  }

  /// Entity names from messages outside the context window, or null when the
  /// whole conversation fits (or the dropped prefix names nothing).
  String? _pinnedEntities() {
    final candidates = _contextCandidates();
    if (candidates.length <= _maxContextMessages) return null;
    return buildPinnedEntities(candidates.sublist(0, candidates.length - _maxContextMessages));
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

    // 🚀 PRD §10: Unified AI-driven routing.
    final intent = detectedIntent ?? source ?? 'full_analysis';

    AppLogger.ai('Final intent for prompt: "$intent" (detected: "$detectedIntent", source: "$source")');

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
          pinnedEntities: _pinnedEntities(),
          currentTime: DateTime.now().toIso8601String(),
          mode: source,
          intent: intent,
        ),
        history: _buildHistory(),
        userText: userText,
        images: images,
        intent: intent,
        promptVersion: AiVersions.chatPromptVersion,
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

    final userText = _findUserTextForAiMessage(aiLocalId);
    final result = _processChatTagUseCase(_fullAiText, userText: userText, imageUrl: imageUrl, source: source, chatMessageId: aiLocalId, isFinal: false, promptVersion: AiVersions.chatPromptVersion, servedModel: null);

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
      final userText = _findUserTextForAiMessage(aiLocalId);
      final result = _processChatTagUseCase(_fullAiText, userText: userText, imageUrl: currentMsg.imageUrl, source: currentMsg.source, chatMessageId: aiLocalId, isFinal: true, promptVersion: AiVersions.chatPromptVersion, servedModel: null);
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
    final userText = _findUserTextForAiMessage(aiLocalId);
    final result = _processChatTagUseCase(_fullAiText, userText: userText, imageUrl: currentMsg.imageUrl, source: currentMsg.source, chatMessageId: aiLocalId, isFinal: true, promptVersion: _repository.lastPromptVersion ?? AiVersions.chatPromptVersion, servedModel: _repository.lastServedModel);

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
      wasTruncated: _repository.lastResponseTruncated,
      promptVersion: _repository.lastPromptVersion ?? AiVersions.chatPromptVersion,
      model: _repository.lastServedModel,
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

  /// Returns [ChatSendError.offline] when refused for connectivity (same
  /// silent-tap fix as [regenerateLastResponse]).
  Future<ChatSendError?> handleSeeMoreSwaps(String prompt, ScanResult? scan) async {
    if (_isLoading) return null;
    if (!_connectionChecker.isInternetAvailable.value) return ChatSendError.offline;

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

      // P2-11: ground "see more" in real OFF alternatives. The OFF category
      // tag isn't stored on ScanResult, so resolve it via the cached product
      // fetch (barcode → categoryTag); the 30-min OFF memo makes this ~free
      // right after a scan. Any failure (or no barcode) degrades to the
      // previous LLM-only behavior.
      List<ProductSwap>? groundedSwaps;
      final barcode = scan?.barcode;
      if (barcode != null && barcode.isNotEmpty) {
        try {
          final product = await _offService.getProduct(barcode);
          final category = product?.categoryTag;
          if (category != null && category.isNotEmpty) {
            final alternatives = await _offService.getBetterAlternatives(category, scan?.nutriscore ?? product?.nutriscore);
            if (alternatives.isNotEmpty) {
              groundedSwaps = alternatives.take(3).map((p) => p.toSwap()).toList();
            }
          }
        } catch (e) {
          AppLogger.ai('Fetch alternatives failed', error: e);
        }
      }

      final stream = _repository.sendMessageStream(
        systemInstruction: Prompts.chatSystemInstruction(
          userGoals: _historyNotifier.userGoals,
          userSensitivities: _historyNotifier.userSensitivities,
          userLifestyle: _historyNotifier.userLifestyle,
          cyclePhase: _historyNotifier.cyclePhase,
          communicationStyle: _historyNotifier.commStyle,
          historySummary: _historyNotifier.cachedSummary,
          pinnedEntities: _pinnedEntities(),
          currentTime: DateTime.now().toIso8601String(),
          mode: 'swaps',
          intent: 'meal_swaps',
        ),
        history: _buildHistory(),
        userText: groundedSwaps != null ? swapsGroundingFragment(userMsg.text, groundedSwaps) : userMsg.text,
        intent: 'meal_swaps',
        promptVersion: AiVersions.chatPromptVersion,
      );

      final aiLocalId = aiPlaceholder.localId;
      final fullTextBuffer = StringBuffer();
      final persistedTags = <String>{};

      await for (final chunk in stream) {
        fullTextBuffer.write(chunk);
        final result = _processChatTagUseCase(fullTextBuffer.toString(), userText: userMsg.text, source: 'chat', chatMessageId: aiLocalId, isFinal: false, promptVersion: AiVersions.chatPromptVersion, servedModel: null, fallbackSwaps: groundedSwaps ?? const []);

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

      // J-4/P3-4: capture the echo flags NOW — the persist await below could
      // let a concurrent AI call's reset interleave before the stamping copyWith.
      final wasTruncated = _repository.lastResponseTruncated;
      final promptVersion = _repository.lastPromptVersion ?? AiVersions.chatPromptVersion;
      final servedModel = _repository.lastServedModel;

      // Atomic persistence for See More Swaps
      final finalResult = _processChatTagUseCase(fullTextBuffer.toString(), userText: userMsg.text, source: 'chat', chatMessageId: aiLocalId, isFinal: true, promptVersion: promptVersion, servedModel: servedModel, fallbackSwaps: groundedSwaps ?? const []);
      final hydratedResult = await _persistAiResponseUseCase(finalResult, chatMessageId: aiLocalId, source: 'chat', persistedTagBlocks: persistedTags);

      final finalAi = _historyNotifier.messages.firstWhere((m) => m.localId == aiLocalId);
      final updatedAi = finalAi.copyWith(
        scanData: hydratedResult.scan,
        mealLogs: hydratedResult.meal != null ? [hydratedResult.meal!] : null,
        symptomLogs: hydratedResult.symptoms,
        swapData: hydratedResult.swaps,
        analysisResult: hydratedResult,
        wasTruncated: wasTruncated,
        promptVersion: promptVersion,
        model: servedModel,
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
    return null;
  }
}
