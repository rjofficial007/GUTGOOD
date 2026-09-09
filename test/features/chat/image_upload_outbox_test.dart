import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/services/storage_service.dart';
import 'package:gutgood/core/utils/image_hash.dart';
import 'package:gutgood/features/chat/data/services/image_upload_outbox.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockStorageService extends Mock implements StorageService {}

void main() {
  late MockStorageService storage;
  late Directory dir;
  late ImageUploadOutbox outbox;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = MockStorageService();
    dir = await Directory.systemTemp.createTemp('upload_outbox_test');
    outbox = ImageUploadOutboxImpl(prefs: await SharedPreferences.getInstance(), storageService: storage, baseDir: dir);
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  Uint8List bytes([int seed = 1]) => Uint8List.fromList(List.generate(64, (i) => (i + seed) % 256));

  group('ImageUploadOutbox', () {
    test('successful upload passes through with nothing persisted', () async {
      when(() => storage.uploadFoodImage(any())).thenAnswer((_) async => 'http://u/1.jpg');

      final url = await outbox.uploadOrEnqueue(bytes: bytes(), chatLocalId: 'm1', index: 0);

      expect(url, 'http://u/1.jpg');
      expect(outbox.isEmpty, isTrue);
      expect(dir.listSync(), isEmpty);
    });

    test('failed upload persists bytes + entry, surviving re-instantiation', () async {
      when(() => storage.uploadFoodImage(any())).thenAnswer((_) async => null);

      final url = await outbox.uploadOrEnqueue(bytes: bytes(), chatLocalId: 'm1', index: 0);

      expect(url, isNull);
      expect(outbox.pendingFor('m1'), hasLength(1));
      expect(outbox.pendingFor('m1').single.attempts, 1);
      expect(dir.listSync(), hasLength(1));

      // "Restart": a fresh instance over the same prefs+dir sees the entry.
      final fresh = ImageUploadOutboxImpl(prefs: await SharedPreferences.getInstance(), storageService: storage, baseDir: dir);
      expect(fresh.pendingFor('m1'), hasLength(1));
    });

    test('throwing upload queues the same as a null return', () async {
      when(() => storage.uploadFoodImage(any())).thenThrow(Exception('boom'));

      expect(await outbox.uploadOrEnqueue(bytes: bytes(), chatLocalId: 'm1', index: 0), isNull);
      expect(outbox.pendingFor('m1'), hasLength(1));
    });

    test('flush recovers, callbacks per message, and cleans up', () async {
      when(() => storage.uploadFoodImage(any())).thenAnswer((_) async => null);
      await outbox.uploadOrEnqueue(bytes: bytes(1), chatLocalId: 'm1', index: 0);
      await outbox.uploadOrEnqueue(bytes: bytes(2), chatLocalId: 'm1', index: 1);

      when(() => storage.uploadFoodImage(any())).thenAnswer((inv) async => 'http://u/${(inv.positionalArguments[0] as Uint8List)[0]}.jpg');
      final recovered = <String, Map<int, RecoveredUpload>>{};
      await outbox.flush(
        onRecovered: (chatLocalId, uploadsByIndex) async {
          recovered[chatLocalId] = uploadsByIndex;
        },
      );

      expect(recovered.keys, ['m1']);
      expect(recovered['m1']!.keys, {0, 1});
      expect(recovered['m1']![0]!.url, 'http://u/1.jpg');
      // Non-canonical URL: hash falls back to the entry's bytes hash.
      expect(recovered['m1']![0]!.hash, imageHash(bytes(1)));
      expect(outbox.isEmpty, isTrue);
      expect(dir.listSync(), isEmpty);
    });

    test('flush parses the registry hash from canonical URLs', () async {
      when(() => storage.uploadFoodImage(any())).thenAnswer((_) async => null);
      await outbox.uploadOrEnqueue(bytes: bytes(), chatLocalId: 'm1', index: 0);

      when(() => storage.uploadFoodImage(any())).thenAnswer((_) async => 'https://x/food_images/abcdef0123456789.jpg?alt=media');
      final recovered = <String, Map<int, RecoveredUpload>>{};
      await outbox.flush(
        onRecovered: (chatLocalId, uploadsByIndex) async {
          recovered[chatLocalId] = uploadsByIndex;
        },
      );

      expect(recovered['m1']![0]!.hash, 'abcdef0123456789');
    });

    test('flush drops entries whose cached file is gone, settling the message', () async {
      when(() => storage.uploadFoodImage(any())).thenAnswer((_) async => null);
      await outbox.uploadOrEnqueue(bytes: bytes(), chatLocalId: 'm1', index: 0);
      await dir.listSync().single.delete();

      final settled = <String, Map<int, RecoveredUpload>>{};
      await outbox.flush(
        onRecovered: (chatLocalId, uploadsByIndex) async {
          settled[chatLocalId] = uploadsByIndex;
        },
      );

      expect(settled, {'m1': <int, String>{}});
      expect(outbox.isEmpty, isTrue);
    });

    test('flush failures keep entries with growing attempts', () async {
      when(() => storage.uploadFoodImage(any())).thenAnswer((_) async => null);
      await outbox.uploadOrEnqueue(bytes: bytes(), chatLocalId: 'm1', index: 0);

      await outbox.flush(onRecovered: (_, _) async {});
      await outbox.flush(onRecovered: (_, _) async {});

      expect(outbox.pendingFor('m1'), hasLength(1));
      expect(outbox.pendingFor('m1').single.attempts, 3);
    });

    test('poison entries are dropped after max attempts', () async {
      when(() => storage.uploadFoodImage(any())).thenAnswer((_) async => null);
      await outbox.uploadOrEnqueue(bytes: bytes(), chatLocalId: 'm1', index: 0);

      final settled = <String, Map<int, RecoveredUpload>>{};
      for (var i = 0; i < 10; i++) {
        await outbox.flush(
          onRecovered: (chatLocalId, uploadsByIndex) async {
            settled[chatLocalId] = uploadsByIndex;
          },
        );
      }

      expect(settled, {'m1': <int, String>{}});
      expect(outbox.isEmpty, isTrue);
      expect(dir.listSync(), isEmpty);
    });

    test('same bytes twice share one file without losing either entry', () async {
      when(() => storage.uploadFoodImage(any())).thenAnswer((_) async => null);
      await outbox.uploadOrEnqueue(bytes: bytes(), chatLocalId: 'm1', index: 0);
      await outbox.uploadOrEnqueue(bytes: bytes(), chatLocalId: 'm1', index: 1);
      expect(dir.listSync(), hasLength(1));

      when(() => storage.uploadFoodImage(any())).thenAnswer((_) async => 'http://u/shared.jpg');
      final recovered = <String, Map<int, RecoveredUpload>>{};
      await outbox.flush(
        onRecovered: (chatLocalId, uploadsByIndex) async {
          recovered[chatLocalId] = uploadsByIndex;
        },
      );

      expect(recovered['m1']!.keys, {0, 1});
      expect(outbox.isEmpty, isTrue);
      expect(dir.listSync(), isEmpty);
    });

    test('clear empties entries and files; corrupt prefs read empty', () async {
      when(() => storage.uploadFoodImage(any())).thenAnswer((_) async => null);
      await outbox.uploadOrEnqueue(bytes: bytes(), chatLocalId: 'm1', index: 0);
      await outbox.clear();

      expect(outbox.isEmpty, isTrue);
      expect(dir.existsSync(), isFalse);

      SharedPreferences.setMockInitialValues({'chat_upload_outbox_v1': 'not json {{{'});
      final broken = ImageUploadOutboxImpl(prefs: await SharedPreferences.getInstance(), storageService: storage, baseDir: dir);
      expect(broken.isEmpty, isTrue);
    });
  });
}
