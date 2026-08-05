import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/remote_config_service.dart';
import 'package:gutgood/core/services/usage_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/extensions.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/auth/presentation/widgets/auth_bottom_sheets.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_provider.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:gutgood/features/scanner/presentation/pages/super_scanner_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:upgrader/upgrader.dart';

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

  Future<void> _handleCamera(ChatNotifier chatNotifier, GutAuthNotifier authNotifier,
      {ScannerMode mode = ScannerMode.label}) async {
    if (chatNotifier.isLoading) return;
    if (!await _guardUsage(chatNotifier, authNotifier, isScan: true)) return;

    if (!mounted) return;
    final result = await context.push(AppRoutes.scannerPath(mode.name));
    if (result == null || result is! Map<String, dynamic> || !result.containsKey('bytes')) return;

    final bytes = result['bytes'] as Uint8List;
    final type = result['type'] as String? ?? mode.name;

    final added = await chatNotifier.handleImageAttachment(bytes, type: type);
    if (!added) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(AppStrings.maxAttachmentsMessage), behavior: SnackBarBehavior.floating));
      }
      return;
    }

    setState(() {
      _controller.text = chatNotifier.getPromptForType(type);
    });
  }

  Future<void> _pickImages(ChatNotifier chatNotifier, GutAuthNotifier authNotifier) async {
    if (chatNotifier.isLoading) return;
    if (!await _guardUsage(chatNotifier, authNotifier, isScan: true)) return;

    try {
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final added = await chatNotifier.handleImageAttachment(bytes, type: 'gallery');

      if (added) {
        setState(() {
          _controller.text = chatNotifier.getPromptForType('gallery');
        });
      }
    } catch (e, st) {
      AppLogger.error('ChatScreen: Image pick failed', error: e, stackTrace: st);
    }
  }

  Future<bool> _guardUsage(ChatNotifier chatNotifier, GutAuthNotifier authNotifier,
      {required bool isScan}) async {
    final usageService = sl<UsageService>();
    final allowed = isScan ? await usageService.canScan() : await usageService.canChat();
    if (allowed) return true;

    if (mounted) {
      if (authNotifier.isAnonymous) {
        unawaited(showAuthBottomSheet(context,
            customMessage: AppStrings.chatAuthMessage, onSuccess: chatNotifier.refreshHistory));
      } else {
        unawaited(showPaywallBottomSheet(context, onProceedWithLimited: () {}));
      }
    }
    return false;
  }

  Future<void> _send(ChatNotifier chatNotifier, GutAuthNotifier authNotifier,
      [String? quickText]) async {
    if (chatNotifier.isLoading) return;

    final hasImages = chatNotifier.pendingAttachments.isNotEmpty;
    final msg = (quickText ?? _controller.text).trim();
    if (msg.isEmpty && !hasImages) return;

    if (!await _guardUsage(chatNotifier, authNotifier, isScan: hasImages)) return;

    final error = await chatNotifier.send(
        text: msg,
        hiddenContext: hasImages ? chatNotifier.pendingHiddenContext : null,
        source: 'chat');

    if (!mounted) return;

    if (error == null) {
      _controller.clear();
      _clearDraft();
      chatNotifier.clearPendingHiddenContext();
      _scrollToBottom(animated: false);
      return;
    }

    switch (error) {
      case ChatSendError.offline:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(AppStrings.offlineMessage), behavior: SnackBarBehavior.floating));
      case ChatSendError.uploadFailed:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(AppStrings.connectionError), behavior: SnackBarBehavior.floating));
      case ChatSendError.busy:
      case ChatSendError.empty:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatNotifier = context.read<ChatNotifier>();
      if (chatNotifier.isStreaming && _isNearBottom) {
        _scrollToBottom(animated: false);
      }
    });

    return UpgradeAlert(
      dialogStyle:
          Platform.isAndroid ? UpgradeDialogStyle.material : UpgradeDialogStyle.cupertino,
      barrierDismissible: !RemoteConfigService.instance.isForceUpdateApp,
      showReleaseNotes: !kReleaseMode,
      showIgnore: !RemoteConfigService.instance.isForceUpdateApp,
      showLater: !RemoteConfigService.instance.isForceUpdateApp,
      shouldPopScope: () => !RemoteConfigService.instance.isForceUpdateApp,
      onIgnore: () => true,
      onLater: () => true,
      onUpdate: () => true,
      upgrader: Upgrader(
        durationUntilAlertAgain:
            RemoteConfigService.instance.isForceUpdateApp == true ? Duration.zero : const Duration(days: 3),
        debugLogging: !kReleaseMode,
        debugDisplayAlways: false,
        messages: UpgraderMessages(),
      ),
      child: Scaffold(
        backgroundColor: context.appColorScheme.cardBackground,
        appBar: const _ChatAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _MessageListView(
                  scrollController: _scroll,
                  onSend: _send,
                ),
              ),
              const _SuggestionChipsSection(),
              _ChatComposer(
                controller: _controller,
                onChanged: _scheduleDraftSave,
                onCamera: _handleCamera,
                onGallery: _pickImages,
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar();

  @override
  Widget build(BuildContext context) => Selector2<ProfileNotifier, InsightsNotifier, (int?, bool)>(
      selector: (_, p, i) => (p.profile?.streak, i.healthAlerts.any((a) => !a.isRead)),
      builder: (context, data, _) {
        final streak = data.$1;
        final hasUnreadAlerts = data.$2;

        return GutAppBar(
          title: AppStrings.gutgood,
          showBrandingIcon: true,
          streak: streak,
          actions: [
            GestureDetector(
              onTap: () => showPaywallBottomSheet(context, onProceedWithLimited: () {}),
              child: const Tooltip(message: AppStrings.viewPremiumBenefits, child: PremiumBadge()),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(AppIcons.bell,
                      color: context.appColorScheme.textPrimary, size: AppSizes.icon20),
                  onPressed: () => context.push(AppRoutes.notificationArchive),
                ),
                if (hasUnreadAlerts)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: context.appColorScheme.error,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: context.appColorScheme.cardBackground, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            Gap.w4,
          ],
        );
      },
    );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _MessageListView extends StatelessWidget {
  const _MessageListView({required this.scrollController, required this.onSend});
  final ScrollController scrollController;
  final Future<void> Function(ChatNotifier, GutAuthNotifier, [String?]) onSend;

  @override
  Widget build(BuildContext context) => Selector<ChatNotifier, (bool, int, bool)>(
      selector: (_, n) => (n.historyLoading, n.messages.length, n.isLoading),
      builder: (context, state, _) {
        final historyLoading = state.$1;
        final messageCount = state.$2;
        final isLoading = state.$3;

        if (historyLoading) return const _ChatShimmerLoading();
        if (messageCount <= 1 && !isLoading) return const _EmptyChatState();

        return CustomScrollView(
          controller: scrollController,
          reverse: true,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p20),
              sliver: const _MessageSliverList(),
            ),
          ],
        );
      },
    );
}

