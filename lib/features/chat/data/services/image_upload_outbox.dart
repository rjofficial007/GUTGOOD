import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:gutgood/core/services/storage_service.dart';
import 'package:gutgood/core/utils/image_hash.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One attachment awaiting (re)upload. Bytes live on disk (cache dir —
/// expendable by design); this entry is the prefs-side index.
class PendingUpload {
  const PendingUpload({required this.chatLocalId, required this.hash, required this.index, this.attempts = 0, required this.createdAt});

  factory PendingUpload.fromJson(Map<String, dynamic> json) => PendingUpload(
    chatLocalId: json['chatLocalId'] as String? ?? '',
    hash: json['hash'] as String? ?? '',
    index: (json['index'] as num?)?.toInt() ?? 0,
    attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  final String chatLocalId;
  final String hash;
  final int index;
  final int attempts;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {'chatLocalId': chatLocalId, 'hash': hash, 'index': index, 'attempts': attempts, 'createdAt': createdAt.toIso8601String()};

  bool get isValid => chatLocalId.isNotEmpty && hash.isNotEmpty;

  PendingUpload withAttempt() => PendingUpload(chatLocalId: chatLocalId, hash: hash, index: index, attempts: attempts + 1, createdAt: createdAt);
}

/// A recovered upload: the URL to display plus the content hash to link.
/// Hashes (not URLs) are the registry identity, so recovery must carry both.
class RecoveredUpload {
  const RecoveredUpload({required this.url, required this.hash});

  final String url;
  final String hash;
}

/// Disk+prefs-backed retry queue for image uploads (audit §E: restart-safe
/// outbox). A failed upload persists its bytes to the cache dir and retries
/// on later flush triggers — same turn, reconnect, or next app start. If the
/// OS purges the cached file, the entry is dropped gracefully on flush.
abstract class ImageUploadOutbox {
  bool get isEmpty;
  List<PendingUpload> pendingFor(String chatLocalId);

  /// Tries an immediate upload; on failure persists bytes+entry for retry.
  /// Returns the URL on success, null when queued.
  Future<String?> uploadOrEnqueue({required Uint8List bytes, required String chatLocalId, required int index});

  /// Retries everything pending. [onRecovered] fires once per message settled
  /// this flush with its recovered uploads by attachment index — empty when
  /// the message's entries were dropped (poison cap, purged file), so the UI
  /// can stop waiting. Entries still pending fire nothing.
  Future<void> flush({required Future<void> Function(String chatLocalId, Map<int, RecoveredUpload> uploadsByIndex) onRecovered});

  Future<void> clear();
}

class ImageUploadOutboxImpl implements ImageUploadOutbox {
  ImageUploadOutboxImpl({required SharedPreferences prefs, required StorageService storageService, required Directory baseDir})
    : _prefs = prefs,
      _storage = storageService,
      _baseDir = baseDir;

  final SharedPreferences _prefs;
  final StorageService _storage;
  final Directory _baseDir;

  static const _key = 'chat_upload_outbox_v1';
  static const _maxAttempts = 10;

  bool _flushing = false;

