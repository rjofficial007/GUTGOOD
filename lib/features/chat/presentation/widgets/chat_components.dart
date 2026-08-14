import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';
import 'package:gutgood/core/widgets/chat/image_preview_dialog.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_provider.dart';
import 'package:intl/intl.dart';
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
  Widget build(BuildContext context) => ListView.builder(
    padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p20),
    itemCount: 10,
    reverse: false,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemBuilder: (context, index) {
      final isUser = index % 2 == 0;
      final baseColor = context.appColorScheme.border.withValues(alpha: 0.2);
      final highlightColor = context.appColorScheme.border.withValues(alpha: 0.5);

      if (isUser) {
        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(bottom: AppSizes.p12),
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                width: MediaQuery.sizeOf(context).width * (0.4 + (index % 3) * 0.1),
                height: AppSizes.h54,
                decoration: BoxDecoration(
                  color: AppPalette.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppSizes.r24),
                    topRight: Radius.circular(AppSizes.r24),
                    bottomLeft: Radius.circular(AppSizes.r24),
                    bottomRight: Radius.circular(AppSizes.r8),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.only(bottom: AppSizes.p12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: Container(
                  width: AppSizes.icon28,
                  height: AppSizes.icon28,
                  decoration: const BoxDecoration(color: AppPalette.white, shape: BoxShape.circle),
                ),
              ),
            ),
            Gap.w8,
            Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                width: MediaQuery.sizeOf(context).width * (0.5 + (index % 2) * 0.1),
                height: AppSizes.p56 + (index * 4),
                decoration: BoxDecoration(
                  color: AppPalette.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppSizes.r24),
                    topRight: Radius.circular(AppSizes.r24),
                    bottomLeft: Radius.circular(AppSizes.r8),
                    bottomRight: Radius.circular(AppSizes.r24),
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
          Text(AppStrings.emptyStateTitle, style: context.displayMd, textAlign: .center),
          Gap.h24,
          Text(
            AppStrings.emptyStateSubtitle,
            style: context.bodyLg.copyWith(color: context.appColorScheme.textSecondary),
            textAlign: .center,
          ),
          Gap.h24,
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSizes.p4,
            mainAxisSpacing: AppSizes.p4,
            childAspectRatio: 0.7,
            children: const [
              _EmptyStateCard(icon: AppIcons.scan, title: AppStrings.emptyStateScanFood, subtitle: AppStrings.emptyStateScanFoodDesc),
              _EmptyStateCard(icon: AppIcons.clipboardList, title: AppStrings.emptyStateCheckIngredients, subtitle: AppStrings.emptyStateCheckIngredientsDesc),
              _EmptyStateCard(icon: AppIcons.messageCircle, title: AppStrings.emptyStateAskGutGood, subtitle: AppStrings.emptyStateAskGutGoodDesc),
            ],
          ),
        ],
      ),
    ),
  );
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p10),
    decoration: BoxDecoration(
      color: context.appColorScheme.cardBackground,
      borderRadius: BorderRadius.circular(AppSizes.r20),
      border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
    ),
    child: Column(
      children: [
        Gap.h4,
        Container(
          padding: EdgeInsets.all(AppSizes.p14),
          decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.5), shape: BoxShape.circle),
          child: Icon(icon, size: AppSizes.icon24, color: context.appColorScheme.textPrimary),
        ),
        Gap.h16,
        Text(title, textAlign: TextAlign.center, style: context.bodyBold.copyWith(height: 1.1)),
        Gap.h8,
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: context.caption.copyWith(color: context.appColorScheme.textSecondary, height: 1.2),
        ),
      ],
    ),
  );
}

class DateHeader extends StatelessWidget {
  const DateHeader({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    String label;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) {
      label = AppStrings.today;
    } else if (d == yesterday) {
      label = AppStrings.yesterday;
    } else {
      label = DateFormat('MMMM d, yyyy').format(date);
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.p24),
      child: Row(
        children: [
          Expanded(child: Divider(color: context.appColorScheme.border)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appColorScheme.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          Expanded(child: Divider(color: context.appColorScheme.border)),
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
    alignment: AlignmentGeometry.centerLeft,
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
                  barrierColor: Colors.black.withValues(alpha: 0.1),
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.only(right: AppSizes.p8),
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p14, vertical: AppSizes.p8),
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.r20),
        border: Border.all(color: context.appColorScheme.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appColorScheme.textPrimary, fontWeight: FontWeight.w600),
      ),
    ),
  );
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
              border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: context.appColorScheme.textPrimary, size: 20),
          ),
        ),
      ),
    ),
  );
}

class SendStopButton extends StatelessWidget {
  const SendStopButton({super.key, required this.controller, required this.chatNotifier, required this.onSend});

  final TextEditingController controller;
  final ChatNotifier chatNotifier;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final hasContent = controller.text.trim().isNotEmpty || chatNotifier.pendingAttachments.isNotEmpty;
      final colorScheme = context.appColorScheme;

      if (chatNotifier.isStreaming) {
        return ComposerActionCircle(
          label: AppStrings.stopGenerating,
          onTap: () {
            HapticHelper.light();
            chatNotifier.stopGeneration();
          },
          icon: Icon(AppIcons.square, color: colorScheme.cardBackground, size: 14, fill: 1.0),
        );
      }

      if (chatNotifier.isLoading) {
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
