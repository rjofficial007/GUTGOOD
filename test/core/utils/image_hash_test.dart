import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/utils/image_hash.dart';

void main() {
  group('imageHash', () {
    test('is a stable 16-hex-char digest', () {
      final bytes = Uint8List.fromList([1, 2, 3, 250, 251]);

      expect(imageHash(bytes), hasLength(16));
      expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(imageHash(bytes)), isTrue);
      expect(imageHash(bytes), imageHash(Uint8List.fromList([1, 2, 3, 250, 251])));
    });

    test('differs across different bytes (incl. empty)', () {
      expect(imageHash(Uint8List(0)), hasLength(16));
      expect(imageHash(Uint8List.fromList([1])), isNot(imageHash(Uint8List.fromList([2]))));
    });
  });

  group('imageHashFromFoodUrl', () {
    test('parses raw and URL-encoded canonical paths', () {
      expect(imageHashFromFoodUrl('https://x/food_images/abcdef0123456789.jpg'), 'abcdef0123456789');
      expect(imageHashFromFoodUrl('https://firebasestorage.googleapis.com/v0/b/b/o/users%2Fu%2Ffood_images%2Fabcdef0123456789.jpg?alt=media&token=t'), 'abcdef0123456789');
    });

    test('returns null for legacy, foreign, and malformed shapes', () {
      expect(imageHashFromFoodUrl('https://x/food_images/1718035200000.jpg'), isNull);
      expect(imageHashFromFoodUrl('https://x/avatars/abcdef0123456789.jpg'), isNull);
      expect(imageHashFromFoodUrl('https://off/image.jpg'), isNull);
      expect(imageHashFromFoodUrl('not a url'), isNull);
      expect(imageHashFromFoodUrl(''), isNull);
    });
  });
}
