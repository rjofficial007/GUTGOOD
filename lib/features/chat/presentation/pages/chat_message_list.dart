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
    final loadingSwapsMessageId = context.select<ChatComposerNotifier, String?>((n) => n.loadingSwapsMessageId);

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
                  isLoading:
                      msg.role == 'ai' &&
                      msg.errorKind == ChatErrorKind.none &&
                      ((isLatestAi && isLoading) || msg.text.isEmpty || msg.text == AppStrings.findingSwaps) &&
                      msg.scanData == null &&
                      msg.swapData == null,
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
                  isLoadingSwaps: msg.localId == loadingSwapsMessageId,
                  onScanConsumptionResolved: (consumed) async {
                    DateTime? occurredAt;
                    if (consumed) {
                      final choice = await showJournalEventSheet(ctx, title: 'When did you eat this?');
                      if (choice == null) return false;
                      occurredAt = choice.occurredAt;
                    }
                    final didSave = await historyNotifier.resolveScanConsumption(msg, consumed: consumed, occurredAt: occurredAt);
                    if (!didSave && ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneral), behavior: SnackBarBehavior.floating));
                    }
                    return didSave;
                  },
                  swapData: msg.swapData,
                  onSeeMoreSwaps: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final error = await composerNotifier.handleSeeMoreSwaps(msg);
                    if (error == ChatSendError.offline && context.mounted) {
                      messenger.showSnackBar(const SnackBar(content: Text(AppStrings.offlineMessage), behavior: SnackBarBehavior.floating));
                    } else if (error == ChatSendError.failed && context.mounted) {
                      messenger.showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneral), behavior: SnackBarBehavior.floating));
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
                if (msg.role == 'ai' && !isLoading && !isStreaming) ...[
                  for (final meal in msg.mealLogs.where((meal) => meal.firestoreId != null))
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.schedule, size: 16),
                        label: Text(
                          meal.occurredAtProvenance == OccurrenceProvenance.user
                              ? 'Meal time · ${MaterialLocalizations.of(ctx).formatMediumDate(meal.eventTime.toLocal())} ${TimeOfDay.fromDateTime(meal.eventTime.toLocal()).format(ctx)}'
                              : 'Confirm meal time · ${meal.items.firstOrNull ?? "Meal"}',
                        ),
                        onPressed: () async {
                          final choice = await showJournalEventSheet(ctx, title: 'When did you eat this?', initialTime: meal.eventTime);
                          if (choice == null) return;
                          final saved = await historyNotifier.confirmJournalTiming(msg, meal: meal, occurredAt: choice.occurredAt);
                          if (!saved && ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneral)));
                        },
                      ),
                    ),
                  for (final symptom in msg.symptomLogs.where((symptom) => symptom.firestoreId != null))
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.schedule, size: 16),
                        label: Text(
                          symptom.occurredAtProvenance == OccurrenceProvenance.user
                              ? '${symptom.symptom} · ${MaterialLocalizations.of(ctx).formatMediumDate(symptom.eventTime.toLocal())} ${TimeOfDay.fromDateTime(symptom.eventTime.toLocal()).format(ctx)}'
                              : 'Confirm symptom time · ${symptom.symptom}',
                        ),
                        onPressed: () async {
                          try {
                            final meals = await historyNotifier.recentConfirmedMeals();
                            if (!ctx.mounted) return;
                            final choice = await showJournalEventSheet(ctx, title: 'When did you feel this?', initialTime: symptom.eventTime, meals: meals, initialMealId: symptom.lastMealFirestoreId);
                            if (choice == null) return;
                            final saved = await historyNotifier.confirmJournalTiming(msg, symptom: symptom, occurredAt: choice.occurredAt, linkedMealId: choice.mealId);
                            if (!saved && ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneral)));
                          } catch (_) {
                            if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text(AppStrings.errorGeneral)));
                          }
                        },
                      ),
                    ),
                ],
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
