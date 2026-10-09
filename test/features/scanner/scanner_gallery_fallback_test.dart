import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/features/scanner/domain/repositories/scanner_repository.dart';
import 'package:gutgood/features/scanner/presentation/providers/scanner_notifier.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/storage_service.dart';
import 'package:gutgood/infrastructure/open_food_facts/off_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockScannerRepository extends Mock implements ScannerRepository {}

class _MockAuthFirestoreService extends Mock implements AuthFirestoreService {}

class _MockOffService extends Mock implements OffService {}

class _MockStorageService extends Mock implements StorageService {}

void main() {
  test('gallery image without a barcode returns as a food photo for preview', () async {
    final notifier = ScannerNotifier(
      repository: _MockScannerRepository(),
      authFirestoreService: _MockAuthFirestoreService(),
      offService: _MockOffService(),
      storageService: _MockStorageService(),
    );
    final bytes = Uint8List.fromList([1, 2, 3]);
    String? capturedMode;
    Uint8List? capturedBytes;

    await notifier.handlePhotoCapture(
      bytes: bytes,
      mode: 'barcode',
      isBatchMode: false,
      analyzeBarcodeInImage: (_) async => null,
      onBarcodeFound: (_, _) {},
      onImageCaptured: (image, mode) {
        capturedBytes = image;
        capturedMode = mode;
      },
      onError: (message) => fail('Unexpected gallery failure: $message'),
      onHaptic: () {},
      fallbackToPhotoWhenBarcodeMissing: true,
    );

    expect(capturedMode, 'food');
    expect(capturedBytes, bytes);
  });

  test('gallery image is still returned when barcode analysis cannot decode it', () async {
    final notifier = ScannerNotifier(
      repository: _MockScannerRepository(),
      authFirestoreService: _MockAuthFirestoreService(),
      offService: _MockOffService(),
      storageService: _MockStorageService(),
    );
    final bytes = Uint8List.fromList([4, 5, 6]);
    String? capturedMode;

    await notifier.handlePhotoCapture(
      bytes: bytes,
      mode: 'barcode',
      isBatchMode: false,
      analyzeBarcodeInImage: (_) async => throw StateError('unsupported image'),
      onBarcodeFound: (_, _) {},
      onImageCaptured: (_, mode) => capturedMode = mode,
      onError: (message) => fail('Unexpected gallery failure: $message'),
      onHaptic: () {},
      fallbackToPhotoWhenBarcodeMissing: true,
    );

    expect(capturedMode, 'food');
  });
}
