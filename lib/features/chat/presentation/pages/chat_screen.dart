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
import 'package:gutgood/features/chat/presentation/providers/chat_composer_notifier.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_history_notifier.dart';
import 'package:gutgood/features/chat/presentation/widgets/chat_components.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:gutgood/features/scanner/domain/models/scanner_mode.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  static const String _draftKey = 'chat_draft';

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _hasScrolledToBottomInitially = false;
  ChatHistoryNotifier? _historyNotifier;
  ChatComposerNotifier? _composerNotifier;
  Timer? _draftDebounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _restoreDraft();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _historyNotifier = context.read<ChatHistoryNotifier>();
      _composerNotifier = context.read<ChatComposerNotifier>();
      _historyNotifier?.addListener(_handleHistoryLoaded);
      _handleHistoryLoaded(); // Check if history is already loaded
    });
  }

  @override
  void dispose() {
    _historyNotifier?.removeListener(_handleHistoryLoaded);
    _historyNotifier?.removeListener(_onHistoryUpdated);
    _composerNotifier?.removeListener(_onComposerUpdated);
    _draftDebounce?.cancel();
    _scroll.removeListener(_onScroll);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _handleHistoryLoaded() {
    if (_historyNotifier == null) return;
    if (!_historyNotifier!.historyLoading && !_hasScrolledToBottomInitially && _historyNotifier!.messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scrollToBottom(animated: false);
          _hasScrolledToBottomInitially = true;
          setState(() {});
        }
      });
    }
  }

  void _onComposerUpdated() {}
  void _onHistoryUpdated() {}

  void _onScroll() {
    if (!_scroll.hasClients) return;

    // Load more: at the top
    if (_scroll.position.pixels <= 50) {
      context.read<ChatHistoryNotifier>().loadMore();
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scroll.hasClients) return;
    final maxScroll = _scroll.position.maxScrollExtent;
    if (animated) {
      _scroll.animateTo(maxScroll, duration: const Duration(milliseconds: 250), curve: Curves.easeOutQuad);
    } else {
      _scroll.jumpTo(maxScroll);
    }
    // Repeat on post-frame to ensure the new user message layout expansion is scrolled into view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        final newMax = _scroll.position.maxScrollExtent;
        if ((newMax - _scroll.position.pixels).abs() > 4) {
          if (animated) {
            _scroll.animateTo(newMax, duration: const Duration(milliseconds: 200), curve: Curves.easeOutQuad);
          } else {
            _scroll.jumpTo(newMax);
          }
        }
      }
    });
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

  Future<void> handleCamera(ChatHistoryNotifier historyNotifier, ChatComposerNotifier composerNotifier, GutAuthNotifier authNotifier, {ScannerMode? mode}) async {
    if (composerNotifier.isLoading) return;
    if (!await QuotaGuard.check(context, type: QuotaType.scan, onAuthSuccess: historyNotifier.refreshHistory)) return;

    if (!mounted) return;
    final path = mode != null ? AppRoutes.scannerPath(mode.name) : '/scanner';
    final result = await context.push(path);
    if (result == null || result is! Map<String, dynamic> || !result.containsKey('bytes')) return;

    final bytes = result['bytes'] as Uint8List;
    final type = result['type'] as String? ?? (mode?.name ?? 'food');

    final added = await composerNotifier.handleImageAttachment(bytes, type: type);
    if (!added) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.maxAttachmentsMessage), behavior: SnackBarBehavior.floating));
      }
      return;
    }

    setState(() {
      _controller.text = composerNotifier.getPromptForType(type);
    });
  }

  Future<void> _pickImages(ChatHistoryNotifier historyNotifier, ChatComposerNotifier composerNotifier, GutAuthNotifier authNotifier) async {
    if (composerNotifier.isLoading) return;
    if (!await QuotaGuard.check(context, type: QuotaType.scan, onAuthSuccess: historyNotifier.refreshHistory)) return;

    try {
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final added = await composerNotifier.handleImageAttachment(bytes, type: 'gallery');

      if (added) {
        setState(() {
          _controller.text = composerNotifier.getPromptForType('gallery');
        });
      }
    } catch (e, st) {
      AppLogger.error('ChatScreen: Image pick failed', error: e, stackTrace: st);
    }
  }

  Future<void> _send(ChatHistoryNotifier historyNotifier, ChatComposerNotifier composerNotifier, GutAuthNotifier authNotifier, [String? quickText]) async {
    if (composerNotifier.isLoading) return;

    final hasImages = composerNotifier.pendingAttachments.isNotEmpty;
    final msg = (quickText ?? _controller.text).trim();
    if (msg.isEmpty && !hasImages) return;

    _scrollToBottom(animated: true);

    FocusManager.instance.primaryFocus?.unfocus();

    if (!await QuotaGuard.check(context, type: hasImages ? QuotaType.scan : QuotaType.chat, onAuthSuccess: historyNotifier.refreshHistory)) return;

    final error = await composerNotifier.send(text: msg, hiddenContext: hasImages ? composerNotifier.pendingHiddenContext : null, source: hasImages ? composerNotifier.pendingHiddenContext : 'chat');

    if (!mounted) return;

    if (error == null) {
      _controller.clear();
      _clearDraft();
      composerNotifier.clearPendingHiddenContext();
      _scrollToBottom(animated: true);
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
            const Expanded(child: _MessageListView()),
            _ChatComposer(controller: _controller, onChanged: _scheduleDraftSave, onCamera: handleCamera, onGallery: _pickImages, onSend: _send),
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
  const _MessageListView();

  @override
  Widget build(BuildContext context) {
    final scrollController = context.findAncestorStateOfType<ChatScreenState>()!._scroll;
    return Selector<ChatHistoryNotifier, (bool, int)>(
      selector: (_, n) => (n.historyLoading, n.messages.length),
      builder: (context, state, _) {
        final historyLoading = state.$1;
        final allMessages = context.read<ChatHistoryNotifier>().messages;
        final messages = allMessages.where((m) => !m.isHidden).toList();
        final messageCount = messages.length;
        final isLoading = context.select<ChatComposerNotifier, bool>((n) => n.isLoading);

        if (historyLoading) return const ChatShimmerLoading();
        if (messageCount <= 1 && !isLoading) return const ChatEmptyState();
        return CustomScrollView(
          controller: scrollController,
          reverse: false,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [SliverPadding(padding: EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p10, AppSizes.p16, 0), sliver: const _MessageSliverList())],
        );
      },
    );
  }
}