class _MessageSliverList extends StatelessWidget {
  const _MessageSliverList();

  @override
  Widget build(BuildContext context) {
    final chatNotifier = context.read<ChatNotifier>();
    final messages = context.select<ChatNotifier, List<ChatMessage>>((n) => n.messages);
    final isStreaming = context.select<ChatNotifier, bool>((n) => n.isStreaming);
    final isLoading = context.select<ChatNotifier, bool>((n) => n.isLoading);
    final latestAiIndex = _latestAiIndex(messages);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          final msg = messages[i];
          final prevMsg = i < messages.length - 1 ? messages[i + 1] : null;

          var showDateHeader = false;
          if (prevMsg == null) {
            showDateHeader = true;
          } else {
            final d1 = DateTime(msg.time.year, msg.time.month, msg.time.day);
            final d2 = DateTime(prevMsg.time.year, prevMsg.time.month, prevMsg.time.day);
            if (d1 != d2) showDateHeader = true;
          }

          final showAvatar =
              msg.role == 'ai' && (prevMsg == null || prevMsg.role != 'ai' || showDateHeader);
          final isLatestAi = i == latestAiIndex;

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
                isLoading: msg.role == 'ai' &&
                    msg.text.isEmpty &&
                    msg.errorKind == ChatErrorKind.none &&
                    msg.scanData == null,
                imageUrls: msg.imageUrls,
                localImages: msg.localImages,
                isSending: msg.isSending,
                sendFailed: msg.sendFailed,
                isStreaming: isStreaming && isLatestAi,
                errorKind: msg.errorKind,
                screenWidth: MediaQuery.sizeOf(context).width,
                showAvatar: showAvatar,
                showActions: isLatestAi && msg.text.isNotEmpty && !isLoading,
                onRegenerate: chatNotifier.canRegenerate
                    ? () {
                        HapticHelper.light();
                        unawaited(chatNotifier.regenerateLastResponse());
                      }
                    : null,
                onRetry: msg.sendFailed
                    ? () => unawaited(chatNotifier.retryMessage(msg))
                    : (msg.errorKind == ChatErrorKind.connection
                        ? () => unawaited(chatNotifier.regenerateLastResponse())
                        : null),
                onQuotaPressed: () =>
                    unawaited(showPaywallBottomSheet(context, onProceedWithLimited: () {})),
                showFeedback: isLatestAi &&
                    !isStreaming &&
                    msg.text.isNotEmpty &&
                    msg.scanData == null &&
                    msg.swapData == null &&
                    msg.errorKind == ChatErrorKind.none,
                feedback: msg.feedback,
                onFeedback: (type) async {
                  if (msg.feedback != null) return;
                  if (type == 'helpful' || type == 'not_helpful') {
                    unawaited(chatNotifier.handleFeedback(msg, type));
                    HapticHelper.light();
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text(AppStrings.thanksFeedback),
                          behavior: SnackBarBehavior.floating));
                    }
                  }
                },
              ),
              if (msg.isSwap == true && msg.swapData != null)
                SwapItContainer(
                    swaps: msg.swapData!,
                    onSeeMore: () => chatNotifier.handleSeeMoreSwaps(msg.text, i)),
              if (msg.scanData != null)
                ScanResultInlineCard(
                  scanData: msg.scanData!,
                  onViewFullReport: () => unawaited(context
                      .push(AppRoutes.scanResult, extra: {'scanData': msg.scanData!.toMap()})),
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
            final targetId = key.value;
            final idx = messages.indexWhere((m) => m.localId == targetId);
            return idx == -1 ? null : idx;
          }
          return null;
        },
      ),
    );
  }

  int _latestAiIndex(List<ChatMessage> messages) {
    for (var i = 0; i < messages.length; i++) {
      if (messages[i].role == 'ai') return i;
    }
    return -1;
  }
}

