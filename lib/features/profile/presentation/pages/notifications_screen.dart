import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/notification_preferences.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/model_utils.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final data = cloudPrefs ?? {};

    setState(() {
      _enableAll = ModelUtils.parseBool(data['enableAll'], defaultValue: prefs.getBool('notif_enable_all') ?? true);
      _mealReminders = ModelUtils.parseBool(data['mealReminders'], defaultValue: prefs.getBool('notif_meal_reminders') ?? true);
      _noMealLoggedReminder = ModelUtils.parseBool(data['noMealLoggedReminder'], defaultValue: prefs.getBool('notif_no_meal_logged') ?? true);
      _dailyReminder = ModelUtils.parseBool(data['dailyReminder'], defaultValue: prefs.getBool('notif_daily_reminder') ?? true);
      _insightUpdates = ModelUtils.parseBool(data['insightUpdates'], defaultValue: prefs.getBool('notif_insight_updates') ?? true);
      _weeklySummary = ModelUtils.parseBool(data['weeklySummary'], defaultValue: prefs.getBool('notif_weekly_summary') ?? true);

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
    final picked = await BottomSheetHelper.showTimePickerSheet(context: context, title: AppStrings.selectTime, initialTime: initial, backgroundColor: AppPalette.transparent);
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.appColorScheme.cardBackground,
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
              showCard: false,
              topPadding: 0,
              children: [
                _ModernSettingCard(
                  child: AppSwitchTile(title: AppStrings.enableNotifications, desc: AppStrings.receiveUpdates, value: _enableAll, onChanged: _toggleEnableAll, showBottomBorder: false),
                ),
              ],
            ),

            GutSection(
              title: AppStrings.reminders,
              showCard: false,
              opacity: _enableAll ? 1.0 : 0.4,
              children: [
                IgnorePointer(
                  ignoring: !_enableAll,
                  child: Column(
                    children: [
                      _ModernSettingCard(
                        child: AppSwitchTile(
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
                          showBottomBorder: false,
                        ),
                      ),
                      ClipRect(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: (_mealReminders && _enableAll)
                              ? Padding(
                                  padding: EdgeInsets.only(top: AppSizes.p4),
                                  child: Column(
                                    children: [
                                      _ModernTimeTile(
                                        label: AppStrings.breakfastTime,
                                        time: _breakfastTime,
                                        icon: AppIcons.sun,
                                        onTap: () => _pickTime(_breakfastTime, (t) async {
                                          setState(() => _breakfastTime = t);
                                          await _persistTime('notif_breakfast_time', t);
                                          await _applyMealReminderSchedule();
                                        }),
                                      ),
                                      _ModernTimeTile(
                                        label: AppStrings.lunchTime,
                                        time: _lunchTime,
                                        icon: AppIcons.utensils,
                                        onTap: () => _pickTime(_lunchTime, (t) async {
                                          setState(() => _lunchTime = t);
                                          await _persistTime('notif_lunch_time', t);
                                          await _applyMealReminderSchedule();
                                        }),
                                      ),
                                      _ModernTimeTile(
                                        label: AppStrings.dinnerTime,
                                        time: _dinnerTime,
                                        icon: AppIcons.moon,
                                        onTap: () => _pickTime(_dinnerTime, (t) async {
                                          setState(() => _dinnerTime = t);
                                          await _persistTime('notif_dinner_time', t);
                                          await _applyMealReminderSchedule();
                                        }),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                      ),
                      _ModernSettingCard(
                        child: AppSwitchTile(
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
                          showBottomBorder: false,
                        ),
                      ),
                      _ModernSettingCard(
                        child: AppSwitchTile(
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
                          showBottomBorder: false,
                        ),
                      ),
                      ClipRect(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: (_dailyReminder && _enableAll)
                              ? Padding(
                                  padding: EdgeInsets.only(top: AppSizes.p4),
                                  child: _ModernTimeTile(
                                    label: AppStrings.reminderTime,
                                    time: _dailyReminderTime,
                                    icon: AppIcons.clock,
                                    onTap: () => _pickTime(_dailyReminderTime, (t) async {
                                      setState(() => _dailyReminderTime = t);
                                      await _persistTime('notif_daily_time', t);
                                      await _applyDailyReminderSchedule();
                                    }),
                                  ),
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
              showCard: false,
              opacity: _enableAll ? 1.0 : 0.4,
              children: [
                IgnorePointer(
                  ignoring: !_enableAll,
                  child: Column(
                    children: [
                      _ModernSettingCard(
                        child: AppSwitchTile(
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
                          showBottomBorder: false,
                        ),
                      ),
                      _ModernSettingCard(
                        child: AppSwitchTile(
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
}

class _ModernSettingCard extends StatelessWidget {
  const _ModernSettingCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
      margin: EdgeInsets.only(bottom: AppSizes.p12),
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p20),
      decoration: BoxDecoration(
        color: context.appColorScheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r24),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
      ),
      child: child,
    );
}

class _ModernTimeTile extends StatelessWidget {

  const _ModernTimeTile({required this.label, required this.time, required this.icon, required this.onTap});
  final String label;
  final TimeOfDay time;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
      margin: EdgeInsets.only(bottom: AppSizes.p12),
      decoration: BoxDecoration(
        color: context.appColorScheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r24),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.r24),
          child: Padding(
            padding: EdgeInsets.all(AppSizes.p20),
            child: Row(
              children: [
                Container(
                  width: AppSizes.w52,
                  height: AppSizes.w52,
                  decoration: BoxDecoration(color: context.appColorScheme.textPrimary, borderRadius: BorderRadius.circular(AppSizes.r18)),
                  child: Icon(icon, color: context.appColorScheme.cardBackground, size: AppSizes.icon24),
                ),
                Gap.w16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: AppSizes.s9),
                      ),
                      Gap.h4,
                      Text(
                        time.format(context),
                        style: context.headingMd.copyWith(color: context.appColorScheme.textPrimary, fontWeight: FontWeight.w900, fontSize: AppSizes.s22),
                      ),
                    ],
                  ),
                ),
                Icon(AppIcons.chevronRight, color: context.appColorScheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
}
