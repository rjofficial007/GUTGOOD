import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/date_formatter.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';
import 'package:gutgood/core/widgets/chat/image_preview_dialog.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/chat/presentation/pages/chat_screen.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_composer_notifier.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_history_notifier.dart';
import 'package:gutgood/features/scanner/domain/models/scanner_mode.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class AnimatedChatItem extends StatefulWidget {
  const AnimatedChatItem({super.key, required this.child});
  final Widget child;

  @override
  State<AnimatedChatItem> createState() => _AnimatedChatItemState();
}

class _AnimatedChatItemState extends State<AnimatedChatItem> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: _visible ? 1.0 : 0.0,
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOutCubic,
    child: AnimatedSlide(offset: _visible ? Offset.zero : const Offset(0, 0.02), duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic, child: widget.child),
  );
}

class ChatShimmerLoading extends StatelessWidget {
  const ChatShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    final baseColor = colorScheme.elevatedSurface;
    final highlightColor = colorScheme.cardBackground;

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p20),
      itemCount: 8,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final isUser = index % 2 == 0;

        return Padding(
          padding: EdgeInsets.only(bottom: AppSizes.p16),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  width: MediaQuery.sizeOf(context).width * (isUser ? 0.6 : 0.75),
                  height: isUser ? 50 : 80,
                  decoration: BoxDecoration(
                    color: AppPalette.white,
                    borderRadius: BorderRadius.circular(AppSizes.r20).copyWith(
                      bottomRight: isUser ? const Radius.circular(4) : null,
                      bottomLeft: !isUser ? const Radius.circular(4) : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChatPaginationLoader extends StatelessWidget {
  const ChatPaginationLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Shimmer.fromColors(
        baseColor: colorScheme.elevatedSurface,
        highlightColor: colorScheme.cardBackground,
        child: Container(
          width: 120,
          height: 32,
          decoration: BoxDecoration(
            color: AppPalette.white,
            borderRadius: BorderRadius.circular(AppSizes.r16),
          ),
        ),
      ),
    );
  }
}

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppStrings.emptyStateTitle, style: context.displayMd, textAlign: TextAlign.center),
          Gap.h24,
          Text(
            AppStrings.emptyStateSubtitle,
            style: context.bodyLg.copyWith(color: context.appColorScheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          Gap.h24,
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSizes.p8,
            mainAxisSpacing: AppSizes.p8,
            childAspectRatio: 0.75,
            children: [
              _EmptyStateCard(
                icon: AppIcons.scan,
                title: AppStrings.emptyStateScanFood,
                subtitle: AppStrings.emptyStateScanFoodDesc,
                onTap: () {
                  final state = context.findAncestorStateOfType<ChatScreenState>();
                  if (state != null) {
                    final historyNotifier = context.read<ChatHistoryNotifier>();
                    final composerNotifier = context.read<ChatComposerNotifier>();
                    final authNotifier = context.read<GutAuthNotifier>();
                    state.handleCamera(historyNotifier, composerNotifier, authNotifier, mode: ScannerMode.food);
                  }
                },
              ),
              _EmptyStateCard(
                icon: AppIcons.clipboardList,
                title: AppStrings.emptyStateCheckIngredients,
                subtitle: AppStrings.emptyStateCheckIngredientsDesc,
                onTap: () {
                  final state = context.findAncestorStateOfType<ChatScreenState>();
                  if (state != null) {
                    final historyNotifier = context.read<ChatHistoryNotifier>();
                    final composerNotifier = context.read<ChatComposerNotifier>();
                    final authNotifier = context.read<GutAuthNotifier>();
                    state.handleCamera(historyNotifier, composerNotifier, authNotifier, mode: ScannerMode.label);
                  }
                },
              ),
              _EmptyStateCard(
                icon: AppIcons.messageCircle,
                title: AppStrings.emptyStateAskGutGood,
                subtitle: AppStrings.emptyStateAskGutGoodDesc,
                onTap: () {
                  FocusScope.of(context).requestFocus();
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.icon, required this.title, required this.subtitle, this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p12),
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppSizes.r24),
          border: Border.all(color: colorScheme.borderSubtle),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(AppSizes.p12),
              decoration: BoxDecoration(color: colorScheme.surfaceSubtle, shape: BoxShape.circle),
              child: Icon(icon, size: AppSizes.icon20, color: colorScheme.textPrimary),
            ),
            Gap.h12,
            Text(title, textAlign: TextAlign.center, style: context.bodyBold.copyWith(height: 1.1, fontSize: 12)),
            Gap.h6,
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: context.caption.copyWith(color: colorScheme.textMuted, height: 1.2, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}


class DateHeader extends StatelessWidget {
  const DateHeader({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final label = DateFormatter.formatDate(date);

    final colorScheme = context.appColorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.p24, top: AppSizes.p12),
      child: Row(
        children: [
          Expanded(child: Divider(color: colorScheme.border.withAlpha(77))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.borderSubtle),
            ),
            child: Text(label.toUpperCase(), style: context.captionTiny.copyWith(color: colorScheme.textMuted)),
          ),
          Expanded(child: Divider(color: colorScheme.border.withAlpha(77))),
        ],
      ),
    );
  }
}

