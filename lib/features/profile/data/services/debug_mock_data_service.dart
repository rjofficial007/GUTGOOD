import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/yuka_score.dart';
import 'package:gutgood/features/insights/application/usecases/generate_insight_usecase.dart';
import 'package:gutgood/infrastructure/firebase/firestore/chat_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/insight_firestore_service.dart';

part 'debug_mock_thirty_days.dart';
part 'debug_mock_chat_history.dart';
part 'debug_mock_showcase_scans.dart';

/// Service to generate pattern-rich mock data for testing.
class DebugMockDataService {
  DebugMockDataService({
    required HistoryFirestoreService historyFirestoreService,
    required InsightFirestoreService insightFirestoreService,
    required ChatFirestoreService chatFirestoreService,
    required GenerateInsightUseCase generateInsightUseCase,
  }) : _historyFirestoreService = historyFirestoreService,
       _insightFirestoreService = insightFirestoreService,
       _chatFirestoreService = chatFirestoreService,
       _generateInsightUseCase = generateInsightUseCase;

  final HistoryFirestoreService _historyFirestoreService;
  final InsightFirestoreService _insightFirestoreService;
  final ChatFirestoreService _chatFirestoreService;
  final GenerateInsightUseCase _generateInsightUseCase;

  String _mockRecordId(String kind, DateTime time, String label) {
    final day = '${time.year}_${time.month.toString().padLeft(2, '0')}_${time.day.toString().padLeft(2, '0')}';
    final slug = label.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_').replaceAll(RegExp('^_+'), '');
    return 'debug_${kind}_${day}_${slug.isEmpty ? 'record' : slug}';
  }

  Future<void> _logMockMeal(MealLog meal) async {
    if (meal.createdAt.isAfter(DateTime.now()) || meal.eventTime.isAfter(DateTime.now())) return;
    final id = await _historyFirestoreService.logMeal(
      meal.copyWith(occurredAt: meal.createdAt, occurredAtProvenance: OccurrenceProvenance.user),
      docId: _mockRecordId('meal', meal.createdAt, '${meal.mealType}_${meal.items.firstOrNull ?? 'meal'}'),
    );
    if (id == null) throw StateError('Could not save mock meal ${meal.items.firstOrNull ?? ''}.');
  }

  Future<void> _logMockSymptom(SymptomLog symptom) async {
    if (symptom.createdAt.isAfter(DateTime.now()) || symptom.eventTime.isAfter(DateTime.now())) return;
    final id = await _historyFirestoreService.logSymptom(
      symptom.copyWith(occurredAt: symptom.occurredAt ?? symptom.createdAt, occurredAtProvenance: OccurrenceProvenance.user, provenance: RecordProvenance.user),
      docId: _mockRecordId('symptom', symptom.createdAt, symptom.symptom),
    );
    if (id == null) throw StateError('Could not save mock symptom ${symptom.symptom}.');
  }

  Future<void> _saveMockScan(ScanResult scan, {required String scanId}) async {
    if (!await _historyFirestoreService.trySaveToScanHistory(scan, scanId: scanId)) {
      throw StateError('Could not save mock scan ${scan.productName}.');
    }
  }
}
