import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';
import 'package:gutgood/features/history/presentation/providers/history_notifier.dart';
import 'package:mocktail/mocktail.dart';

class MockHistoryRepository extends Mock implements HistoryRepository {}

class MockAppStateService extends Mock implements AppStateService {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

Stream<User?> _emptyAuthStateChanges(Invocation _) => const Stream<User?>.empty();

void main() {
  test('Meals filter shows scan-linked meal logs without duplicating them in All', () async {
    final repository = MockHistoryRepository();
    final appState = MockAppStateService();
    final auth = MockFirebaseAuth();
    final now = DateTime(2026, 10, 8, 12);
    final scan = ScanResult(
      productName: 'Chicken Bowl',
      brand: '',
      score: 80,
      impactType: ImpactType.positive,
      impact: '',
      scanId: 'scan-1',
      createdAt: now,
    );
    final meals = [
      MealLog(items: const ['Chicken Bowl'], scanId: 'scan-1', createdAt: now),
      MealLog(items: const ['Homemade Soup'], createdAt: now.subtract(const Duration(hours: 1))),
    ];

    when(() => appState.chatUpdated).thenReturn(ValueNotifier(false));
    when(() => appState.sessionReset).thenReturn(ValueNotifier(false));
    when(auth.authStateChanges).thenAnswer(_emptyAuthStateChanges);
    when(() => repository.getScanHistory(limit: any(named: 'limit'))).thenAnswer((_) async => [scan]);
    when(() => repository.getLabelScans(limit: any(named: 'limit'))).thenAnswer((_) async => []);
    when(() => repository.getMenuScans(limit: any(named: 'limit'))).thenAnswer((_) async => []);
    when(() => repository.getRecentMealLogs(limit: any(named: 'limit'))).thenAnswer((_) async => meals);
    when(() => repository.getRecentSymptomLogs(limit: any(named: 'limit'))).thenAnswer((_) async => []);

    final notifier = HistoryNotifier(repository: repository, appStateService: appState, auth: auth);
    await notifier.refreshAll();

    notifier.setFilter(HistoryFilter.meals);
    expect(notifier.filteredEntries, hasLength(2));
    expect(notifier.filteredEntries.every((entry) => entry.type == JournalEntryType.meal), isTrue);

    notifier.setFilter(HistoryFilter.all);
    expect(notifier.filteredEntries, hasLength(2));
    expect(notifier.filteredEntries.where((entry) => entry.type == JournalEntryType.meal), hasLength(1));

    notifier.dispose();
  });
}
