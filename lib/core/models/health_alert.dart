import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';

class HealthAlert extends Equatable {
  const HealthAlert({required this.id, required this.title, required this.message, required this.type, required this.createdAt, this.isRead = false});

  factory HealthAlert.fromMap(Map<String, dynamic> map, {String? id}) => HealthAlert(
    id: id ?? map['id'] ?? '',
    title: map['title'] ?? '',
    message: map['message'] ?? '',
    type: map['type'] ?? 'system',
    createdAt: DateTimeUtils.parse(map['createdAt'] ?? map['time']),
    isRead: map['isRead'] ?? false,
  );
  final String id;
  final String title;
  final String message;
  final String type; // 'processed_food', 'streak_saver', 'insight_ready', etc.
  final DateTime createdAt;
  final bool isRead;

  Map<String, dynamic> toMap() => {'title': title, 'message': message, 'type': type, 'createdAt': DateTimeUtils.toTimestamp(createdAt), 'isRead': isRead};

  HealthAlert copyWith({bool? isRead}) => HealthAlert(id: id, title: title, message: message, type: type, createdAt: createdAt, isRead: isRead ?? this.isRead);

  @override
  List<Object?> get props => [id, title, message, type, createdAt, isRead];
}
