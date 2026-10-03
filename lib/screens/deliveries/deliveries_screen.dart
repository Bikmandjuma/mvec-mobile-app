import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/mv_icon.dart';
import '../../widgets/smart_table.dart';

class DeliveriesScreen extends ConsumerWidget {
  const DeliveriesScreen({super.key});

  static const _steps = ['PENDING', 'CONFIRMED', 'PROCESSING', 'PACKED', 'SHIPPED', 'IN_TRANSIT', 'OUT_FOR_DELIVERY', 'AT_HUB', 'DELIVERED'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Deliveries',
          subtitle: 'Track deliveries and escrow settlement states.',
        ),
        ordersAsync.when(
          data: (orders) {
            final deliveries = orders
                .where((o) {
                  final s = '${o.status ?? ''} ${o.paymentStatus ?? ''}'.toUpperCase();
                  return s.contains('SHIP') || s.contains('DELIVERY');
                })
                .toList();
            final todayDelivered = orders
                .where((o) => (o.status ?? '').toUpperCase() == 'DELIVERED' && o.createdAt != null && _isToday(o.createdAt!))
                .length;
            final stepperStatus = deliveries.isEmpty ? 'DELIVERED' : (deliveries.first.status ?? 'DELIVERED');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: MetricCard(label: 'Delivered today', value: '$todayDelivered', icon: 'box')),
                  ],
                ),
                const SizedBox(height: 12),
                DataCard(title: 'Delivery steps', child: _DeliveryStepper(status: stepperStatus)),
                const SizedBox(height: 12),
                InfoBox('Delivery OTP is shared with the customer at handoff.'),
                const SizedBox(height: 16),
                SmartTable(
                  columns: const [
                    MvColumn('Order', 'Order', bold: true),
                    MvColumn('Buyer', 'Buyer'),
                    MvColumn('Vendor', 'Vendor'),
                    MvColumn('Status', 'Status'),
                    MvColumn('Settlement', 'Settlement'),
                  ],
                  rows: [
                    for (final o in deliveries)
                      {
                        'Order': o.display,
                        'Buyer': o.buyer ?? '—',
                        'Vendor': o.vendor ?? '—',
                        'Status': o.status ?? 'PENDING',
                        'Settlement': o.paymentStatus ?? '—',
                      },
                  ],
                  pageSize: 8,
                  emptyMessage: 'No active deliveries',
                ),
              ],
            );
          },
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(ordersProvider)),
          loading: () => const LoadingState(),
        ),
      ],
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _DeliveryStepper extends StatelessWidget {
  const _DeliveryStepper({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final steps = DeliveriesScreen._steps;
    final raw = steps.indexOf(status.toUpperCase());
    final filled = raw < 0 ? 0 : raw;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                child: Center(child: _node(context, i, filled)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                child: Text(
                  titleCase(steps[i]),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: i <= filled ? FontWeight.w800 : FontWeight.w600,
                    color: i <= filled ? MvColors.primaryDeep : Theme.of(context).hintColor,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _node(BuildContext context, int i, int filled) {
    final done = i <= filled;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? null : MvColors.surface2,
        border: done ? null : Border.all(color: Theme.of(context).dividerColor),
        gradient: done ? MvColors.gradient : null,
      ),
      child: done ? const Center(child: MvIcon('check', size: 12, color: Colors.white)) : null,
    );
  }
}