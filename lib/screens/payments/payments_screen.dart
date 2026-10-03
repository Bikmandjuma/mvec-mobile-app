import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHead(
          eyebrow: 'ADMIN · PAYMENTS',
          title: 'Payments',
          subtitle: 'Monitor payment confirmations and protected settlement states.',
        ),
        ordersAsync.when(
          data: (orders) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DataCard(
                title: 'Settlement summary',
                child: Row(
                  children: [
                    Expanded(child: MetricCard(label: 'Held funds', value: money(18400000), icon: 'wallet')),
                    const SizedBox(width: 12),
                    Expanded(child: MetricCard(label: 'Released', value: money(12150000), icon: 'check')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SmartTable(
                columns: const [
                  MvColumn('Id', 'Id', bold: true),
                  MvColumn('Order', 'Order'),
                  MvColumn('Payer', 'Payer'),
                  MvColumn('Amount', 'Amount'),
                  MvColumn('Method', 'Method'),
                  MvColumn('Status', 'Status'),
                ],
                rows: [
                  for (final o in orders)
                    {
                      'Id': _paymentId(o),
                      'Order': o.display,
                      'Payer': o.buyer ?? '—',
                      'Amount': money(o.total),
                      'Method': _methodLabel(o.paymentMethod),
                      'Status': o.paymentStatus ?? '—',
                    },
                ],
                pageSize: 8,
                filterKey: 'Status',
                filterLabel: 'Status',
                filterOptions: const [],
              ),
            ],
          ),
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(ordersProvider)),
          loading: () => const LoadingState(),
        ),
      ],
    );
  }

  String _paymentId(OrderRecord o) {
    final p = o.raw?['payment'];
    if (p is Map) {
      final id = p['id'] ?? p['transactionId'] ?? p['reference'] ?? p['_id'];
      if (id != null) return id.toString();
    }
    return o.id ?? '—';
  }

  String _methodLabel(String? m) {
    final s = (m ?? '').toUpperCase();
    if (s.contains('MTN') || s.contains('MOMO') || s.contains('MOBILE')) return 'MTN MoMo';
    if (s.contains('AIRTEL')) return 'Airtel Money';
    return (m == null || m.isEmpty) ? 'Card' : m;
  }
}