import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/insights/food_swap.dart';
import 'package:gutgood/infrastructure/firebase/firestore/swap_recommendation_firestore_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockFirestore extends Mock implements FirebaseFirestore {}

class MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocument extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockAuth auth;
  late MockUser user;
  late MockFirestore db;
  late MockCollection profiles;
  late MockDocument profile;
  late MockCollection cache;
  late MockDocument cacheDoc;
  late MockSnapshot snapshot;
  late SwapRecommendationFirestoreServiceImpl service;
  Map<String, dynamic>? savedData;
  String? savedDocumentId;

  const context = <String, Object?>{
    'goals': ['fiber'],
    'pattern': {'reaction': 'Bloating', 'observations': 3},
  };
  const alternative = SwapAlternative(
    foodId: 'quinoa',
    name: 'Quinoa',
    replaces: 'steel cut oats',
    reason: 'A whole-grain option with a similar texture.',
    category: 'Grain',
    imageKeyword: 'quinoa',
    benefitTags: ['Whole grain'],
    benefits: [
      SwapBenefit(
        title: 'Whole grain',
        description: 'Contains fiber.',
        icon: 'leaf',
      ),
    ],
    whyBetterOption: 'A source-specific comparison with tradeoffs.',
    nutrition: SwapNutrition(
      calories: 120,
      protein: '4 g',
      carbohydrates: '21 g',
      fiber: '3 g',
      basis: 'per serving',
    ),
  );

  setUp(() {
    auth = MockAuth();
    user = MockUser();
    db = MockFirestore();
    profiles = MockCollection();
    profile = MockDocument();
    cache = MockCollection();
    cacheDoc = MockDocument();
    snapshot = MockSnapshot();
    savedData = null;
    savedDocumentId = null;

    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('user-1');
    when(() => db.collection('user_profiles')).thenReturn(profiles);
    when(() => profiles.doc('user-1')).thenReturn(profile);
    when(() => profile.collection('swap_recommendations')).thenReturn(cache);
    when(() => cache.doc(any())).thenAnswer((invocation) {
      savedDocumentId = invocation.positionalArguments.single as String;
      return cacheDoc;
    });
    when(() => cacheDoc.get()).thenAnswer((_) async => snapshot);
    when(() => snapshot.exists).thenReturn(true);
    when(snapshot.data).thenAnswer((_) => savedData);
    when(() => cacheDoc.set(any())).thenAnswer((invocation) async {
      savedData = Map<String, dynamic>.from(
        invocation.positionalArguments.first as Map,
      );
    });
    service = SwapRecommendationFirestoreServiceImpl(auth: auth, db: db);
  });

  test(
    'saves and reuses source-food swaps while invalidating changed context',
    () async {
      await service.saveSwaps(
        sourceFoodName: 'Steel Cut Oats',
        requestContext: context,
        promptVersion: 1,
        alternatives: const [alternative],
      );

      expect(savedDocumentId, isNotNull);
      final sourceDocumentId = savedDocumentId;
      expect(savedData?['sourceFoodName'], 'Steel Cut Oats');
      expect(savedData?['alternatives'], hasLength(1));
      final sameContext = await service.getCachedSwaps(
        sourceFoodName: 'steel   cut oats',
        requestContext: const {
          'pattern': {'observations': 3, 'reaction': 'Bloating'},
          'goals': ['fiber'],
        },
        promptVersion: 1,
      );
      expect(sameContext, [alternative]);
      expect(savedDocumentId, sourceDocumentId);

      final changedContext = await service.getCachedSwaps(
        sourceFoodName: 'Steel Cut Oats',
        requestContext: const {
          'goals': ['low sugar'],
        },
        promptVersion: 1,
      );
      expect(changedContext, isNull);
      expect(savedDocumentId, sourceDocumentId);
    },
  );

  test('a missing profile never reads or writes a shared cache', () async {
    when(() => auth.currentUser).thenReturn(null);

    expect(
      await service.getCachedSwaps(
        sourceFoodName: 'Oats',
        requestContext: context,
        promptVersion: 1,
      ),
      isNull,
    );
    await service.saveSwaps(
      sourceFoodName: 'Oats',
      requestContext: context,
      promptVersion: 1,
      alternatives: const [alternative],
    );
    verifyNever(() => db.collection('user_profiles'));
  });
}
