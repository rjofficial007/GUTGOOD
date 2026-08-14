import 'package:gutgood/core/models/scan_result.dart';

class ScanResultArgs {
  const ScanResultArgs({required this.scanData, this.heroTag});

  factory ScanResultArgs.fromMap(Map<String, dynamic> map) => ScanResultArgs(scanData: ScanResult.fromMap(map['scanData'] as Map<String, dynamic>), heroTag: map['heroTag'] as String?);
  final ScanResult scanData;
  final String? heroTag;

  Map<String, dynamic> toMap() => {'scanData': scanData.toMap(), 'heroTag': heroTag};
}
