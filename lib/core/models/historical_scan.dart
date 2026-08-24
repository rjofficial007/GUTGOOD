import 'package:gutgood/core/models/scan_result.dart';

/// Wrapper for scan results in the history view.
class HistoricalScan {
  const HistoricalScan({required this.data, required this.createdAt, this.userImageUrl});
  final ScanResult data;
  final DateTime createdAt;
  final String? userImageUrl;
}
