import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/notification_preferences.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gutgood/core/theme/app_color_scheme.dart';

import '../../../../core/services/firestore_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;

  bool _enableAll = true;
  bool _mealReminders = true;
  bool _noMealLoggedReminder = true;
  bool _dailyReminder = true;
  bool _insightUpdates = true;
  bool _weeklySummary = true;

  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 12, minute: 30);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _dailyReminderTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final cloudProfile = await sl<FirestoreService>().getUserMetadata();
    final cloudPrefs = cloudProfile?.notificationPreferences;

    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> data = cloudPrefs ?? {};
    
    setState(() {
      _enableAll = data['enableAll'] ?? prefs.getBool('notif_enable_all') ?? true;
      _mealReminders = data['mealReminders'] ?? prefs.getBool('notif_meal_reminders') ?? true;
      _noMealLoggedReminder = data['noMealLoggedReminder'] ?? prefs.getBool('notif_no_meal_logged') ?? true;
      _dailyReminder = data['dailyReminder'] ?? prefs.getBool('notif_daily_reminder') ?? true;
      _insightUpdates = data['insightUpdates'] ?? prefs.getBool('notif_insight_updates') ?? true;
      _weeklySummary = data['weeklySummary'] ?? prefs.getBool('notif_weekly_summary') ?? true;

      _breakfastTime = _decodeTime(data['breakfastTime'] ?? prefs.getString('notif_breakfast_time')) ?? _breakfastTime;
      _lunchTime = _decodeTime(data['lunchTime'] ?? prefs.getString('notif_lunch_time')) ?? _lunchTime;
      _dinnerTime = _decodeTime(data['dinnerTime'] ?? prefs.getString('notif_dinner_time')) ?? _dinnerTime;
      _dailyReminderTime = _decodeTime(data['dailyReminderTime'] ?? prefs.getString('notif_daily_time')) ?? _dailyReminderTime;

      _loading = false;
    });
  }

  TimeOfDay? _decodeTime(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
  }

  String _encodeTime(TimeOfDay t) => '${t.hour}:${t.minute}';

  Future<void> _persistBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    await _syncToFirestore();
  }

  Future<void> _persistTime(String key, TimeOfDay value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, _encodeTime(value));
    await _syncToFirestore();
  }

  Future<void> _syncToFirestore() async {
    final prefs = NotificationPreferences(
      enableAll: _enableAll,
      mealReminders: _mealReminders,
      noMealLoggedReminder: _noMealLoggedReminder,
      dailyReminder: _dailyReminder,
      insightUpdates: _insightUpdates,
      weeklySummary: _weeklySummary,
      breakfastTime: _encodeTime(_breakfastTime),
      lunchTime: _encodeTime(_lunchTime),
      dinnerTime: _encodeTime(_dinnerTime),
      dailyReminderTime: _encodeTime(_dailyReminderTime),
    );
    await sl<FirestoreService>().saveNotificationPreferences(prefs);
  }

  Future<void> _applyMealReminderSchedule() async {
    final notificationService = sl<NotificationService>();
    if (_enableAll && _mealReminders) {
      await notificationService.scheduleBreakfastReminder(_breakfastTime.hour, _breakfastTime.minute);
      await notificationService.scheduleLunchReminder(_lunchTime.hour, _lunchTime.minute);
      await notificationService.scheduleDinnerReminder(_dinnerTime.hour, _dinnerTime.minute);
    } else {
      await notificationService.cancelMealReminders();
    }
  }

  Future<void> _applyNoMealLoggedSchedule() async {
    final notificationService = sl<NotificationService>();
    if (_enableAll && _noMealLoggedReminder) {
      await notificationService.scheduleNoMealLoggedReminder();
    } else {
      await notificationService.cancelNoMealLoggedReminder();
    }
  }

  Future<void> _applyDailyReminderSchedule() async {
    final notificationService = sl<NotificationService>();
    if (_enableAll && _dailyReminder) {
      await notificationService.scheduleDailyReminder(hour: _dailyReminderTime.hour, minute: _dailyReminderTime.minute);
    } else {
      await notificationService.cancelDailyReminder();
    }
  }

  Future<void> _toggleEnableAll(bool val) async {
    setState(() => _enableAll = val);
    await _persistBool('notif_enable_all', val);
    await _syncToFirestore();
    if (!val) {
      await sl<NotificationService>().cancelAll();
    } else {
      await _applyMealReminderSchedule();
      await _applyNoMealLoggedSchedule();
      await _applyDailyReminderSchedule();
    }
  }

  Future<void> _pickTime(TimeOfDay initial, ValueChanged<TimeOfDay> onPicked) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: context.appColorScheme.textPrimary)),
      );
    }

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      appBar: const GutAppBar(title: AppStrings.notificationPreferences),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GutSection(
              showCard: true,
              topPadding: 0,
              children: [
                AppSwitchTile(
                  title: AppStrings.enableNotifications, 
                  desc: AppStrings.receiveUpdates, 
                  value: _enableAll, 
                  onChanged: _toggleEnableAll, 
                  showBottomBorder: false,
                ),
              ],
            ),

            GutSection(
              title: AppStrings.reminders,
              showCard: true,
              opacity: _enableAll ? 1.0 : 0.4,
              children: [
                IgnorePointer(
                  ignoring: !_enableAll,
                  child: Column(
                    children: [
                      AppSwitchTile(
                        icon: AppIcons.utensils,
                        title: AppStrings.mealRemindersLabel,
                        desc: AppStrings.mealRemindersDesc,
                        value: _mealReminders,
                        onChanged: _enableAll
                            ? (val) async {
                                setState(() => _mealReminders = val);
                                await _persistBool('notif_meal_reminders', val);
                                await _applyMealReminderSchedule();
                              }
                            : null,
                        showBottomBorder: _enableAll && _mealReminders,
                      ),
                      ClipRect(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: (_mealReminders && _enableAll)
                              ? Column(
                                  children: [
                                    _buildTimeRow(
                                      AppStrings.breakfastTime,
                                      _breakfastTime,
                                      () => _pickTime(_breakfastTime, (t) async {
                                        setState(() => _breakfastTime = t);
                                        await _persistTime('notif_breakfast_time', t);
                                        await _applyMealReminderSchedule();
                                      }),
                                    ),
                                    _buildTimeRow(
                                      AppStrings.lunchTime,
                                      _lunchTime,
                                      () => _pickTime(_lunchTime, (t) async {
                                        setState(() => _lunchTime = t);
                                        await _persistTime('notif_lunch_time', t);
                                        await _applyMealReminderSchedule();
                                      }),
                                    ),
                                    _buildTimeRow(
                                      AppStrings.dinnerTime,
                                      _dinnerTime,
                                      () => _pickTime(_dinnerTime, (t) async {
                                        setState(() => _dinnerTime = t);
                                        await _persistTime('notif_dinner_time', t);
                                        await _applyMealReminderSchedule();
                                      }),
                                    ),
                                    Divider(height: 1, color: context.appColorScheme.border.withValues(alpha: 0.5)),
                                  ],
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                      ),
                      AppSwitchTile(
                        icon: AppIcons.alertCircle,
                        title: AppStrings.missedLoggingAlert,
                        desc: AppStrings.missedLoggingDesc,
                        value: _noMealLoggedReminder,
                        onChanged: _enableAll
                            ? (val) async {
                                setState(() => _noMealLoggedReminder = val);
                                await _persistBool('notif_no_meal_logged', val);
                                await _applyNoMealLoggedSchedule();
                              }
                            : null,
                      ),
                      AppSwitchTile(
                        icon: AppIcons.bell,
                        title: AppStrings.dailyCheckInReminder,
                        desc: AppStrings.dailyCheckInDesc,
                        value: _dailyReminder,
                        onChanged: _enableAll
                            ? (val) async {
                                setState(() => _dailyReminder = val);
                                await _persistBool('notif_daily_reminder', val);
                                await _applyDailyReminderSchedule();
                              }
                            : null,
                        showBottomBorder: _enableAll && _dailyReminder,
                      ),
                      ClipRect(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: (_dailyReminder && _enableAll)
                              ? _buildTimeRow(
                                  AppStrings.reminderTime,
                                  _dailyReminderTime,
                                  () => _pickTime(_dailyReminderTime, (t) async {
                                    setState(() => _dailyReminderTime = t);
                                    await _persistTime('notif_daily_time', t);
                                    await _applyDailyReminderSchedule();
                                  }),
                                  isLast: true,
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            GutSection(
              title: AppStrings.sectionUpdates,
              showCard: true,
              opacity: _enableAll ? 1.0 : 0.4,
              children: [
                IgnorePointer(
                  ignoring: !_enableAll,
                  child: Column(
                    children: [
                      AppSwitchTile(
                        icon: AppIcons.zap,
                        title: AppStrings.insightUpdatesLabel,
                        desc: AppStrings.insightUpdatesDesc,
                        value: _insightUpdates,
                        onChanged: _enableAll
                            ? (val) async {
                                setState(() => _insightUpdates = val);
                                await _persistBool('notif_insight_updates', val);
                              }
                            : null,
                      ),
                      AppSwitchTile(
                        icon: AppIcons.calendar,
                        title: AppStrings.weeklySummaryLabel,
                        desc: AppStrings.weeklySummaryDesc,
                        value: _weeklySummary,
                        onChanged: _enableAll
                            ? (val) async {
                                setState(() => _weeklySummary = val);
                                await _persistBool('notif_weekly_summary', val);
                              }
                            : null,
                        showBottomBorder: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Gap.h40,
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(String label, TimeOfDay time, VoidCallback onTap, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(left: 36.0.w, bottom: isLast ? 20.0.h : 12.0.h, top: 10.0.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0.r),
        child: Row(
          children: [
            Icon(AppIcons.clock, size: 14.0.w, color: context.appColorScheme.textMuted),
            Gap.w12,
            Expanded(
              child: Text(
                label,
                style: context.bodySm.copyWith(color: context.appColorScheme.textSecondary, fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0.w, vertical: 6.0.h),
              decoration: BoxDecoration(
                color: context.appColorScheme.cardBackground,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: context.appColorScheme.border),
              ),
              child: Text(
                time.format(context),
                style: context.bodySm.copyWith(fontWeight: FontWeight.w900, color: context.appColorScheme.textPrimary),
              ),
            ),
            Gap.w4,
          ],
        ),
      ),
    );
  }
}
