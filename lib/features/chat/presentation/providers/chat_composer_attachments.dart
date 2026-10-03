part of 'chat_composer_notifier.dart';

/// Attachment and prompt-input operations.

extension ChatComposerAttachments on ChatComposerNotifier {
  Future<bool> handleImageAttachment(Uint8List bytes, {required String type}) async {
    final added = await addAttachment(bytes, source: type);
    if (added) {
      _pendingHiddenContext = type;
      _notifyStateChanged();
    }
    return added;
  }

  void clearPendingHiddenContext() {
    _pendingHiddenContext = null;
    _notifyStateChanged();
  }

  String getPromptForType(String type) => switch (type) {
    'menu' => AppStrings.menuPhotoPrompt,
    'label' => AppStrings.labelPhotoPrompt,
    'food' => AppStrings.mealPhotoPrompt,
    _ => AppStrings.galleryPhotoPrompt,
  };

  Future<bool> addAttachment(Uint8List bytes, {String source = 'gallery'}) async {
    if (_isLoading) return false;
    _attachments.clear();
    // Vision input, not a Storage thumbnail: the AI needs legible text for
    // labels/menus, so this uses compressForAi() (~1280 px) instead of the
    // ~320 px profile that compressImage() was written for.
    final compressed = await _storageService.compressForAi(bytes);
    _attachments.add(ChatAttachment(id: const Uuid().v4(), bytes: compressed, source: source));
    await _analyticsService.logEvent(name: 'attachment_added', parameters: {'source': source});
    _notifyStateChanged();
    return true;
  }

  void removeAttachment(String id) {
    _attachments.removeWhere((a) => a.id == id);
    _notifyStateChanged();
  }
}
