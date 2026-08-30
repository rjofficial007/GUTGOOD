import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/constants/storage_keys.dart';
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
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  static const String _draftKey = StorageKeys.chatDraft;

  final TextEditingController _controller = TextEditingController();

  final ScrollController _scroll = ScrollController();

  final ImagePicker _picker = ImagePicker();

  ChatHistoryNotifier? _historyNotifier;

  Timer? _draftDebounce;

  bool _showJumpToLatest = false;

  @override
  void initState() {
    super.initState();

    _scroll.addListener(_onScroll);

    _restoreDraft();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _historyNotifier = context.read<ChatHistoryNotifier>();

      _historyNotifier?.addListener(_handleHistoryLoaded);

      _handleHistoryLoaded();
    });
  }

  @override
  void dispose() {
    _historyNotifier?.removeListener(_handleHistoryLoaded);

    _draftDebounce?.cancel();

    _scroll.removeListener(_onScroll);

    _controller.dispose();
    _scroll.dispose();

    super.dispose();
  }

  // ===========================================================================
  // HISTORY
  // ===========================================================================

  void _handleHistoryLoaded() {
    // No initial scroll to bottom needed with reverse: true
  }

  // ===========================================================================
  // SCROLL
  // ===========================================================================

  void _onScroll() {
    if (!_scroll.hasClients) return;

    final position = _scroll.position;

    // Show jump to bottom button if we are scrolled up significantly
    final isScrolledUp = position.pixels > 300;
    if (isScrolledUp != _showJumpToLatest) {
      setState(() => _showJumpToLatest = isScrolledUp);
    }

    // Pagination: when reaching the top (end of the list in reverse: true)
    if (position.pixels >= position.maxScrollExtent - 200) {
      _historyNotifier?.loadMore();
    }
  }

  Future<void> _jumpToLatest() async {
    if (!_scroll.hasClients) return;
    await _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutQuad);
  }

  // ===========================================================================
  // DRAFT
  // ===========================================================================

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

  // ===========================================================================
  // CAMERA
  // ===========================================================================

  Future<void> handleCamera(ChatHistoryNotifier historyNotifier, ChatComposerNotifier composerNotifier, GutAuthNotifier authNotifier, {ScannerMode? mode}) async {
    if (composerNotifier.isLoading) {
      return;
    }

    if (!await QuotaGuard.check(context, type: QuotaType.scan, onAuthSuccess: historyNotifier.refreshHistory)) {
      return;
    }

    if (!mounted) return;

    final path = mode != null ? AppRoutes.scannerPath(mode.name) : '/scanner';

    final result = await context.push(path);

    if (result == null || result is! Map<String, dynamic> || !result.containsKey('bytes')) {
      return;
    }

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

  // ===========================================================================
  // GALLERY
  // ===========================================================================

  Future<void> _pickImages(ChatHistoryNotifier historyNotifier, ChatComposerNotifier composerNotifier, GutAuthNotifier authNotifier) async {
    if (composerNotifier.isLoading) {
      return;
    }

    if (!await QuotaGuard.check(context, type: QuotaType.scan, onAuthSuccess: historyNotifier.refreshHistory)) {
      return;
    }

    try {
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

      if (image == null) {
        return;
      }

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

  // ===========================================================================
  // SEND
  // ===========================================================================

  Future<void> _send(ChatHistoryNotifier historyNotifier, ChatComposerNotifier composerNotifier, GutAuthNotifier authNotifier, [String? quickText]) async {
    if (composerNotifier.isLoading) return;

    final msg = (quickText ?? _controller.text).trim();
    final hasImages = composerNotifier.pendingAttachments.isNotEmpty;

    if (msg.isEmpty && !hasImages) return;

    FocusManager.instance.primaryFocus?.unfocus();

    if (!await QuotaGuard.check(context, type: hasImages ? QuotaType.scan : QuotaType.chat, onAuthSuccess: historyNotifier.refreshHistory)) {
      return;
    }

    if (!mounted) return;

    final userMsgId = const Uuid().v4();

    // Reset UI state for new turn
    setState(() => _showJumpToLatest = false);

    final sendFuture = composerNotifier.send(
      text: msg,
      hiddenContext: hasImages ? composerNotifier.pendingHiddenContext : null,
      source: hasImages ? composerNotifier.pendingHiddenContext : 'chat',
      providedUserMsgId: userMsgId,
    );

    // No auto-scroll when user sends or AI responds.
    // The viewport remains naturally anchored at the bottom in reverse: true mode.

    final error = await sendFuture;

    if (!mounted) return;

    if (error == null) {
      _controller.clear();
      _clearDraft();
      composerNotifier.clearPendingHiddenContext();
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

  // ===========================================================================
  // BUILD
  // ===========================================================================

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
      durationUntilAlertAgain: RemoteConfigService.instance.isForceUpdateApp ? Duration.zero : const Duration(days: 3),
      debugLogging: !kReleaseMode,
      debugDisplayAlways: false,
      messages: UpgraderMessages(),
    ),
    child: Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      appBar: const _ChatAppBar(),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const Expanded(child: _MessageListView()),
                _ChatComposer(controller: _controller, onChanged: _scheduleDraftSave, onCamera: handleCamera, onGallery: _pickImages, onSend: _send),
              ],
            ),
            if (_showJumpToLatest)
              Positioned(
                bottom: 100,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: _jumpToLatest,
                  backgroundColor: context.appColorScheme.textPrimary,
                  foregroundColor: context.appColorScheme.cardBackground,
                  child: const Icon(AppIcons.chevronDown),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

// =============================================================================
// SUGGESTION CHIPS
// =============================================================================

class _SuggestionChipsSection extends StatelessWidget {
  const _SuggestionChipsSection({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Selector<ChatHistoryNotifier, int>(
    selector: (_, n) => n.messages.length,
    builder: (context, count, _) {
      final suggestions = [
        AppStrings.suggestRateMeal,
        AppStrings.suggestBetterSwap,
        AppStrings.suggestBloatCheck,
        AppStrings.suggestIsThisHealthy,
        AppStrings.suggestMealPlan,
        AppStrings.suggestExplainIngredients,
        AppStrings.menuPhotoPrompt,
      ];

      return Container(
        height: 38,
        margin: EdgeInsets.only(bottom: AppSizes.p12),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
          itemCount: suggestions.length,
          itemBuilder: (context, i) => ChatSuggestionChip(
            label: suggestions[i],
            onTap: () {
              HapticHelper.light();

              controller.text = suggestions[i];

              controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
            },
          ),
        ),
      );
    },
  );
}

// =============================================================================
// APP BAR
// =============================================================================

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

// =============================================================================
// MESSAGE LIST
// =============================================================================

class _MessageListView extends StatelessWidget {
  const _MessageListView();

  @override
  Widget build(BuildContext context) {
    final chatScreenState = context.findAncestorStateOfType<ChatScreenState>()!;

    final scrollController = chatScreenState._scroll;

    return Selector<ChatHistoryNotifier, (bool, int)>(
      selector: (_, n) => (n.historyLoading, n.messages.length),
      builder: (context, state, _) {
        final historyLoading = state.$1;

        final allMessages = context.read<ChatHistoryNotifier>().messages;

        final messages = allMessages.where((m) => !m.isHidden).toList();

        final isLoading = context.select<ChatComposerNotifier, bool>((n) => n.isLoading);

        if (historyLoading) {
          return const ChatShimmerLoading();
        }

        final hasUserMessages = messages.any((m) => m.role == 'user');

        if (!hasUserMessages && !isLoading) {
          return const ChatEmptyState();
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            chatScreenState._onScroll();
            return false;
          },
          child: CustomScrollView(
            controller: scrollController,
            reverse: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              const SliverPadding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), sliver: _MessageSliverList()),
              if (context.select<ChatHistoryNotifier, bool>((n) => n.isPaginationLoading)) const SliverToBoxAdapter(child: ChatPaginationLoader()),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// MESSAGE SLIVER
// =============================================================================

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

    /*
     * IMPORTANT:
     *
     * In reverse: true, index 0 is the bottom.
     * messages[0] is the newest message.
     */
    final messages = allMessages.where((m) => !m.isHidden).toList();

    final isStreaming = context.select<ChatComposerNotifier, bool>((n) => n.isStreaming);

    final isLoading = context.select<ChatComposerNotifier, bool>((n) => n.isLoading);

    final latestAiIndex = _latestAiIndex(messages);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          final msg = messages[i];

          // In reverse: true, messages[i+1] is rendered ABOVE messages[i]
          // Wait, no. index i is BELOW index i+1.
          // So messages[i+1] is physically above messages[i].
          // messages[i+1] is OLDER than messages[i].
          final olderMsg = i < messages.length - 1 ? messages[i + 1] : null;

          var showDateHeader = false;

          if (olderMsg == null) {
            showDateHeader = true;
          } else {
            final d1 = DateTime(msg.createdAt.year, msg.createdAt.month, msg.createdAt.day);
            final d2 = DateTime(olderMsg.createdAt.year, olderMsg.createdAt.month, olderMsg.createdAt.day);

            if (d1 != d2) {
              showDateHeader = true;
            }
          }

          final showAvatar = msg.role == 'ai' && (olderMsg == null || olderMsg.role != 'ai' || showDateHeader);

          final isLatestAi = i == latestAiIndex;

          final messageKey = ValueKey(msg.localId);

          return KeyedSubtree(
            key: messageKey,
            child: AnimatedChatItem(
              child: Padding(
                padding: EdgeInsets.only(bottom: AppSizes.p12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showDateHeader) DateHeader(date: msg.createdAt),
                    ChatBubble(
                      text: msg.text,
                      isUser: msg.role == 'user',
                      createdAt: msg.createdAt,
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
                        if (msg.feedback != null && type != AppStrings.labelTellMeMore) {
                          return;
                        }

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
                      onViewFullReport: msg.scanData != null
                          ? () {
                              final result = msg.scanData!;
                              unawaited(context.push(result.detailRoute, extra: ScanResultArgs(scanData: result)));
                            }
                          : null,
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
      if (messages[i].role == 'ai') {
        return i;
      }
    }

    return -1;
  }
}

// =============================================================================
// CHAT COMPOSER
// =============================================================================

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
        border: Border(top: BorderSide(color: colorScheme.borderSubtle)),
      ),
      padding: EdgeInsets.symmetric(vertical: AppSizes.p12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (composerNotifier.pendingAttachments.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
              child: AttachmentPreview(
                bytes: composerNotifier.pendingAttachments.first.bytes,
                heroTag: 'attachment_${composerNotifier.pendingAttachments.first.id}',
                onRemove: () => composerNotifier.removeAttachment(composerNotifier.pendingAttachments.first.id),
              ),
            ),

          _SuggestionChipsSection(controller: controller),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: colorScheme.elevatedSurface,
                      borderRadius: BorderRadius.circular(AppSizes.r20),
                      border: Border.all(color: colorScheme.border.withAlpha(204)),
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
          ),
        ],
      ),
    );
  }
}
