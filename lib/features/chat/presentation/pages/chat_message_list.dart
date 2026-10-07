part of 'chat_screen.dart';

/// Chat message-list presentation components.

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

        if (historyLoading) {
          return const ChatShimmerLoading();
        }

        return CustomScrollView(
          controller: scrollController,
          reverse: false,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [SliverPadding(padding: EdgeInsets.fromLTRB(AppSizes.p16, 0, AppSizes.p16, AppSizes.p16), sliver: const _MessageSliverList())],
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

    final anchorIndex = messages.indexWhere((message) => message.localId == screenState._latestUserMsgId);
    bool startsDay(int index) => index == 0 || !DateUtils.isSameDay(messages[index - 1].createdAt, messages[index].createdAt);

    Widget buildMessage(BuildContext ctx, int i) {
      final msg = messages[i];

      final prevMsg = i > 0 ? messages[i - 1] : null;

      final showDateHeader = i != anchorIndex && startsDay(i);

      final showAvatar = msg.role == 'ai' && (prevMsg == null || prevMsg.role != 'ai' || showDateHeader);

      final isLatestAi = i == latestAiIndex;

      final isLatestUser = i == anchorIndex;

      return KeyedSubtree(
        key: ValueKey(msg.localId),
        child: AnimatedChatItem(
          animate: !isLatestUser,
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
                          if (error == ChatSendError.offline && context.mounted) {
                            messenger.showSnackBar(const SnackBar(content: Text(AppStrings.offlineMessage), behavior: SnackBarBehavior.floating));
                          }
                        }
                      : null,
                  onRetry: msg.isQueued
                      ? () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final error = await composerNotifier.flushOutbox();
                          if (error == ChatSendError.offline && context.mounted) {
                            messenger.showSnackBar(const SnackBar(content: Text(AppStrings.offlineMessage), behavior: SnackBarBehavior.floating));
                          }
                        }
                      : (msg.sendFailed
                            ? () => unawaited(composerNotifier.retryMessage(msg))
                            : (msg.errorKind == ChatErrorKind.connection
                                  ? () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      final error = await composerNotifier.regenerateLastResponse();
                                      if (error == ChatSendError.offline && context.mounted) {
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
                  onScanConsumptionResolved: (consumed) async {
                    final didSave = await historyNotifier.resolveScanConsumption(msg, consumed: consumed);
                    if (!didSave && ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneral), behavior: SnackBarBehavior.floating));
                    }
                    return didSave;
                  },
                  swapData: msg.swapData,
                  onSeeMoreSwaps: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final error = await composerNotifier.handleSeeMoreSwaps(msg.text, msg.scanData);
                    if (error == ChatSendError.offline && context.mounted) {
                      messenger.showSnackBar(const SnackBar(content: Text(AppStrings.offlineMessage), behavior: SnackBarBehavior.floating));
                    }
                  },
                  onViewFullReport: msg.scanData != null
                      ? () {
                          // Every scan type renders in the unified result screen.
                          unawaited(context.push(AppRoutes.scanResult, extra: ScanResultArgs(scanData: msg.scanData!)));
                        }
                      : null,
                  onScannerModeSelected: (mode) {
                    final screenState = context.findAncestorStateOfType<ChatScreenState>();
                    if (screenState != null) {
                      unawaited(screenState.handleCamera(historyNotifier, composerNotifier, authNotifier, mode: mode));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final historyCount = anchorIndex < 0 ? messages.length : anchorIndex;
    final history = SliverList(
      delegate: SliverChildBuilderDelegate(
        buildMessage,
        childCount: historyCount,
        findChildIndexCallback: (key) {
          if (key is! ValueKey<String>) return null;
          final index = messages.indexWhere((message) => message.localId == key.value);
          return index >= 0 && index < historyCount ? index : null;
        },
      ),
    );
    if (anchorIndex < 0) return history;

    return SliverMainAxisGroup(
      slivers: [
        history,
        // Keep a new day's heading above the scroll target, so the prompt
        // itself lands directly beneath the App Bar.
        if (startsDay(anchorIndex)) SliverToBoxAdapter(child: DateHeader(date: messages[anchorIndex].createdAt)),
        ChatTurnSliver(anchorKey: screenState._latestUserMsgKey, children: [for (var i = anchorIndex; i < messages.length; i++) buildMessage(context, i)]),
      ],
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
