part of 'chat_composer_notifier.dart';

/// Image upload hydration and recovery workflow.

extension ChatComposerUploads on ChatComposerNotifier {
  /// Immediate upload attempt with outbox fallback (P1-3a + pass C). Never
  /// throws: failures persist to the disk-backed queue and resolve via
  /// [flushUploads] — same turn, reconnect, or next app start. The turn
  /// itself always proceeds on local bytes.
  Future<void> _uploadAndHydrate(List<ChatAttachment> sending, String userLocalId) async {
    final byIndex = <int, RecoveredUpload>{};
    for (var i = 0; i < sending.length; i++) {
      try {
        final url = await _uploadOutbox.uploadOrEnqueue(bytes: sending[i].bytes, chatLocalId: userLocalId, index: i);
        if (url != null) byIndex[i] = RecoveredUpload(url: url, hash: _hashFor(url, sending[i].bytes));
      } catch (e) {
        AppLogger.warning('ChatComposer: upload attempt failed; queued for retry. Error: $e');
      }
    }
    if (byIndex.isEmpty) {
      AppLogger.warning('ChatComposer: all image uploads queued; turn continues on local bytes');
      return; // isSending stays true until flushUploads settles the queue
    }
    _lastSentImageUrl = byIndex.values.first.url;
    await _applyRecovery(userLocalId, byIndex);
  }

  /// Registry identity for an uploaded URL. Canonical URLs always encode it;
  /// the bytes-hash fallback only serves mocked/test storage shapes.
  String _hashFor(String url, Uint8List bytes) => imageHashFromFoodUrl(url) ?? imageHash(bytes);

  /// Retries queued uploads; silent background work — failures simply stay
  /// queued. Skipped while offline so attempts aren't burned on a dead radio.
  Future<void> flushUploads() async {
    if (_flushingUploads || _uploadOutbox.isEmpty) return;
    if (!_connectionChecker.isInternetAvailable.value) return;
    _flushingUploads = true;
    try {
      await _uploadOutbox.flush(onRecovered: _applyRecovery);
    } finally {
      _flushingUploads = false;
    }
  }

  /// Merges [uploadsByIndex] into the message, persists the URL/hash pair,
  /// and links each photo to this message in the registry. Clears local
  /// state once nothing for this message is still queued. Falls back to a
  /// direct Firestore patch when the message isn't in memory (restart case).
  Future<void> _applyRecovery(String chatLocalId, Map<int, RecoveredUpload> uploadsByIndex) async {
    if (uploadsByIndex.isEmpty && _uploadOutbox.pendingFor(chatLocalId).isNotEmpty) return;
    final current = _findMessage(chatLocalId);
    final urlsByIndex = uploadsByIndex.map((i, u) => MapEntry(i, u.url));
    final hashesByIndex = uploadsByIndex.map((i, u) => MapEntry(i, u.hash));
    final merged = _mergeIndexed(current?.imageUrls ?? const <String>[], urlsByIndex, '');
    final mergedHashes = _mergeIndexed(current?.imageHashes ?? const <String>[], hashesByIndex, '');
    if (current == null) {
      // Restart case: patch the Firestore doc directly (doc id == localId).
      // Multi-image restart recovery is last-wins per flush — acceptable:
      // the UI caps attachments at one per turn.
      await _repository.patchMessageImageUrls(localId: chatLocalId, imageUrls: merged.where((u) => u.isNotEmpty).toList());
      await _repository.patchMessageImageHashes(localId: chatLocalId, imageHashes: mergedHashes.where((h) => h.isNotEmpty).toList());
      for (final hash in mergedHashes) {
        if (hash.isNotEmpty) await _foodImages.addLink(hash: hash, kind: FoodImageLinks.kindChat, id: chatLocalId);
      }
      return;
    }
    try {
      final done = _uploadOutbox.pendingFor(chatLocalId).isEmpty;
      final saved = await _repository.saveMessage(current.copyWith(imageUrls: merged, imageHashes: mergedHashes, isSending: !done));
      // Keep local bytes only when there is nothing remote to show (poison /
      // purged entries): the photo stays visible session-locally.
      _historyNotifier.replaceMessage(chatLocalId, merged.any((u) => u.isNotEmpty) ? saved.copyWith(clearLocalImages: true) : saved);

      final docId = saved.firestoreId ?? chatLocalId;
      for (final hash in mergedHashes) {
        if (hash.isNotEmpty) await _foodImages.addLink(hash: hash, kind: FoodImageLinks.kindChat, id: docId);
      }

      String? firstUrl;
      String? firstHash;
      for (var i = 0; i < merged.length; i++) {
        if (merged[i].isNotEmpty) {
          firstUrl = merged[i];
          firstHash = i < mergedHashes.length ? mergedHashes[i] : null;
          break;
        }
      }
      final aiLocalId = _activeAiLocalId;
      if (aiLocalId != null && firstUrl != null) {
        final url = firstUrl;
        final aiMsg = _findMessage(aiLocalId);
        if (aiMsg != null && aiMsg.imageUrl == null) {
          _historyNotifier.replaceMessage(aiLocalId, aiMsg.copyWith(imageUrl: url, imageUrls: [url], imageHashes: firstHash == null ? null : [firstHash]));
        }
      }
    } catch (e) {
      AppLogger.warning('ChatComposer: URL hydration save failed. Error: $e');
    }
  }

  /// Index-aligned merge that tolerates gaps (fill placeholders survive
  /// until their flush fills them; the bubble shows local bytes while any
  /// exist).
  List<T> _mergeIndexed<T>(List<T> existing, Map<int, T> byIndex, T fill) {
    final merged = List<T>.from(existing);
    for (final entry in byIndex.entries) {
      while (merged.length <= entry.key) {
        merged.add(fill);
      }
      merged[entry.key] = entry.value;
    }
    return merged;
  }

  ChatMessage? _findMessage(String localId) {
    for (final m in _historyNotifier.messages) {
      if (m.localId == localId) return m;
    }
    return null;
  }
}