  List<PendingUpload> get _pending {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list.whereType<Map<String, dynamic>>().map(PendingUpload.fromJson).where((e) => e.isValid).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  bool get isEmpty => _pending.isEmpty;

  @override
  List<PendingUpload> pendingFor(String chatLocalId) => _pending.where((e) => e.chatLocalId == chatLocalId).toList();

  File _fileFor(String hash) => File('${_baseDir.path}/$hash.jpg');

  @override
  Future<String?> uploadOrEnqueue({required Uint8List bytes, required String chatLocalId, required int index}) async {
    String? url;
    try {
      url = await _storage.uploadFoodImage(bytes);
    } catch (e) {
      AppLogger.warning('ImageUploadOutbox: immediate upload threw, queueing. Error: $e');
    }
    if (url != null) return url;

    try {
      final hash = imageHash(bytes);
      await _baseDir.create(recursive: true);
      await _fileFor(hash).writeAsBytes(bytes, flush: true);
      final entries = _pending.where((e) => !(e.chatLocalId == chatLocalId && e.index == index)).toList()
        ..add(PendingUpload(chatLocalId: chatLocalId, hash: hash, index: index, attempts: 1, createdAt: DateTime.now()));
      await _persist(entries);
      AppLogger.ai('ImageUploadOutbox: queued $hash for $chatLocalId');
    } catch (e) {
      AppLogger.warning('ImageUploadOutbox: could not persist pending upload. Error: $e');
    }
    return null;
  }

  @override
  Future<void> flush({required Future<void> Function(String chatLocalId, Map<int, RecoveredUpload> uploadsByIndex) onRecovered}) async {
    if (_flushing) return;
    _flushing = true;
    try {
      await _sweepOrphans();
      final recovered = <String, Map<int, RecoveredUpload>>{};
      final touched = <String>{};
      for (final entry in _pending) {
        final file = _fileFor(entry.hash);
        if (!file.existsSync()) {
          await _removeEntry(entry);
          touched.add(entry.chatLocalId);
          continue;
        }
        if (entry.attempts >= _maxAttempts) {
          AppLogger.warning('ImageUploadOutbox: dropping poison entry ${entry.hash} after ${entry.attempts} attempts');
          await _removeEntry(entry, deleteFile: true);
          touched.add(entry.chatLocalId);
          continue;
        }
        await _replaceEntry(entry.withAttempt());
        String? url;
        try {
          url = await _storage.uploadFoodImage(await file.readAsBytes());
        } catch (e) {
          AppLogger.warning('ImageUploadOutbox: retry failed for ${entry.hash}. Error: $e');
        }
        if (url == null) continue; // stays queued
        await _removeEntry(entry, deleteFile: true);
        // Stored bytes are compressed server-side, so the upload id is the
        // hash parsed from the canonical URL (`.../food_images/<hash>.jpg`),
        // falling back to the entry hash for mocked/cached shapes.
        (recovered[entry.chatLocalId] ??= {})[entry.index] =
            RecoveredUpload(url: url, hash: imageHashFromFoodUrl(url) ?? entry.hash);
        touched.add(entry.chatLocalId);
      }
      for (final chatLocalId in touched) {
        try {
          await onRecovered(chatLocalId, recovered[chatLocalId] ?? {});
        } catch (err) {
          AppLogger.warning('ImageUploadOutbox: recovery callback failed for $chatLocalId. Error: $err');
        }
      }
    } finally {
      _flushing = false;
    }
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_key);
    try {
      if (_baseDir.existsSync()) await _baseDir.delete(recursive: true);
    } catch (e) {
      AppLogger.warning('ImageUploadOutbox: cache cleanup failed. Error: $e');
    }
  }

  Future<void> _persist(List<PendingUpload> entries) async {
    await _prefs.setString(_key, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  Future<void> _replaceEntry(PendingUpload entry) async {
    final entries = _pending;
    final idx = entries.indexWhere((e) => e.chatLocalId == entry.chatLocalId && e.hash == entry.hash && e.index == entry.index);
    if (idx != -1) {
      entries[idx] = entry;
      await _persist(entries);
    }
  }

  Future<void> _removeEntry(PendingUpload entry, {bool deleteFile = false}) async {
    await _persist(_pending.where((e) => !(e.chatLocalId == entry.chatLocalId && e.hash == entry.hash && e.index == entry.index)).toList());
    if (deleteFile) {
      // Same bytes can back several entries (same photo twice) — delete the
      // file only when nothing references it anymore.
      if (_pending.any((e) => e.hash == entry.hash)) return;
      try {
        final file = _fileFor(entry.hash);
        if (file.existsSync()) await file.delete();
      } catch (e) {
        AppLogger.warning('ImageUploadOutbox: file cleanup failed. Error: $e');
      }
    }
  }

  /// Deletes cached files no entry references (e.g. superseded re-enqueues).
  Future<void> _sweepOrphans() async {
    try {
      if (!_baseDir.existsSync()) return;
      final referenced = _pending.map((e) => '${e.hash}.jpg').toSet();
      await for (final entity in _baseDir.list()) {
        if (entity is File && !referenced.contains(entity.uri.pathSegments.last)) {
          await entity.delete();
        }
      }
    } catch (e) {
      AppLogger.warning('ImageUploadOutbox: orphan sweep failed. Error: $e');
    }
  }
}
