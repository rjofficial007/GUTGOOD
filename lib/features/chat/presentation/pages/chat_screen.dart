import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/strings/chat_strings.dart';
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

  /// Number of frames to wait for the newly-sent user message to enter the
  /// widget tree before attempting the one-time send scroll.
  static const int _maxAnchorAttempts = 12;

  /// ID of the current turn's user message (the send-scroll anchor target).
  /// Null when no turn is active.
  String? _latestUserMsgId;

  /// Stable key attached to the current turn's user message so the send
  /// scroll can locate the actual widget instead of guessing its offset.
  final GlobalKey _latestUserMsgKey = GlobalKey();

  /// Whether the turn-scoped spacer below the conversation is enabled.
  ///
  /// The spacer exists ONLY between send and turn end. Positioning the new
  /// user message near the top of the viewport is physically impossible
  /// without trailing scroll extent (there is not enough content below the
  /// message yet), so exactly one viewport of it is provided while the turn
  /// is active — and removed the moment the turn ends, leaving zero
  /// artificial space.
  bool _turnSpacerEnabled = false;

  /// Monotonic turn counter. Guards stale turn-end callbacks from a previous
  /// send against disabling a newer turn's spacer.
  int _turnSeq = 0;

  /// Distance from the newest content (in logical pixels) beyond which the
  /// manual jump control appears. Very large on purpose: the button must
  /// stay rare and appear only when the user is deep in history reading.
  static const double _showJumpToLatestThreshold = 1000;

  /// Distance back within which a visible jump control hides again.
  /// Lower than the show threshold (hysteresis) so the button never
  /// flickers when the user hovers around the boundary.
  static const double _hideJumpToLatestThreshold = 100;

  /// Whether the manual "Jump to latest" control is currently visible.
  /// Purely a navigation affordance — it never moves the viewport by
  /// itself; only an explicit user tap scrolls.
  bool _showJumpToLatest = false;

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
      _composerNotifier?.addListener(_handleComposerChangedForTurn);

      _handleHistoryLoaded();

      // The jump control is scroll-driven only (see _onScroll): content
      // growth underneath a stationary viewport — e.g. AI streaming —
      // must NOT summon it. This call just establishes the initial state.
      _syncJumpButtonVisibility();
    });
  }

  @override
  void dispose() {
    _historyNotifier?.removeListener(_handleHistoryLoaded);
    _composerNotifier?.removeListener(_handleComposerChangedForTurn);

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

        _scrollToBottomInitially();

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

    /*
     * Existing pagination behavior.
     *
     * Kept exactly as the original implementation:
     * reaching the top loads older messages.
     *
     * NOTE: besides pagination, this listener only re-evaluates the manual
     * jump control's visibility. It never scrolls — the ONLY automatic
     * scroll in this screen is the one-time send scroll below.
     */
    if (_scroll.position.pixels <= 50) {
      context.read<ChatHistoryNotifier>().loadMore();
    }

    _syncJumpButtonVisibility();
  }

  /// Positions the conversation at the newest content after the initial
  /// history load. Runs exactly once per screen lifetime; the second pass
  /// absorbs first-layout growth (fonts, images) that lands late.
  Future<void> _scrollToBottomInitially() async {
    if (!mounted || !_scroll.hasClients) {
      return;
    }

    _scroll.jumpTo(_scroll.position.maxScrollExtent);

    await WidgetsBinding.instance.endOfFrame;

    if (!mounted || !_scroll.hasClients) {
      return;
    }

    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  // ===========================================================================
  // JUMP TO LATEST (MANUAL CONTROL)
  // ===========================================================================
  //
  // ChatGPT-style: when the user has intentionally scrolled away from the
  // newest content, a small floating arrow offers to take them back. It is
  // purely manual — it NEVER fires on its own, and no AI update (thinking,
  // streaming, growth) ever triggers scrolling OR summons the button. Only
  // actual scrolling (the user's, or the one-time send scroll) updates it.

  /// Shows the jump control once the viewport sits more than
  /// [_showJumpToLatestThreshold] above the newest content; hides it again
  /// once back within [_hideJumpToLatestThreshold] (hysteresis — no
  /// flicker around the boundary). Requires newer content to actually
  /// exist below; never shows for short/unscrollable conversations.
  /// Never moves the viewport itself.
  void _syncJumpButtonVisibility() {
    if (!mounted) return;

    if (!_scroll.hasClients) {
      if (_showJumpToLatest) {
        setState(() {
          _showJumpToLatest = false;
        });
      }

      return;
    }

    final position = _scroll.position;

    final hasNewerContent = position.maxScrollExtent > 0;

    final distanceFromBottom = position.maxScrollExtent - position.pixels;

    final threshold = _showJumpToLatest ? _hideJumpToLatestThreshold : _showJumpToLatestThreshold;

    final shouldShow = hasNewerContent && distanceFromBottom > threshold;

    if (shouldShow != _showJumpToLatest) {
      setState(() {
        _showJumpToLatest = shouldShow;
      });
    }
  }

  /// Runs ONLY from an explicit user tap: glides to the newest content,
  /// then hides the control. This is the only viewport motion in the
  /// screen besides the one-time send scroll (and the initial load).
  Future<void> _jumpToLatest() async {
    if (!_scroll.hasClients) return;

    await _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);

    if (!mounted) return;

    _syncJumpButtonVisibility();
  }

  // ===========================================================================
  // TURN-ANCHORED SEND SCROLL
  // ===========================================================================
  //
  // The ONLY automatic scroll in this screen happens on user send:
  //
  //   SEND -> scroll ONCE to the new user message (near the top)
  //        -> STOP. AI updates never move the viewport.
  //
  // AI responses (loading, streaming, cards, images, Firestore updates,
  // rebuilds) NEVER trigger scrolling. The user scrolls manually.

  /// Ends the turn the moment the AI truly finishes (completion, error, or
  /// stop) so the turn spacer is removed only after the complete response
  /// has arrived. Never scrolls.
  ///
  /// This is the PRIMARY turn-end signal: [_send]'s future resolves when
  /// streaming *starts*, not when it completes, so [_send] only ends the
  /// turn itself on the error paths (which never stream). All paths are
  /// idempotent.
  void _handleComposerChangedForTurn() {
    final composer = _composerNotifier;

    if (composer == null || !_turnSpacerEnabled) return;

    // The first composer notification of a turn always carries the ACTIVE
    // flags (send() sets isLoading=true before notifying), so an idle
    // observation here can only mean the turn actually ended.
    if (!composer.isLoading && !composer.isStreaming) {
      _endTurn(_turnSeq);
    }
  }

  /// Ends the turn's scroll scaffolding: removes the trailing spacer.
  /// Never moves the viewport itself.
  void _endTurn(int seq) {
    if (seq != _turnSeq || !_turnSpacerEnabled) return;

    if (!mounted) return;

    setState(() {
      _turnSpacerEnabled = false;
    });

    AppLogger.debug('ChatScreen: turn ended, spacer removed');

    // Spacer removal shrinks the scroll extent without moving any pixels,
    // so no scroll notification fires — re-evaluate the jump control once
    // layout has settled (this can only hide it, never show it).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _syncJumpButtonVisibility();
    });
  }

  /// Waits for the newly-sent user message to enter the widget tree, then
  /// performs the ONE send scroll: glide it near the top of the viewport.
  ///
  /// If the user sent from far up in history, the new message is outside
  /// the sliver's built range (slivers build lazily), so its position
  /// cannot be measured yet. In that case the tail is first brought into
  /// layout with an instant jump, and the SINGLE glide still runs once.
  Future<void> _anchorToLatestUserMessage() async {
    if (!mounted) return;

    final requestedId = _latestUserMsgId;

    if (requestedId == null) {
      return;
    }

    for (var i = 0; i < _maxAnchorAttempts; i++) {
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return;

      /*
       * A newer message was sent; its own anchor chain owns the motion.
       */
      if (_latestUserMsgId != requestedId) {
        return;
      }

      if (_latestUserMsgKey.currentContext != null) {
        break;
      }

      /*
       * The send failed before inserting a message (offline): nothing to
       * anchor to — leave the viewport alone.
       */
      final composer = _composerNotifier;

      if (composer != null && !composer.isLoading && !composer.isStreaming) {
        return;
      }

      /*
       * Message still outside the built range (user sent from far up):
       * bring the tail into layout once, then measure on the next frame.
       */
      if (i == 0 && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    }

    if (!mounted) return;

    if (_latestUserMsgId != requestedId) {
      return;
    }

    final targetContext = _latestUserMsgKey.currentContext;

    if (targetContext == null) {
      AppLogger.warning('ChatScreen: sent message was not available for the send scroll.');
      return;
    }

    await _glideToUserMessage(targetContext);
  }

  /// Glides the viewport exactly once so the sent user message sits near
  /// the top (with breathing room). The AI response then appears and grows
  /// below it without any further motion.
  Future<void> _glideToUserMessage(BuildContext messageContext) async {
    if (!mounted || !_scroll.hasClients) {
      return;
    }

    final renderObject = messageContext.findRenderObject();

    if (renderObject == null || !renderObject.attached) {
      return;
    }

    try {
      final viewport = RenderAbstractViewport.of(renderObject);

      final reveal = viewport.getOffsetToReveal(renderObject, 0.0);

      final target = (reveal.offset - AppSizes.p24).clamp(_scroll.position.minScrollExtent, _scroll.position.maxScrollExtent);

      /*
       * Already correctly positioned.
       */
      if ((target - _scroll.position.pixels).abs() <= 2) {
        return;
      }

      await _scroll.animateTo(target.toDouble(), duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    } catch (e, st) {
      AppLogger.error('ChatScreen: send scroll failed', error: e, stackTrace: st);
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
    // NEW TURN — the send scroll below is the ONLY automatic scroll.
    // ========================================================================

    _turnSeq++;

    final turnSeq = _turnSeq;

    final userMsgId = const Uuid().v4();

    setState(() {
      _latestUserMsgId = userMsgId;
      _turnSpacerEnabled = true;
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
     * Scroll ONCE to the new user message, then stop. Everything after
     * this (thinking, streaming, cards) must not move the viewport.
     */
    await _anchorToLatestUserMessage();

    final error = await sendFuture;

    if (!mounted) return;

    if (error == null) {
      // NOTE: the turn is deliberately NOT ended here. send() resolves as
      // soon as the stream is *set up* (_streamReply returns right after
      // stream.listen attaches) — the AI response is still arriving. The
      // composer-idle watcher ends the turn when the AI truly finishes,
      // which is also when the spacer is removed.
      _controller.clear();

      _clearDraft();

      composerNotifier.clearPendingHiddenContext();

      return;
    }

    // The send never reached streaming (offline/empty/busy, queued, or the
    // upload failed first): no completion will ever arrive, so drop the
    // turn's scroll scaffolding immediately. (The upload-failed path also
    // ends the turn internally via _finishTurn, making this idempotent.)
    _endTurn(turnSeq);

    switch (error) {
      case ChatSendError.offline:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.offlineMessage), behavior: SnackBarBehavior.floating));

      case ChatSendError.uploadFailed:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.connectionError), behavior: SnackBarBehavior.floating));

      case ChatSendError.queued:
        // Accepted into the outbox: clear the composer like a send. The
        // queued bubble (same localId as the turn anchor) is already visible.
        _controller.clear();
        _clearDraft();
        composerNotifier.clearPendingHiddenContext();

      case ChatSendError.busy:
      case ChatSendError.empty:
        break;
    }
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
              Expanded(
                child: Stack(
                  children: [
                    const _MessageListView(),
                    if (_showJumpToLatest)
                      Positioned(
                        right: AppSizes.p16,
                        bottom: AppSizes.p12,
                        child: _JumpToLatestButton(onTap: _jumpToLatest),
                      ),
                  ],
                ),
              ),
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
              onTap: () => showPaywallScreen(context, onProceedWithLimited: () {}),
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

        final isLoading = context.select<ChatComposerNotifier, bool>((n) => n.isLoading);

        if (historyLoading) {
          return const ChatShimmerLoading();
        }

        final hasUserMessages = messages.any((m) => m.role == 'user');

        if (!hasUserMessages && !isLoading) {
          return const ChatEmptyState();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return CustomScrollView(
              controller: scrollController,
              reverse: false,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(padding: EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p10, AppSizes.p16, AppSizes.p16), sliver: const _MessageSliverList()),

                /*
                 * Turn-scoped spacer: enabled ONLY between send and turn end.
                 *
                 * Positioning the new user message near the top is physically
                 * impossible without trailing scroll extent (there is not
                 * enough content below the message yet), so exactly one
                 * viewport of it is provided while the turn is active — and
                 * removed the moment the turn ends. At rest, scroll extent
                 * is always exactly: actual content + the padding above.
                 */
                if (chatScreenState._turnSpacerEnabled) SliverToBoxAdapter(child: SizedBox(height: constraints.maxHeight)),
              ],
            );
          },
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
                      imageHashes: msg.imageHashes,
                      localImages: msg.localImages,
                      isSending: msg.isSending,
                      sendFailed: msg.sendFailed,
                      isQueued: msg.isQueued,
                      isStreaming: isStreaming && isLatestAi,
                      errorKind: msg.errorKind,
                      wasTruncated: msg.wasTruncated,
                      screenWidth: MediaQuery.sizeOf(context).width,
                      showAvatar: showAvatar,
                      showActions: isLatestAi && msg.text.isNotEmpty && !isLoading,
                      onRegenerate: composerNotifier.canRegenerate
                          ? () async {
                              HapticHelper.light();

                              final messenger = ScaffoldMessenger.of(context);
                              final error = await composerNotifier.regenerateLastResponse();
                              if (error == ChatSendError.offline) {
                                messenger.showSnackBar(const SnackBar(content: Text(AppStrings.offlineMessage), behavior: SnackBarBehavior.floating));
                              }
                            }
                          : null,
                      onRetry: msg.isQueued
                          ? () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final error = await composerNotifier.flushOutbox();
                              if (error == ChatSendError.offline) {
                                messenger.showSnackBar(const SnackBar(content: Text(AppStrings.offlineMessage), behavior: SnackBarBehavior.floating));
                              }
                            }
                          : (msg.sendFailed
                                ? () => unawaited(composerNotifier.retryMessage(msg))
                                : (msg.errorKind == ChatErrorKind.connection
                                ? () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final error = await composerNotifier.regenerateLastResponse();
                                    if (error == ChatSendError.offline) {
                                      messenger.showSnackBar(const SnackBar(content: Text(AppStrings.offlineMessage), behavior: SnackBarBehavior.floating));
                                    }
                                  }
                                : null)),
                      onQuotaPressed: () => unawaited(showPaywallScreen(context, onProceedWithLimited: () {})),
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
                      onSeeMoreSwaps: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final error = await composerNotifier.handleSeeMoreSwaps(msg.text, msg.scanData);
                        if (error == ChatSendError.offline) {
                          messenger.showSnackBar(const SnackBar(content: Text(AppStrings.offlineMessage), behavior: SnackBarBehavior.floating));
                        }
                      },
                      onViewFullReport: msg.scanData != null
                          ? () {
                              // Every scan type renders in the unified result screen.
                              unawaited(context.push(AppRoutes.scanResult, extra: ScanResultArgs(scanData: msg.scanData!)));
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

// =============================================================================
// JUMP TO LATEST BUTTON
// =============================================================================

/// Floating manual navigation control, ChatGPT-style.
///
/// A compact rounded-square arrow styled like the composer's send button
/// (filled, light icon). Visible only while the user is meaningfully away
/// from the newest content. Tapping it is the ONLY motion besides the send
/// scroll — it never fires on its own, and no AI update ever moves the
/// viewport or summons it.
class _JumpToLatestButton extends StatelessWidget {
  const _JumpToLatestButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;

    return Semantics(
      button: true,
      label: AppStrings.jumpToLatest,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: colorScheme.textPrimary, borderRadius: BorderRadius.circular(AppSizes.r14)),
          child: Icon(AppIcons.arrowDown, size: 20, color: colorScheme.cardBackground, semanticLabel: null),
        ),
      ),
    );
  }
}
