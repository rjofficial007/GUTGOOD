import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';
import 'package:gutgood/features/history/presentation/providers/saved_foods_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockHistoryRepository extends Mock implements HistoryRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockHistoryRepository repository;
  late MockAuthRepository auth;
  late AppStateServiceImpl state;
  late StreamController<AuthUser?> users;
  final food = ScanResult.fromMap(const {'productName': 'Greek  Yogurt'});
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  setUp(() {
    repository = MockHistoryRepository();
    auth = MockAuthRepository();
    state = AppStateServiceImpl();
    users = StreamController<AuthUser?>.broadcast(sync: true);
    when(() => auth.authStateChanges).thenAnswer((_) => users.stream);
    when(() => repository.getSavedFoods()).thenAnswer((_) async => [food]);
  });

  tearDown(() async => users.close());

  SavedFoodsProvider createProvider() => SavedFoodsProvider(
    repository: repository,
    appStateService: state,
    authRepository: auth,
  );

  test(
    'bookmark matching uses the same normalized identity as storage',
    () async {
      final provider = createProvider();
      addTearDown(provider.dispose);
      await flush();
      expect(provider.isSaved(' greek yogurt '), isTrue);
      expect(provider.isSaved('Other food'), isFalse);
      expect(provider.isSaved('Greek  Yogurt', barcode: '123'), isFalse);
    },
  );

  test('completion after disposal does not notify listeners', () async {
    final request = Completer<List<ScanResult>>();
    when(() => repository.getSavedFoods()).thenAnswer((_) => request.future);
    createProvider().dispose();
    expect(users.hasListener, isFalse);
    request.complete([food]);
    await flush();
  });

  test('older request cannot overwrite a newer refresh', () async {
    final old = Completer<List<ScanResult>>();
    when(() => repository.getSavedFoods()).thenAnswer((_) => old.future);
    final provider = createProvider();
    addTearDown(provider.dispose);
    when(() => repository.getSavedFoods()).thenAnswer((_) async => [food]);
    state.notifySavedFoodsUpdated();
    await flush();
    old.complete([]);
    await flush();
    expect(provider.savedFoods, [food]);
    expect(provider.isLoading, isFalse);
  });

  test('session reset clears foods and invalidates in-flight reads', () async {
    final provider = createProvider();
    addTearDown(provider.dispose);
    await flush();
    final old = Completer<List<ScanResult>>();
    when(() => repository.getSavedFoods()).thenAnswer((_) => old.future);
    state
      ..notifySavedFoodsUpdated()
      ..resetSession();
    expect(provider.savedFoods, isEmpty);
    old.complete([food]);
    await flush();
    expect(provider.savedFoods, isEmpty);
    expect(provider.isLoading, isFalse);
  });

  test('sign-out clears foods and sign-in loads the new account', () async {
    final provider = createProvider();
    addTearDown(provider.dispose);
    await flush();
    users.add(null);
    expect(provider.savedFoods, isEmpty);
    final nextFood = ScanResult.fromMap(const {'productName': 'Oats'});
    when(() => repository.getSavedFoods()).thenAnswer((_) async => [nextFood]);
    users.add(const AuthUser(uid: 'next', isAnonymous: false));
    await flush();
    expect(provider.savedFoods, [nextFood]);
  });

  test(
    'failed refresh ends loading and retains the last successful list',
    () async {
      final provider = createProvider();
      addTearDown(provider.dispose);
      await flush();
      when(
        () => repository.getSavedFoods(),
      ).thenAnswer((_) async => throw StateError('offline'));
      state.notifySavedFoodsUpdated();
      await flush();
      expect(provider.isLoading, isFalse);
      expect(provider.savedFoods, [food]);
    },
  );

  test('toggle performs one refresh and waits for its result', () async {
    final provider = createProvider();
    addTearDown(provider.dispose);
    await flush();
    when(() => repository.toggleSaveFood(food)).thenAnswer((_) async {});
    when(() => repository.getSavedFoods()).thenAnswer((_) async => []);
    await provider.toggleSave(food);
    expect(provider.savedFoods, isEmpty);
    verify(() => repository.getSavedFoods()).called(2);
  });

  test(
    'toggle finishing after session reset cannot reload old account data',
    () async {
      final provider = createProvider();
      addTearDown(provider.dispose);
      await flush();
      final write = Completer<void>();
      when(
        () => repository.toggleSaveFood(food),
      ).thenAnswer((_) => write.future);
      final pending = provider.toggleSave(food);
      state.resetSession();
      write.complete();
      await pending;
      expect(provider.savedFoods, isEmpty);
      verify(() => repository.getSavedFoods()).called(1);
    },
  );
}
