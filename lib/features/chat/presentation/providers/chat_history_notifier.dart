import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore/auth_firestore_service.dart';
import 'package:gutgood/core/services/firestore/chat_firestore_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ChatHistoryNotifier with ChangeNotifier {
  ChatHistoryNotifier({
    required ChatRepository repository,
    required ChatFirestoreService chatFirestoreService,
    required AuthFirestoreService authFirestoreService,
    required AiService aiService,
    required AppStateService appStateService,
    required SharedPreferences prefs,
    required FirebaseAuth auth,
  }) : _repository = repository,
       _chatFirestoreService = chatFirestoreService,
       _authFirestoreService = authFirestoreService,
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
  final AiService _aiService;
  final AppStateService _appStateService;
  final SharedPreferences _prefs;
  final FirebaseAuth _auth;

  final List<ChatMessage> _messages = [];
  final Set<String> _optimisticIds = {};

  bool _historyLoading = true;
  bool _isPaginationLoading = false;
  int _currentLimit = 50;

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

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get historyLoading => _historyLoading;
  bool get isPaginationLoading => _isPaginationLoading;
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
    if (!_isPaginationLoading && _messages.isEmpty) {
      _historyLoading = true;
    }
    notifyListeners();

    _chatStreamSub = _chatFirestoreService
        .getMessagesStream(limit: _currentLimit)
        .listen(
          (serverMessages) {
            final serverLocalIds = serverMessages.map((m) => m.localId).toSet();

            // Keep optimistic messages the server hasn't confirmed yet.
            final pending = _messages.where((m) => _optimisticIds.contains(m.localId) && !serverLocalIds.contains(m.localId)).toList();

            _messages
              ..clear()
              ..addAll(pending)
              ..addAll(serverMessages);

            _optimisticIds.removeAll(serverLocalIds);

            if (_messages.isEmpty && !_historyLoading) {
              unawaited(_createInitialGreeting());
            }

            _historyLoading = false;
            notifyListeners();
            unawaited(_loadProfileData());
          },
          onError: (e) {
            AppLogger.ai('Message stream error', error: e);
            _historyLoading = false;
            notifyListeners();
          },
        );
  }

  void refreshHistory() => _initChatStream();

  Future<void> loadMore() async {
    if (_isPaginationLoading || _historyLoading) return;
    if (_messages.length < _currentLimit) return;

    _isPaginationLoading = true;
    _currentLimit += 50;
    _initChatStream();

    await Future.delayed(const Duration(milliseconds: 500));
    _isPaginationLoading = false;
    notifyListeners();
  }

  Future<void> _createInitialGreeting() async {
    final initialMsg = ChatMessage(localId: const Uuid().v4(), role: 'ai', text: AppStrings.chatInitialGreeting, isSwap: false, time: DateTime.now());
    await _chatFirestoreService.saveMessage(initialMsg);
  }

  void _onProfileUpdated() => unawaited(_loadProfileData());

  void clearHistory() {
    _messages.clear();
    _optimisticIds.clear();
    _cachedSummary = null;
    _summarizedThroughMessageId = null;
    _historyLoading = false;
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
    _messages.insert(0, msg);
    notifyListeners();
  }

  void removeMessage(String localId) {
    _messages.removeWhere((m) => m.localId == localId);
    _optimisticIds.remove(localId);
    notifyListeners();
  }

  void replaceMessage(String localId, ChatMessage next) {
    final idx = _messages.indexWhere((m) => m.localId == localId);
    if (idx != -1) {
      _messages[idx] = next;
      notifyListeners();
    }
  }

  Future<void> deleteMessage(ChatMessage msg) async {
    removeMessage(msg.localId);
    if (msg.firestoreId != null) {
      await _repository.deleteMessage(msg);
    }
  }

  Future<void> handleFeedback(ChatMessage msg, String type) async {
    final index = _messages.indexOf(msg);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(feedback: type);
      notifyListeners();
    }
    await _repository.updateMessageFeedback(msg, type);
  }

  Future<void> precomputeSummary() async {
    if (_isSummarizing || _messages.length <= 6) return;
    _isSummarizing = true;

    try {
      const maxContextMessages = 6;
      final chronological = _messages.reversed.where((m) => m.text.isNotEmpty).toList();
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
