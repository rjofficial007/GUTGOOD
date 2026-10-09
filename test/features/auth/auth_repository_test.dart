import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gutgood/infrastructure/firebase/analytics_service.dart';
import 'package:gutgood/infrastructure/firebase/crashlytics_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/notification_service.dart';
import 'package:gutgood/infrastructure/payments/purchase_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFirebaseAuth extends Mock implements firebase.FirebaseAuth {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockAuthFirestoreService extends Mock implements AuthFirestoreService {}

class MockPurchaseService extends Mock implements PurchaseService {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockAppStateService extends Mock implements AppStateService {}

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockCrashlyticsService extends Mock implements CrashlyticsService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockUserCredential extends Mock implements firebase.UserCredential {}

class MockUser extends Mock implements firebase.User {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock implements HttpsCallableResult {}

void main() {
  late AuthRepositoryImpl repository;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockAuthFirestoreService mockFirestoreService;
  late MockPurchaseService mockPurchaseService;
  late MockSharedPreferences mockSharedPreferences;
  late MockAppStateService mockAppStateService;
  late MockFirebaseFunctions mockFirebaseFunctions;
  late MockAnalyticsService mockAnalyticsService;
  late MockCrashlyticsService mockCrashlyticsService;
  late MockNotificationService mockNotificationService;

  setUpAll(() {
    registerFallbackValue(UserProfile(uid: '', updatedAt: DateTime.now(), createdAt: DateTime.now()));
  });

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockFirestoreService = MockAuthFirestoreService();
    mockPurchaseService = MockPurchaseService();
    mockSharedPreferences = MockSharedPreferences();
    mockAppStateService = MockAppStateService();
    mockFirebaseFunctions = MockFirebaseFunctions();
    mockAnalyticsService = MockAnalyticsService();
    mockCrashlyticsService = MockCrashlyticsService();
    mockNotificationService = MockNotificationService();

    repository = AuthRepositoryImpl(
      firebaseAuth: mockFirebaseAuth,
      googleSignIn: mockGoogleSignIn,
      firestoreService: mockFirestoreService,
      purchaseService: mockPurchaseService,
      prefs: mockSharedPreferences,
      appStateService: mockAppStateService,
      firebaseFunctions: mockFirebaseFunctions,
      analyticsService: mockAnalyticsService,
      crashlyticsService: mockCrashlyticsService,
      notificationService: mockNotificationService,
    );
  });

  group('AuthRepository', () {
    test('signInAnonymously performs Firebase sign in and updates profile', () async {
      final mockUser = MockUser();
      final mockCredential = MockUserCredential();

      when(() => mockUser.uid).thenReturn('anon-123');
      when(() => mockUser.email).thenReturn(null);
      when(() => mockUser.isAnonymous).thenReturn(true);
      when(() => mockUser.displayName).thenReturn(null);
      when(() => mockUser.providerData).thenReturn(const []);
      when(() => mockCredential.user).thenReturn(mockUser);

      firebase.User? currentUser;
      when(() => mockFirebaseAuth.currentUser).thenAnswer((_) => currentUser);
      when(() => mockFirebaseAuth.signInAnonymously()).thenAnswer((_) async {
        currentUser = mockUser;
        return mockCredential;
      });
      when(() => mockFirestoreService.saveUserProfile(any())).thenAnswer((_) async {});
      when(() => mockSharedPreferences.setBool(any(), any())).thenAnswer((_) async => true);
      when(() => mockAppStateService.notifyProfileUpdated()).thenAnswer((_) {});
      when(() => mockAnalyticsService.logEvent(name: any(named: 'name'))).thenAnswer((_) async {});
      when(() => mockAnalyticsService.setUserId(any())).thenAnswer((_) async {});
      when(() => mockCrashlyticsService.setUserId(any())).thenAnswer((_) async {});

      await repository.signInAnonymously();

      verify(() => mockFirebaseAuth.signInAnonymously()).called(1);
      verify(() => mockFirestoreService.saveUserProfile(any())).called(1);
      verify(() => mockSharedPreferences.setBool('onboarded', false)).called(1);
    });

    test('signInAnonymously fails when profile creation fails', () async {
      final mockUser = MockUser();
      final mockCredential = MockUserCredential();

      when(() => mockUser.uid).thenReturn('anon-123');
      when(() => mockUser.email).thenReturn(null);
      when(() => mockUser.isAnonymous).thenReturn(true);
      when(() => mockUser.displayName).thenReturn(null);
      when(() => mockUser.providerData).thenReturn(const []);
      when(() => mockCredential.user).thenReturn(mockUser);

      firebase.User? currentUser;
      when(() => mockFirebaseAuth.currentUser).thenAnswer((_) => currentUser);
      when(() => mockFirebaseAuth.signInAnonymously()).thenAnswer((_) async {
        currentUser = mockUser;
        return mockCredential;
      });
      when(() => mockFirestoreService.saveUserProfile(any())).thenThrow(StateError('write failed'));

      await expectLater(repository.signInAnonymously(), throwsA(isA<StateError>()));
      verifyNever(() => mockSharedPreferences.setBool(any(), any()));
      verifyNever(() => mockAppStateService.notifyProfileUpdated());
    });

    test('existing anonymous Auth user repairs a missing Firestore profile', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('anon-123');
      when(() => mockUser.email).thenReturn(null);
      when(() => mockUser.isAnonymous).thenReturn(true);
      when(() => mockUser.displayName).thenReturn(null);
      when(() => mockUser.photoURL).thenReturn(null);
      when(() => mockUser.providerData).thenReturn(const []);
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockFirestoreService.createUserProfileIfMissing(any())).thenAnswer((_) async {});

      await repository.signInAnonymously();

      verify(() => mockFirestoreService.createUserProfileIfMissing(any())).called(1);
      verifyNever(() => mockFirebaseAuth.signInAnonymously());
    });

