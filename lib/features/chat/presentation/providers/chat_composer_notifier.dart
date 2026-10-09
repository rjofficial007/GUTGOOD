import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/ai/classification/ai_classifier_service.dart';
import 'package:gutgood/core/ai/client/ai_exceptions.dart';
import 'package:gutgood/core/ai/prompts/prompt_catalog.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';
import 'package:gutgood/core/utils/image_hash.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/model_utils.dart';
import 'package:gutgood/features/chat/application/usecases/persist_ai_response_usecase.dart';
import 'package:gutgood/features/chat/data/services/chat_outbox_service.dart';
import 'package:gutgood/features/chat/data/services/image_upload_outbox.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';
import 'package:gutgood/features/chat/domain/services/chat_prompt_context.dart';
import 'package:gutgood/features/chat/domain/services/chat_safety_guardrails.dart';
import 'package:gutgood/features/chat/domain/usecases/process_chat_tag_usecase.dart';
import 'package:gutgood/features/chat/domain/usecases/send_message_stream_usecase.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_history_notifier.dart';
import 'package:gutgood/infrastructure/firebase/analytics_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/food_image_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/storage_service.dart';
import 'package:gutgood/infrastructure/open_food_facts/off_service.dart';
import 'package:gutgood/infrastructure/platform/internet_connection_checker.dart';
import 'package:uuid/uuid.dart';

part 'chat_composer_attachments.dart';
part 'chat_composer_send.dart';
part 'chat_composer_uploads.dart';
part 'chat_composer_regeneration.dart';
part 'chat_composer_outbox.dart';
part 'chat_composer_context.dart';
part 'chat_composer_stream.dart';
part 'chat_composer_swaps.dart';

/// [ChatSendError.queued] is not a failure: the text was accepted into the
/// offline outbox and will auto-send on reconnect. The UI treats it like a
/// send (clears the composer) but ends the turn immediately — nothing streams.
enum ChatSendError { offline, busy, empty, uploadFailed, queued, failed }

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
    VoidCallback? onTurnCompleted,
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
       _foodImages = foodImages,
       _onTurnCompleted = onTurnCompleted {
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
  final VoidCallback? _onTurnCompleted;

  bool _isLoading = false;
  bool _isStreaming = false;
  bool _flushing = false;
  bool _flushingUploads = false;
  bool _connectivityWasOnline = true;
  final List<ChatAttachment> _attachments = [];

  String? _activeAiLocalId;
  String? _loadingSwapsMessageId;
  StreamSubscription<String>? _aiSubscription;
  Timer? _flushTimer;
  DateTime? _lastPersistTime;
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

  String? _findUserImageUrlForAiMessage(String aiLocalId) {
    final messages = _historyNotifier.messages;
    final index = messages.indexWhere((m) => m.localId == aiLocalId);
    if (index == -1) return null;
    for (var i = index + 1; i < messages.length; i++) {
      final message = messages[i];
      if (message.role != 'user') continue;
      for (final url in message.imageUrls) {
        if (url.trim().isNotEmpty) return url;
      }
      final imageUrl = message.imageUrl?.trim();
      if (imageUrl?.isNotEmpty == true) return imageUrl;
      return null;
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
  String? get loadingSwapsMessageId => _loadingSwapsMessageId;
  bool get canRegenerate => !_isLoading && _hasLastRequest;
  String? get pendingHiddenContext => _pendingHiddenContext;

  // Parts are extensions, so they delegate through this class method rather
  // than reaching ChangeNotifier's protected API directly.
  void _notifyStateChanged() => notifyListeners();

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
    _loadingSwapsMessageId = null;
    // Queued texts belong to the old session — drop them (and their bubbles)
    // rather than sending one account's words as another.
    for (final entry in _outbox.pending) {
      _historyNotifier.removeMessage(entry.id);
    }
    unawaited(_outbox.clear());
    unawaited(_uploadOutbox.clear());
    notifyListeners();
  }
}
