import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/insights/body_pattern.dart';
import 'package:gutgood/core/models/scans/scan_result.dart';

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

class HighlightDetailArgs {
  const HighlightDetailArgs({
    required this.tag,
    this.emoji,
    this.icon,
    this.imageUrl,
    this.userImageUrl,
    required this.title,
    this.body,
    required this.accentColor,
    required this.backgroundColor,
    this.chartType,
    this.footLeft,
    this.chartValues = const [],
    // v2 detail-screen content (optional; legacy routes omit them).
    this.whyPoints = const [],
    this.timeframe,
    this.frequency,
    this.pattern,
  });
  factory HighlightDetailArgs.fromMap(Map<String, dynamic> map) => HighlightDetailArgs(
    tag: map['tag'] as String,
    emoji: map['emoji'] as String?,
    icon: map['icon'] as String?,
    imageUrl: map['imageUrl'] as String?,
    userImageUrl: map['userImageUrl'] as String?,
    title: map['title'] as String,
    body: map['body'] as String?,
    accentColor: map['accentColor'] as int,
    backgroundColor: map['backgroundColor'] as int,
    chartType: map['chartType'] as String?,
    footLeft: map['footLeft'] as String?,
    chartValues: (map['chartValues'] as List? ?? []).cast<double>(),
    whyPoints: (map['whyPoints'] as List? ?? []).cast<String>(),
    timeframe: map['timeframe'] as String?,
    frequency: map['frequency'] as String?,
  );

  final String tag;
  final String? emoji;
  final String? icon; // icon name as string
  final String? imageUrl;
  final String? userImageUrl;
  final String title;
  final String? body;
  final int accentColor;
  final int backgroundColor;
  final String? chartType;
  final String? footLeft;
  final List<double> chartValues;

  /// v2: "Why it works"/"Why it's a trigger" checklist, plus the stat row.
  final List<String> whyPoints;
  final String? timeframe;
  final String? frequency;
  final BodyPattern? pattern;

  Map<String, dynamic> toMap() => {
    'tag': tag,
    'emoji': emoji,
    'icon': icon,
    'imageUrl': imageUrl,
    'userImageUrl': userImageUrl,
    'title': title,
    'body': body,
    'accentColor': accentColor,
    'backgroundColor': backgroundColor,
    'chartType': chartType,
    'footLeft': footLeft,
    'chartValues': chartValues,
    'whyPoints': whyPoints,
    'timeframe': timeframe,
    'frequency': frequency,
  };
}
