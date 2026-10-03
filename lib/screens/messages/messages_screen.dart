import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/party.dart';
import '../../providers/admin_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/mv_icon.dart';

final _messagesProvider = FutureProvider.autoDispose.family<List<MessageRecord>, String>(
  (ref, conversationId) {
    final myId = ref.watch(currentUserProvider)?.id;
    return ref.watch(platformServiceProvider).conversationMessages(conversationId, myId: myId);
  },
);

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  String? _selectedId;
  final _compose = TextEditingController();

  @override
  void dispose() {
    _compose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final listPane = switch (conversations) {
      AsyncData(:final value) => _conversationList(context, value),
      AsyncError(:final error) => ErrorState(
          message: friendlyError(error),
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
      _ => const LoadingState(),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Messages',
          subtitle: 'Platform support conversations.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            final selected = _selectedId;
            if (wide) {
              return SizedBox(
                height: 640,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 300, child: listPane),
                    const VerticalDivider(width: 1),
                    Expanded(child: _threadPane(selected)),
                  ],
                ),
              );
            }
            return SizedBox(
              height: 640,
              child: selected == null ? listPane : _threadPane(selected),
            );
          },
        ),
      ],
    );
  }

  Widget _conversationList(BuildContext context, List<ConversationRecord> conversations) {
    if (conversations.isEmpty) return const EmptyState(message: 'No conversations');
    return Card(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: conversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, i) => _tile(conversations[i]),
      ),
    );
  }

  Widget _tile(ConversationRecord c) {
    final name = c.participants?.split(',').first.trim() ?? c.subject ?? 'Conversation';
    final unread = c.unread ?? 0;
    final selected = _selectedId == c.id;
    return ListTile(
      onTap: () => setState(() => _selectedId = c.id),
      selected: selected,
      selectedTileColor: MvColors.soft,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: MvColors.metricIconBg,
        child: Text(
          initials(name),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: MvColors.primaryDeep),
        ),
      ),
      title: Text(
        c.subject ?? name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        c.lastMessage ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor),
      ),
      trailing: unread > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: MvColors.badgeRed, borderRadius: BorderRadius.circular(10)),
              child: Text(
                '$unread',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _threadPane(String? conversationId) {
    if (conversationId == null) return const EmptyState(message: 'Select a conversation');
    final messages = ref.watch(_messagesProvider(conversationId));
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _threadHeader(conversationId),
          const Divider(height: 1),
          Expanded(
            child: switch (messages) {
              AsyncData(:final value) => _messageList(value),
              AsyncError(:final error) => ErrorState(
                  message: friendlyError(error),
                  onRetry: () => ref.invalidate(_messagesProvider(conversationId)),
                ),
              _ => const LoadingState(),
            },
          ),
          _composer(conversationId),
        ],
      ),
    );
  }

  Widget _threadHeader(String conversationId) {
    final conversations = ref.read(conversationsProvider);
    final subject = conversations.whenOrNull(data: (list) {
      for (final c in list) {
        if (c.id == conversationId) return c.subject ?? c.participants?.split(',').first;
      }
      return null;
    });
    final narrow = MediaQuery.of(context).size.width < 860;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          if (narrow) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _selectedId = null),
              icon: const MvIcon('arrow'),
              tooltip: 'Back to conversations',
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              subject ?? 'Conversation',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageList(List<MessageRecord> messages) {
    if (messages.isEmpty) return const EmptyState(message: 'No messages yet');
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: messages.length,
      itemBuilder: (context, i) => _bubble(messages[i]),
    );
  }

  Widget _bubble(MessageRecord m) {
    final mine = m.mine == true;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          gradient: mine ? MvColors.gradient : null,
          color: mine ? null : Theme.of(context).scaffoldBackgroundColor,
          border: mine ? null : Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(mine ? 12 : 2),
            bottomRight: Radius.circular(mine ? 2 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              m.body ?? '',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: mine ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              shortDateTime(m.createdAt),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: mine ? Colors.white70 : Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer(String conversationId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _compose,
              style: const TextStyle(fontSize: 13),
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => _send(conversationId),
              decoration: const InputDecoration(
                hintText: 'Type a message…',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _send(conversationId),
            style: IconButton.styleFrom(
              backgroundColor: MvColors.primaryDeep,
              foregroundColor: Colors.white,
              disabledBackgroundColor: MvColors.neutralBg,
              disabledForegroundColor: MvColors.neutralText,
            ),
            tooltip: 'Send',
            icon: const MvIcon('arrow', color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _send(String conversationId) async {
    final body = _compose.text.trim();
    if (body.isEmpty) return;
    _compose.clear();
    try {
      await ref.read(platformServiceProvider).sendMessage(conversationId, body);
      if (mounted) {
        FocusScope.of(context).unfocus();
        ref.invalidate(_messagesProvider(conversationId));
      }
    } catch (e) {
      if (mounted) showMvSnack(context, friendlyError(e));
    }
  }
}