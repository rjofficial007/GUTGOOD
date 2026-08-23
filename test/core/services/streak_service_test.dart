import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/services/streak_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late StreakServiceImpl service;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    service = StreakServiceImpl(prefs: mockPrefs);
  });

  group('StreakService', () {
    test('First activity should initialize streak to 1', () async {
      when(() => mockPrefs.getInt('streak_current')).thenReturn(null);
      when(() => mockPrefs.getString('streak_last_active_date')).thenReturn(null);
      when(() => mockPrefs.getInt('streak_longest')).thenReturn(0);
      
      when(() => mockPrefs.setInt('streak_current', 1)).thenAnswer((_) async => true);
      when(() => mockPrefs.setString('streak_last_active_date', any())).thenAnswer((_) async => true);
      when(() => mockPrefs.setInt('streak_longest', 1)).thenAnswer((_) async => true);

      await service.markActivityToday();

      verify(() => mockPrefs.setInt('streak_current', 1)).called(1);
    });

    test('Multiple activities on same day should not increment streak', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      when(() => mockPrefs.getInt('streak_current')).thenReturn(1);
      when(() => mockPrefs.getString('streak_last_active_date')).thenReturn(today);

      await service.markActivityToday();

      verifyNever(() => mockPrefs.setInt(any(), any()));
    });

    test('Activity on consecutive day should increment streak', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
      
      when(() => mockPrefs.getInt('streak_current')).thenReturn(5);
      when(() => mockPrefs.getString('streak_last_active_date')).thenReturn(yesterday);
      when(() => mockPrefs.getInt('streak_longest')).thenReturn(5);

      when(() => mockPrefs.setInt('streak_current', 6)).thenAnswer((_) async => true);
      when(() => mockPrefs.setString('streak_last_active_date', any())).thenAnswer((_) async => true);
      when(() => mockPrefs.setInt('streak_longest', 6)).thenAnswer((_) async => true);

      await service.markActivityToday();

      verify(() => mockPrefs.setInt('streak_current', 6)).called(1);
    });

    test('Activity after missed day should reset streak to 1', () async {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2)).toIso8601String().split('T')[0];
      
      when(() => mockPrefs.getInt('streak_current')).thenReturn(10);
      when(() => mockPrefs.getString('streak_last_active_date')).thenReturn(twoDaysAgo);
      when(() => mockPrefs.getInt('streak_longest')).thenReturn(10);

      when(() => mockPrefs.setInt('streak_current', 1)).thenAnswer((_) async => true);
      when(() => mockPrefs.setString('streak_last_active_date', any())).thenAnswer((_) async => true);

      await service.markActivityToday();

      verify(() => mockPrefs.setInt('streak_current', 1)).called(1);
    });

    test('syncWithRemote should update local if remote is newer', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
      
      when(() => mockPrefs.getString('streak_last_active_date')).thenReturn(yesterday);
      when(() => mockPrefs.getInt('streak_current')).thenReturn(1);
      when(() => mockPrefs.getInt('streak_longest')).thenReturn(1);

      when(() => mockPrefs.setInt('streak_current', 5)).thenAnswer((_) async => true);
      when(() => mockPrefs.setString('streak_last_active_date', today)).thenAnswer((_) async => true);
      when(() => mockPrefs.setInt('streak_longest', 10)).thenAnswer((_) async => true);

      await service.syncWithRemote(remoteStreak: 5, remoteLongest: 10, remoteLastDate: today);

      verify(() => mockPrefs.setInt('streak_current', 5)).called(1);
      verify(() => mockPrefs.setInt('streak_longest', 10)).called(1);
    });

    test('currentStreak should return 0 if last activity was more than 1 day ago', () async {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2)).toIso8601String().split('T')[0];
      
      when(() => mockPrefs.getInt('streak_current')).thenReturn(10);
      when(() => mockPrefs.getString('streak_last_active_date')).thenReturn(twoDaysAgo);

      expect(service.currentStreak, 0);
    });

    test('currentStreak should return stored value if last activity was yesterday', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
      
      when(() => mockPrefs.getInt('streak_current')).thenReturn(10);
      when(() => mockPrefs.getString('streak_last_active_date')).thenReturn(yesterday);

      expect(service.currentStreak, 10);
    });
  });
}
