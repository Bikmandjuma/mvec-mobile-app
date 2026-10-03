import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  static const _entryTypes = ['HOLD', 'RELEASE', 'SETTLEMENT', 'COMMISSION', 'REFUND', 'FEE'];

  int _page = 1;
  String? _entryType;

  @override
  Widget build(BuildContext context) {
    final ledgerAsync = ref.watch(ledgerProvider(PartyQuery(page: _page, status: _entryType)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'ADMIN · FINANCE',
          title: 'Financial Ledger',
          subtitle: 'All platform ledger entries.',
          actions: [
            OutlineMvButton(
              label: 'Record ledger entry',
              icon: 'plus',
              onPressed: () => showMvSnack(context, 'Demo action — ledger entries are created automatically by the platform.'),
            ),
          ],
        ),
        ledgerAsync.when(
          data: (paged) {
            var held = 0.0;
            var released = 0.0;
            for (final e in paged.items) {
              final t = (e.entryType ?? '').toUpperCase();
              final s = (e.status ?? '').toUpperCase();
              if (t.contains('HOLD') || s == 'HELD') held += e.amount ?? 0;
              if (s == 'RELEASED') released += e.amount ?? 0;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: MetricCard(label: 'Ledger records', value: '${paged.total ?? paged.items.length}')),
                    const SizedBox(width: 12),
                    Expanded(child: MetricCard(label: 'Held funds', value: money(held), icon: 'wallet')),
                    const SizedBox(width: 12),
                    Expanded(child: MetricCard(label: 'Released', value: money(released), icon: 'check')),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _entryFilter(),
                ),
                const SizedBox(height: 12),
                SmartTable(
                  columns: const [
                    MvColumn('Ledger ID', 'Ledger ID', bold: true),
                    MvColumn('Event', 'Event'),
                    MvColumn('Order', 'Order'),
                    MvColumn('Amount', 'Amount'),
                    MvColumn('Status', 'Status'),
                    MvColumn('Date', 'Date'),
                  ],
                  rows: [
                    for (final e in paged.items)
                      {
                        'Ledger ID': e.id ?? '—',
                        'Event': e.event ?? '—',
                        'Order': e.order ?? '—',
                        'Amount': money(e.amount),
                        'Status': e.status ?? '—',
                        'Date': shortDate(e.date),
                      },
                  ],
                  pageSize: 8,
                  serverPage: _page,
                  serverTotalPages: paged.pages ?? 1,
                  onServerPageChanged: (p) => setState(() => _page = p),
                ),
              ],
            );
          },
          error: (e, _) => ErrorState(
            message: friendlyError(e),
            onRetry: () => ref.invalidate(ledgerProvider(PartyQuery(page: _page, status: _entryType))),
          ),
          loading: () => const LoadingState(),
        ),
      ],
    );
  }

  Widget _entryFilter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Entry type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).canvasColor,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _entryType,
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('All')),
                for (final t in _entryTypes)
                  DropdownMenuItem<String?>(value: t, child: Text(t)),
              ],
              onChanged: (v) => setState(() {
                _entryType = v;
                _page = 1;
              }),
            ),
          ),
        ),
      ],
    );
  }
}