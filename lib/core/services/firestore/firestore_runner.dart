import 'package:gutgood/core/utils/logger_service.dart';

/// Centralized runner for Firestore operations that standardizes error logging.
Future<T> runFirestoreOperation<T>({
  required String operationName,
  required Future<T> Function() action,
}) async {
  try {
    return await action();
  } catch (e, stack) {
    AppLogger.firestore('Firestore operation failed [$operationName]', error: e, stackTrace: stack);
    rethrow;
  }
}
