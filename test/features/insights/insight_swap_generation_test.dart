import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/client/ai_client.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/features/insights/data/repositories/insight_repository_impl.dart';
import 'package:gutgood/infrastructure/firebase/analytics_service.dart';
import 'package:gutgood/infrastructure/firebase/crashlytics_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/chat_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/insight_firestore_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Ai extends Mock implements AiClient {}

class _History extends Mock implements HistoryFirestoreService {}

class _Insights extends Mock implements InsightFirestoreService {}

class _Chat extends Mock implements ChatFirestoreService {}

class _Analytics extends Mock implements AnalyticsService {}

class _Crashlytics extends Mock implements CrashlyticsService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('retries missing swaps and refuses completion when the retry also omits them', () async {
    registerFallbackValue(DateTime.now());
    final ai = _Ai();
    final history = _History();
    final analytics = _Analytics();
    final crashlytics = _Crashlytics();
    SharedPreferences.setMockInitialValues({});
    final repository = InsightRepositoryImpl(
      historyFirestoreService: history,
      insightFirestoreService: _Insights(),
      chatFirestoreService: _Chat(),
      aiService: ai,
      prefs: await SharedPreferences.getInstance(),
      analyticsService: analytics,
      crashlyticsService: crashlytics,
    );
    when(() => history.getRecentScans(since: any(named: 'since'))).thenAnswer((_) async => []);
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
    when(() => crashlytics.recordError(any(), any(), reason: any(named: 'reason'))).thenAnswer((_) async {});
    final alternatives = ['Grilled chicken sandwich', 'Baked chicken sandwich', 'Grilled fish sandwich', 'Roasted vegetable sandwich']
        .map(
          (name) => {
            'foodId': name.replaceAll(' ', '_'),
            'name': name,
            'reason': 'Different preparation to compare.',
            'category': 'Meals & Bowls',
            'benefitTags': ['Different preparation'],
            'structuredBenefits': [
              {'title': 'Preparation', 'description': 'Try this preparation and compare your logs.'},
            ],
            'whyBetterOption': 'Compare a different preparation with your usual burger.',
          },
        )
        .toList();
    Map<String, dynamic> response(List<dynamic> swaps) => {
      'status': 'ready',
      'topInsight': {
        'title': 'Burger observation',
        'description': 'Bloating reported after burgers.',
        'involvedFoods': ['Fried Chicken Burger'],
        'nextSteps': ['Track your reactions.'],
      },
      'foodSwaps': swaps,
    };
    final completeSwaps = [
      {
        'source': {'name': 'Fried Chicken Burger', 'foodId': 'fried_chicken_burger'},
        'alternatives': alternatives,
      },
    ];
    var responses = [response([]), response(completeSwaps)];
    when(
      () => ai.generateContent(
        prompt: any(named: 'prompt'),
        promptVersion: any(named: 'promptVersion'),
      ),
    ).thenAnswer((_) async => jsonEncode(responses.removeAt(0)));
    Future<AIInsight> generate() => repository.analyzeGutHealth(
      goals: const [],
      sensitivities: const ['Tree Nuts', 'Soy'],
      lifestyle: const [],
      cyclePhase: 'Not specified',
      chatSummary: null,
      chatHistory: const [],
      recentJournalText: 'Fried chicken burgers followed by bloating.',
      historicalJournalSummary: null,
      scoreHistory: null,
      patternCandidates: const [
        BodyPattern(
          id: 'burger-bloating',
          type: BodyPattern.typeBloating,
          trigger: 'Fried Chicken Burger',
          reaction: 'Bloating',
          frequency: 5,
          confidence: 'Medium',
          description: 'Bloating was reported after five burger meals.',
          involvedFoods: ['fried chicken burger'],
          updatedAt: '',
        ),
      ],
    );

    final insight = await generate();
    expect(insight.foodSwaps.single.alternatives, hasLength(4));
    expect(insight.foodSwaps.single.relatedPatternId, 'burger-bloating');
    final prompts = verify(
      () => ai.generateContent(
        prompt: captureAny(named: 'prompt'),
        promptVersion: any(named: 'promptVersion'),
      ),
    ).captured;
    expect(prompts, hasLength(2));
    expect(prompts.last, contains('foodSwaps MUST contain at least one swap'));
    responses = [response([]), response([])];
    await expectLater(generate(), throwsA(isA<FormatException>()));
    verify(
      () => ai.generateContent(
        prompt: any(named: 'prompt'),
        promptVersion: any(named: 'promptVersion'),
      ),
    ).called(2);
  });
}
