import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gutgood/core/utils/logger_service.dart';

abstract class StorageService {
  Future<Uint8List> compressImage(Uint8List bytes);
  Future<String?> uploadFoodImage(Uint8List bytes);
  Future<String?> uploadProfilePicture(Uint8List bytes);
  Future<void> deleteImage(String url);
  Future<void> migrateUserFiles(String fromUid, String toUid);
  Future<void> deleteAllUserFiles(String uid);
}

class StorageServiceImpl implements StorageService {
  StorageServiceImpl({
    required FirebaseAuth auth,
    required FirebaseStorage storage,
  }) : _auth = auth,
       _storage = storage;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  String? get _uid => _auth.currentUser?.uid;

  @override
  Future<Uint8List> compressImage(Uint8List bytes) async {
    try {
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: 512,
        minWidth: 512,
        quality: 80,
      );
      return compressedBytes;
    } catch (e) {
      AppLogger.error('StorageService: Compression failed', error: e);
      return bytes;
    }
  }

  @override
  Future<String?> uploadFoodImage(Uint8List bytes) async {
    if (_uid == null) return null;

    try {
      final compressedBytes = await compressImage(bytes);
      final fileName = 'food_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('users/$_uid/food_images/$fileName');

      final uploadTask = ref.putData(
        compressedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      AppLogger.error('StorageService: Food image upload failed', error: e);
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

      final uploadTask = ref.putData(
        compressedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      AppLogger.error(
        'StorageService: Profile picture upload failed',
        error: e,
      );
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
          final destRef = _storage.ref().child(
            'users/$toUid/$folder/${item.name}',
          );
          await destRef.putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          await item.delete();
        }
      } catch (e) {
        AppLogger.error(
          'StorageService: Migration failed for $folder',
          error: e,
        );
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
