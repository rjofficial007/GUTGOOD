import 'package:equatable/equatable.dart';

class HealthAlert extends Equatable {
  final String id;
  final String title;
  final String message;
  final String type; // 'processed_food', 'streak_saver', 'insight_ready', etc.
  final DateTime time;
  final bool isRead;

  const HealthAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.time,
    this.isRead = false,
  });

  factory HealthAlert.fromMap(Map<String, dynamic> map, {String? id}) {
    return HealthAlert(
      id: id ?? map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'system',
      time: map['time'] != null ? DateTime.parse(map['time']) : DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'time': time.toIso8601String(),
      'isRead': isRead,
    };
  }

  HealthAlert copyWith({bool? isRead}) {
    return HealthAlert(
      id: id,
      title: title,
      message: message,
      type: type,
      time: time,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [id, title, message, type, time, isRead];
}
