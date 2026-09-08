import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gutgood/core/utils/logger_service.dart';

abstract class StorageService {
  /// Thumbnail profile (~320 px) for Storage uploads and history tiles.
  Future<Uint8List> compressImage(Uint8List bytes);

  /// Vision profile (~1280 px short edge) for anything sent to the AI proxy.
  Future<Uint8List> compressForAi(Uint8List bytes);
  Future<String?> uploadFoodImage(Uint8List bytes);
  Future<String?> uploadProfilePicture(Uint8List bytes);
  Future<void> deleteImage(String url);
  Future<void> migrateUserFiles(String fromUid, String toUid);
  Future<void> deleteAllUserFiles(String uid);
}

class StorageServiceImpl implements StorageService {
  StorageServiceImpl({required FirebaseAuth auth, required FirebaseStorage storage}) : _auth = auth, _storage = storage;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  String? get _uid => _auth.currentUser?.uid;

  @override
  Future<Uint8List> compressImage(Uint8List bytes) async {
    if (bytes.isEmpty) return bytes;
    try {
      final originalSize = bytes.lengthInBytes / 1024;
      AppLogger.info('StorageService: Original image size: ${originalSize.toStringAsFixed(2)}KB');

      // 🚀 Professional Compression: Target ~20KB
      // Reducing resolution to 320px and quality to 20% to hit the 20KB target.
      final compressedBytes = await FlutterImageCompress.compressWithList(bytes, minHeight: 320, minWidth: 320, quality: 50, format: CompressFormat.jpeg, autoCorrectionAngle: true, keepExif: false);

      final finalSize = compressedBytes.lengthInBytes / 1024;
      AppLogger.info('StorageService: Compressed image size: ${finalSize.toStringAsFixed(2)}KB');

      return compressedBytes;
    } catch (e, st) {
      AppLogger.error('StorageService: Compression plugin failure', error: e, stackTrace: st);
      return bytes;
    }
  }

  // ---------------------------------------------------------------------------
  // AI vision profile
  // ---------------------------------------------------------------------------

  /// Short-edge target for images sent to the vision model.
  ///
  /// 320 px (the thumbnail profile above) is unreadable for the two features
  /// that depend on OCR-like reading — ingredient labels and restaurant menus.
  static const int _aiMinEdge = 1280;

  /// Quality ladder walked until the result fits [_aiTargetBytes].
  static const List<int> _aiQualityLadder = [78, 70, 60, 50];

  /// Comfortably under the proxy's MAX_IMAGE_BASE64_CHARS (1.6M chars ≈ 1.2 MB
  /// decoded). Images above that cap are rejected by the proxy.
  static const int _aiTargetBytes = 400 * 1024;

  @override
  Future<Uint8List> compressForAi(Uint8List bytes) async {
    if (bytes.isEmpty) return bytes;
    try {
      var best = bytes;
      for (final quality in _aiQualityLadder) {
        best = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: _aiMinEdge,
          minHeight: _aiMinEdge,
          quality: quality,
          format: CompressFormat.jpeg,
          autoCorrectionAngle: true,
          keepExif: false,
        );
        if (best.lengthInBytes <= _aiTargetBytes) break;
      }

      AppLogger.info(
        'StorageService: AI image ${(bytes.lengthInBytes / 1024).toStringAsFixed(0)}KB -> ${(best.lengthInBytes / 1024).toStringAsFixed(0)}KB',
      );
      return best;
    } catch (e, st) {
      // Never block a scan on a compression failure — send the original bytes.
      AppLogger.error('StorageService: AI compression failure', error: e, stackTrace: st);
      return bytes;
    }
  }

  @override
  Future<String?> uploadFoodImage(Uint8List bytes) async {
    final uid = _uid;
    if (uid == null) {
      AppLogger.error('StorageService: Upload failed, user not authenticated');
      return null;
    }

    try {
      final compressedBytes = await compressImage(bytes);
      final fileName = 'food_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('users/$uid/food_images/$fileName');

      AppLogger.info('StorageService: Uploading to Firebase Storage: ${ref.fullPath}');

      final uploadTask = ref.putData(compressedBytes, SettableMetadata(contentType: 'image/jpeg'));

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      AppLogger.info('StorageService: Food image upload successful: $url');
      return url;
    } catch (e, st) {
      AppLogger.error('StorageService: uploadFoodImage exception', error: e, stackTrace: st);
      return null;
    }
  }

  @override
  Future<String?> uploadProfilePicture(Uint8List bytes) async {
    if (_uid == null) return null;

    try {
      final compressedBytes = await compressImage(bytes);
      const fileName = 'profile_pic.jpg';
      final ref = _storage.ref().child('users/$_uid/profile/$fileName');

      final uploadTask = ref.putData(compressedBytes, SettableMetadata(contentType: 'image/jpeg'));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      AppLogger.error('StorageService: Profile picture upload failed', error: e);
      return null;
    }
  }

  @override
  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      AppLogger.error('StorageService: Delete failed', error: e);
    }
  }

  @override
  Future<void> migrateUserFiles(String fromUid, String toUid) async {
    final foldersToMove = ['profile', 'food_images'];
    for (final folder in foldersToMove) {
      final fromRef = _storage.ref().child('users/$fromUid/$folder');
      try {
        final listResult = await fromRef.listAll();
        for (final item in listResult.items) {
          final bytes = await item.getData();
          if (bytes == null) continue;
          final destRef = _storage.ref().child('users/$toUid/$folder/${item.name}');
          await destRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
          await item.delete();
        }
      } catch (e) {
        AppLogger.error('StorageService: Migration failed for $folder', error: e);
      }
    }
  }

  @override
  Future<void> deleteAllUserFiles(String uid) async {
    try {
      final userRef = _storage.ref().child('users/$uid');
      await _deleteFolder(userRef);
    } catch (e) {
      AppLogger.error('StorageService: Delete all user files failed', error: e);
    }
  }

  Future<void> _deleteFolder(Reference ref) async {
    final listResult = await ref.listAll();
    for (final item in listResult.items) {
      await item.delete();
    }
    for (final prefix in listResult.prefixes) {
      await _deleteFolder(prefix);
    }
  }
}
