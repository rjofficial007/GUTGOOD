import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  static const String _draftKey = 'chat_draft';

  /// Where the latest user message should appear in the viewport.
  ///
  /// 0.0  = very top
  /// 0.12 = 12% from top
  /// 0.5  = center
  static const double _userMessageAlignment = 0.12;

  /// Number of frames to wait for the newly-created message.
  static const int _maxAnchorAttempts = 12;

  /// Prevents multiple anchor operations from being queued.
  bool _anchorScrollScheduled = false;

  /// Prevents repeated anchoring during the same turn.
  bool _hasAnchoredCurrentTurn = false;

  /// Prevents programmatic scrolling from being interpreted as
  /// manual scrolling.
  bool _programmaticScrolling = false;

  /// True when the user manually interacts with the conversation.
  bool _userIsInteractingWithScroll = false;

  /// Whether temporary anchor space is currently enabled.
  bool _anchorSpaceEnabled = false;

  /// ID of the latest user message.
  String? _latestUserMsgId;

  /// Stable key attached to the latest user message.
  final GlobalKey _latestUserMsgKey = GlobalKey();

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
    final notifier = _historyNotifier;

    if (notifier == null) return;

    if (!notifier.historyLoading && !_hasScrolledToBottomInitially && notifier.messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) {
          return;
        }

        _scrollToBottom(animated: false);

        _hasScrolledToBottomInitially = true;

        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  // ===========================================================================
  // SCROLL
  // ===========================================================================

  void _onScroll() {
    if (!_scroll.hasClients) return;

    final position = _scroll.position;

    /*
     * Don't interpret our own animation as user interaction.
     */
    if (!_programmaticScrolling && position.isScrollingNotifier.value) {
      _userIsInteractingWithScroll = true;
    }

    /*
     * Existing pagination behavior.
     *
     * Keep this exactly as your original implementation:
     * reaching the top loads older messages.
     */
    if (position.pixels <= 50) {
      context.read<ChatHistoryNotifier>().loadMore();
    }
  }

  /// Scrolls to the bottom.
  ///
  /// Used only for initial conversation loading.
  Future<void> _scrollToBottom({bool animated = true}) async {
    if (!mounted || !_scroll.hasClients) {
      return;
    }

    final maxScroll = _scroll.position.maxScrollExtent;

    _programmaticScrolling = true;

    try {
      if (animated) {
        await _scroll.animateTo(maxScroll, duration: const Duration(milliseconds: 250), curve: Curves.easeOutQuad);
      } else {
        _scroll.jumpTo(maxScroll);
      }

      await WidgetsBinding.instance.endOfFrame;

      if (!mounted || !_scroll.hasClients) {
        return;
      }

      final newMax = _scroll.position.maxScrollExtent;

      if ((newMax - _scroll.position.pixels).abs() > 4) {
        if (animated) {
          await _scroll.animateTo(newMax, duration: const Duration(milliseconds: 200), curve: Curves.easeOutQuad);
        } else {
          _scroll.jumpTo(newMax);
        }
      }
    } finally {
      _programmaticScrolling = false;
    }
  }

  // ===========================================================================
  // LATEST USER MESSAGE ANCHOR
  // ===========================================================================

  /// Enables temporary space below the conversation.
  ///
  /// This is important.
  ///
  /// Without this, Flutter may not physically have enough scroll extent
  /// to move the latest user message to 12% of the viewport.
  void _enableAnchorSpace() {
    if (_anchorSpaceEnabled) return;

    _anchorSpaceEnabled = true;

    if (mounted) {
      setState(() {});
    }
  }

  void _disableAnchorSpace() {
    if (!_anchorSpaceEnabled) return;

    _anchorSpaceEnabled = false;

    if (mounted) {
      setState(() {});
    }
  }

  void _scrollToLatestUser({int attempt = 0}) {
    if (!mounted) return;

    if (_latestUserMsgId == null) {
      return;
    }

    if (_anchorScrollScheduled) {
      return;
    }

    _anchorScrollScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _anchorScrollScheduled = false;

      if (!mounted) return;

      await _tryAnchorLatestUser(attempt: attempt);
    });
  }

  Future<void> _tryAnchorLatestUser({required int attempt}) async {
    if (!mounted) return;

    /*
     * Don't fight the user.
     */
    if (_userIsInteractingWithScroll) {
      return;
    }

    final targetContext = _latestUserMsgKey.currentContext;

    /*
     * Message isn't built yet.
     */
    if (targetContext == null) {
      if (attempt >= _maxAnchorAttempts) {
        AppLogger.warning(
          'ChatScreen: Latest user message anchor '
          'was not found after '
          '$_maxAnchorAttempts attempts.',
        );

        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _tryAnchorLatestUser(attempt: attempt + 1);
      });

      return;
    }

    final renderObject = targetContext.findRenderObject();

    if (renderObject == null || !renderObject.attached) {
      if (attempt >= _maxAnchorAttempts) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _tryAnchorLatestUser(attempt: attempt + 1);
      });

      return;
    }

    await _animateToAnchor(targetContext);

    _hasAnchoredCurrentTurn = true;
  }

  /// Calculates the exact scroll position required to put the
  /// latest user message at [_userMessageAlignment].
  ///
  /// Unlike Scrollable.ensureVisible(), this explicitly asks Flutter
  /// where the target should be revealed.
  Future<void> _animateToAnchor(BuildContext messageContext) async {
    if (!mounted || !_scroll.hasClients) {
      return;
    }

    if (_userIsInteractingWithScroll) {
      return;
    }

    final renderObject = messageContext.findRenderObject();

    if (renderObject == null || !renderObject.attached) {
      return;
    }

    final viewport = RenderAbstractViewport.of(renderObject);

    if (viewport == null) {
      return;
    }

    try {
      final reveal = viewport.getOffsetToReveal(renderObject, _userMessageAlignment);

      final minScroll = _scroll.position.minScrollExtent;

      final maxScroll = _scroll.position.maxScrollExtent;

      final targetOffset = reveal.offset.clamp(minScroll, maxScroll);

      final difference = (targetOffset - _scroll.position.pixels).abs();

      /*
       * Already correctly positioned.
       */
      if (difference <= 2) {
        return;
      }

      _programmaticScrolling = true;

      await _scroll.animateTo(targetOffset.toDouble(), duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    } catch (e, st) {
      AppLogger.error('ChatScreen: Failed to anchor latest user message', error: e, stackTrace: st);
    } finally {
      _programmaticScrolling = false;
    }
  }

  /// Performs a small number of corrections after the first anchor.
  ///
  /// This handles layout changes caused by:
  ///
  /// - AI response placeholder
  /// - image loading
  /// - streamed text
  ///
  /// It intentionally does NOT continuously follow every AI token.
  Future<void> _correctLatestUserAnchor() async {
    if (!mounted) return;

    if (!_hasAnchoredCurrentTurn) {
      return;
    }

    if (_userIsInteractingWithScroll) {
      return;
    }

    for (var i = 0; i < 3; i++) {
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted || !_scroll.hasClients) {
        return;
      }

      if (_userIsInteractingWithScroll) {
        return;
      }

      final context = _latestUserMsgKey.currentContext;

      if (context == null) {
        return;
      }

      final renderObject = context.findRenderObject();

      if (renderObject == null || !renderObject.attached) {
        return;
      }

      final viewport = RenderAbstractViewport.of(renderObject);

      if (viewport == null) {
        return;
      }

      final reveal = viewport.getOffsetToReveal(renderObject, _userMessageAlignment);

      final targetOffset = reveal.offset.clamp(_scroll.position.minScrollExtent, _scroll.position.maxScrollExtent);

      final difference = (targetOffset - _scroll.position.pixels).abs();

      if (difference <= 3) {
        return;
      }

      try {
        _programmaticScrolling = true;

        await _scroll.animateTo(targetOffset.toDouble(), duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
      } finally {
        _programmaticScrolling = false;
      }
    }
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
    if (composerNotifier.isLoading) {
      return;
    }

    final hasImages = composerNotifier.pendingAttachments.isNotEmpty;

    final msg = (quickText ?? _controller.text).trim();

    if (msg.isEmpty && !hasImages) {
      return;
    }

    /*
     * Close keyboard before measuring viewport.
     */
    FocusManager.instance.primaryFocus?.unfocus();

    if (!await QuotaGuard.check(context, type: hasImages ? QuotaType.scan : QuotaType.chat, onAuthSuccess: historyNotifier.refreshHistory)) {
      return;
    }

    if (!mounted) return;

    // ========================================================================
    // NEW TURN
    // ========================================================================

    final userMsgId = const Uuid().v4();

    /*
     * This is a NEW explicit user action.
     * Therefore allow the anchor to happen even if the user previously
     * scrolled manually.
     */
    _userIsInteractingWithScroll = false;

    setState(() {
      _latestUserMsgId = userMsgId;

      _hasAnchoredCurrentTurn = false;

      /*
       * Give the conversation enough scroll extent to physically
       * position the user message near the top.
       */
      _anchorSpaceEnabled = true;
    });

    // ========================================================================
    // SEND
    // ========================================================================

    final sendFuture = composerNotifier.send(
      text: msg,
      hiddenContext: hasImages ? composerNotifier.pendingHiddenContext : null,
      source: hasImages ? composerNotifier.pendingHiddenContext : 'chat',
      providedUserMsgId: userMsgId,
    );

    /*
     * Wait until the user message has actually entered the widget tree.
     */
    await _waitForLatestUserMessageAndAnchor();

    final error = await sendFuture;

    if (!mounted) return;

    if (error == null) {
      _controller.clear();

      _clearDraft();

      composerNotifier.clearPendingHiddenContext();

      /*
       * Give any final layout changes one frame.
       *
       * We do not continuously scroll during streaming.
       */
      await _correctLatestUserAnchor();

      /*
       * The conversation now has enough real AI content in most cases.
       *
       * Keep the anchor space enabled while this turn is visible.
       * It will be replaced by the actual response height naturally.
       */
      return;
    }

    /*
     * If sending failed, remove the temporary anchor space.
     */
    _disableAnchorSpace();

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

  Future<void> _waitForLatestUserMessageAndAnchor() async {
    if (!mounted) return;

    final requestedId = _latestUserMsgId;

    if (requestedId == null) {
      return;
    }

    /*
     * First layout.
     */
    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) return;

    if (_latestUserMsgKey.currentContext != null) {
      _hasAnchoredCurrentTurn = true;

      _scrollToLatestUser();

      return;
    }

    /*
     * Wait for subsequent frames.
     */
    for (var i = 0; i < _maxAnchorAttempts; i++) {
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return;

      /*
       * A newer message was sent.
       */
      if (_latestUserMsgId != requestedId) {
        return;
      }

      final targetContext = _latestUserMsgKey.currentContext;

      if (targetContext != null) {
        _hasAnchoredCurrentTurn = true;

        _scrollToLatestUser();

        return;
      }
    }

    AppLogger.warning(
      'ChatScreen: Latest user message '
      'was not available for scroll anchoring.',
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
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
        durationUntilAlertAgain: RemoteConfigService.instance.isForceUpdateApp ? Duration.zero : const Duration(days: 3),
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
}

// =============================================================================
// SUGGESTION CHIPS
// =============================================================================

class _SuggestionChipsSection extends StatelessWidget {
  const _SuggestionChipsSection({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Selector<ChatHistoryNotifier, int>(
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
            itemBuilder: (context, i) {
              return ChatSuggestionChip(
                label: suggestions[i],
                onTap: () {
                  HapticHelper.light();

                  controller.text = suggestions[i];

                  controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                },
              );
            },
          ),
        );
      },
    );
  }
}

