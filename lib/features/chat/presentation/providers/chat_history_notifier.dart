import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore/auth_firestore_service.dart';
import 'package:gutgood/core/services/firestore/chat_firestore_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ChatHistoryNotifier with ChangeNotifier {
  ChatHistoryNotifier({
    required ChatRepository repository,
    required ChatFirestoreService chatFirestoreService,
    required AuthFirestoreService authFirestoreService,
    required HistoryFirestoreService historyFirestoreService,
    required AiService aiService,
    required AppStateService appStateService,
    required SharedPreferences prefs,
    required FirebaseAuth auth,
  }) : _repository = repository,
       _chatFirestoreService = chatFirestoreService,
       _authFirestoreService = authFirestoreService,
       _historyFirestoreService = historyFirestoreService,
       _aiService = aiService,
       _appStateService = appStateService,
       _prefs = prefs,
       _auth = auth {
    _initChatStream();
    _appStateService.chatUpdated.addListener(refreshHistory);
    _appStateService.profileUpdated.addListener(_onProfileUpdated);
    _appStateService.sessionReset.addListener(clearHistory);

    _auth.authStateChanges().listen((user) {
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
  final AiService _aiService;
  final AppStateService _appStateService;
  final SharedPreferences _prefs;
  final FirebaseAuth _auth;

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

  List<ChatMessage> get messages {
    final combined = <ChatMessage>[..._streamedMessages, ..._paginatedMessages];
    // Deduplicate by localId just in case
    final seen = <String>{};
    return combined.where((m) => seen.add(m.localId)).toList();
  }

  bool get historyLoading => _historyLoading;
  bool get isPaginationLoading => _isPaginationLoading;
  bool get hasMoreMessages => _hasMoreMessages;
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

    _chatStreamSub = _chatFirestoreService.getMessagesStream(limit: _pageSize).listen(
      (serverMessages) {
        final serverLocalIds = serverMessages.map((m) => m.localId).toSet();

        // Keep optimistic messages the server hasn't confirmed yet.
        final pending = _streamedMessages
            .where((m) => _optimisticIds.contains(m.localId) && !serverLocalIds.contains(m.localId))
            .toList();

        _streamedMessages
          ..clear()
          ..addAll(pending)
          ..addAll(serverMessages);

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
      final older = await _repository.getOlderMessages(limit: _pageSize, before: lastMessage.time);

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
    final initialMsg = ChatMessage(localId: const Uuid().v4(), role: 'ai', text: AppStrings.chatInitialGreeting, isSwap: false, time: DateTime.now());

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
      _userGoals = _prefs.getStringList('user_goals') ?? [];
      _userSensitivities = _prefs.getStringList('user_sensitivities') ?? [];
      _userLifestyle = _prefs.getStringList('user_lifestyle') ?? [];
      _cycleSyncEnabled = _prefs.getBool('cycle_sync_enabled') ?? false;
      final cp = _prefs.getString('cycle_phase');
      _cyclePhase = _cycleSyncEnabled ? (cp ?? AppStrings.phaseLuteal) : AppStrings.notSpecified;
    }

    _commStyle = _prefs.getString('ai_comm_style') ?? AppStrings.friendlySupportive;
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

  Future<void> precomputeSummary() async {
    if (_isSummarizing || messages.length <= 6) return;
    _isSummarizing = true;

    try {
      const maxContextMessages = 6;
      final chronological = messages.reversed.where((m) => m.text.isNotEmpty).toList();
      if (chronological.length <= maxContextMessages) return;

      final agedOut = chronological.sublist(0, chronological.length - maxContextMessages);

      final newlyAgedOut = _summarizedThroughMessageId == null
          ? agedOut
          : agedOut.skipWhile((m) => m.firestoreId?.toString() != _summarizedThroughMessageId && m.localId != _summarizedThroughMessageId).toList();

      if (newlyAgedOut.isEmpty) return;

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
