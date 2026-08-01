import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/services/remote_config_service.dart';
import 'package:gutgood/core/services/usage_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/extensions.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/auth/presentation/widgets/auth_bottom_sheets.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:upgrader/upgrader.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_icons.dart';
import 'package:gutgood/core/router/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../scanner/presentation/pages/super_scanner_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const String _draftKey = 'chat_draft';

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ImagePicker _picker = ImagePicker();

  /// Hidden vision/analysis instruction attached to scanner-captured images.
  /// Sent to the AI alongside the user's visible text; never displayed.
  String? _pendingHiddenContext;

  bool _isNearBottom = true;
  Timer? _draftDebounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _restoreDraft();
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _scroll.removeListener(_onScroll);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Reverse list: offset 0 is the visual bottom.
    _isNearBottom = !_scroll.hasClients || _scroll.position.pixels <= 150;
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scroll.hasClients) return;
    if (animated) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _scroll.jumpTo(0.0);
    }
  }

  // ---------------------------------------------------------------------------
  // Draft persistence
  // ---------------------------------------------------------------------------
  void _restoreDraft() {
    final draft = sl<SharedPreferences>().getString(_draftKey);
    if (draft != null && draft.isNotEmpty) {
      _controller.text = draft;
    }
  }

  void _scheduleDraftSave() {
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 400), () {
      final text = _controller.text;
      final prefs = sl<SharedPreferences>();
      if (text.trim().isEmpty) {
        prefs.remove(_draftKey);
      } else {
        prefs.setString(_draftKey, text);
      }
    });
  }

  void _clearDraft() {
    _draftDebounce?.cancel();
    sl<SharedPreferences>().remove(_draftKey);
  }

  // ---------------------------------------------------------------------------
  // Attachments (ChatGPT model: previews in composer, sent only on Send)
  // ---------------------------------------------------------------------------
  Future<void> _handleCamera(ChatNotifier chatNotifier, GutAuthNotifier authNotifier, {ScannerMode mode = ScannerMode.label}) async {
    if (chatNotifier.isLoading) return;
    if (!await _guardUsage(chatNotifier, authNotifier, isScan: true)) return;

    if (!mounted) return;
    final result = await context.push(AppRoutes.scannerPath(mode.name));
    if (result == null || result is! Map || !result.containsKey('bytes')) return;

    final bytes = result['bytes'] as Uint8List;
    final type = result['type'] as String? ?? mode.name;

    final added = await chatNotifier.addAttachment(bytes, source: type);
    if (!added) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.maxAttachmentsMessage), behavior: SnackBarBehavior.floating));
      }
      return;
    }

    setState(() {
      _pendingHiddenContext = switch (type) {
        'menu' => AppStrings.restaurantMenuInstruction,
        'label' => AppStrings.analyzeLabelVision,
        'food' => AppStrings.analyzeMealVision,
        _ => AppStrings.analyzeGalleryVision,
      };

      // Pre-fill an editable suggested prompt (the user can change or erase it —
      // exactly like ChatGPT's caption field under an attached photo).
      if (_controller.text.trim().isEmpty) {
        _controller.text = switch (type) {
          'menu' => AppStrings.menuPhotoPrompt,
          'label' => AppStrings.labelPhotoPrompt,
          'food' => AppStrings.mealPhotoPrompt,
          _ => AppStrings.galleryPhotoPrompt,
        };
      }
    });
  }

  Future<void> _pickImages(ChatNotifier chatNotifier, GutAuthNotifier authNotifier) async {
    if (chatNotifier.isLoading) return;
    if (!await _guardUsage(chatNotifier, authNotifier, isScan: true)) return;

    try {
      final remaining = ChatNotifier.maxAttachments - chatNotifier.pendingAttachments.length;
      if (remaining <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.maxAttachmentsMessage), behavior: SnackBarBehavior.floating));
        }
        return;
      }

      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80, limit: remaining);
      if (images.isEmpty) return;

      var addedAny = false;
      for (final image in images) {
        final bytes = await image.readAsBytes();
        addedAny = (await chatNotifier.addAttachment(bytes, source: 'gallery')) || addedAny;
      }

      if (addedAny) {
        setState(() => _pendingHiddenContext ??= AppStrings.analyzeGalleryVision);
      }
    } catch (e, st) {
      Log.e('ChatScreen: Image pick failed', error: e, stackTrace: st);
    }
  }

  // ---------------------------------------------------------------------------
  // Sending
  // ---------------------------------------------------------------------------
  Future<bool> _guardUsage(ChatNotifier chatNotifier, GutAuthNotifier authNotifier, {required bool isScan}) async {
    final usageService = sl<UsageService>();
    final allowed = isScan ? await usageService.canScan() : await usageService.canChat();
    Log.d('ChatScreen: usage guard (scan: $isScan) -> $allowed');
    if (allowed) return true;

    if (mounted) {
      if (authNotifier.isAnonymous) {
        showAuthBottomSheet(context, customMessage: AppStrings.chatAuthMessage, onSuccess: chatNotifier.refreshHistory);
      } else {
        showPaywallBottomSheet(context, onProceedWithLimited: () {});
      }
    }
    return false;
  }

  Future<void> _send(ChatNotifier chatNotifier, GutAuthNotifier authNotifier, [String? quickText]) async {
    if (chatNotifier.isLoading) return;

    final bool hasImages = chatNotifier.pendingAttachments.isNotEmpty;
    final String msg = (quickText ?? _controller.text).trim();
    if (msg.isEmpty && !hasImages) return;

    if (!await _guardUsage(chatNotifier, authNotifier, isScan: hasImages)) return;

    final error = await chatNotifier.send(text: msg, hiddenContext: hasImages ? _pendingHiddenContext : null, source: 'chat');

    if (!mounted) return;

    if (error == null) {
      _controller.clear();
      _clearDraft();
      setState(() => _pendingHiddenContext = null);
      _scrollToBottom(animated: false);
      return;
    }

    switch (error) {
      case ChatSendError.offline:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.offlineMessage), behavior: SnackBarBehavior.floating));
      case ChatSendError.uploadFailed:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.connectionError), behavior: SnackBarBehavior.floating));
      case ChatSendError.busy:
      case ChatSendError.empty:
        break;
    }
  }

  int _latestAiIndex(List<ChatMessage> messages) {
    for (var i = 0; i < messages.length; i++) {
      if (messages[i].role == 'ai') return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final chatNotifier = context.watch<ChatNotifier>();
    final authNotifier = context.read<GutAuthNotifier>();
    final screenWidth = context.width;
    final messages = chatNotifier.messages;
    final latestAi = _latestAiIndex(messages);

    // ChatGPT follow-scroll: while tokens arrive, stick to the bottom unless
    // the user deliberately scrolled up to read.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatNotifier.isStreaming && _isNearBottom) {
        _scrollToBottom(animated: false);
      }
    });

    return UpgradeAlert(
      dialogStyle: Platform.isAndroid ? UpgradeDialogStyle.material : UpgradeDialogStyle.cupertino,
      barrierDismissible: !RemoteConfigService.instance.isForceUpdateApp,
      showReleaseNotes: !kReleaseMode,
      showIgnore: !RemoteConfigService.instance.isForceUpdateApp,
      showLater: !RemoteConfigService.instance.isForceUpdateApp,
      shouldPopScope: () => !RemoteConfigService.instance.isForceUpdateApp,
      onIgnore: () => true,
      onLater: () => true,
      onUpdate: () => true,
      upgrader: Upgrader(
        durationUntilAlertAgain: RemoteConfigService.instance.isForceUpdateApp == true ? const Duration(seconds: 0) : const Duration(days: 3),
        debugLogging: !kReleaseMode,
        debugDisplayAlways: false,
        messages: UpgraderMessages(),
        willDisplayUpgrade: ({required bool display, String? installedVersion, UpgraderVersionInfo? versionInfo}) {
          Log.d("UpgradeAlert display: $display, installed: $installedVersion, store: ${versionInfo?.appStoreVersion}");
        },
      ),
      child: Scaffold(
        backgroundColor: context.appColorScheme.cardBackground,
        appBar: GutAppBar(
          title: AppStrings.gutgood,
          showBrandingIcon: true,
          actions: [
            GestureDetector(
              onTap: () => showPaywallBottomSheet(context, onProceedWithLimited: () {}),
              child: const Tooltip(message: AppStrings.viewPremiumBenefits, child: PremiumBadge()),
            ),
            Gap.w16,
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  controller: _scroll,
                  reverse: true,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    if (chatNotifier.historyLoading)
                      const SliverToBoxAdapter(child: _ChatShimmerLoading())
                    else if (messages.length <= 1 && !chatNotifier.isLoading)
                      const SliverFillRemaining(child: _EmptyChatState())
                    else
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final msg = messages[i];
                              final prevMsg = i < messages.length - 1 ? messages[i + 1] : null;

                              bool showDateHeader = false;
                              if (prevMsg == null) {
                                showDateHeader = true;
                              } else {
                                final d1 = DateTime(msg.time.year, msg.time.month, msg.time.day);
                                final d2 = DateTime(prevMsg.time.year, prevMsg.time.month, prevMsg.time.day);
                                if (d1 != d2) showDateHeader = true;
                              }

                              final bool showAvatar = msg.role == 'ai' && (prevMsg == null || prevMsg.role != 'ai' || showDateHeader);
                              final bool isLatestAi = i == latestAi;

                              return KeyedSubtree(
                                key: ValueKey(msg.localId),
                                child: _AnimatedChatItem(
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: AppSizes.p12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        if (showDateHeader) _DateHeader(date: msg.time),
                                        ChatBubble(
                                          text: msg.text,
                                          isUser: msg.role == 'user',
                                          time: msg.time,
                                          isLoading: msg.role == 'ai' && msg.text.isEmpty && msg.errorKind == ChatErrorKind.none && msg.scanData == null,
                                          imageUrls: msg.imageUrls,
                                          localImages: msg.localImages,
                                          isSending: msg.isSending,
                                          sendFailed: msg.sendFailed,
                                          isStreaming: chatNotifier.isStreaming && isLatestAi,
                                          errorKind: msg.errorKind,
                                          screenWidth: screenWidth,
                                          showAvatar: showAvatar,
                                          showActions: isLatestAi && msg.text.isNotEmpty && !chatNotifier.isLoading,
                                          onRegenerate: chatNotifier.canRegenerate
                                              ? () {
                                                  HapticHelper.light();
                                                  chatNotifier.regenerateLastResponse();
                                                }
                                              : null,
                                          onRetry: msg.sendFailed
                                              ? () => chatNotifier.retryMessage(msg)
                                              : (msg.errorKind == ChatErrorKind.connection ? () => chatNotifier.regenerateLastResponse() : null),
                                          onQuotaPressed: () => showPaywallBottomSheet(context, onProceedWithLimited: () {}),
                                          showFeedback:
                                              isLatestAi && !chatNotifier.isStreaming && msg.text.isNotEmpty && msg.scanData == null && msg.swapData == null && msg.errorKind == ChatErrorKind.none,
                                          feedback: msg.feedback,
                                          onFeedback: (type) async {
                                            if (msg.feedback != null) return;
                                            if (type == 'helpful' || type == 'not_helpful') {
                                              chatNotifier.handleFeedback(msg, type);
                                              HapticHelper.light();
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.thanksFeedback), behavior: SnackBarBehavior.floating));
                                              }
                                            } else if (type == 'tell_me_more') {
                                              _send(chatNotifier, authNotifier, AppStrings.tellMeMorePrompt);
                                            }
                                          },
                                        ),
                                        if (msg.isSwap == true && msg.swapData != null) SwapItContainer(swaps: msg.swapData!, onSeeMore: () => chatNotifier.handleSeeMoreSwaps(msg.text, i)),
                                        if (msg.scanData != null)
                                          ScanResultInlineCard(
                                            scanData: msg.scanData!,
                                            onViewFullReport: () => context.push(AppRoutes.scanResult, extra: {'scanData': msg.scanData!.toMap()}),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: messages.length,
                            findChildIndexCallback: (key) {
                              if (key is ValueKey<String>) {
                                final idx = messages.indexWhere((m) => m.localId == key.value);
                                return idx == -1 ? null : idx;
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (messages.length <= 1 && !chatNotifier.isLoading && !chatNotifier.historyLoading)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
                  child: Row(
                    children: [
                      _Chip(AppStrings.chipBloated, () => _send(chatNotifier, authNotifier, AppStrings.chipBloatedPrompt)),
                      _Chip(AppStrings.chipHealthy, () => _send(chatNotifier, authNotifier, AppStrings.chipHealthyPrompt)),
                      _Chip(AppStrings.chipSwap, () => _send(chatNotifier, authNotifier, AppStrings.chipSwapPrompt)),
                      _Chip(AppStrings.chipRestaurant, () => _handleCamera(chatNotifier, authNotifier, mode: ScannerMode.menu)),
                    ],
                  ),
                ),
              _buildComposer(chatNotifier, authNotifier),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Composer (ChatGPT-style: previews above an editable field, smart send/stop)
  // ---------------------------------------------------------------------------
  Widget _buildComposer(ChatNotifier chatNotifier, GutAuthNotifier authNotifier) {
    final colorScheme = context.appColorScheme;

    return Container(
      color: colorScheme.cardBackground,
      padding: EdgeInsets.fromLTRB(AppSizes.p12, AppSizes.p12, AppSizes.p12, AppSizes.p12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (chatNotifier.pendingAttachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _AttachmentPreviewRow(notifier: chatNotifier),
              ),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.elevatedSurface,
                borderRadius: BorderRadius.circular(AppSizes.r16),
                border: Border.all(color: colorScheme.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: GutTextField(
                      controller: _controller,
                      maxLines: 5,
                      minLines: 1,
                      onChanged: (_) => _scheduleDraftSave(),
                      hintText: chatNotifier.isStreaming ? AppStrings.thinking : AppStrings.askAnything,
                      borderless: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                  _ComposerIconButton(
                    icon: AppIcons.camera,
                    label: AppStrings.scanIngredientsMeal,
                    onTap: chatNotifier.isLoading ? null : () => _handleCamera(chatNotifier, authNotifier),
                  ),
                  Gap.w4,
                  _ComposerIconButton(
                    icon: AppIcons.image,
                    label: AppStrings.attachPhotos,
                    onTap: chatNotifier.isLoading ? null : () => _pickImages(chatNotifier, authNotifier),
                  ),
                  Gap.w4,
                  _buildSendStopButton(chatNotifier, authNotifier),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendStopButton(ChatNotifier chatNotifier, GutAuthNotifier authNotifier) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final bool hasContent = _controller.text.trim().isNotEmpty || chatNotifier.pendingAttachments.isNotEmpty;
        final colorScheme = context.appColorScheme;

        // Streaming → ChatGPT's stop control.
        if (chatNotifier.isStreaming) {
          return Semantics(
            label: AppStrings.stopGenerating,
            button: true,
            child: Tooltip(
              message: AppStrings.stopGenerating,
              child: GestureDetector(
                onTap: () {
                  HapticHelper.light();
                  chatNotifier.stopGeneration();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: colorScheme.textPrimary, shape: BoxShape.circle),
                  child: Icon(AppIcons.square, color: colorScheme.cardBackground, size: 14, fill: 1.0),
                ),
              ),
            ),
          );
        }

        // Uploading/preparing → inert spinner.
        if (chatNotifier.isLoading) {
          return Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: colorScheme.textPrimary, shape: BoxShape.circle),
            child: Center(
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: colorScheme.cardBackground, strokeWidth: 2)),
            ),
          );
        }

        final bool enabled = hasContent;
        return Semantics(
          label: AppStrings.sendMessage,
          button: true,
          enabled: enabled,
          child: Tooltip(
            message: AppStrings.sendMessage,
            child: GestureDetector(
              onTap: enabled ? () => _send(chatNotifier, authNotifier) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: colorScheme.textPrimary, shape: BoxShape.circle),
                child: Icon(AppIcons.send, color: colorScheme.cardBackground, size: 20),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Thumbnail strip of pending attachments shown INSIDE the composer,
/// above the (still fully editable) text field — the core ChatGPT pattern.
class _AttachmentPreviewRow extends StatelessWidget {
  final ChatNotifier notifier;
  const _AttachmentPreviewRow({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final attachments = notifier.pendingAttachments;
    return Container(
      height: 68,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return KeyedSubtree(
            key: ValueKey(attachment.id),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(attachment.bytes, width: 60, height: 60, fit: BoxFit.cover, gaplessPlayback: true),
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
                        notifier.removeAttachment(attachment.id);
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
          );
        },
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ComposerIconButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
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
                border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
              ),
              child: Icon(icon, color: context.appColorScheme.textPrimary, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

/// Runs the entrance animation exactly once per message — the previous
/// implementation re-animated every bubble on every streaming token (jank).
class _AnimatedChatItem extends StatefulWidget {
  final Widget child;
  const _AnimatedChatItem({required this.child});

  @override
  State<_AnimatedChatItem> createState() => _AnimatedChatItemState();
}

class _AnimatedChatItemState extends State<_AnimatedChatItem> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(offset: _visible ? Offset.zero : const Offset(0, 0.02), duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic, child: widget.child),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.p40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppAssets.appMascot, width: AppSizes.p120),
            Gap.h32,
            Text(AppStrings.heyImGutGood, style: context.headingMd.copyWith(fontWeight: FontWeight.w900)),
            Gap.h12,
            Text(
              AppStrings.gutgoodEmptyDescription,
              textAlign: TextAlign.center,
              style: context.body.copyWith(color: context.appColorScheme.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatShimmerLoading extends StatelessWidget {
  const _ChatShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p20),
      itemCount: 10,
      reverse: true,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final isUser = index % 2 == 0;
        final baseColor = context.appColorScheme.border.withValues(alpha: 0.2);
        final highlightColor = context.appColorScheme.border.withValues(alpha: 0.1);

        if (isUser) {
          return Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(bottom: AppSizes.p12),
              child: Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  width: context.width * (0.4 + (index % 3) * 0.1),
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
                child: Container(
                  width: AppSizes.icon28,
                  height: AppSizes.icon28,
                  decoration: const BoxDecoration(color: AppPalette.white, shape: BoxShape.circle),
                ),
              ),
              Gap.w12,
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  width: context.width * (0.5 + (index % 2) * 0.1),
                  height: AppSizes.h74,
                  decoration: BoxDecoration(
                    color: AppPalette.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppSizes.r8),
                      topRight: Radius.circular(AppSizes.r24),
                      bottomLeft: Radius.circular(AppSizes.r24),
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
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

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
      margin: EdgeInsets.symmetric(vertical: AppSizes.p24),
      child: Row(
        children: [
          Expanded(child: Divider(color: context.appColorScheme.border)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
            child: Text(
              label.toUpperCase(),
              style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          Expanded(child: Divider(color: context.appColorScheme.border)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Chip(this.label, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
          style: context.caption.copyWith(color: context.appColorScheme.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
