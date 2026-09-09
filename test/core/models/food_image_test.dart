import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/food_image.dart';

void main() {
  group('FoodImageLinks', () {
    test('addLink is idempotent and removeLink is a silent no-op when absent', () {
      var links = const FoodImageLinks();

      links = links.addLink(FoodImageLinks.kindChat, 'm1');
      links = links.addLink(FoodImageLinks.kindChat, 'm1');
      expect(links.chat, ['m1']);
      expect(links.total, 1);

      links = links.removeLink(FoodImageLinks.kindMeal, 'nope');
      expect(links.total, 1);

      links = links.removeLink(FoodImageLinks.kindChat, 'm1');
      expect(links.isEmpty, isTrue);
    });

    test('unknown kinds leave the links untouched', () {
      const links = FoodImageLinks(chat: ['m1']);
      expect(links.addLink('bogus', 'x'), links);
      expect(links.removeLink('bogus', 'm1'), links);
    });

    test('total spans all four buckets', () {
      const links = FoodImageLinks(chat: ['m1', 'm2'], scans: ['s1'], meals: ['j1'], symptoms: ['y1']);
      expect(links.total, 5);
    });

    test('round-trips through map', () {
      const links = FoodImageLinks(chat: ['m1'], scans: ['s1'], meals: ['j1'], symptoms: ['y1']);
      final revived = FoodImageLinks.fromMap(links.toMap());
      expect(revived, links);
    });

    test('fromMap tolerates null, missing keys, and non-string entries', () {
      expect(const FoodImageLinks(), FoodImageLinks.fromMap(null));
      final links = FoodImageLinks.fromMap({'chat': ['m1', 42, null]});
      expect(links.chat, ['m1']);
      expect(links.meals, isEmpty);
    });
  });

  group('FoodImage', () {
    test('fromMap parses a full doc', () {
      final image = FoodImage.fromMap({
        'hash': 'abcdef0123456789',
        'storagePath': 'users/u/food_images/abcdef0123456789.jpg',
        'downloadUrl': 'https://full/x.jpg',
        'thumbPath': 'users/u/food_images/thumbs/abcdef0123456789.jpg',
        'thumbUrl': 'https://thumb/x.jpg',
        'width': 1024,
        'height': 768,
        'bytes': 12345,
        'links': {'chat': ['m1'], 'scans': ['s1'], 'meals': [], 'symptoms': []},
        'linkCount': 2,
        'foods': ['pizza'],
        'createdAt': '2026-01-01T00:00:00.000',
      });

      expect(image.hash, 'abcdef0123456789');
      expect(image.thumbUrl, 'https://thumb/x.jpg');
      expect(image.links.total, 2);
      expect(image.linkCount, 2);
      expect(image.foods, ['pizza']);
      expect(image.createdAt, DateTime(2026, 1, 1));
      expect(image.lastUnlinkedAt, isNull);
    });

    test('minimal docs parse with defaults and survive a toMap round-trip', () {
      const image = FoodImage(hash: 'abcdef0123456789', storagePath: 'p');
      final revived = FoodImage.fromMap(image.toMap());

      expect(revived, image);
      expect(revived.downloadUrl, isNull);
      expect(revived.thumbUrl, isNull);
      expect(revived.links.isEmpty, isTrue);
      expect(revived.createdAt, isNull);
    });
  });
}
