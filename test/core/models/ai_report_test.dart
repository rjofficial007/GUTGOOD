import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/ai_report.dart';

void main() {
  group('AiReport', () {
    test('the reasons and field names match firestore.rules exactly', () {
      // The important test. A reason or field the rules don't recognise is
      // rejected server-side — and because submission swallows errors, every
      // report would then fail silently in production.
      final rules = File('firestore.rules').readAsStringSync();
      final fn = rules.substring(rules.indexOf('function isValidAiReport'));
      final fnBody = fn.substring(0, fn.indexOf('match /'));

      // 1. Reasons: the app and the rules must offer exactly the same set.
      final reasonList = RegExp(r"in \[([^\]]+)\]").firstMatch(fnBody)!.group(1)!;
      final reasonsInRules = RegExp(r"'([a-z_]+)'").allMatches(reasonList).map((m) => m.group(1)!).toSet();

      for (final reason in AiReport.allowedReasons) {
        expect(reasonsInRules, contains(reason), reason: 'firestore.rules does not accept the reason "$reason".');
      }
      expect(
        reasonsInRules,
        unorderedEquals(AiReport.allowedReasons.toSet()),
        reason: 'The app and the rules offer different reason sets.',
      );

      // 2. Fields: toMap() must never emit a key the rules' hasOnly() rejects.
      final hasOnly = RegExp(r"hasOnly\(\[([^\]]+)\]\)").firstMatch(fnBody)!.group(1)!;
      final fieldsInRules = RegExp(r"'([A-Za-z_]+)'").allMatches(hasOnly).map((m) => m.group(1)!).toSet();

      final emittedWithId = AiReport(reason: 'other', messageExcerpt: 'x', details: 'y', messageId: 'm1').toMap().keys.toSet();
      final emittedWithoutId = AiReport(reason: 'other', messageExcerpt: 'x').toMap().keys.toSet();

      expect(emittedWithId.difference(fieldsInRules), isEmpty, reason: 'toMap() emits a field the rules reject.');
      expect(emittedWithoutId.difference(fieldsInRules), isEmpty);
    });

    test('rejects a reason the rules would never accept', () {
      const report = AiReport(reason: 'because_i_said_so', messageExcerpt: 'x');
      expect(report.isValidReason, isFalse);
    });

    test('truncates the excerpt and details to the rule limits', () {
      final long = 'x' * 5000;
      final map = AiReport(reason: 'other', messageExcerpt: long, details: long).toMap();

      expect((map['messageExcerpt'] as String).length, AiReport.maxExcerptLength);
      expect((map['details'] as String).length, AiReport.maxDetailsLength);
    });

    test('omits messageId when there isn\'t one, so the rules\' hasOnly check passes', () {
      final map = AiReport(reason: 'inaccurate', messageExcerpt: 'hi').toMap();

      expect(map.containsKey('messageId'), isFalse);
      expect(map.keys, unorderedEquals(['reason', 'messageExcerpt', 'details', 'reportedBy', 'createdAt']));
    });

    test('excerptOf trims and truncates the message text', () {
      expect(AiReport.excerptOf('  hello  '), 'hello');
      expect(AiReport.excerptOf('y' * 9000).length, AiReport.maxExcerptLength);
    });

    test('copyWith can stamp the reporter without losing the reason', () {
      const report = AiReport(reason: 'unsafe', messageExcerpt: 'advice', details: 'details');
      final stamped = report.copyWith(reportedBy: 'uid-123');

      expect(stamped.reportedBy, 'uid-123');
      expect(stamped.reason, 'unsafe');
      expect(stamped.details, 'details');
    });
  });
}