class _MessageSliverList extends StatefulWidget {
  const _MessageSliverList();

  @override
  State<_MessageSliverList> createState() => _MessageSliverListState();
}

class _MessageSliverListState extends State<_MessageSliverList> {
  @override
  Widget build(BuildContext context) {
    final historyNotifier = context.read<ChatHistoryNotifier>();
    final composerNotifier = context.read<ChatComposerNotifier>();
    final authNotifier = context.read<GutAuthNotifier>();

    final allMessages = context.select<ChatHistoryNotifier, List<ChatMessage>>((n) => n.messages);
    // Oldest to newest
    final messages = allMessages.where((m) => !m.isHidden).toList().reversed.toList();

    final isStreaming = context.select<ChatComposerNotifier, bool>((n) => n.isStreaming);
    final isLoading = context.select<ChatComposerNotifier, bool>((n) => n.isLoading);
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
                      onRegenerate: composerNotifier.canRegenerate
                          ? () {
                              HapticHelper.light();
                              unawaited(composerNotifier.regenerateLastResponse());
                            }
                          : null,
                      onRetry: msg.sendFailed
                          ? () => unawaited(composerNotifier.retryMessage(msg))
                          : (msg.errorKind == ChatErrorKind.connection ? () => unawaited(composerNotifier.regenerateLastResponse()) : null),
                      onQuotaPressed: () => unawaited(showPaywallBottomSheet(context, onProceedWithLimited: () {})),
                      showFeedback: isLatestAi && !isStreaming && msg.text.isNotEmpty && msg.scanData == null && msg.swapData == null && msg.errorKind == ChatErrorKind.none,
                      feedback: msg.feedback,
                      onFeedback: (type) async {
                        if (msg.feedback != null && type != AppStrings.labelTellMeMore) return;

                        if (type == AppStrings.labelHelpful || type == AppStrings.labelNotHelpful) {
                          unawaited(historyNotifier.handleFeedback(msg, type));
                          HapticHelper.light();
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text(AppStrings.thanksFeedback), behavior: SnackBarBehavior.floating));
                          }
                        } else if (type == AppStrings.labelTellMeMore) {
                          HapticHelper.light();
                          final screenState = context.findAncestorStateOfType<ChatScreenState>();
                          unawaited(screenState?._send(historyNotifier, composerNotifier, authNotifier, AppStrings.tellMeMorePrompt));
                        }
                      },
                      scanData: msg.scanData,
                      swapData: msg.swapData,
                      onSeeMoreSwaps: () => composerNotifier.handleSeeMoreSwaps(msg.text, i),
                      onViewFullReport: msg.scanData != null ? () => unawaited(context.push(AppRoutes.scanResult, extra: ScanResultArgs(scanData: msg.scanData!))) : null,
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
      padding: EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p12, AppSizes.p16, MediaQuery.paddingOf(context).bottom + AppSizes.p12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (composerNotifier.pendingAttachments.isNotEmpty)
            AttachmentPreview(
              bytes: composerNotifier.pendingAttachments.first.bytes,
              heroTag: 'attachment_${composerNotifier.pendingAttachments.first.id}',
              onRemove: () => composerNotifier.removeAttachment(composerNotifier.pendingAttachments.first.id),
            ),
          Row(
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
                        icon: AppIcons.camera,
                        label: AppStrings.scanIngredientsMeal,
                        onTap: composerNotifier.isLoading ? null : () => onCamera(historyNotifier, composerNotifier, authNotifier),
                      ),
                      Gap.w4,
                      ComposerIconButton(
                        icon: AppIcons.image,
                        label: AppStrings.attachPhotos,
                        onTap: composerNotifier.isLoading ? null : () => onGallery(historyNotifier, composerNotifier, authNotifier),
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
        ],
      ),
    );
  }
}
