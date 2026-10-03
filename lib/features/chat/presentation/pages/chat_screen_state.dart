part of 'chat_screen.dart';

/// Chat screen state and turn coordination.

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
      // If we are currently in a turn (user just sent a message), the
      // send-scroll anchor handles the positioning. A jump-to-bottom
      // here would fight with it and, because of the turn spacer,
      // push the new message off the top of the viewport.
      if (_latestUserMsgId != null) {
        _hasScrolledToBottomInitially = true;
        return;
      }

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

  /// Returns the max scroll extent adjusted for the turn spacer. When the
  /// spacer is active, the raw maxScrollExtent points to the bottom of a
  /// huge empty area; this points to the end of the actual content.
  double get _effectiveMaxScrollExtent {
    if (!_scroll.hasClients) return 0.0;
    final position = _scroll.position;
    var max = position.maxScrollExtent;
    if (_turnSpacerEnabled) {
      max -= position.viewportDimension;
    }
    return max.clamp(0.0, position.maxScrollExtent);
  }

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

    _scroll.jumpTo(_effectiveMaxScrollExtent);

    await WidgetsBinding.instance.endOfFrame;

    if (!mounted || !_scroll.hasClients) {
      return;
    }

    _scroll.jumpTo(_effectiveMaxScrollExtent);
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

    final maxExtent = _effectiveMaxScrollExtent;

    final hasNewerContent = maxExtent > 0;

    final distanceFromBottom = maxExtent - position.pixels;

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

    await _scroll.animateTo(_effectiveMaxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);

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
       *
       * We jump to the effective bottom (end of content) rather than the
       * raw maxScrollExtent to avoid overshooting into the turn spacer.
       */
      if (i == 0 && _scroll.hasClients) {
        _scroll.jumpTo(_effectiveMaxScrollExtent);
      }
    }

    if (!mounted) return;

    if (_latestUserMsgId != requestedId) {
      return;
    }

    await _glideToUserMessage(_latestUserMsgKey);
  }

  /// Glides the viewport exactly once so the sent user message sits near
  /// the top (with breathing room). The AI response then appears and grows
  /// below it without any further motion.
  Future<void> _glideToUserMessage(GlobalKey key) async {
    final messageContext = key.currentContext;
    if (messageContext == null || !messageContext.mounted || !mounted || !_scroll.hasClients) {
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.offlineMessage), behavior: SnackBarBehavior.floating));
        }

      case ChatSendError.uploadFailed:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.connectionError), behavior: SnackBarBehavior.floating));
        }

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

// =============================================================================
// SUGGESTION CHIPS
// =============================================================================

