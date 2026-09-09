import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/scan_result.dart';

class ScanResultArgs {
  const ScanResultArgs({required this.scanData, this.heroTag});

  factory ScanResultArgs.fromMap(Map<String, dynamic> map) => ScanResultArgs(scanData: ScanResult.fromMap(map['scanData'] as Map<String, dynamic>), heroTag: map['heroTag'] as String?);
  final ScanResult scanData;
  final String? heroTag;

  Map<String, dynamic> toMap() => {'scanData': scanData.toMap(), 'heroTag': heroTag};
}

/// Full-list additives screen payload: the items to show plus header copy.
class AdditiveListArgs {
  const AdditiveListArgs({required this.items, required this.title, this.subtitle = ''});

  factory AdditiveListArgs.fromMap(Map<String, dynamic> map) => AdditiveListArgs(
    items: (map['items'] as List? ?? const []).map((e) => AdditiveConcern.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
    title: map['title']?.toString() ?? '',
    subtitle: map['subtitle']?.toString() ?? '',
  );

  final List<AdditiveConcern> items;
  final String title;
  final String subtitle;

  Map<String, dynamic> toMap() => {'items': items.map((c) => c.toMap()).toList(), 'title': title, 'subtitle': subtitle};
}