class AttachmentPreview extends StatelessWidget {
  const AttachmentPreview({super.key, required this.bytes, required this.onRemove, required this.heroTag});
  final dynamic bytes;
  final VoidCallback onRemove;
  final String heroTag;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      height: 68,
      margin: const EdgeInsets.only(bottom: 6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  barrierColor: AppPalette.black.withAlpha(26),
                  pageBuilder: (context, _, _) => ImagePreviewDialog(localImages: [bytes], initialIndex: 0, heroTag: heroTag),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
                ),
              );
            },
            child: Hero(
              tag: heroTag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(bytes, width: 60, height: 60, fit: BoxFit.cover, gaplessPlayback: true),
              ),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: Semantics(
              label: AppStrings.removeAttachment,
              button: true,
              child: GestureDetector(
                onTap: () {
                  HapticHelper.light();
                  onRemove();
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: context.appColorScheme.textPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.appColorScheme.cardBackground, width: 1.5),
                  ),
                  child: Icon(AppIcons.x, size: 12, color: context.appColorScheme.cardBackground),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class ChatSuggestionChip extends StatelessWidget {
  const ChatSuggestionChip({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: AppSizes.p10),
        padding: EdgeInsets.symmetric(horizontal: AppSizes.p18, vertical: AppSizes.p8),
        decoration: BoxDecoration(
          color: colorScheme.elevatedSurface,
          borderRadius: BorderRadius.circular(AppSizes.r20),
          border: Border.all(color: colorScheme.border.withAlpha(102)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: context.label.copyWith(
            color: colorScheme.textPrimary.withAlpha(204),
          ),
        ),
      ),
    );
  }
}

class ComposerIconButton extends StatelessWidget {
  const ComposerIconButton({super.key, required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    enabled: onTap != null,
    child: Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1.0,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.appColorScheme.cardBackground,
              borderRadius: BorderRadius.circular(AppSizes.r14),
              border: Border.all(color: context.appColorScheme.borderSubtle),
            ),
            child: Icon(icon, color: context.appColorScheme.textPrimary, size: 20),
          ),
        ),
      ),
    ),
  );
}

class SendStopButton extends StatelessWidget {
  const SendStopButton({super.key, required this.controller, required this.composerNotifier, required this.onSend});

  final TextEditingController controller;
  final ChatComposerNotifier composerNotifier;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final hasContent = controller.text.trim().isNotEmpty || composerNotifier.pendingAttachments.isNotEmpty;
      final colorScheme = context.appColorScheme;

      if (composerNotifier.isStreaming) {
        return ComposerActionCircle(
          label: AppStrings.stopGenerating,
          onTap: () {
            HapticHelper.light();
            composerNotifier.stopGeneration();
          },
          icon: Icon(AppIcons.square, color: colorScheme.cardBackground, size: 14, fill: 1.0),
        );
      }

      if (composerNotifier.isLoading) {
        return ComposerActionCircle(
          label: 'Loading',
          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: colorScheme.cardBackground, strokeWidth: 2)),
        );
      }

      return ComposerActionCircle(
        label: AppStrings.sendMessage,
        onTap: hasContent ? onSend : null,
        enabled: hasContent,
        icon: Icon(AppIcons.send, color: colorScheme.cardBackground, size: 20),
      );
    },
  );
}

class ComposerActionCircle extends StatelessWidget {
  const ComposerActionCircle({super.key, required this.label, this.onTap, this.icon, this.child, this.enabled = true});

  final String label;
  final VoidCallback? onTap;
  final Widget? icon;
  final Widget? child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: colorScheme.textPrimary, shape: BoxShape.circle),
            child: Center(child: child ?? icon),
          ),
        ),
      ),
    );
  }
}
