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

  /// Keep the latest sent turn tall enough to align its prompt at the top,
  /// including after a short response completes.
  String? _latestUserMsgId;

  /// Stable key attached to the current turn's user message so the send
  /// scroll can locate the actual widget instead of guessing its offset.
  final GlobalKey _latestUserMsgKey = GlobalKey();

  bool _sendScrollCancelled = false;

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

  Timer? _draftDebounce;

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

      // The jump control is scroll-driven only (see _onScroll): content
      // growth underneath a stationary viewport — e.g. AI streaming —
      // must NOT summon it. This call just establishes the initial state.
      _syncJumpButtonVisibility();
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
      _hasScrolledToBottomInitially = true;
      // If we are currently in a turn (user just sent a message), the
      // send-scroll anchor handles the positioning. A jump-to-bottom
      // here would fight with it and push the new message away from view.
      if (_latestUserMsgId != null) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) {
          return;
        }

        unawaited(_scrollToBottomInitially());
      });
    }
  }

  // ===========================================================================
  // SCROLL
  // ===========================================================================

  /// The latest turn fills at least one viewport, rather than adding a whole
  /// empty viewport after the messages.
  double get _effectiveMaxScrollExtent {
    if (!_scroll.hasClients) return 0.0;
    return _scroll.position.maxScrollExtent;
  }

  bool _handleUserScroll(UserScrollNotification notification) {
    if (notification.direction != ScrollDirection.idle) {
      _sendScrollCancelled = true;
    }
    return false;
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
     * jump control's visibility. Automatic positioning happens only on send.
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
    if (!mounted || !_scroll.hasClients || _latestUserMsgId != null) {
      return;
    }

    _scroll.jumpTo(_effectiveMaxScrollExtent);

    await WidgetsBinding.instance.endOfFrame;

    if (!mounted || !_scroll.hasClients || _latestUserMsgId != null) {
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
  /// then hides the control.
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
  // Reveal the sent prompt once. Streaming only grows the turn below it.

  Future<void> _anchorToLatestUserMessage() async {
    final requestedId = _latestUserMsgId;
    if (requestedId == null) return;

    for (var i = 0; i < _maxAnchorAttempts; i++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || _latestUserMsgId != requestedId || _sendScrollCancelled) return;
      if (_latestUserMsgKey.currentContext != null) break;
      if (_historyNotifier?.messages.any((message) => message.localId == requestedId) != true) return;

      // Bring a new turn sent from older history into the sliver's built range.
      if (_scroll.hasClients) _scroll.jumpTo(_effectiveMaxScrollExtent);
    }

    // A second bounded pass absorbs keyboard/composer resizing and lazy-list
    // measurement during the first animation. User gestures cancel both passes.
    for (var pass = 0; pass < 2; pass++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || _latestUserMsgId != requestedId || _sendScrollCancelled) return;
      final messageContext = _latestUserMsgKey.currentContext;
      if (messageContext == null || !messageContext.mounted) return;
      await Scrollable.ensureVisible(
        messageContext,
        alignment: 0,
        duration: Duration(milliseconds: pass == 0 ? 350 : 120),
        curve: Curves.easeOutCubic,
      );
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

    final userMsgId = const Uuid().v4();

    setState(() {
      _latestUserMsgId = userMsgId;
      _hasScrolledToBottomInitially = true;
      _sendScrollCancelled = false;
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
      _controller.clear();

      _clearDraft();

      composerNotifier.clearPendingHiddenContext();

      return;
    }

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
                  NotificationListener<UserScrollNotification>(onNotification: _handleUserScroll, child: const _MessageListView()),
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
