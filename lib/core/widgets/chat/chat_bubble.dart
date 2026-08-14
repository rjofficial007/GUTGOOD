import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';
import 'package:gutgood/core/widgets/chat/chat_action_icon.dart';
import 'package:gutgood/core/widgets/chat/image_preview_dialog.dart';
import 'package:gutgood/core/widgets/chat/thinking_indicator.dart';
import 'package:gutgood/core/widgets/feedback_tag.dart';

class ChatBubble extends StatelessWidget {
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

  void _copyToClipboard(BuildContext context) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    HapticHelper.medium();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.messageCopied), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
  }

  bool get _hasImages => (localImages != null && localImages!.isNotEmpty) || imageUrls.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoadingState(context);

    final formattedTime = _getFormattedTime();

    if (isUser) return _buildUserMessage(context, formattedTime);

    if (text.isEmpty && errorKind != ChatErrorKind.none) {
      return _buildAssistantErrorCard(context);
    }

    return _buildAiMessage(context, formattedTime);
  }

  String _getFormattedTime() {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final amPm = time.hour >= 12 ? AppStrings.unitPM : AppStrings.unitAM;
    return '$hour:${time.minute.toString().padLeft(2, '0')} $amPm';
  }

  Widget _buildLoadingState(BuildContext context) => Semantics(
    label: 'AI is thinking',
    child: Padding(
      padding: EdgeInsets.only(bottom: AppSizes.p16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(AppAssets.appIconBg, height: 24, width: 24, color: context.appColorScheme.textPrimary),
          Gap.w12,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: context.appColorScheme.cardBackground,
              border: Border.all(color: context.appColorScheme.border),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: const ThinkingIndicator(),
          ),
        ],
      ),
    ),
  );

  Widget _buildUserMessage(BuildContext context, String formattedTime) => Semantics(
    label: 'User message: $text',
    child: Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onLongPress: () => _copyToClipboard(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: screenWidth * 0.85),
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: isSending ? 0.7 : 1.0),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(6)),
                  border: sendFailed ? Border.all(color: context.appColorScheme.error, width: 1.5) : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_hasImages) _buildImageStrip(context, dark: true),
                    if (_hasImages) Gap.h8,
                    if (text.isNotEmpty) Text(text, style: context.body.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
                    Gap.h4,
                    _buildUserStatusRow(context, formattedTime),
                  ],
                ),
              ),
            ),
          ),
          if (sendFailed && onRetry != null) _buildRetryButton(context),
        ],
      ),
    ),
  );

  Widget _buildUserStatusRow(BuildContext context, String formattedTime) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (isSending)
        Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7))),
        )
      else if (sendFailed)
        Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: Icon(AppIcons.alertCircle, size: 11, color: Theme.of(context).colorScheme.onPrimary),
        ),
      Text(
        isSending ? AppStrings.labelSending : (sendFailed ? AppStrings.labelFailed : '$formattedTime ✓✓'),
        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.54), fontSize: AppSizes.s10, fontWeight: FontWeight.bold),
      ),
    ],
  );

  Widget _buildRetryButton(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: AppSizes.p12),
    child: GestureDetector(
      onTap: onRetry,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.rotateCcw, size: 13, color: context.appColorScheme.error),
          Gap.w4,
          Text(
            AppStrings.tapToRetry,
            style: context.caption.copyWith(color: context.appColorScheme.error, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );

  Widget _buildAiMessage(BuildContext context, String formattedTime) => Semantics(
    label: 'AI message: $text',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(AppAssets.appIconBg, height: 24, width: 24, color: context.appColorScheme.textPrimary),
            Gap.w12,
            Expanded(
              child: GestureDetector(
                onLongPress: () => _copyToClipboard(context),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  // padding: const EdgeInsets.all(16),
                  // decoration: BoxDecoration(
                  //   color: context.appColorScheme.cardBackground,
                  //   border: Border.all(color: context.appColorScheme.border),
                  //   borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                  // ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMarkdownContent(context),
                      Gap.h8,
                      Text(formattedTime, style: context.caption.copyWith(fontSize: 10, color: context.appColorScheme.textMuted)),
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
            padding: const EdgeInsets.only(left: 36, bottom: 8),
            child: ChatActionIcon(icon: AppIcons.copy, tooltip: AppStrings.copyMessage, onTap: () => _copyToClipboard(context)),
          ),
        if (showFeedback && onFeedback != null) _buildFeedbackRow(context),
      ],
    ),
  );

  Widget _buildMarkdownContent(BuildContext context) => MarkdownBody(
    data: isStreaming ? '$text ▌' : text,
    selectable: !isStreaming,
    styleSheet: MarkdownStyleSheet(
      p: context.body.copyWith(height: 1.5),
      strong: context.bodyBold,
      h1: context.headingSm,
      h2: context.title,
      listBullet: context.body,
      code: context.bodySm.copyWith(fontFamily: 'monospace', backgroundColor: context.appColorScheme.elevatedSurface, color: context.appColorScheme.textPrimary),
      codeblockPadding: const EdgeInsets.all(12),
      codeblockDecoration: BoxDecoration(
        color: context.appColorScheme.elevatedSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.appColorScheme.border),
      ),
      tableHead: context.bodyBold,
      tableBody: context.body,
      tableBorder: TableBorder.all(color: context.appColorScheme.border, width: 0.5),
      blockquote: context.body.copyWith(color: context.appColorScheme.textSecondary, fontStyle: FontStyle.italic),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: context.appColorScheme.textMuted, width: 3)),
      ),
    ),
  );

  Widget _buildFeedbackRow(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 36, bottom: 16, right: 10),
    child: Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        FeedbackTag(icon: AppIcons.thumbsUp, label: AppStrings.helpful, onTap: () => onFeedback!(AppStrings.labelHelpful), isSelected: feedback == AppStrings.labelHelpful),
        FeedbackTag(icon: AppIcons.thumbsDown, label: AppStrings.notHelpful, onTap: () => onFeedback!(AppStrings.labelNotHelpful), isSelected: feedback == AppStrings.labelNotHelpful),
        FeedbackTag(icon: AppIcons.refreshCcw, label: AppStrings.tellMeMore, onTap: () => onFeedback!(AppStrings.labelTellMeMore)),
      ],
    ),
  );

  Widget _buildImageStrip(BuildContext context, {required bool dark}) {
    final local = localImages;
    final count = (local != null && local.isNotEmpty) ? local.length : imageUrls.length;
    final size = count > 1 ? 120.0 : 180.0;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(count, (i) {
        final borderRadius = BorderRadius.circular(12);
        final heroTag = 'chat_image_${local != null ? "local" : "url"}_${i}_${time.millisecondsSinceEpoch}';

        final image = (local != null && local.isNotEmpty)
            ? Image.memory(local[i], height: size, width: size, fit: BoxFit.cover, gaplessPlayback: true)
            : CachedNetworkImage(
                imageUrl: imageUrls[i],
                height: size,
                width: size,
                fit: BoxFit.cover,
                memCacheWidth: (size * 2).round(),
                placeholder: (_, _) => Container(height: size, width: size, color: dark ? AppPalette.white.withValues(alpha: 0.24) : context.appColorScheme.elevatedSurface),
                errorWidget: (_, _, _) => Container(
                  height: size,
                  width: size,
                  color: context.appColorScheme.elevatedSurface,
                  child: Icon(AppIcons.image, color: context.appColorScheme.textMuted),
                ),
              );

        return GestureDetector(
          onTap: () => _showFullScreenImage(context, i, heroTag),
          child: Hero(
            tag: heroTag,
            child: ClipRRect(borderRadius: borderRadius, child: image),
          ),
        );
      }),
    );
  }

  void _showFullScreenImage(BuildContext context, int index, String heroTag) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.1),
        pageBuilder: (context, _, _) => ImagePreviewDialog(imageUrls: imageUrls, localImages: localImages, initialIndex: index, heroTag: heroTag),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Widget _buildInterruptedRow(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(AppIcons.alertTriangle, size: 13, color: context.appColorScheme.warning),
      Gap.w8,
      Text(
        AppStrings.responseInterrupted,
        style: context.caption.copyWith(color: context.appColorScheme.warning, fontWeight: FontWeight.w600),
      ),
    ],
  );

  Widget _buildAssistantErrorCard(BuildContext context) {
    final isQuota = errorKind == ChatErrorKind.quota;
    return Padding(
      padding: EdgeInsets.only(left: 36, bottom: AppSizes.p16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: (isQuota ? context.appColorScheme.warning : context.appColorScheme.error).withValues(alpha: 0.06),
          border: Border.all(color: (isQuota ? context.appColorScheme.warning : context.appColorScheme.error).withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(AppSizes.r16),
        ),
        child: Row(
          children: [
            Icon(AppIcons.alertCircle, size: 18, color: isQuota ? context.appColorScheme.warning : context.appColorScheme.error),
            Gap.w12,
            Expanded(
              child: Text(isQuota ? AppStrings.dailyLimitMessage : AppStrings.connectionError, style: context.bodySm.copyWith(color: context.appColorScheme.textPrimary, height: 1.4)),
            ),
            if (isQuota && onQuotaPressed != null)
              TextButton(
                onPressed: onQuotaPressed,
                child: Text(
                  AppStrings.upgrade,
                  style: context.bodySm.copyWith(fontWeight: FontWeight.w800, color: context.appColorScheme.textPrimary),
                ),
              )
            else if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text(
                  AppStrings.retry,
                  style: context.bodySm.copyWith(fontWeight: FontWeight.w800, color: context.appColorScheme.textPrimary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
