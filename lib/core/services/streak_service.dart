import 'package:gutgood/core/utils/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class StreakService {
  int get currentStreak;
  int get longestStreak;
  String? get lastActiveDate;
  
  /// Increments streak if it's a new day, or initializes it.
  /// Does nothing if already active today.
  Future<void> markActivityToday();
  
  /// Reconciles local streak with cloud profile data.
  Future<void> syncWithRemote({required int remoteStreak, required int remoteLongest, required String? remoteLastDate});
}

class StreakServiceImpl implements StreakService {
  StreakServiceImpl({required SharedPreferences prefs}) : _prefs = prefs;
  
  final SharedPreferences _prefs;
  
  static const _keyStreak = 'streak_current';
  static const _keyLongest = 'streak_longest';
  static const _keyLastDate = 'streak_last_active_date';

  @override
  int get currentStreak {
    final rawStreak = _prefs.getInt(_keyStreak) ?? 0;
    final lastDate = lastActiveDate;
    if (lastDate == null || rawStreak == 0) return 0;

    try {
      final last = DateTime.parse(lastDate);
      final lastMidnight = DateTime(last.year, last.month, last.day);
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final diff = todayMidnight.difference(lastMidnight).inDays;

      if (diff > 1) return 0;
      return rawStreak;
    } catch (_) {
      return 0;
    }
  }

  @override
  int get longestStreak => _prefs.getInt(_keyLongest) ?? 0;

  @override
  String? get lastActiveDate => _prefs.getString(_keyLastDate);

  @override
  Future<void> markActivityToday() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastDate = lastActiveDate;
    
    if (lastDate == today) {
      AppLogger.debug('StreakService: Already active today ($today)');
      return;
    }

    var nextStreak = 1;
    
    if (lastDate != null) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
      
      if (lastDate == yesterday) {
        nextStreak = currentStreak + 1;
      }
    }

    AppLogger.info('StreakService: Activity recorded! Streak: $nextStreak (Day: $today)');
    
    await _prefs.setInt(_keyStreak, nextStreak);
    await _prefs.setString(_keyLastDate, today);
    
    if (nextStreak > longestStreak) {
      await _prefs.setInt(_keyLongest, nextStreak);
    }
  }

  @override
  Future<void> syncWithRemote({required int remoteStreak, required int remoteLongest, required String? remoteLastDate}) async {
    if (remoteLastDate == null) return;
    
    final localLastDate = lastActiveDate;
    
    // If remote has a newer activity date, or the same date but a higher streak, trust remote.
    // This handles multi-device sync.
    var shouldUpdate = false;
    
    if (localLastDate == null || remoteLastDate.compareTo(localLastDate) > 0) {
      shouldUpdate = true;
    } else if (remoteLastDate == localLastDate && remoteStreak > currentStreak) {
      shouldUpdate = true;
    }
    
    if (shouldUpdate) {
      AppLogger.debug('StreakService: Syncing with remote data ($remoteLastDate, streak: $remoteStreak)');
      await _prefs.setInt(_keyStreak, remoteStreak);
      await _prefs.setString(_keyLastDate, remoteLastDate);
    }
    
    if (remoteLongest > longestStreak) {
      await _prefs.setInt(_keyLongest, remoteLongest);
    }
  }
}