// =============================================================================
// APP BAR
// =============================================================================

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar();

  @override
  Widget build(BuildContext context) {
    return Selector2<ProfileNotifier, InsightsNotifier, (int?, bool)>(
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
  }

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

        final messageCount = messages.length;

        final isLoading = context.select<ChatComposerNotifier, bool>((n) => n.isLoading);

        if (historyLoading) {
          return const ChatShimmerLoading();
        }

        final hasUserMessages = messages.any((m) => m.role == 'user');

        if (!hasUserMessages && !isLoading) {
          return const ChatEmptyState();
        }

        return NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction != ScrollDirection.idle) {
              chatScreenState._userIsInteractingWithScroll = true;
            }

            return false;
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomScrollView(
                controller: scrollController,
                reverse: false,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(padding: EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p10, AppSizes.p16, 0), sliver: const _MessageSliverList()),

                  /*
                   * Temporary anchor space.
                   *
                   * This is the important part that allows a newly
                   * sent user message to actually move to 12% of the
                   * viewport even when there isn't enough AI content
                   * below it yet.
                   *
                   * It is disabled when no new turn is active.
                   */
                  if (chatScreenState._anchorSpaceEnabled) SliverToBoxAdapter(child: SizedBox(height: constraints.maxHeight * (1 - ChatScreenState._userMessageAlignment))),
                ],
              );
            },
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

    final screenState = context.findAncestorStateOfType<ChatScreenState>()!;

    final allMessages = context.select<ChatHistoryNotifier, List<ChatMessage>>((n) => n.messages);

    /*
     * IMPORTANT:
     *
     * KEEP YOUR ORIGINAL ORDERING.
     *
     * Do not change this unless ChatHistoryNotifier itself changes.
     */
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
            final d1 = DateTime(msg.createdAt.year, msg.createdAt.month, msg.createdAt.day);

            final d2 = DateTime(prevMsg.createdAt.year, prevMsg.createdAt.month, prevMsg.createdAt.day);

            if (d1 != d2) {
              showDateHeader = true;
            }
          }

          final showAvatar = msg.role == 'ai' && (prevMsg == null || prevMsg.role != 'ai' || showDateHeader);

          final isLatestAi = i == latestAiIndex;

          final isLatestUser = msg.localId == screenState._latestUserMsgId;

          final messageKey = isLatestUser ? screenState._latestUserMsgKey : ValueKey(msg.localId);

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
                              final scan = msg.scanData!;
                              final cat = scan.category?.toLowerCase() ?? '';
                              final src = scan.source?.toLowerCase() ?? '';
                              final name = scan.productName.toLowerCase();

                              // 🚀 Smart Routing: Select screen based on scan type
                              if (cat == 'menu' || src == 'menu' || name.contains('menu')) {
                                if (msg.mealLogs.isNotEmpty) {
                                  unawaited(context.push(AppRoutes.mealDetail, extra: msg.mealLogs.first));
                                } else {
                                  // Fallback to menu result if no structured meal log is attached
                                  unawaited(context.push(AppRoutes.menuResult, extra: ScanResultArgs(scanData: scan)));
                                }
                              } else if (cat == 'label' || src == 'label' || name.contains('label') || name.contains('ingredients')) {
                                unawaited(context.push(AppRoutes.labelResult, extra: ScanResultArgs(scanData: scan)));
                              } else {
                                unawaited(context.push(AppRoutes.scanResult, extra: ScanResultArgs(scanData: scan)));
                              }
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
    for (var i = messages.length - 1; i >= 0; i--) {
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
        border: Border(top: BorderSide(color: colorScheme.border.withValues(alpha: 0.5))),
      ),
      padding: EdgeInsets.fromLTRB(0, AppSizes.p12, 0, MediaQuery.paddingOf(context).bottom + AppSizes.p12),
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
          ),
        ],
      ),
    );
  }
}
