import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/ai/client/ai_client.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/constants/storage_keys.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/auth/data/services/usage_service.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/chat_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ChatHistoryNotifier with ChangeNotifier {
  ChatHistoryNotifier({
    required ChatRepository repository,
    required ChatFirestoreService chatFirestoreService,
    required AuthFirestoreService authFirestoreService,
    required HistoryFirestoreService historyFirestoreService,
    required AiClient aiService,
    required AppStateService appStateService,
    required SharedPreferences prefs,
    required FirebaseAuth auth,
    required UsageService usageService,
  }) : _repository = repository,
       _chatFirestoreService = chatFirestoreService,
       _authFirestoreService = authFirestoreService,
       _historyFirestoreService = historyFirestoreService,
       _aiService = aiService,
       _appStateService = appStateService,
       _prefs = prefs,
       _auth = auth,
       _usageService = usageService {
    _initChatStream();
    _appStateService.chatUpdated.addListener(refreshHistory);
    _appStateService.profileUpdated.addListener(_onProfileUpdated);
    _appStateService.sessionReset.addListener(clearHistory);

    _authSub = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _initChatStream();
      } else {
        clearHistory();
      }
    });
  }

  final ChatRepository _repository;
  final ChatFirestoreService _chatFirestoreService;
  final AuthFirestoreService _authFirestoreService;
  final HistoryFirestoreService _historyFirestoreService;
  final AiClient _aiService;
  final AppStateService _appStateService;
  final SharedPreferences _prefs;
  final FirebaseAuth _auth;
  final UsageService _usageService;

  final List<ChatMessage> _streamedMessages = [];
  final List<ChatMessage> _paginatedMessages = [];
  final Set<String> _optimisticIds = {};

  bool _historyLoading = true;
  bool _isPaginationLoading = false;
  bool _hasMoreMessages = true;
  static const int _pageSize = 30;

  // Personalization context
  List<String> _userGoals = [];
  List<String> _userSensitivities = [];
  List<String> _userLifestyle = [];
  String _commStyle = AppStrings.friendlySupportive;
  String _cyclePhase = AppStrings.notSpecified;
  bool _cycleSyncEnabled = false;

  // Summarization
  String? _cachedSummary;
  String? _summarizedThroughMessageId;
  bool _isSummarizing = false;

  StreamSubscription<List<ChatMessage>>? _chatStreamSub;
  StreamSubscription<User?>? _authSub;

  List<ChatMessage> get messages {
    final combined = <ChatMessage>[..._streamedMessages, ..._paginatedMessages];
    // Deduplicate by localId just in case
    final seen = <String>{};
    return combined.where((m) => seen.add(m.localId)).toList();
  }

  bool get historyLoading => _historyLoading;
  String? get cachedSummary => _cachedSummary;

  // Context getters for Composer
  List<String> get userGoals => _userGoals;
  List<String> get userSensitivities => _userSensitivities;
  List<String> get userLifestyle => _userLifestyle;
  String get commStyle => _commStyle;
  String get cyclePhase => _cyclePhase;

  @override
  void dispose() {
    _chatStreamSub?.cancel();
    _authSub?.cancel();
    _appStateService.profileUpdated.removeListener(_onProfileUpdated);
    _appStateService.sessionReset.removeListener(clearHistory);
    super.dispose();
  }

  void _initChatStream() {
    _chatStreamSub?.cancel();
    if (!_isPaginationLoading && _streamedMessages.isEmpty) {
      _historyLoading = true;
    }
    notifyListeners();

    _chatStreamSub = _chatFirestoreService
        .getMessagesStream(limit: _pageSize)
        .listen(
          (serverMessages) {
            final serverLocalIds = serverMessages.map((m) => m.localId).toSet();

            // Keep optimistic messages the server hasn't confirmed yet.
            final pending = _streamedMessages.where((m) => _optimisticIds.contains(m.localId) && !serverLocalIds.contains(m.localId)).toList();

            // Image turns: the server echo lands ~instantly after save, long
            // before the Storage upload hydrates imageUrls. Without this the
            // echo wipes the in-memory bytes and the photo drops out of the
            // bubble for the whole upload. Carry local-only state across
            // until remote URLs exist (upload hydration clears it then).
            final inMemory = <String, ChatMessage>{for (final m in _streamedMessages) m.localId: m};
            final merged = serverMessages.map((srv) {
              final existing = inMemory[srv.localId];
              if (existing != null && existing.localImages?.isNotEmpty == true && srv.imageUrls.isEmpty) {
                return srv.copyWith(localImages: existing.localImages, isSending: existing.isSending);
              }
              return srv;
            }).toList();

            _streamedMessages
              ..clear()
              ..addAll(pending)
              ..addAll(merged);

            _optimisticIds.removeAll(serverLocalIds);

            final wasLoading = _historyLoading;
            _historyLoading = false;

            if (messages.isEmpty && wasLoading && !_isPaginationLoading) {
              unawaited(_createInitialGreeting());
            }

            notifyListeners();
            unawaited(_loadProfileData());
          },
          onError: (e) {
            AppLogger.ai('Message stream error', error: e);
            final wasLoading = _historyLoading;
            _historyLoading = false;

            if (messages.isEmpty && wasLoading && !_isPaginationLoading) {
              unawaited(_createInitialGreeting());
            }
            notifyListeners();
          },
        );
  }

  void refreshHistory() => _initChatStream();

  Future<void> loadMore() async {
    if (_isPaginationLoading || !_hasMoreMessages) return;

    final all = messages;
    if (all.isEmpty) return;

    _isPaginationLoading = true;
    notifyListeners();

    try {
      final lastMessage = all.last;
      final older = await _repository.getOlderMessages(limit: _pageSize, before: lastMessage.createdAt);

      if (older.length < _pageSize) {
        _hasMoreMessages = false;
      }

      if (older.isNotEmpty) {
        _paginatedMessages.addAll(older);
      }
    } catch (e) {
      AppLogger.ai('Pagination failed', error: e);
    } finally {
      _isPaginationLoading = false;
      notifyListeners();
    }
  }

  Future<void> _createInitialGreeting() async {
    AppLogger.ai('Creating initial chat greeting.');
    final initialMsg = ChatMessage(localId: const Uuid().v4(), role: 'ai', text: AppStrings.chatInitialGreeting, isSwap: false, createdAt: DateTime.now());

    _streamedMessages.add(initialMsg);
    _optimisticIds.add(initialMsg.localId);
    notifyListeners();

    await _chatFirestoreService.saveMessage(initialMsg);
  }

  void _onProfileUpdated() => unawaited(_loadProfileData());

  void clearHistory() {
    _streamedMessages.clear();
    _paginatedMessages.clear();
    _optimisticIds.clear();
    _cachedSummary = null;
    _summarizedThroughMessageId = null;
    _historyLoading = false;
    _hasMoreMessages = true;
    _chatStreamSub?.cancel();
    notifyListeners();
  }

  Future<void> _loadProfileData() async {
    final profile = await _authFirestoreService.getUserMetadata();

    if (profile != null) {
      _userGoals = profile.goals;
      _userSensitivities = profile.sensitivities;
      _userLifestyle = profile.lifestyle;
      _cycleSyncEnabled = profile.cycleSyncEnabled;
      final cp = profile.cyclePhase;
      _cyclePhase = _cycleSyncEnabled ? (cp ?? AppStrings.phaseLuteal) : AppStrings.notSpecified;
      _cachedSummary = profile.chatSummary;
    } else {
      _userGoals = _prefs.getStringList(StorageKeys.userGoals) ?? [];
      _userSensitivities = _prefs.getStringList(StorageKeys.userSensitivities) ?? [];
      _userLifestyle = _prefs.getStringList(StorageKeys.userLifestyle) ?? [];
      _cycleSyncEnabled = _prefs.getBool(StorageKeys.cycleSyncEnabled) ?? false;
      final cp = _prefs.getString(StorageKeys.cyclePhase);
      _cyclePhase = _cycleSyncEnabled ? (cp ?? AppStrings.phaseLuteal) : AppStrings.notSpecified;
    }

    _commStyle = _prefs.getString(StorageKeys.aiCommStyle) ?? AppStrings.friendlySupportive;
  }

  // Optimistic UI methods
  void addOptimisticMessage(ChatMessage msg) {
    _optimisticIds.add(msg.localId);
    _streamedMessages.insert(0, msg);
    notifyListeners();
  }

  void removeMessage(String localId) {
    _streamedMessages.removeWhere((m) => m.localId == localId);
    _paginatedMessages.removeWhere((m) => m.localId == localId);
    _optimisticIds.remove(localId);
    notifyListeners();
  }

  void replaceMessage(String localId, ChatMessage next) {
    final sIdx = _streamedMessages.indexWhere((m) => m.localId == localId);
    if (sIdx != -1) {
      _streamedMessages[sIdx] = next;
      notifyListeners();
      return;
    }
    final pIdx = _paginatedMessages.indexWhere((m) => m.localId == localId);
    if (pIdx != -1) {
      _paginatedMessages[pIdx] = next;
      notifyListeners();
    }
  }

  Future<void> deleteMessage(ChatMessage msg) async {
    removeMessage(msg.localId);
    unawaited(_historyFirestoreService.deleteLogsForMessage(msg.localId));
    if (msg.firestoreId != null) {
      await _repository.deleteMessage(msg);
    }
  }

  Future<void> handleFeedback(ChatMessage msg, String type) async {
    final sIdx = _streamedMessages.indexOf(msg);
    if (sIdx != -1) {
      _streamedMessages[sIdx] = _streamedMessages[sIdx].copyWith(feedback: type);
      notifyListeners();
    } else {
      final pIdx = _paginatedMessages.indexOf(msg);
      if (pIdx != -1) {
        _paginatedMessages[pIdx] = _paginatedMessages[pIdx].copyWith(feedback: type);
        notifyListeners();
      }
    }
    await _repository.updateMessageFeedback(msg, type);
  }

  /// Files a user report about an AI response (Play generative-AI policy).
  ///
  /// The service swallows its own errors so a blocked write can never surface

  /// Newly-aged-out messages required before a summary run (K-6/P2-5): without
  /// batching, every turn past the 6-message window spent an AI call + 2
  /// writes from the same 20/day `system` budget classification uses.
  static const int _minNewMessagesForSummary = 4;

  Future<void> precomputeSummary() async {
    if (_isSummarizing || messages.length <= 6) return;
    _isSummarizing = true;

    try {
      const maxContextMessages = 6;
      final chronological = messages.reversed.where((m) => m.text.isNotEmpty).toList();
      if (chronological.length <= maxContextMessages) return;

      final agedOut = chronological.sublist(0, chronological.length - maxContextMessages);

      // Everything strictly after the marker: the old skipWhile re-included
      // the marker message itself, re-summarizing 1 stale message per run.
      final List<ChatMessage> newlyAgedOut;
      if (_summarizedThroughMessageId == null) {
        newlyAgedOut = agedOut;
      } else {
        final idx = agedOut.indexWhere((m) => m.firestoreId?.toString() == _summarizedThroughMessageId || m.localId == _summarizedThroughMessageId);
        newlyAgedOut = idx == -1 ? const [] : agedOut.sublist(idx + 1);
      }

      if (newlyAgedOut.length < _minNewMessagesForSummary) return;
      if (!await _usageService.canSummarize()) {
        AppLogger.ai('Summary skipped: system quota reserved for classification.');
        return;
      }

      AppLogger.ai('Summarizing ${newlyAgedOut.length} messages.');
      _cachedSummary = await _aiService.summarizeHistory(newlyAgedOut, previousSummary: _cachedSummary);

      final profile = await _authFirestoreService.getUserMetadata();
      if (profile != null) {
        await _authFirestoreService.updateUserProfile(profile.copyWith(chatSummary: _cachedSummary));
      }

      final last = agedOut.last;
      _summarizedThroughMessageId = last.firestoreId?.toString() ?? last.localId;
    } catch (e, st) {
      AppLogger.ai('Summary failed', error: e, stackTrace: st);
    } finally {
      _isSummarizing = false;
    }
  }
}
