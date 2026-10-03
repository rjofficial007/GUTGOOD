part of 'chat_screen.dart';

/// Chat composer presentation component.

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({required this.controller, required this.onChanged, required this.onCamera, required this.onGallery, required this.onSend});

  final TextEditingController controller;

  final VoidCallback onChanged;

  final Future<void> Function(ChatHistoryNotifier, ChatComposerNotifier, GutAuthNotifier, {ScannerMode? mode}) onCamera;

  final Future<void> Function(ChatHistoryNotifier, ChatComposerNotifier, GutAuthNotifier) onGallery;

  final Future<void> Function(ChatHistoryNotifier, ChatComposerNotifier, GutAuthNotifier, [String?]) onSend;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;

    final historyNotifier = context.watch<ChatHistoryNotifier>();

    final composerNotifier = context.watch<ChatComposerNotifier>();

    final authNotifier = context.read<GutAuthNotifier>();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        border: Border(top: BorderSide(color: colorScheme.border.withValues(alpha: 0.5))),
      ),
      padding: EdgeInsets.fromLTRB(0, AppSizes.p12, 0, MediaQuery.paddingOf(context).bottom + AppSizes.p12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (composerNotifier.pendingAttachments.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
              child: AttachmentPreview(
                bytes: composerNotifier.pendingAttachments.first.bytes,
                heroTag: 'attachment_${composerNotifier.pendingAttachments.first.id}',
                onRemove: () => composerNotifier.removeAttachment(composerNotifier.pendingAttachments.first.id),
              ),
            ),

          _SuggestionChipsSection(controller: controller),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: colorScheme.elevatedSurface,
                      borderRadius: BorderRadius.circular(AppSizes.r20),
                      border: Border.all(color: colorScheme.border.withValues(alpha: 0.8)),
                    ),
                    child: Row(
                      children: [
                        Gap.w4,

                        Expanded(
                          child: GutTextField(
                            textCapitalization: TextCapitalization.sentences,
                            controller: controller,
                            maxLines: 5,
                            minLines: 1,
                            onChanged: (_) => onChanged(),
                            hintText: composerNotifier.isStreaming ? AppStrings.thinking : AppStrings.askAnything,
                            borderless: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          ),
                        ),

                        ComposerIconButton(
                          icon: AppIcons.image,
                          label: AppStrings.attachPhotos,
                          onTap: composerNotifier.isLoading ? null : () => onGallery(historyNotifier, composerNotifier, authNotifier),
                        ),

                        Gap.w4,

                        ComposerActionCircle(
                          label: AppStrings.scanIngredientsMeal,
                          onTap: composerNotifier.isLoading ? null : () => onCamera(historyNotifier, composerNotifier, authNotifier),
                          enabled: !composerNotifier.isLoading,
                          borderRadius: BorderRadius.circular(AppSizes.r14),
                          icon: Icon(AppIcons.camera, color: context.appColorScheme.cardBackground, size: 20),
                        ),

                        Gap.w4,

                        SendStopButton(controller: controller, composerNotifier: composerNotifier, onSend: () => onSend(historyNotifier, composerNotifier, authNotifier)),

                        Gap.w4,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// JUMP TO LATEST BUTTON
// =============================================================================

/// Floating manual navigation control, ChatGPT-style.
///
/// A compact rounded-square arrow styled like the composer's send button
/// (filled, light icon). Visible only while the user is meaningfully away
/// from the newest content. Tapping it is the ONLY motion besides the send
/// scroll — it never fires on its own, and no AI update ever moves the
/// viewport or summons it.
