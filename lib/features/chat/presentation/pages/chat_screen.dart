import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/route_arguments.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/remote_config_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/quota_guard.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_provider.dart';
import 'package:gutgood/features/chat/presentation/widgets/chat_components.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:gutgood/features/scanner/presentation/pages/super_scanner_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  bool _hasScrolledToBottomInitially = false;
  ChatNotifier? _chatNotifier;
  Timer? _draftDebounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _restoreDraft();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _chatNotifier = context.read<ChatNotifier>();
      _chatNotifier?.addListener(_handleHistoryLoaded);
      _handleHistoryLoaded(); // Check if history is already loaded
    });
  }

  @override
  void dispose() {
    _chatNotifier?.removeListener(_handleHistoryLoaded);
    _draftDebounce?.cancel();
    _scroll.removeListener(_onScroll);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _handleHistoryLoaded() {
    if (_chatNotifier == null) return;
    if (!_chatNotifier!.historyLoading && !_hasScrolledToBottomInitially && _chatNotifier!.messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scrollToBottom();
          _hasScrolledToBottomInitially = true;
          setState(() {});
        }
      });
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;

    // Load more: at the top
    if (_scroll.position.pixels <= 50) {
      context.read<ChatNotifier>().loadMore();
    }
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
      // Double-check after next frame to handle sliver expansion
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
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

  Future<void> _handleCamera(ChatNotifier chatNotifier, GutAuthNotifier authNotifier, {ScannerMode mode = ScannerMode.label}) async {
    if (chatNotifier.isLoading) return;
    if (!await QuotaGuard.check(context, type: QuotaType.scan, onAuthSuccess: chatNotifier.refreshHistory)) return;

    if (!mounted) return;
    final result = await context.push(AppRoutes.scannerPath(mode.name));
    if (result == null || result is! Map<String, dynamic> || !result.containsKey('bytes')) return;

    final bytes = result['bytes'] as Uint8List;
    final type = result['type'] as String? ?? mode.name;

    final added = await chatNotifier.handleImageAttachment(bytes, type: type);
    if (!added) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.maxAttachmentsMessage), behavior: SnackBarBehavior.floating));
      }
      return;
    }

    setState(() {
      _controller.text = chatNotifier.getPromptForType(type);
    });
  }

  Future<void> _pickImages(ChatNotifier chatNotifier, GutAuthNotifier authNotifier) async {
    if (chatNotifier.isLoading) return;
    if (!await QuotaGuard.check(context, type: QuotaType.scan, onAuthSuccess: chatNotifier.refreshHistory)) return;

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

  Future<void> _send(ChatNotifier chatNotifier, GutAuthNotifier authNotifier, [String? quickText]) async {
    if (chatNotifier.isLoading) return;

    final hasImages = chatNotifier.pendingAttachments.isNotEmpty;
    final msg = (quickText ?? _controller.text).trim();
    if (msg.isEmpty && !hasImages) return;

    // Dismiss keyboard on send
    FocusManager.instance.primaryFocus?.unfocus();

    if (!await QuotaGuard.check(context, type: hasImages ? QuotaType.scan : QuotaType.chat, onAuthSuccess: chatNotifier.refreshHistory)) return;

    final error = await chatNotifier.send(text: msg, hiddenContext: hasImages ? chatNotifier.pendingHiddenContext : null, source: 'chat');

    if (!mounted) return;

    if (error == null) {
      _controller.clear();
      _clearDraft();
      chatNotifier.clearPendingHiddenContext();
      // 🟢 Fix: Removed automatic scroll to bottom.
      // This allows the user to maintain their scroll position even after sending a message,
      // preventing the screen from being yanked to the "end" as the AI starts responding.
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

  @override
  Widget build(BuildContext context) => UpgradeAlert(
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
      durationUntilAlertAgain: RemoteConfigService.instance.isForceUpdateApp == true ? Duration.zero : const Duration(days: 3),
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
              child: _MessageListView(scrollController: _scroll, onSend: _send),
            ),
            const _SuggestionChipsSection(),
            _ChatComposer(controller: _controller, onChanged: _scheduleDraftSave, onCamera: _handleCamera, onGallery: _pickImages, onSend: _send),
          ],
        ),
      ),
    ),
  );
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
                icon: Icon(AppIcons.bell, color: context.appColorScheme.textPrimary, size: AppSizes.icon20),
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
                      border: Border.all(color: context.appColorScheme.cardBackground, width: 1.5),
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
      final allMessages = context.read<ChatNotifier>().messages;
      final messages = allMessages.where((m) => !m.isHidden).toList();
      final messageCount = messages.length;
      final isLoading = state.$3;

      if (historyLoading) return const ChatShimmerLoading();
      if (messageCount <= 1 && !isLoading) return const ChatEmptyState();
      return CustomScrollView(
        controller: scrollController,
        reverse: false,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p10, AppSizes.p16, 0),
            sliver: _MessageSliverList(onSend: onSend),
          ),
        ],
      );
    },
  );
}

class _MessageSliverList extends StatefulWidget {
  const _MessageSliverList({required this.onSend});
  final Future<void> Function(ChatNotifier, GutAuthNotifier, [String?]) onSend;

  @override
  State<_MessageSliverList> createState() => _MessageSliverListState();
}

