import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(ledgerProvider(const PartyQuery(page: 1)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHead(
          eyebrow: 'ADMIN · FINANCE',
          title: 'Transactions',
          subtitle: 'Platform financial transactions.',
        ),
        ledgerAsync.when(
          data: (paged) => SmartTable(
            columns: const [
              MvColumn('Ref', 'Ref', bold: true),
              MvColumn('Event', 'Event'),
              MvColumn('Order', 'Order'),
              MvColumn('Amount', 'Amount'),
              MvColumn('Status', 'Status'),
              MvColumn('Date', 'Date'),
            ],
            rows: [
              for (final e in paged.items)
                {
                  'Ref': _shortId(e.id),
                  'Event': e.event ?? '—',
                  'Order': e.order ?? '—',
                  'Amount': money(e.amount),
                  'Status': e.status ?? '—',
                  'Date': shortDate(e.date),
                  '_entry': e,
                },
            ],
            pageSize: 8,
            rowActions: (row) => TableActionBtn(
              icon: 'eye',
              tooltip: 'View entry',
              onPressed: () => _viewEntry(context, row['_entry'] as LedgerEntry),
            ),
          ),
          error: (e, _) => ErrorState(
            message: friendlyError(e),
            onRetry: () => ref.invalidate(ledgerProvider(const PartyQuery(page: 1))),
          ),
          loading: () => const LoadingState(),
        ),
      ],
    );
  }

  String _shortId(String? id) {
    if (id == null || id.isEmpty) return '—';
    return id.length <= 8 ? id : '…${id.substring(id.length - 8)}';
  }

  void _viewEntry(BuildContext context, LedgerEntry e) {
    showMvDetailModal(
      context,
      title: 'LEDGER ENTRY',
      children: [
        KeyValueGrid(
          entries: [
            MapEntry('Reference', e.id ?? '—'),
            MapEntry('Event', e.event ?? '—'),
            MapEntry('Order', e.order ?? '—'),
            MapEntry('Amount', money(e.amount)),
            MapEntry('Status', e.status ?? '—'),
            MapEntry('Date', shortDateTime(e.date)),
          ],
        ),
        if (e.description != null) ...[
          const SizedBox(height: 14),
          Text(
            'NOTES',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .6, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 4),
          Text(e.description!, style: const TextStyle(fontSize: 12.5, height: 1.45)),
        ],
      ],
    );
  }
}