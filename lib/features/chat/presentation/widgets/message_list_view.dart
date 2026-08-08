import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_provider.dart';
import 'package:gutgood/features/chat/presentation/widgets/chat_components.dart';
import 'package:provider/provider.dart';

class MessageListView extends StatelessWidget {
  const MessageListView({
    super.key,
    required this.scrollController,
    required this.onSend,
  });
  final ScrollController scrollController;
  final Future<void> Function(ChatNotifier, GutAuthNotifier, [String?]) onSend;

  @override
  Widget build(BuildContext context) => Consumer<ChatNotifier>(
    builder: (context, chatNotifier, _) {
      final messages = chatNotifier.messages;
      final historyLoading = chatNotifier.historyLoading;
      final isLoading = chatNotifier.isLoading;
      final messageCount = messages.length;

      if (historyLoading) return const ChatShimmerLoading();
      if (messageCount <= 1 && !isLoading) return const ChatEmptyState();

      return CustomScrollView(
        controller: scrollController,
        reverse: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.p16,
              vertical: AppSizes.p20,
            ),
            sliver: _MessageSliverList(messages: messages),
          ),
        ],
      );
    },
  );
}

class _MessageSliverList extends StatelessWidget {
  const _MessageSliverList({required this.messages});
  final List<ChatMessage> messages;

  int _latestAiIndex(List<ChatMessage> messages) {
    for (var i = 0; i < messages.length; i++) {
      if (messages[i].role == 'ai') return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final isStreaming = context.select<ChatNotifier, bool>(
      (n) => n.isStreaming,
    );
    final latestAiIndex = _latestAiIndex(messages);

    return SliverList(
      delegate: SliverChildBuilderDelegate((ctx, i) {
        final msg = messages[i];
        final prevMsg = i < messages.length - 1 ? messages[i + 1] : null;

        var showDateHeader = false;
        if (prevMsg == null) {
          showDateHeader = true;
        } else {
          final d1 = DateTime(msg.time.year, msg.time.month, msg.time.day);
          final d2 = DateTime(
            prevMsg.time.year,
            prevMsg.time.month,
            prevMsg.time.day,
          );
          if (d1 != d2) showDateHeader = true;
        }

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
                    isLoading:
                        msg.role == 'ai' &&
                        msg.text.isEmpty &&
                        msg.errorKind == ChatErrorKind.none &&
                        msg.scanData == null,
                    imageUrls: msg.imageUrls,
                    localImages: msg.localImages,
                    isSending: msg.isSending,
                    sendFailed: msg.sendFailed,
                    isStreaming: isStreaming && isLatestAi,
                    errorKind: msg.errorKind,
                    screenWidth: MediaQuery.sizeOf(context).width,
                  ),
                ],
              ),
            ),
          ),
        );
      }, childCount: messages.length),
    );
  }
}
