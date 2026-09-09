import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/features/chat/data/services/chat_outbox_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ChatOutboxService outbox;

  QueuedMessage msg(String id, [String text = 'hello']) => QueuedMessage(id: id, text: text, source: 'chat', createdAt: DateTime(2026, 1, 1));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    outbox = ChatOutboxServiceImpl(prefs: await SharedPreferences.getInstance());
  });

  group('ChatOutboxService', () {
    test('starts empty', () {
      expect(outbox.pending, isEmpty);
      expect(outbox.isEmpty, isTrue);
    });

    test('enqueue/dequeue preserves FIFO order', () async {
      await outbox.enqueue(msg('a', 'first'));
      await outbox.enqueue(msg('b', 'second'));

      expect(outbox.pending.map((m) => m.id), ['a', 'b']);

      await outbox.dequeue('a');

      expect(outbox.pending.map((m) => m.id), ['b']);
      expect(outbox.isEmpty, isFalse);
    });

    test('re-enqueue of the same id moves it back without duplicating', () async {
      await outbox.enqueue(msg('a'));
      await outbox.enqueue(msg('b'));
      await outbox.enqueue(msg('a', 'updated'));

      expect(outbox.pending.map((m) => m.id), ['b', 'a']);
      expect(outbox.pending.last.text, 'updated');
    });

    test('entries round-trip through prefs (restart-safe)', () async {
      await outbox.enqueue(QueuedMessage(id: 'a', text: 'hi', hiddenContext: 'ctx', source: 'chat', createdAt: DateTime(2026, 5, 4, 3, 2, 1)));

      final fresh = ChatOutboxServiceImpl(prefs: await SharedPreferences.getInstance());
      final loaded = fresh.pending.single;

      expect(loaded.id, 'a');
      expect(loaded.text, 'hi');
      expect(loaded.hiddenContext, 'ctx');
      expect(loaded.source, 'chat');
      expect(loaded.createdAt, DateTime(2026, 5, 4, 3, 2, 1));
    });

    test('corrupt prefs read as empty; invalid entries are dropped', () async {
      SharedPreferences.setMockInitialValues({'chat_text_outbox_v1': 'not json {{{'});
      final broken = ChatOutboxServiceImpl(prefs: await SharedPreferences.getInstance());
      expect(broken.pending, isEmpty);

      SharedPreferences.setMockInitialValues({
        'chat_text_outbox_v1': '[{"id":"","text":"x"},{"id":"ok","text":"y"}]',
      });
      final partial = ChatOutboxServiceImpl(prefs: await SharedPreferences.getInstance());
      expect(partial.pending.map((m) => m.id), ['ok']);
    });

    test('clear empties the outbox', () async {
      await outbox.enqueue(msg('a'));
      await outbox.clear();

      expect(outbox.isEmpty, isTrue);
    });
  });
}
