import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/app/theme/app_theme.dart';
import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/models/insights/food_swap.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';
import 'package:gutgood/features/insights/presentation/pages/better_swaps_screen.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/swap_recommendation_firestore_service.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class MockAuthFirestoreService extends Mock implements AuthFirestoreService {}

class MockSwapRecommendationFirestoreService extends Mock
    implements SwapRecommendationFirestoreService {}

void main() {
  late MockChatRepository chatRepository;
  late MockAuthFirestoreService authFirestoreService;
  late MockSwapRecommendationFirestoreService swapCache;
  var cacheHit = true;

  const alternative = SwapAlternative(
    foodId: 'quinoa',
    name: 'Quinoa',
    reason: 'A whole-grain alternative with a similar texture.',
  );

  setUp(() async {
    await sl.reset();
    chatRepository = MockChatRepository();
    authFirestoreService = MockAuthFirestoreService();
    swapCache = MockSwapRecommendationFirestoreService();
    cacheHit = true;
    sl
      ..registerSingleton<ChatRepository>(chatRepository)
      ..registerSingleton<AuthFirestoreService>(authFirestoreService)
      ..registerSingleton<SwapRecommendationFirestoreService>(swapCache);
    when(authFirestoreService.getUserMetadata).thenAnswer((_) async => null);
    when(
      () => swapCache.getCachedSwaps(
        sourceFoodName: any(named: 'sourceFoodName'),
        requestContext: any(named: 'requestContext'),
        promptVersion: any(named: 'promptVersion'),
      ),
    ).thenAnswer((_) async => cacheHit ? const [alternative] : null);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('loads cached swaps without requesting another AI response', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            Responsive.init(context);
            return const BetterSwapsScreen(
              swap: FoodSwap(
                id: 'oats',
                source: SwapSource(foodId: 'oats', name: 'Steel Cut Oats'),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quinoa'), findsOneWidget);
    verify(
      () => swapCache.getCachedSwaps(
        sourceFoodName: 'Steel Cut Oats',
        requestContext: any(named: 'requestContext'),
        promptVersion: any(named: 'promptVersion'),
      ),
    ).called(1);
    verifyNever(
      () => chatRepository.sendMessageStream(
        systemInstruction: any(named: 'systemInstruction'),
        history: const [],
        userText: any(named: 'userText'),
        intent: any(named: 'intent'),
        promptVersion: any(named: 'promptVersion'),
      ),
    );
  });

  testWidgets('generates and caches swaps after a cache miss', (tester) async {
    cacheHit = false;
    when(() => chatRepository.lastResponseTruncated).thenReturn(false);
    when(
      () => chatRepository.sendMessageStream(
        systemInstruction: any(named: 'systemInstruction'),
        history: any(named: 'history'),
        userText: any(named: 'userText'),
        intent: any(named: 'intent'),
        promptVersion: any(named: 'promptVersion'),
      ),
    ).thenAnswer(
      (_) => Stream.value(
        jsonEncode([
          {
            'name': 'Quinoa',
            'replaces': 'Steel Cut Oats',
            'reason': 'A whole-grain alternative with a similar texture.',
            'category': 'Grain',
            'tag': 'Whole Grain',
            'imageKeyword': 'quinoa',
            'imageUrl': null,
            'barcode': null,
            'nutriscore': null,
            'impactLevel': null,
            'benefitTags': ['Whole grain'],
            'structuredBenefits': [],
            'whyBetterOption': 'A source-specific comparison.',
            'nutrition': {
              'calories': null,
              'protein': null,
              'totalFat': null,
              'carbohydrates': null,
              'fiber': null,
              'sugars': null,
              'saturatedFat': null,
              'sodium': null,
              'servingSize': null,
              'basis': null,
            },
          },
        ]),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            Responsive.init(context);
            return const BetterSwapsScreen(
              swap: FoodSwap(
                id: 'oats',
                source: SwapSource(foodId: 'oats', name: 'Steel Cut Oats'),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    verify(
      () => chatRepository.sendMessageStream(
        systemInstruction: any(named: 'systemInstruction'),
        history: const [],
        userText: any(named: 'userText'),
        intent: 'meal_swaps',
        promptVersion: any(named: 'promptVersion'),
      ),
    ).called(1);
    verify(
      () => swapCache.saveSwaps(
        sourceFoodName: 'Steel Cut Oats',
        requestContext: any(named: 'requestContext'),
        promptVersion: any(named: 'promptVersion'),
        alternatives: any(named: 'alternatives'),
      ),
    ).called(1);
  });
}
