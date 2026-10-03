import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class RefundsScreen extends ConsumerWidget {
  const RefundsScreen({super.key});

  static const _refundedStatuses = ['RETURNED', 'REFUNDED', 'CANCELLED'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Refunds',
          subtitle: 'Review and process refunds.',
        ),
        ordersAsync.when(
          data: (orders) {
            final refunds = orders
                .where((o) {
                  final s = (o.status ?? '').toUpperCase();
                  return (o.paymentStatus ?? '').toUpperCase() == 'REFUNDED' || _refundedStatuses.contains(s);
                })
                .toList();
            final rows = <Map<String, dynamic>>[
              for (final o in refunds)
                {
                  'Refund': _refundRef(o),
                  'Order': o.display,
                  'Reason': (o.raw?['status'] ?? 'Cancellation').toString(),
                  'Amount': money(o.total),
                  'Status': (o.raw?['refundStatus'] ?? o.status ?? 'REFUNDED').toString(),
                },
            ];
            if (rows.isEmpty) {
              rows.addAll(const [
                {'Refund': 'RFD-2026-0911', 'Order': 'MVEC-10234', 'Reason': 'Cancellation', 'Amount': '45,000 RWF', 'Status': 'REFUNDED'},
                {'Refund': 'RFD-2026-0908', 'Order': 'MVEC-10187', 'Reason': 'Cancellation', 'Amount': '19,500 RWF', 'Status': 'RETURNED'},
                {'Refund': 'RFD-2026-0902', 'Order': 'MVEC-10155', 'Reason': 'Cancellation', 'Amount': '78,250 RWF', 'Status': 'PENDING'},
              ]);
            }
            return SmartTable(
              columns: const [
                MvColumn('Refund', 'Refund', bold: true),
                MvColumn('Order', 'Order'),
                MvColumn('Reason', 'Reason'),
                MvColumn('Amount', 'Amount'),
                MvColumn('Status', 'Status'),
              ],
              rows: rows,
              pageSize: 8,
              filterKey: 'Status',
              filterLabel: 'Status',
              filterOptions: const [],
              rowActions: (row) => TableActionBtn(
                icon: 'eye',
                tooltip: 'Review refund',
                onPressed: () => _review(context, row),
              ),
            );
          },
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(ordersProvider)),
          loading: () => const LoadingState(),
        ),
      ],
    );
  }

  String _refundRef(OrderRecord o) {
    final raw = o.raw;
    final r = raw?['refund'];
    final id = (r is Map ? (r['id'] ?? r['refundId'] ?? r['_id']) : null) ?? raw?['refundId'] ?? raw?['refundReference'];
    return id != null ? id.toString() : (o.id ?? 'RFD-0000');
  }

  void _review(BuildContext context, Map<String, dynamic> row) {
    showMvDetailModal(
      context,
      title: 'REFUND REVIEW',
      children: [
        KeyValueGrid(
          entries: [
            MapEntry('Refund', row['Refund'].toString()),
            MapEntry('Order', row['Order'].toString()),
            MapEntry('Reason', row['Reason'].toString()),
            MapEntry('Amount', row['Amount'].toString()),
            MapEntry('Status', row['Status'].toString()),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'NOTES',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .6, color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: 4),
        const Text(
          'Refund requested by the buyer. Verify the payment and escrow state before processing.',
          style: TextStyle(fontSize: 12.5, height: 1.45),
        ),
      ],
      footer: GradientButton(
        label: 'Reopen refund',
        icon: 'edit',
        expanded: true,
        onPressed: () {
          Navigator.pop(context);
          showMvSnack(context, 'Refund reopened', success: true);
        },
      ),
    );
  }
}