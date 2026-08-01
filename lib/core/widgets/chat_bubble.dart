import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/feedback_tag.dart';

import '../constants/app_icons.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

/// ChatGPT-style chat bubble.
///
/// - Multi-image support (user turns can carry up to 4 photos).
/// - Streaming cursor while the assistant is typing.
/// - Action bar (Copy / Regenerate) under the latest assistant turn.
/// - Error cards with Retry / Upgrade affordances for failed turns.
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime time;
  final bool isLoading;
  final List<String> imageUrls;
  final List<Uint8List>? localImages;
  final bool isSending;
  final bool sendFailed;
  final bool isStreaming;
  final ChatErrorKind errorKind;
  final double screenWidth;
  final bool showFeedback;
  final String? feedback;
  final Function(String)? onFeedback;
  final bool showAvatar;
  final bool showActions;
  final VoidCallback? onRegenerate;
  final VoidCallback? onRetry;
  final VoidCallback? onQuotaPressed;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.time,
    this.isLoading = false,
    this.imageUrls = const [],
    this.localImages,
    this.isSending = false,
    this.sendFailed = false,
    this.isStreaming = false,
    this.errorKind = ChatErrorKind.none,
    required this.screenWidth,
    this.showFeedback = false,
    this.feedback,
    this.onFeedback,
    this.showAvatar = true,
    this.showActions = false,
    this.onRegenerate,
    this.onRetry,
    this.onQuotaPressed,
  });

  void _copyToClipboard(BuildContext context) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    HapticHelper.medium();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.messageCopied), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
  }

  bool get _hasImages => (localImages != null && localImages!.isNotEmpty) || imageUrls.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: EdgeInsets.only(bottom: AppSizes.p16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(AppAssets.appIconBg, height: 24.0.w, width: 24.0.w, color: context.appColorScheme.textPrimary),
            Gap.w12,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.0.w, vertical: 12.0.h),
              decoration: BoxDecoration(
                color: context.appColorScheme.cardBackground,
                border: Border.all(color: context.appColorScheme.border),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(6.0.r), topRight: Radius.circular(20.0.r), bottomLeft: Radius.circular(20.0.r), bottomRight: Radius.circular(20.0.r)),
              ),
              child: const ThinkingIndicator(),
            ),
          ],
        ),
      );
    }

    final int hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final String amPm = time.hour >= 12 ? 'PM' : 'AM';
    final String formattedTime = '$hour:${time.minute.toString().padLeft(2, '0')} $amPm';

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onLongPress: () => _copyToClipboard(context),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: screenWidth * 0.85),
                child: Container(
                  margin: EdgeInsets.only(bottom: 4.0.h),
                  padding: EdgeInsets.all(16.0.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: isSending ? 0.7 : 1.0),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20.0.r), topRight: Radius.circular(20.0.r), bottomLeft: Radius.circular(20.0.r), bottomRight: Radius.circular(6.0.r)),
                    border: sendFailed ? Border.all(color: context.appColorScheme.error, width: 1.5) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_hasImages) _buildImageStrip(context, dark: true),
                      if (_hasImages) Gap.h8,
                      if (text.isNotEmpty) Text(text, style: context.body.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
                      Gap.h4,
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSending)
                            Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: SizedBox(
                                width: 10.0.w,
                                height: 10.0.w,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)),
                              ),
                            )
                          else if (sendFailed)
                            Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: Icon(AppIcons.alertCircle, size: 11.0.w, color: Theme.of(context).colorScheme.onPrimary),
                            ),
                          Text(
                            isSending ? 'Sending...' : (sendFailed ? 'Failed' : '$formattedTime ✓✓'),
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.54), fontSize: 10.0.sp, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (sendFailed && onRetry != null)
              Padding(
                padding: EdgeInsets.only(bottom: AppSizes.p12),
                child: GestureDetector(
                  onTap: onRetry,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.rotateCcw, size: 13.0.w, color: context.appColorScheme.error),
                      Gap.w4,
                      Text(
                        AppStrings.tapToRetry,
                        style: context.caption.copyWith(color: context.appColorScheme.error, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Assistant error turn (no content was produced).
    if (text.isEmpty && errorKind != ChatErrorKind.none) {
      return _buildAssistantErrorCard(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: showAvatar ? 1.0 : 0.0,
              child: Image.asset(AppAssets.appIconBg, height: 24.0.w, width: 24.0.w, color: context.appColorScheme.textPrimary),
            ),
            Gap.w12,
            Expanded(
              child: GestureDetector(
                onLongPress: () => _copyToClipboard(context),
                child: Container(
                  margin: EdgeInsets.only(bottom: 8.0.h),
                  padding: EdgeInsets.all(16.0.w),
                  decoration: BoxDecoration(
                    color: context.appColorScheme.cardBackground,
                    border: Border.all(color: context.appColorScheme.border),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(6.0.r), topRight: Radius.circular(20.0.r), bottomLeft: Radius.circular(20.0.r), bottomRight: Radius.circular(20.0.r)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownBody(
                        data: isStreaming ? '$text ▌' : text,
                        selectable: !isStreaming,
                        styleSheet: MarkdownStyleSheet(
                          p: context.body.copyWith(height: 1.5),
                          strong: context.bodyBold,
                          h1: context.headingSm,
                          h2: context.title,
                          listBullet: context.body,
                          code: context.bodySm.copyWith(fontFamily: 'monospace', backgroundColor: context.appColorScheme.elevatedSurface, color: context.appColorScheme.textPrimary),
                          codeblockPadding: EdgeInsets.all(12.0.w),
                          codeblockDecoration: BoxDecoration(color: context.appColorScheme.elevatedSurface, borderRadius: BorderRadius.circular(8.0.r), border: Border.all(color: context.appColorScheme.border)),
                          tableHead: context.bodyBold,
                          tableBody: context.body,
                          tableBorder: TableBorder.all(color: context.appColorScheme.border, width: 0.5),
                          blockquote: context.body.copyWith(color: context.appColorScheme.textSecondary, fontStyle: FontStyle.italic),
                          blockquoteDecoration: BoxDecoration(border: Border(left: BorderSide(color: context.appColorScheme.textMuted, width: 3))),
                        ),
                      ),
                      Gap.h8,
                      Text(
                        formattedTime,
                        style: context.caption.copyWith(fontSize: 10.0.sp, color: context.appColorScheme.textMuted),
                      ),
                      if (errorKind == ChatErrorKind.connection && !isStreaming) ...[Gap.h8, _buildInterruptedRow(context)],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showActions)
          Padding(
            padding: EdgeInsets.only(left: 36.0.w, bottom: AppSizes.p8),
            child: Row(
              children: [
                _ActionIcon(icon: AppIcons.copy, tooltip: AppStrings.copyMessage, onTap: () => _copyToClipboard(context)),
                Gap.w16,
                if (onRegenerate != null) _ActionIcon(icon: AppIcons.refreshCcw, tooltip: AppStrings.regenerate, onTap: onRegenerate!),
              ],
            ),
          ),
        if (showFeedback && onFeedback != null)
          Padding(
            padding: EdgeInsets.only(left: 36.0.w, bottom: AppSizes.p16, right: AppSizes.p10),
            child: Wrap(
              spacing: 5.0.w,
              runSpacing: 5.0.h,
              children: [
                FeedbackTag(icon: AppIcons.thumbsUp, label: AppStrings.helpful, onTap: () => onFeedback!('helpful'), isSelected: feedback == 'helpful'),
                FeedbackTag(icon: AppIcons.thumbsDown, label: AppStrings.notHelpful, onTap: () => onFeedback!('not_helpful'), isSelected: feedback == 'not_helpful'),
                FeedbackTag(icon: AppIcons.refreshCcw, label: AppStrings.tellMeMore, onTap: () => onFeedback!('tell_me_more')),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImageStrip(BuildContext context, {required bool dark}) {
    final local = localImages;
    final int count = (local != null && local.isNotEmpty) ? local.length : imageUrls.length;
    final double size = count > 1 ? 120.0.w : 180.0.w;

    return Wrap(
      spacing: 8.0.w,
      runSpacing: 8.0.w,
      children: List.generate(count, (i) {
        final borderRadius = BorderRadius.circular(12.0.r);
        final Widget image = (local != null && local.isNotEmpty)
            ? Image.memory(local[i], height: size, width: size, fit: BoxFit.cover, gaplessPlayback: true)
            : CachedNetworkImage(
                imageUrl: imageUrls[i],
                height: size,
                width: size,
                fit: BoxFit.cover,
                memCacheWidth: (size * 2).round(),
                placeholder: (_, _) => Container(height: size, width: size, color: dark ? Colors.white24 : context.appColorScheme.elevatedSurface),
                errorWidget: (_, _, _) => Container(
                  height: size,
                  width: size,
                  color: context.appColorScheme.elevatedSurface,
                  child: Icon(AppIcons.image, color: context.appColorScheme.textMuted),
                ),
              );
        return ClipRRect(borderRadius: borderRadius, child: image);
      }),
    );
  }

  Widget _buildInterruptedRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.alertTriangle, size: 13.0.w, color: context.appColorScheme.warning),
        Gap.w8,
        Text(
          AppStrings.responseInterrupted,
          style: context.caption.copyWith(color: context.appColorScheme.warning, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildAssistantErrorCard(BuildContext context) {
    final bool isQuota = errorKind == ChatErrorKind.quota;
    return Padding(
      padding: EdgeInsets.only(left: 36.0.w, bottom: AppSizes.p16),
      child: Container(
        padding: EdgeInsets.all(14.0.w),
        decoration: BoxDecoration(
          color: (isQuota ? context.appColorScheme.warning : context.appColorScheme.error).withValues(alpha: 0.06),
          border: Border.all(color: (isQuota ? context.appColorScheme.warning : context.appColorScheme.error).withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(AppSizes.r16),
        ),
        child: Row(
          children: [
            Icon(isQuota ? AppIcons.sparkles : AppIcons.alertCircle, size: 18.0.w, color: isQuota ? context.appColorScheme.warning : context.appColorScheme.error),
            Gap.w12,
            Expanded(
              child: Text(
                isQuota ? AppStrings.dailyLimitMessage : AppStrings.connectionError,
                style: context.bodySm.copyWith(color: context.appColorScheme.textPrimary, height: 1.4),
              ),
            ),
            if (isQuota && onQuotaPressed != null)
              TextButton(onPressed: onQuotaPressed, child: Text(AppStrings.upgrade, style: context.bodySm.copyWith(fontWeight: FontWeight.w800, color: context.appColorScheme.textPrimary)))
            else if (onRetry != null)
              TextButton(onPressed: onRetry, child: Text(AppStrings.retry, style: context.bodySm.copyWith(fontWeight: FontWeight.w800, color: context.appColorScheme.textPrimary))),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticHelper.light();
          onTap();
        },
        child: Container(
          padding: EdgeInsets.all(6.0.w),
          decoration: BoxDecoration(
            color: context.appColorScheme.elevatedSurface,
            borderRadius: BorderRadius.circular(AppSizes.r10),
            border: Border.all(color: context.appColorScheme.border),
          ),
          child: Icon(icon, size: 15.0.w, color: context.appColorScheme.textSecondary),
        ),
      ),
    );
  }
}

class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({super.key});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double delay = index * 0.2;
            final double progress = (_controller.value - delay).clamp(0.0, 1.0);
            final double offset = -4 * (progress > 0 && progress < 1 ? (progress * (1 - progress) * 4) : 0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, offset),
                child: Container(
                  width: 6.0.w,
                  height: 6.0.w,
                  decoration: BoxDecoration(color: context.appColorScheme.textPrimary, shape: BoxShape.circle),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
