import 'scan_result.dart';

class HistoricalScan {
  final ScanResult data;
  final DateTime time;
  final String? userImageUrl;

  const HistoricalScan({required this.data, required this.time, this.userImageUrl});
}