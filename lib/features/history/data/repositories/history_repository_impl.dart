import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final FirestoreService _firestoreService;

  HistoryRepositoryImpl({required FirestoreService firestoreService}) : _firestoreService = firestoreService;

  @override
  Future<List<ChatMessage>> getMessages({int? limit, int? offset, DateTime? beforeTime}) async {
    // Note: beforeTime/offset pagination can be implemented in FirestoreService if needed.
    // For now, using the basic stream or a one-shot fetch.
    return []; // Re-routing history logic to use the getScanHistory instead of scanning all chat messages
  }

  @override
  Future<List<ScanResult>> getScanHistory({int limit = 50}) async {
    return await _firestoreService.getScanHistory(limit: limit);
  }

  @override
  Future<List<ScanResult>> getSavedFoods() async {
    return await _firestoreService.getSavedFoods();
  }

  @override
  Future<void> toggleSaveFood(ScanResult scanData) async {
    await _firestoreService.toggleSaveFood(scanData);
  }

  @override
  Future<bool> isFoodSaved(String? productName, {String? barcode}) async {
    return await _firestoreService.isFoodSaved(productName, barcode: barcode);
  }
}
