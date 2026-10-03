import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/app_theme.dart';

/// A single demo order placeholder for the current/past order list.
class _Order {
  const _Order({
    required this.id,
    required this.status,
    required this.date,
    required this.total,
    required this.items,
  });

  final String id;
  final String status;
  final String date;
  final double total;
  final int items;
}

/// Orders tab: current (active) and previous orders.
///
/// Renders local sample entries for now; later this screen will be backed
/// by `GET /api/orders` through the same service pattern.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static const List<_Order> _sampleOrders = <_Order>[
    _Order(
      id: '#MV-20415',
      status: 'Out for delivery',
      date: 'Sep 21, 2026',
      total: 189.99,
      items: 1,
    ),
    _Order(
      id: '#MV-20398',
      status: 'Processing',
      date: 'Sep 19, 2026',
      total: 123.49,
      items: 3,
    ),
    _Order(
      id: '#MV-20321',
      status: 'Delivered',
      date: 'Sep 10, 2026',
      total: 64.00,
      items: 2,
    ),
    _Order(
      id: '#MV-20277',
      status: 'Delivered',
      date: 'Aug 28, 2026',
      total: 34.50,
      items: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text('Orders', style: AppTextStyles.headline(context)),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Past'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _OrdersList(activeOnly: true),
                _OrdersList(activeOnly: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.activeOnly});

  final bool activeOnly;

  static const Set<String> _activeStatuses = <String>{
    'Out for delivery',
    'Processing',
  };

  @override
  Widget build(BuildContext context) {
    final orders = OrdersScreen._sampleOrders
        .where((order) => _activeStatuses.contains(order.status) == activeOnly)
        .toList();

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: context.mv.textMuted,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              activeOnly ? 'No active orders' : 'No past orders yet',
              style: AppTextStyles.title(context),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _OrderCard(order: orders[index]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final _Order order;

  @override
  Widget build(BuildContext context) {
    final statusColor = order.status == 'Delivered'
        ? AppColors.success
        : AppColors.warning;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.id,
                  style: AppTextStyles.title(context).copyWith(fontSize: 13),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: context.mv.textMuted,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(order.date, style: AppTextStyles.caption(context)),
                const Spacer(),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: AppTextStyles.price(context).copyWith(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${order.items} item(s) · View details',
              style: AppTextStyles.bodySecondary(context).copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}