    test('signOut cleans up services and session', () async {
      final mockUser = MockUser();
      when(() => mockUser.isAnonymous).thenReturn(false);
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

      when(() => mockAppStateService.setLoggingOut(any())).thenAnswer((_) {});
      when(() => mockFirestoreService.clearFcmToken()).thenAnswer((_) async {});
      when(() => mockNotificationService.cancelAll()).thenAnswer((_) async {});
      when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async {});
      when(() => mockPurchaseService.logout()).thenAnswer((_) async {});
      when(() => mockSharedPreferences.getKeys()).thenReturn(const {});
      when(() => mockAppStateService.resetSession()).thenAnswer((_) {});

      await repository.signOut();

      verify(() => mockFirebaseAuth.signOut()).called(1);
      verify(() => mockPurchaseService.logout()).called(1);
      verify(() => mockAppStateService.resetSession()).called(1);
    });

    group('Merging', () {
      test('confirmMerge calls cloud function and updates local state', () async {
        final mockCallable = MockHttpsCallable();
        final mockResult = MockHttpsCallableResult();

        when(() => mockFirebaseFunctions.httpsCallable(any())).thenReturn(mockCallable);
        when(() => mockCallable.call(any())).thenAnswer((_) async => mockResult);
        when(() => mockResult.data).thenReturn(const {'alreadyMerged': false});

        when(() => mockAppStateService.setMigrating(any())).thenAnswer((_) {});
        when(() => mockAppStateService.resetSession()).thenAnswer((_) {});
        when(() => mockSharedPreferences.setBool(any(), any())).thenAnswer((_) async => true);
        when(() => mockSharedPreferences.remove(any())).thenAnswer((_) async => true);

        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        await repository.confirmMerge('anon-uid', 'perm-uid');

        verify(() => mockFirebaseFunctions.httpsCallable('mergeAnonymousAccount')).called(1);
        verify(() => mockAppStateService.resetSession()).called(1);
        verify(() => mockSharedPreferences.setBool('onboarded', true)).called(1);
      });
    });

    test('deleteAccount purges Firestore data and clears local session including streak and onboarding', () async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('user-123');
      when(() => mockUser.isAnonymous).thenReturn(false);
      when(() => mockUser.providerData).thenReturn(const []);
      when(mockUser.delete).thenAnswer((_) async {});

      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockAppStateService.setLoggingOut(any())).thenAnswer((_) {});
      when(() => mockAppStateService.resetSession()).thenAnswer((_) {});
      when(() => mockFirestoreService.clearFcmToken()).thenAnswer((_) async {});
      when(() => mockNotificationService.cancelAll()).thenAnswer((_) async {});
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async {});
      when(() => mockPurchaseService.logout()).thenAnswer((_) async {});
      when(() => mockFirestoreService.deleteUserData()).thenAnswer((_) async {});
      when(() => mockSharedPreferences.getKeys()).thenReturn({'streak_current', 'streak_longest', 'streak_last_active_date', 'onboarded', 'theme_mode'});
      when(() => mockSharedPreferences.remove(any())).thenAnswer((_) async => true);
      when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});

      await repository.deleteAccount();

      verify(() => mockFirestoreService.deleteUserData()).called(1);
      verify(mockUser.delete).called(1);
      verify(() => mockFirebaseAuth.signOut()).called(1);
      verify(() => mockSharedPreferences.remove('streak_current')).called(1);
      verify(() => mockSharedPreferences.remove('streak_longest')).called(1);
      verify(() => mockSharedPreferences.remove('streak_last_active_date')).called(1);
      verify(() => mockSharedPreferences.remove('onboarded')).called(1);
      verifyNever(() => mockSharedPreferences.remove('theme_mode'));
    });
  });
}
