import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/utils/gut_score_utils.dart';

void main() {
  group('GutScoreBand', () {
    test('maps scores correctly to bands', () {
      expect(GutScoreBand.fromScore(95), GutScoreBand.excellent);
      expect(GutScoreBand.fromScore(90), GutScoreBand.excellent);
      expect(GutScoreBand.fromScore(89), GutScoreBand.great);
      expect(GutScoreBand.fromScore(70), GutScoreBand.great);
      expect(GutScoreBand.fromScore(69), GutScoreBand.good);
      expect(GutScoreBand.fromScore(50), GutScoreBand.good);
      expect(GutScoreBand.fromScore(49), GutScoreBand.fair);
      expect(GutScoreBand.fromScore(30), GutScoreBand.fair);
      expect(GutScoreBand.fromScore(29), GutScoreBand.trigger);
      expect(GutScoreBand.fromScore(0), GutScoreBand.trigger);
    });

    test('getStatus returns correct label for score', () {
      expect(GutScoreUtils.getStatus(92), 'Excellent');
      expect(GutScoreUtils.getStatus(75), 'Great');
      expect(GutScoreUtils.getStatus(55), 'Good');
      expect(GutScoreUtils.getStatus(35), 'Fair');
      expect(GutScoreUtils.getStatus(15), 'Trigger');
    });
  });
}
