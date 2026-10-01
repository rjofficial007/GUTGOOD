import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/features/insights/data/repositories/insight_repository_impl.dart';

void main() {
  Map<String, dynamic> baseline() => {
    'status': 'ready',
    'topInsight': {
      'title': 'Your first food and symptom snapshot',
      'description': 'You logged oats and rice and reported mild bloating. A repeated association is not established.',
      'nextSteps': ['Record when bloating starts after your logged meals.'],
    },
    'weeklyRecap': {'foodsLogged': 3},
    'detectedPatterns': [],
  };

  test('accepts a personalized baseline without previous scores or patterns', () {
    expect(isUsableInsightResponse(baseline()), isTrue);
  });

  test('rejects insufficient and empty responses for eligible users', () {
    expect(isUsableInsightResponse({...baseline(), 'status': 'insufficient_data'}), isFalse);
    expect(
      isUsableInsightResponse({
        ...baseline(),
        'weeklyRecap': {'foodsLogged': 0},
      }),
      isFalse,
    );
    expect(isUsableInsightResponse({}), isFalse);
  });

  test('rejects missing titles and mixed-type next steps', () {
    final data = baseline();
    (data['topInsight'] as Map)['title'] = ' ';
    expect(isUsableInsightResponse(data), isFalse);
    (data['topInsight'] as Map)['title'] = 'Snapshot';
    (data['topInsight'] as Map)['nextSteps'] = ['Track timing', 42];
    expect(isUsableInsightResponse(data), isFalse);
  });

  test('rejects copied placeholder instructions even when marked ready', () {
    final data = baseline();
    (data['topInsight'] as Map)['description'] = "Synthesize a personalized summary of the user's logged meals and reported symptoms.";
    expect(isUsableInsightResponse(data), isFalse);
  });
}
