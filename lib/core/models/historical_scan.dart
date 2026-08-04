import 'package:gutgood/core/models/scan_result.dart';

class HistoricalScan {

  const HistoricalScan({required this.data, required this.time, this.userImageUrl});
  final ScanResult data;
  final DateTime time;
  final String? userImageUrl;
}