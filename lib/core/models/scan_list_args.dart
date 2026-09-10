import 'package:gutgood/core/models/scan_result.dart';

enum ScanListKind { ingredients, allergens, additives }

class ScanListDetailArgs {
  const ScanListDetailArgs({required this.kind, required this.scan});
  final ScanListKind kind;
  final ScanResult scan;

  factory ScanListDetailArgs.fromMap(Map<String, dynamic> map) => ScanListDetailArgs(
    kind: ScanListKind.values.firstWhere((k) => k.name == map['kind']?.toString(), orElse: () => ScanListKind.ingredients),
    scan: ScanResult.fromMap(map['scan'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toMap() => {'kind': kind.name, 'scan': scan.toMap()};
}
