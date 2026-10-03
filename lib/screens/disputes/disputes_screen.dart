import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

String _shortId(String? id) {
  if (id == null || id.isEmpty) return '—';
  return id.length <= 8 ? id.toUpperCase() : '${id.substring(0, 8).toUpperCase()}…';
}

class DisputesScreen extends ConsumerStatefulWidget {
  const DisputesScreen({super.key});

  @override
  ConsumerState<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends ConsumerState<DisputesScreen> {
  static const _decisions = ['REFUND_BUYER', 'RELEASE_TO_VENDOR', 'SPLIT_SETTLEMENT'];

  Future<void> _showDetail(DisputeRecord d) async {
    var decision = 'REFUND_BUYER';
    await showMvDetailModal(
      context,
      title: 'DISPUTE DETAIL',
      children: [
        KeyValueGrid(entries: [
          MapEntry('Dispute', _shortId(d.id)),
          MapEntry('Order', d.order ?? '—'),
          MapEntry('Reason', d.reason ?? '—'),
          MapEntry('Buyer', d.buyer ?? '—'),
          MapEntry('Amount', money(d.amount)),
          MapEntry('Status', d.status ?? '—'),
          MapEntry('Submitted', shortDate(d.createdAt)),
        ]),
        if ((d.description ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(d.description!, style: const TextStyle(fontSize: 13, height: 1.5)),
        ],
      ],
      footer: StatefulBuilder(
        builder: (ctx, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Decision', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(ctx).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(ctx).canvasColor,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: decision,
                      isDense: true,
                      items: [for (final o in _decisions) DropdownMenuItem<String>(value: o, child: Text(titleCase(o)))],
                      onChanged: (v) => setModalState(() => decision = v ?? decision),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GradientButton(
              label: 'Save',
              icon: 'check',
              expanded: true,
              onPressed: () async {
                try {
                  await ref.read(platformServiceProvider).arbitrateDispute(d.id ?? '', decision: decision);
                  if (!mounted) return;
                  ref.invalidate(disputesProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) showMvSnack(context, 'Dispute marked ${titleCase(decision)}', success: true);
                } catch (e) {
                  if (mounted) showMvSnack(context, friendlyError(e));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final disputesAsync = ref.watch(disputesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Disputes',
          subtitle: 'Arbitrate buyer–vendor disputes.',
        ),
        disputesAsync.when(
          data: (disputes) => SmartTable(
            columns: const [
              MvColumn('Dispute', 'Dispute', bold: true),
              MvColumn('Order', 'Order'),
              MvColumn('Reason', 'Reason'),
              MvColumn('Buyer', 'Buyer'),
              MvColumn('Amount', 'Amount'),
              MvColumn('Status', 'Status'),
            ],
            rows: [
              for (final d in disputes)
                {
                  'Dispute': _shortId(d.id),
                  'Order': d.order ?? '—',
                  'Reason': d.reason ?? '—',
                  'Buyer': d.buyer ?? '—',
                  'Amount': money(d.amount),
                  'Status': StatusChip(d.status),
                  '_d': d,
                },
            ],
            actionsLabel: 'Details',
            pageSize: 8,
            filterKey: 'status',
            filterLabel: 'Status',
            filterOptions: const ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'],
            rowActions: (row) => TableActionBtn(
              icon: 'eye',
              tooltip: 'View dispute',
              onPressed: () => _showDetail(row['_d'] as DisputeRecord),
            ),
          ),
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(disputesProvider)),
          loading: () => const LoadingState(),
        ),
      ],
    );
  }
}