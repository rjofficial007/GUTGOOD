import 'package:equatable/equatable.dart';

class DailyUsage extends Equatable {

  const DailyUsage({
    required this.uid,
    required this.date,
    this.chatCount = 0,
    this.scanCount = 0,
    this.systemCount = 0,
  });

  factory DailyUsage.fromMap(Map<String, dynamic> map) => DailyUsage(
      uid: map['uid'] ?? '',
      date: map['date'] ?? '',
      chatCount: (map['chat_count'] as num?)?.toInt() ?? 0,
      scanCount: (map['scan_count'] as num?)?.toInt() ?? 0,
      systemCount: (map['system_count'] as num?)?.toInt() ?? 0,
    );
  final String uid;
  final String date;
  final int chatCount;
  final int scanCount;
  final int systemCount;

  Map<String, dynamic> toMap() => {
      'uid': uid,
      'date': date,
      'chat_count': chatCount,
      'scan_count': scanCount,
      'system_count': systemCount,
    };

  @override
  List<Object?> get props => [uid, date, chatCount, scanCount, systemCount];
}
