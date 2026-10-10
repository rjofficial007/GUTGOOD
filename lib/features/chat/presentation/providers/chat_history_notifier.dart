import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/ai/client/ai_client.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/constants/storage_keys.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/auth/data/services/usage_service.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';
import 'package:gutgood/features/logs/data/services/domain_event_persister.dart';
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
    required DomainEventPersister domainEventPersister,
    required AiClient aiService,
    required AppStateService appStateService,
    required SharedPreferences prefs,
    required FirebaseAuth auth,
    required UsageService usageService,
  }) : _repository = repository,
       _chatFirestoreService = chatFirestoreService,
       _authFirestoreService = authFirestoreService,
       _historyFirestoreService = historyFirestoreService,
       _domainEventPersister = domainEventPersister,
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
  final DomainEventPersister _domainEventPersister;
  final AiClient _aiService;
  final AppStateService _appStateService;
  final SharedPreferences _prefs;
  final FirebaseAuth _auth;
  final UsageService _usageService;

  final List<ChatMessage> _streamedMessages = [];
  final List<ChatMessage> _paginatedMessages = [];
  final Set<String> _optimisticIds = {};
  final Set<String> _resolvingConsumptionIds = {};
  final Map<String, ChatMessage> _localConsumptionResolutions = {};

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
  bool isResolvingScanConsumption(String messageId) => _resolvingConsumptionIds.contains(messageId);
  Set<String> get resolvingScanConsumptionIds => Set.unmodifiable(_resolvingConsumptionIds);

  // Context getters for Composer
  List<String> get userGoals => _userGoals;
  List<String> get userSensitivities => _userSensitivities;
  List<String> get userLifestyle => _userLifestyle;
  String get commStyle => _commStyle;
  String get cyclePhase => _cyclePhase;

  Future<bool> appendScanSwaps({required String scanId, required List<ProductSwap> swaps}) async {
    final updated = await _historyFirestoreService.appendScanSwaps(scanId: scanId, swaps: swaps);
    if (updated) _appStateService.notifyChatUpdated();
    return updated;
  }

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
              final localResolution = _localConsumptionResolutions[srv.localId];
              if (localResolution != null) {
                final expectedConsumed = localResolution.scanData?.consumed;
                if (srv.scanData?.consumed == expectedConsumed) {
                  _localConsumptionResolutions.remove(srv.localId);
                } else {
                  // A snapshot can arrive between the local update and its
                  // Firestore echo. Keep the user's confirmation visible
                  // until the server sends that resolved scan preview.
                  return srv.copyWith(scanData: localResolution.scanData, mealLogs: localResolution.mealLogs);
                }
              }
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
    _localConsumptionResolutions.clear();
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
    _localConsumptionResolutions.remove(localId);
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

  Future<bool> resolveScanConsumption(ChatMessage message, {required bool consumed, DateTime? occurredAt}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || !messages.any((item) => item.localId == message.localId)) return false;
    final originalScan = message.scanData;
    if (originalScan == null || !originalScan.needsConsumptionConfirmation || originalScan.consumed != null) return false;
    if (!_resolvingConsumptionIds.add(message.localId)) return true;
    notifyListeners();

    try {
      final originalScanId = originalScan.scanId;
      var scan = originalScanId == null ? originalScan : (await _historyFirestoreService.getScanById(originalScanId) ?? originalScan);
      if (scan.scanId == null || scan.scanId!.isEmpty) {
        scan = scan.copyWith(scanId: '${message.localId}_scan', chatMessageId: message.localId);
      }
      if (scan.consumed != null && scan.consumed != consumed) return false;

      if (uid != _auth.currentUser?.uid) return false;
      MealLog? meal;
      if (consumed) {
        meal = await _domainEventPersister.persistConfirmedScanMeal(scan.copyWith(consumed: true), chatMessageId: message.localId, occurredAt: occurredAt);
        if (meal == null) return false;
      }

      if (uid != _auth.currentUser?.uid) return false;
      final resolvedScan = scan.copyWith(consumed: consumed);
      final scanSaved = await _historyFirestoreService.trySaveToScanHistory(resolvedScan, scanId: resolvedScan.scanId);
      if (uid != _auth.currentUser?.uid || (!scanSaved && !consumed)) return false;
      await _historyFirestoreService.deleteScanMealProjections(chatMessageId: message.localId, scanId: resolvedScan.scanId!, keepMealId: consumed ? meal?.firestoreId : null);

      if (uid != _auth.currentUser?.uid) return false;
      final resolvedMessage = message.copyWith(scanData: resolvedScan, mealLogs: meal == null ? const [] : [meal]);
      _localConsumptionResolutions[message.localId] = resolvedMessage;
      replaceMessage(message.localId, resolvedMessage);
      final chatSaved = await _chatFirestoreService.saveMessage(resolvedMessage);
      _appStateService.notifyChatUpdated();
      return consumed || (scanSaved && chatSaved != null);
    } catch (e) {
      AppLogger.error('ChatHistoryNotifier: failed to save scan consumption response', error: e);
      return false;
    } finally {
      _resolvingConsumptionIds.remove(message.localId);
      notifyListeners();
    }
  }

  Future<List<MealLog>> recentConfirmedMeals() async {
    final since = DateTime.now().subtract(const Duration(days: 30));
    final data = await Future.wait([_historyFirestoreService.getRecentMealLogs(since: since, throwOnError: true), _historyFirestoreService.getRecentScans(since: since, throwOnError: true)]);
    return confirmedFoodMeals(meals: data[0] as List<MealLog>, scans: data[1] as List<ScanResult>).where((meal) => !meal.eventTime.isAfter(DateTime.now())).toList();
  }

  Future<bool> confirmJournalTiming(ChatMessage message, {MealLog? meal, SymptomLog? symptom, required DateTime occurredAt, String? linkedMealId}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || occurredAt.isAfter(DateTime.now())) return false;
    try {
      final current = messages.where((item) => item.localId == message.localId).firstOrNull;
      if (current == null) return false;
      if (meal != null && meal.firestoreId != null) {
        final source = current.mealLogs.where((item) => item.firestoreId == meal.firestoreId).firstOrNull;
        if (source == null) return false;
        final updated = source.copyWith(occurredAt: occurredAt, occurredAtProvenance: OccurrenceProvenance.user);
        if (await _historyFirestoreService.logMeal(updated, docId: meal.firestoreId) == null || uid != _auth.currentUser?.uid) return false;
        _appStateService.notifyChatUpdated();
        final next = current.copyWith(mealLogs: current.mealLogs.map((item) => item.firestoreId == meal.firestoreId ? updated : item).toList());
        if (await _chatFirestoreService.saveMessage(next) == null) return false;
        replaceMessage(next.localId, next);
      } else if (symptom != null && symptom.firestoreId != null) {
        final recentMeals = await recentConfirmedMeals();
        if (linkedMealId != null && !recentMeals.any((meal) => (meal.journalEntryId ?? meal.firestoreId) == linkedMealId)) return false;
        if (uid != _auth.currentUser?.uid) return false;
        final mealId = linkedMealId ?? nearestMealJournalEntryId(symptomTime: occurredAt, meals: recentMeals.where((meal) => meal.occurredAtProvenance == OccurrenceProvenance.user));
        final source = current.symptomLogs.where((item) => item.firestoreId == symptom.firestoreId).firstOrNull;
        if (source == null) return false;
        final selectedMeal = recentMeals.where((meal) => (meal.journalEntryId ?? meal.firestoreId) == mealId).firstOrNull;
        final updated = source.copyWith(
          foodName: selectedMeal?.items.firstOrNull,
          occurredAt: occurredAt,
          occurredAtProvenance: OccurrenceProvenance.user,
          provenance: RecordProvenance.user,
          journalEntryId: mealId,
          lastMealFirestoreId: mealId,
          clearMealLink: mealId == null,
        );
        if (await _historyFirestoreService.logSymptom(updated, docId: symptom.firestoreId) == null || uid != _auth.currentUser?.uid) return false;
        _appStateService.notifyChatUpdated();
        final next = current.copyWith(symptomLogs: current.symptomLogs.map((item) => item.firestoreId == symptom.firestoreId ? updated : item).toList());
        if (await _chatFirestoreService.saveMessage(next) == null) return false;
        replaceMessage(next.localId, next);
      } else {
        return false;
      }
      _appStateService.notifyChatUpdated();
      return true;
    } catch (error) {
      AppLogger.error('Could not confirm journal timing', error: error);
      return false;
    }
  }

  Future<bool> patchScanUserImageUrl({required String scanId, required String imageUrl}) => _historyFirestoreService.patchScanUserImageUrl(scanId: scanId, imageUrl: imageUrl);

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
