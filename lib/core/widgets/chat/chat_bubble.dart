import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/chat/chat_message.dart';
import 'package:gutgood/core/models/scans/scan_result.dart';
import 'package:gutgood/core/models/scans/scan_result_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/date_formatter.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';
import 'package:gutgood/core/widgets/chat/image_preview_dialog.dart';
import 'package:gutgood/core/widgets/chat/registry_thumb_image.dart';
import 'package:gutgood/core/widgets/chat/thinking_indicator.dart';
import 'package:gutgood/core/widgets/widgets.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.isLoading = false,
    this.imageUrls = const [],
    this.imageHashes = const [],
    this.localImages,
    this.isSending = false,
    this.sendFailed = false,
    this.isQueued = false,
    this.isStreaming = false,
    this.errorKind = ChatErrorKind.none,
    this.wasTruncated = false,
    required this.screenWidth,
    this.showFeedback = false,
    this.feedback,
    this.onFeedback,
    this.showAvatar = true,
    this.showActions = false,
    this.onRegenerate,
    this.onRetry,
    this.onQuotaPressed,
    this.scanData,
    this.swapData,
    this.onSeeMoreSwaps,
    this.onViewFullReport,
  });

  final String text;
  final bool isUser;
  final DateTime createdAt;
  final bool isLoading;
  final List<String> imageUrls;

  /// Registry hashes parallel to [imageUrls] (§E thumb lookups). Empty for
  /// legacy turns — the strip then renders full URLs as before.
  final List<String> imageHashes;
  final List<Uint8List>? localImages;
  final bool isSending;
  final bool sendFailed;
  final bool isQueued;
  final bool isStreaming;
  final ChatErrorKind errorKind;
  final bool wasTruncated;
  final double screenWidth;
  final bool showFeedback;
  final String? feedback;
  final Function(String)? onFeedback;

  final bool showAvatar;
  final bool showActions;
  final VoidCallback? onRegenerate;
  final VoidCallback? onRetry;
  final VoidCallback? onQuotaPressed;
  final ScanResult? scanData;
  final List<ProductSwap>? swapData;
  final VoidCallback? onSeeMoreSwaps;
  final VoidCallback? onViewFullReport;

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

    final formattedTime = DateFormatter.formatTime(createdAt);

    if (isUser) return _buildUserMessage(context, formattedTime);

    if (text.isEmpty && errorKind != ChatErrorKind.none) {
      return _buildAssistantErrorCard(context);
    }

    return _buildAiMessage(context, formattedTime);
  }

  Widget _buildLoadingState(BuildContext context) {
    final colorScheme = context.appColorScheme;
    return Semantics(
      label: 'Thinking',
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(bottom: AppSizes.p16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.cardBackground,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(4),
                topRight: Radius.circular(AppSizes.r24),
                bottomLeft: Radius.circular(AppSizes.r24),
                bottomRight: Radius.circular(AppSizes.r24),
              ),
              border: Border.all(color: colorScheme.borderSubtle),
            ),
            child: const ThinkingIndicator(),
          ),
        ),
      ),
    );
  }

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
                  color: context.appColorScheme.textPrimary,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomLeft: Radius.circular(24), bottomRight: Radius.circular(6)),
                  border: sendFailed ? Border.all(color: context.appColorScheme.error, width: 1.5) : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_hasImages) _buildImageStrip(context, dark: true),
                    if (_hasImages) Gap.h8,
                    if (text.isNotEmpty)
                      Text(
                        text,
                        style: context.body.copyWith(color: context.appColorScheme.cardBackground, fontWeight: FontWeight.w500),
                      ),
                    Gap.h4,
                    _buildUserStatusRow(context, formattedTime),
                  ],
                ),
              ),
            ),
          ),
          if ((sendFailed || isQueued) && onRetry != null) _buildRetryButton(context, isQueued ? AppStrings.tapToSendNow : AppStrings.tapToRetry),
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
          child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: context.appColorScheme.cardBackground.withAlpha(178))),
        )
      else if (sendFailed)
        Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: Icon(AppIcons.alertCircle, size: 11, color: context.appColorScheme.cardBackground),
        )
      else if (isQueued)
        Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: Icon(AppIcons.clock, size: 11, color: context.appColorScheme.cardBackground),
        ),
      Text(
        isSending ? AppStrings.labelSending : (sendFailed ? AppStrings.labelFailed : (isQueued ? AppStrings.labelQueued : '$formattedTime ✓✓')),
        style: context.captionTiny.copyWith(color: context.appColorScheme.cardBackground.withAlpha(138), fontWeight: FontWeight.bold),
      ),
    ],
  );

  Widget _buildRetryButton(BuildContext context, String label) => Padding(
    padding: EdgeInsets.only(bottom: AppSizes.p12),
    child: GestureDetector(
      onTap: onRetry,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.rotateCcw, size: 13, color: context.appColorScheme.error),
          Gap.w4,
          Text(
            label,
            style: context.caption.copyWith(color: context.appColorScheme.error, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );

  Widget _buildAiMessage(BuildContext context, String formattedTime) {
    final colorScheme = context.appColorScheme;
    return Semantics(
      label: 'Message: $text',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onLongPress: () => _copyToClipboard(context),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8, right: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.cardBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(4),
                        topRight: Radius.circular(AppSizes.r32),
                        bottomLeft: Radius.circular(AppSizes.r32),
                        bottomRight: Radius.circular(AppSizes.r32),
                      ),
                      border: Border.all(color: colorScheme.borderSubtle),
                      boxShadow: [BoxShadow(color: colorScheme.surfaceSubtle, blurRadius: 15, offset: const Offset(0, 5))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMarkdownContent(context),
                              if (swapData != null && swapData!.isNotEmpty) ...[
                                Gap.h12,
                                Divider(color: colorScheme.borderSubtle, height: 1),
                                Gap.h16,
                                SwapItContainer(swaps: swapData!, isEmbedded: true, onSeeMore: onSeeMoreSwaps),
                              ],
                              if (scanData != null) ...[
                                Gap.h12,
                                Divider(color: colorScheme.borderSubtle, height: 1),
                                Gap.h16,
                                ScanResultInlineCard(scanData: scanData!, isEmbedded: true, onViewFullReport: onViewFullReport),
                              ],

                              if (wasTruncated) ...[Gap.h12, _buildTrimmedRow(context)],
                              Gap.h12,
                              Row(
                                children: [
                                  Icon(AppIcons.clock, size: 10, color: colorScheme.textMuted),
                                  Gap.w4,
                                  Text(formattedTime, style: context.caption.copyWith(fontSize: 9, color: colorScheme.textMuted)),
                                  const Spacer(),
                                  _IntelligenceStamp(),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (errorKind == ChatErrorKind.connection && !isStreaming)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: colorScheme.warning.withAlpha(13),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                            ),
                            child: _buildInterruptedRow(context),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showFeedback && onFeedback != null) _buildFeedbackRow(context),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(BuildContext context) {
    final colorScheme = context.appColorScheme;
    return MarkdownBody(
      data: isStreaming ? '$text ▌' : text,
      selectable: !isStreaming,
      styleSheet: MarkdownStyleSheet(
        p: context.body.copyWith(height: 1.6, letterSpacing: -0.1),
        strong: context.bodyBold.copyWith(color: colorScheme.textPrimary),
        h1: context.headingSm.copyWith(fontWeight: FontWeight.w900),
        h2: context.title.copyWith(fontWeight: FontWeight.w800),
        listBullet: context.body,
        code: context.bodySm.copyWith(fontFamily: 'monospace', backgroundColor: colorScheme.elevatedSurface, color: colorScheme.textPrimary),
        codeblockPadding: const EdgeInsets.all(12),
        codeblockDecoration: BoxDecoration(
          color: colorScheme.elevatedSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.borderSubtle),
        ),
        tableHead: context.bodyBold,
        tableBody: context.body,
        tableBorder: TableBorder.all(color: colorScheme.borderSubtle, width: 0.5),
        blockquote: context.body.copyWith(color: colorScheme.textSecondary, fontStyle: FontStyle.italic),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: colorScheme.textPrimary, width: 2)),
          color: colorScheme.surfaceSubtle,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: colorScheme.borderSubtle, width: 0.5)),
        ),
      ),
    );
  }

  Widget _buildFeedbackRow(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 16, right: 10),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        GutChip(icon: AppIcons.thumbsUp, label: AppStrings.helpful, onTap: () => onFeedback!(AppStrings.labelHelpful), isSelected: feedback == AppStrings.labelHelpful),
        GutChip(icon: AppIcons.thumbsDown, label: AppStrings.notHelpful, onTap: () => onFeedback!(AppStrings.labelNotHelpful), isSelected: feedback == AppStrings.labelNotHelpful),
        GutChip(icon: AppIcons.refreshCcw, label: AppStrings.tellMeMore, onTap: () => onFeedback!(AppStrings.labelTellMeMore), isSelected: false),
      ],
    ),
  );

  Widget _buildImageStrip(BuildContext context, {required bool dark}) {
    final local = localImages;
    final count = (local != null && local.isNotEmpty) ? local.length : imageUrls.length;
    const size = 80.0;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(count, (i) {
        final borderRadius = BorderRadius.circular(16);
        final heroTag = 'chat_image_${local != null ? "local" : "url"}_${i}_${createdAt.millisecondsSinceEpoch}';

        final image = (local != null && local.isNotEmpty)
            ? Image.memory(local[i], height: size, width: size, fit: BoxFit.cover, gaplessPlayback: true)
            : RegistryThumbImage(fullUrl: imageUrls[i], hash: i < imageHashes.length ? imageHashes[i] : null, size: size, dark: dark);

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
        barrierColor: AppPalette.black.withAlpha(26),
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

  Widget _buildTrimmedRow(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(AppIcons.alertTriangle, size: 13, color: context.appColorScheme.warning),
      Gap.w8,
      Flexible(
        child: Text(
          AppStrings.responseTrimmedNotice,
          style: context.caption.copyWith(color: context.appColorScheme.warning, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );

  Widget _buildAssistantErrorCard(BuildContext context) {
    final isQuota = errorKind == ChatErrorKind.quota;
    final colorScheme = context.appColorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.p16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          border: Border.all(color: (isQuota ? colorScheme.warning : colorScheme.error).withAlpha(77)),
          borderRadius: BorderRadius.circular(AppSizes.r24),
          boxShadow: [BoxShadow(color: (isQuota ? colorScheme.warning : colorScheme.error).withAlpha(13), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Icon(AppIcons.alertCircle, size: 20, color: isQuota ? colorScheme.warning : colorScheme.error),
            Gap.w12,
            Expanded(
              child: Text(isQuota ? AppStrings.dailyLimitMessage : AppStrings.connectionError, style: context.bodySm.copyWith(color: colorScheme.textPrimary, height: 1.4)),
            ),
            if (isQuota && onQuotaPressed != null)
              TextButton(
                onPressed: onQuotaPressed,
                child: Text(AppStrings.upgrade.toUpperCase(), style: context.bodyBold.copyWith(fontSize: 11, color: colorScheme.textPrimary)),
              )
            else if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text(AppStrings.retry.toUpperCase(), style: context.bodyBold.copyWith(fontSize: 11, color: colorScheme.textPrimary)),
              ),
          ],
        ),
      ),
    );
  }
}

class _IntelligenceStamp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: colorScheme.textPrimary, borderRadius: BorderRadius.circular(50)),
      child: Text(
        AppStrings.appName,
        style: context.captionMicro.copyWith(color: colorScheme.cardBackground, letterSpacing: 0.5, fontWeight: FontWeight.w900),
      ),
    );
  }
}