class _SuggestionChipsSection extends StatelessWidget {
  const _SuggestionChipsSection();

  @override
  Widget build(BuildContext context) => Selector<ChatNotifier, (int, bool, bool)>(
      selector: (_, n) => (n.messages.length, n.isLoading, n.historyLoading),
      builder: (context, data, _) {
        final count = data.$1;
        final isLoading = data.$2;
        final historyLoading = data.$3;

        if (count > 1 || isLoading || historyLoading) return const SizedBox.shrink();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
        child: Row(
          children: [
            _Chip(AppStrings.chipBloated,
                () => unawaited(_sendQuick(context, AppStrings.chipBloatedPrompt))),
            _Chip(AppStrings.chipHealthy,
                () => unawaited(_sendQuick(context, AppStrings.chipHealthyPrompt))),
            _Chip(AppStrings.chipSwap,
                () => unawaited(_sendQuick(context, AppStrings.chipSwapPrompt))),
            _Chip(
                AppStrings.chipRestaurant, () => _handleCameraQuick(context, ScannerMode.menu)),
          ],
        ),
        );
      },
    );

  Future<void> _sendQuick(BuildContext context, String text) async {
    final chatNotifier = context.read<ChatNotifier>();
    final authNotifier = context.read<GutAuthNotifier>();
    final state = context.findAncestorStateOfType<_ChatScreenState>();
    await state?._send(chatNotifier, authNotifier, text);
  }

  void _handleCameraQuick(BuildContext context, ScannerMode mode) {
    final chatNotifier = context.read<ChatNotifier>();
    final authNotifier = context.read<GutAuthNotifier>();
    final state = context.findAncestorStateOfType<_ChatScreenState>();
    state?._handleCamera(chatNotifier, authNotifier, mode: mode);
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.onChanged,
    required this.onCamera,
    required this.onGallery,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final Future<void> Function(ChatNotifier, GutAuthNotifier, {ScannerMode mode})
      onCamera;
  final Future<void> Function(ChatNotifier, GutAuthNotifier) onGallery;
  final Future<void> Function(ChatNotifier, GutAuthNotifier, [String?]) onSend;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    final chatNotifier = context.watch<ChatNotifier>();
    final authNotifier = context.read<GutAuthNotifier>();

    return Container(
      color: colorScheme.cardBackground,
      padding: EdgeInsets.all(AppSizes.p12),
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
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GutTextField(
                      controller: controller,
                      maxLines: 5,
                      minLines: 1,
                      onChanged: (_) => onChanged(),
                      hintText: chatNotifier.isStreaming ? AppStrings.thinking : AppStrings.askAnything,
                      borderless: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                  _ComposerIconButton(
                    icon: AppIcons.camera,
                    label: AppStrings.scanIngredientsMeal,
                    onTap: chatNotifier.isLoading ? null : () => onCamera(chatNotifier, authNotifier),
                  ),
                  Gap.w4,
                  _ComposerIconButton(
                    icon: AppIcons.image,
                    label: AppStrings.attachPhotos,
                    onTap: chatNotifier.isLoading ? null : () => onGallery(chatNotifier, authNotifier),
                  ),
                  Gap.w4,
                  _SendStopButton(
                    controller: controller,
                    chatNotifier: chatNotifier,
                    onSend: () => onSend(chatNotifier, authNotifier),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendStopButton extends StatelessWidget {
  const _SendStopButton({
    required this.controller,
    required this.chatNotifier,
    required this.onSend,
  });

  final TextEditingController controller;
  final ChatNotifier chatNotifier;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasContent =
            controller.text.trim().isNotEmpty || chatNotifier.pendingAttachments.isNotEmpty;
        final colorScheme = context.appColorScheme;

        if (chatNotifier.isStreaming) {
          return _ComposerActionCircle(
            label: AppStrings.stopGenerating,
            onTap: () {
              HapticHelper.light();
              chatNotifier.stopGeneration();
            },
            icon: Icon(AppIcons.square, color: colorScheme.cardBackground, size: 14, fill: 1.0),
          );
        }

        if (chatNotifier.isLoading) {
          return _ComposerActionCircle(
            label: 'Loading',
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(color: colorScheme.cardBackground, strokeWidth: 2),
            ),
          );
        }

        return _ComposerActionCircle(
          label: AppStrings.sendMessage,
          onTap: hasContent ? onSend : null,
          enabled: hasContent,
          icon: Icon(AppIcons.send, color: colorScheme.cardBackground, size: 20),
        );
      },
    );
}

class _ComposerActionCircle extends StatelessWidget {
  const _ComposerActionCircle({
    required this.label,
    this.onTap,
    this.icon,
    this.child,
    this.enabled = true,
  });

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
            decoration: BoxDecoration(
              color: enabled ? colorScheme.textPrimary : colorScheme.textPrimary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(child: child ?? icon),
          ),
        ),
      ),
    );
  }
}

