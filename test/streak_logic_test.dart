import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/user_profile.dart';

void main() {
  group('UserProfile Effective Streak Tests', () {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T')[0];
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = yesterday.toIso8601String().split('T')[0];
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    final twoDaysAgoStr = twoDaysAgo.toIso8601String().split('T')[0];

    test('Streak is active when lastActivityDate is today', () {
      final profile = UserProfile(
        uid: '123',
        streak: 5,
        lastActivityDate: todayStr,
        updatedAt: now,
        createdAt: now,
      );

      expect(profile.effectiveStreak, 5);
      expect(profile.isStreakActive, true);
    });

    test('Streak is active when lastActivityDate is yesterday', () {
      final profile = UserProfile(
        uid: '123',
        streak: 5,
        lastActivityDate: yesterdayStr,
        updatedAt: now,
        createdAt: now,
      );

      expect(profile.effectiveStreak, 5);
      expect(profile.isStreakActive, true);
    });

    test('Streak is broken when lastActivityDate is 2 days ago', () {
      final profile = UserProfile(
        uid: '123',
        streak: 5,
        lastActivityDate: twoDaysAgoStr,
        updatedAt: now,
        createdAt: now,
      );

      expect(profile.effectiveStreak, 0);
      expect(profile.isStreakActive, false);
    });

    test('Streak is 0 if no lastActivityDate', () {
      final profile = UserProfile(
        uid: '123',
        streak: 5,
        lastActivityDate: null,
        updatedAt: now,
        createdAt: now,
      );

      expect(profile.effectiveStreak, 0);
      expect(profile.isStreakActive, false);
    });
  });
}