class _MessageSliverListState extends State<_MessageSliverList> {
  @override
  Widget build(BuildContext context) {
    final chatNotifier = context.read<ChatNotifier>();
    final authNotifier = context.read<GutAuthNotifier>();

    final allMessages = context.select<ChatNotifier, List<ChatMessage>>((n) => n.messages);
    // Oldest to newest
    final messages = allMessages.where((m) => !m.isHidden).toList().reversed.toList();

    final isStreaming = context.select<ChatNotifier, bool>((n) => n.isStreaming);
    final isLoading = context.select<ChatNotifier, bool>((n) => n.isLoading);
    final latestAiIndex = _latestAiIndex(messages);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          final msg = messages[i];
          final prevMsg = i > 0 ? messages[i - 1] : null;

          var showDateHeader = false;
          if (prevMsg == null) {
            showDateHeader = true;
          } else {
            final d1 = DateTime(msg.time.year, msg.time.month, msg.time.day);
            final d2 = DateTime(prevMsg.time.year, prevMsg.time.month, prevMsg.time.day);
            if (d1 != d2) showDateHeader = true;
          }

          final showAvatar = msg.role == 'ai' && (prevMsg == null || prevMsg.role != 'ai' || showDateHeader);
          final isLatestAi = i == latestAiIndex;

          return KeyedSubtree(
            key: ValueKey(msg.localId),
            child: AnimatedChatItem(
              child: Padding(
                padding: EdgeInsets.only(bottom: AppSizes.p12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showDateHeader) DateHeader(date: msg.time),
                    ChatBubble(
                      text: msg.text,
                      isUser: msg.role == 'user',
                      time: msg.time,
                      isLoading: msg.role == 'ai' && (msg.text.isEmpty || msg.text == AppStrings.findingSwaps) && msg.errorKind == ChatErrorKind.none && msg.scanData == null && msg.swapData == null,
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
                          : (msg.errorKind == ChatErrorKind.connection ? () => unawaited(chatNotifier.regenerateLastResponse()) : null),
                      onQuotaPressed: () => unawaited(showPaywallBottomSheet(context, onProceedWithLimited: () {})),
                      showFeedback: isLatestAi && !isStreaming && msg.text.isNotEmpty && msg.scanData == null && msg.swapData == null && msg.errorKind == ChatErrorKind.none,
                      feedback: msg.feedback,
                      onFeedback: (type) async {
                        if (msg.feedback != null && type != AppStrings.labelTellMeMore) return;

                        if (type == AppStrings.labelHelpful || type == AppStrings.labelNotHelpful) {
                          unawaited(chatNotifier.handleFeedback(msg, type));
                          HapticHelper.light();
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text(AppStrings.thanksFeedback), behavior: SnackBarBehavior.floating));
                          }
                        } else if (type == AppStrings.labelTellMeMore) {
                          HapticHelper.light();
                          unawaited(widget.onSend(chatNotifier, authNotifier, AppStrings.tellMeMorePrompt));
                        }
                      },
                    ),
                    if (msg.isSwap == true && msg.swapData != null) SwapItContainer(swaps: msg.swapData!, onSeeMore: () => chatNotifier.handleSeeMoreSwaps(msg.text, i)),
                    if (msg.scanData != null)
                      ScanResultInlineCard(
                        scanData: msg.scanData!,
                        onViewFullReport: () => unawaited(context.push(AppRoutes.scanResult, extra: ScanResultArgs(scanData: msg.scanData!))),
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
    for (var i = messages.length - 1; i >= 0; i--) {
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
            ChatSuggestionChip(label: AppStrings.chipBloated, onTap: () => unawaited(_sendQuick(context, AppStrings.chipBloatedPrompt))),
            ChatSuggestionChip(label: AppStrings.chipHealthy, onTap: () => unawaited(_sendQuick(context, AppStrings.chipHealthyPrompt))),
            ChatSuggestionChip(label: AppStrings.chipSwap, onTap: () => unawaited(_sendQuick(context, AppStrings.chipSwapPrompt))),
            ChatSuggestionChip(label: AppStrings.chipRestaurant, onTap: () => _handleCameraQuick(context, ScannerMode.menu)),
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
  const _ChatComposer({required this.controller, required this.onChanged, required this.onCamera, required this.onGallery, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onChanged;
  final Future<void> Function(ChatNotifier, GutAuthNotifier, {ScannerMode mode}) onCamera;
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
                child: AttachmentPreview(
                  bytes: chatNotifier.pendingAttachments.first.bytes,
                  heroTag: 'attachment_${chatNotifier.pendingAttachments.first.id}',
                  onRemove: () => chatNotifier.removeAttachment(chatNotifier.pendingAttachments.first.id),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.elevatedSurface,
                borderRadius: BorderRadius.circular(AppSizes.r20),
                border: Border.all(color: colorScheme.border),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GutTextField(
                      textCapitalization: TextCapitalization.sentences,
                      controller: controller,
                      maxLines: 5,
                      minLines: 1,
                      onChanged: (_) => onChanged(),
                      hintText: chatNotifier.isStreaming ? AppStrings.thinking : AppStrings.askAnything,
                      borderless: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                  ComposerIconButton(icon: AppIcons.camera, label: AppStrings.scanIngredientsMeal, onTap: chatNotifier.isLoading ? null : () => onCamera(chatNotifier, authNotifier)),
                  Gap.w4,
                  ComposerIconButton(icon: AppIcons.image, label: AppStrings.attachPhotos, onTap: chatNotifier.isLoading ? null : () => onGallery(chatNotifier, authNotifier)),
                  Gap.w4,
                  SendStopButton(controller: controller, chatNotifier: chatNotifier, onSend: () => onSend(chatNotifier, authNotifier)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
