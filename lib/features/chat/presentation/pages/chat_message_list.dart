part of 'chat_screen.dart';

/// Chat message-list presentation components.

class _MessageListView extends StatelessWidget {
  const _MessageListView();

  @override
  Widget build(BuildContext context) {
    final chatScreenState = context.findAncestorStateOfType<ChatScreenState>()!;

    final scrollController = chatScreenState._scroll;

    return Selector<ChatHistoryNotifier, (bool, int, bool)>(
      selector: (_, n) => (n.historyLoading, n.messages.length, chatScreenState._turnSpacerEnabled),
      builder: (context, state, _) {
        final historyLoading = state.$1;

        if (historyLoading) {
          return const ChatShimmerLoading();
        }

        return LayoutBuilder(
          builder: (context, constraints) => CustomScrollView(
            controller: scrollController,
            reverse: false,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(padding: EdgeInsets.fromLTRB(AppSizes.p16, 0, AppSizes.p16, AppSizes.p16), sliver: const _MessageSliverList()),

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

