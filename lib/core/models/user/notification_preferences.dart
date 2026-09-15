import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/model_utils.dart';

class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    this.enableAll = true,
    this.mealReminders = true,
    this.noMealLoggedReminder = true,
    this.dailyReminder = true,
    this.insightUpdates = true,
    this.weeklySummary = true,
    this.breakfastTime = '8:0',
    this.lunchTime = '12:30',
    this.dinnerTime = '19:0',
    this.dailyReminderTime = '9:0',
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) => NotificationPreferences(
    enableAll: ModelUtils.parseBool(map['enableAll'], defaultValue: true),
    mealReminders: ModelUtils.parseBool(map['mealReminders'], defaultValue: true),
    noMealLoggedReminder: ModelUtils.parseBool(map['noMealLoggedReminder'], defaultValue: true),
    dailyReminder: ModelUtils.parseBool(map['dailyReminder'], defaultValue: true),
    insightUpdates: ModelUtils.parseBool(map['insightUpdates'], defaultValue: true),
    weeklySummary: ModelUtils.parseBool(map['weeklySummary'], defaultValue: true),
    breakfastTime: map['breakfastTime'] ?? '8:0',
    lunchTime: map['lunchTime'] ?? '12:30',
    dinnerTime: map['dinnerTime'] ?? '19:0',
    dailyReminderTime: map['dailyReminderTime'] ?? '9:0',
  );
  final bool enableAll;
  final bool mealReminders;
  final bool noMealLoggedReminder;
  final bool dailyReminder;
  final bool insightUpdates;
  final bool weeklySummary;
  final String breakfastTime;
  final String lunchTime;
  final String dinnerTime;
  final String dailyReminderTime;

  NotificationPreferences copyWith({
    bool? enableAll,
    bool? mealReminders,
    bool? noMealLoggedReminder,
    bool? dailyReminder,
    bool? insightUpdates,
    bool? weeklySummary,
    String? breakfastTime,
    String? lunchTime,
    String? dinnerTime,
    String? dailyReminderTime,
  }) => NotificationPreferences(
    enableAll: enableAll ?? this.enableAll,
    mealReminders: mealReminders ?? this.mealReminders,
    noMealLoggedReminder: noMealLoggedReminder ?? this.noMealLoggedReminder,
    dailyReminder: dailyReminder ?? this.dailyReminder,
    insightUpdates: insightUpdates ?? this.insightUpdates,
    weeklySummary: weeklySummary ?? this.weeklySummary,
    breakfastTime: breakfastTime ?? this.breakfastTime,
    lunchTime: lunchTime ?? this.lunchTime,
    dinnerTime: dinnerTime ?? this.dinnerTime,
    dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
  );

  Map<String, dynamic> toMap() => {
    'enableAll': enableAll ? 1 : 0,
    'mealReminders': mealReminders ? 1 : 0,
    'noMealLoggedReminder': noMealLoggedReminder ? 1 : 0,
    'dailyReminder': dailyReminder ? 1 : 0,
    'insightUpdates': insightUpdates ? 1 : 0,
    'weeklySummary': weeklySummary ? 1 : 0,
    'breakfastTime': breakfastTime,
    'lunchTime': lunchTime,
    'dinnerTime': dinnerTime,
    'dailyReminderTime': dailyReminderTime,
  };

  @override
  List<Object?> get props => [enableAll, mealReminders, noMealLoggedReminder, dailyReminder, insightUpdates, weeklySummary, breakfastTime, lunchTime, dinnerTime, dailyReminderTime];
}