class _AttachmentPreviewRow extends StatelessWidget {
  const _AttachmentPreviewRow({required this.notifier});
  final ChatNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final attachments = notifier.pendingAttachments;
    if (attachments.isEmpty) return const SizedBox.shrink();
    final attachment = attachments.first;

    return Container(
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
                  pageBuilder: (context, _, _) => ImagePreviewDialog(localImages: [attachment.bytes], initialIndex: 0, heroTag: 'attachment_${attachment.id}'),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
                ),
              );
            },
            child: Hero(
              tag: 'attachment_${attachment.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(attachment.bytes, width: 60, height: 60, fit: BoxFit.cover, gaplessPlayback: true),
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
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({required this.icon, required this.label, this.onTap});
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

class _AnimatedChatItem extends StatefulWidget {
  const _AnimatedChatItem({required this.child});
  final Widget child;

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
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: _visible ? 1.0 : 0.0,
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOutCubic,
    child: AnimatedSlide(offset: _visible ? Offset.zero : const Offset(0, 0.02), duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic, child: widget.child),
  );
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) => Center(
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

class _ChatShimmerLoading extends StatelessWidget {
  const _ChatShimmerLoading();

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p20),
    itemCount: 10,
    reverse: true,
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
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: Container(
                  width: AppSizes.icon28,
                  height: AppSizes.icon28,
                  decoration: BoxDecoration(color: context.appColorScheme.cardBackground, shape: BoxShape.circle),
                ),
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
                  color: context.appColorScheme.cardBackground,
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

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});
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
  const _Chip(this.label, this.onTap);
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
        style: context.caption.copyWith(color: context.appColorScheme.textPrimary, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
