import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Notifications',
          subtitle: 'Platform notifications.',
          actions: [
            OutlineMvButton(
              label: 'Mark all read',
              icon: 'check',
              onPressed: () => _markAllRead(context, ref),
            ),
          ],
        ),
        switch (notifications) {
          AsyncData(:final value) => _table(context, value),
          AsyncError(:final error) => ErrorState(
              message: friendlyError(error),
              onRetry: () => ref.invalidate(notificationsProvider),
            ),
          _ => const LoadingState(),
        },
      ],
    );
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(platformServiceProvider).markAllRead();
      ref.invalidate(notificationsProvider);
      if (context.mounted) {
        showMvSnack(context, 'All notifications marked as read.', success: true);
      }
    } catch (e) {
      if (context.mounted) showMvSnack(context, friendlyError(e));
    }
  }

  Widget _table(BuildContext context, List<NotificationRecord> list) {
    final rows = list
        .map((n) => {
              'recipient': n.recipient ?? '-',
              'type': titleCase(n.type ?? 'Event'),
              'message': n.message ?? '',
              'status': (n.status ?? 'UNREAD').toUpperCase(),
              'date': shortDate(n.createdAt),
            })
        .toList();
    return SmartTable(
      columns: const [
        MvColumn('recipient', 'Recipient', flex: 2),
        MvColumn('type', 'Type'),
        MvColumn('message', 'Message', flex: 3),
        MvColumn('date', 'Date'),
      ],
      rows: rows,
      pageSize: 8,
      filterKey: 'status',
      filterLabel: 'Status',
      filterOptions: const ['UNREAD', 'READ'],
      actionsLabel: 'Status · View',
      rowActions: (row) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusChip(
            row['status']?.toString(),
            overrideColor: row['status'] == 'READ' ? MvColors.neutralText : MvColors.warningText,
          ),
          const SizedBox(width: 6),
          TableActionBtn(icon: 'eye', tooltip: 'View', onPressed: () => _view(context, row)),
        ],
      ),
    );
  }

  void _view(BuildContext context, Map<String, dynamic> row) {
    showMvDetailModal(
      context,
      title: 'Notification',
      children: [
        KeyValueGrid(entries: [
          MapEntry('Recipient', row['recipient']?.toString() ?? '-'),
          MapEntry('Type', row['type']?.toString() ?? '-'),
          MapEntry('Status', row['status']?.toString() ?? '-'),
          MapEntry('Date', row['date']?.toString() ?? '-'),
        ]),
        const SizedBox(height: 18),
        Text(
          'Message',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .6,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          row['message']?.toString() ?? '',
          style: const TextStyle(fontSize: 13.5, height: 1.5),
        ),
      ],
    );
  }
}