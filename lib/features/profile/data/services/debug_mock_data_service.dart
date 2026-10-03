import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/yuka_score.dart';
import 'package:gutgood/infrastructure/firebase/firestore/chat_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/food_image_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/insight_firestore_service.dart';
import 'package:gutgood/infrastructure/payments/purchase_service.dart';
import 'package:uuid/uuid.dart';


part 'debug_mock_thirty_days.dart';
part 'debug_mock_chat_history.dart';
part 'debug_mock_showcase_scans.dart';

/// Service to generate pattern-rich mock data for testing.
class DebugMockDataService {
  DebugMockDataService({
    required HistoryFirestoreService historyFirestoreService,
    required InsightFirestoreService insightFirestoreService,
    required ChatFirestoreService chatFirestoreService,
    required PurchaseService purchaseService,
    required FoodImageService foodImageService,
  }) : _historyFirestoreService = historyFirestoreService,
       _insightFirestoreService = insightFirestoreService,
       _chatFirestoreService = chatFirestoreService,
       _purchaseService = purchaseService,
       _foodImageService = foodImageService;

  final HistoryFirestoreService _historyFirestoreService;
  final InsightFirestoreService _insightFirestoreService;
  final ChatFirestoreService _chatFirestoreService;
  final PurchaseService _purchaseService;
  final FoodImageService _foodImageService;
}
