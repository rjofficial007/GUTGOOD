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
import 'package:gutgood/features/chat/presentation/providers/chat_composer_notifier.dart';
import 'package:shimmer/shimmer.dart';

/// Reserves only the space needed to keep the newest prompt at the viewport
/// top. The response naturally fills this space as it streams.
class ChatTurnSliver extends StatelessWidget {
  const ChatTurnSliver({super.key, required this.anchorKey, required this.children});

  final GlobalKey anchorKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) => SliverToBoxAdapter(
      child: ConstrainedBox(
        key: anchorKey,
        constraints: BoxConstraints(minHeight: constraints.viewportMainAxisExtent),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    ),
  );
}

class AnimatedChatItem extends StatefulWidget {
  const AnimatedChatItem({super.key, required this.child, this.animate = true});
  final Widget child;
  final bool animate;

  @override
  State<AnimatedChatItem> createState() => _AnimatedChatItemState();
}

class _AnimatedChatItemState extends State<AnimatedChatItem> {
  late bool _visible;

  @override
  void initState() {
    super.initState();
    _visible = !widget.animate;
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _visible = true);
      });
    }
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
    final baseColor = AppPalette.shimmerBase(context);
    final highlightColor = AppPalette.shimmerHighlight(context);

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
                    borderRadius: BorderRadius.circular(AppSizes.r20).copyWith(bottomRight: isUser ? const Radius.circular(4) : null, topLeft: !isUser ? const Radius.circular(4) : null),
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
        child: Text(label, style: context.label.copyWith(color: colorScheme.textPrimary.withAlpha(204))),
      ),
    );
  }
}

class ComposerIconButton extends StatelessWidget {
  const ComposerIconButton({super.key, required this.icon, required this.label, this.onTap, this.iconColor});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? (Theme.of(context).brightness == Brightness.dark ? AppPalette.white : AppPalette.black);

    return Semantics(
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
              child: Icon(icon, color: effectiveIconColor, size: 20),
            ),
          ),
        ),
      ),
    );
  }
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
  const ComposerActionCircle({super.key, required this.label, this.onTap, this.icon, this.child, this.enabled = true, this.borderRadius});

  final String label;
  final VoidCallback? onTap;
  final Widget? icon;
  final Widget? child;
  final bool enabled;
  final BorderRadius? borderRadius;

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
            decoration: BoxDecoration(color: colorScheme.textPrimary, shape: borderRadius != null ? BoxShape.rectangle : BoxShape.circle, borderRadius: borderRadius),
            child: Center(child: child ?? icon),
          ),
        ),
      ),
    );
  }
}
