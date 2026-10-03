import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/features/auth/data/services/usage_service.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/usage_firestore_service.dart';
import 'package:gutgood/infrastructure/payments/purchase_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAuthFirestoreService extends Mock implements AuthFirestoreService {}

class MockUsageFirestoreService extends Mock implements UsageFirestoreService {}

class MockPurchaseService extends Mock implements PurchaseService {}

void main() {
  late MockAuthRepository authRepository;
  late MockAuthFirestoreService authFirestoreService;
  late MockUsageFirestoreService usageFirestoreService;
  late MockPurchaseService purchaseService;
  late UsageServiceImpl usage;

  UserProfile profile({bool premium = false}) => UserProfile(uid: 'u1', isPremium: premium, updatedAt: DateTime.now(), createdAt: DateTime.now());

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    authRepository = MockAuthRepository();
    authFirestoreService = MockAuthFirestoreService();
    usageFirestoreService = MockUsageFirestoreService();
    purchaseService = MockPurchaseService();
    usage = UsageServiceImpl(
      authRepository: authRepository,
      authFirestoreService: authFirestoreService,
      usageFirestoreService: usageFirestoreService,
      purchaseService: purchaseService,
      prefs: await SharedPreferences.getInstance(),
    );

    when(() => purchaseService.isPremium).thenReturn(false);
    when(() => authRepository.currentUser).thenReturn(const AuthUser(uid: 'u1', isAnonymous: false));
    when(() => authFirestoreService.getUserMetadata()).thenAnswer((_) async => profile());
  });

  group('UsageService.canSummarize (K-6)', () {
    test('allows summaries while system quota is healthy', () async {
      when(() => usageFirestoreService.getUsageToday()).thenAnswer((_) async => const DailyUsage(uid: 'u1', date: '2026-09-09', systemCount: 5));

      expect(await usage.canSummarize(), isTrue);
    });

    test('blocks summaries inside the classification reserve', () async {
      when(() => usageFirestoreService.getUsageToday()).thenAnswer((_) async => const DailyUsage(uid: 'u1', date: '2026-09-09', systemCount: 18));

      expect(await usage.canSummarize(), isFalse);
    });

    test('premium bypasses the gate', () async {
      when(() => purchaseService.isPremium).thenReturn(true);

      expect(await usage.canSummarize(), isTrue);
      verifyNever(() => usageFirestoreService.getUsageToday());
    });

    test('guests use the lifetime system count against the guest cap', () async {
      when(() => authRepository.currentUser).thenReturn(const AuthUser(uid: 'g1', isAnonymous: true));
      when(() => usageFirestoreService.getLifetimeUsage()).thenAnswer((_) async => const DailyUsage(uid: 'g1', date: 'lifetime', systemCount: 8));

      expect(await usage.canSummarize(), isFalse);
    });
  });
}
