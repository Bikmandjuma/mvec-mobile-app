import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

String _shortId(String? id) {
  if (id == null || id.isEmpty) return '—';
  return id.length <= 8 ? id.toUpperCase() : '${id.substring(0, 8).toUpperCase()}…';
}

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  bool _showVendor = true;
  final _busy = <String>{};

  Future<void> _toggle(SubscriptionRecord s) async {
    final id = s.id ?? '';
    if (id.isEmpty || _busy.contains(id)) return;
    final active = (s.status ?? '').toUpperCase() == 'ACTIVE';
    final target = active ? 'CANCELLED' : 'ACTIVE';
    setState(() => _busy.add(id));
    try {
      await ref.read(financeServiceProvider).patchSubscription(id, target);
      if (!mounted) return;
      ref.invalidate(subscriptionsProvider);
      ref.invalidate(buyerSubscriptionsProvider);
      showMvSnack(context, 'Subscription ${_shortId(id)} ${target == 'ACTIVE' ? 'activated' : 'cancelled'}', success: true);
    } catch (e) {
      if (mounted) showMvSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Widget _toggleChip(SubscriptionRecord s) {
    final id = s.id ?? '';
    final active = (s.status ?? '').toUpperCase() == 'ACTIVE';
    final fg = active ? MvColors.successText : MvColors.errorText;
    return InkWell(
      onTap: id.isEmpty || _busy.contains(id) ? null : () => _toggle(s),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? MvColors.successBg : MvColors.errorBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: fg.withValues(alpha: .35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 13,
              height: 13,
              child: _busy.contains(id)
                  ? CircularProgressIndicator(strokeWidth: 1.5, color: fg)
                  : Icon(active ? Icons.pause : Icons.play_arrow, size: 13, color: fg),
            ),
            const SizedBox(width: 5),
            Text(active ? 'Cancel' : 'Activate', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: fg)),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(AsyncValue<List<SubscriptionRecord>> async, {required String title}) {
    return async.when(
      data: (list) => DataCard(
        title: title,
        child: SmartTable(
          columns: const [
            MvColumn('Holder', 'Holder', bold: true),
            MvColumn('Type', 'Type'),
            MvColumn('Amount', 'Amount'),
            MvColumn('Cycle', 'Cycle'),
            MvColumn('Status', 'Status'),
          ],
          rows: [
            for (final s in list)
              {
                'Holder': s.holder ?? '—',
                'Type': s.type ?? '—',
                'Amount': money(s.amount),
                'Cycle': s.cycle ?? '—',
                'Status': StatusChip(s.status),
                '_s': s,
              },
          ],
          actionsLabel: 'Status',
          pageSize: 6,
          rowActions: (row) => _toggleChip(row['_s'] as SubscriptionRecord),
        ),
      ),
      error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(_showVendor ? subscriptionsProvider : buyerSubscriptionsProvider)),
      loading: () => const LoadingState(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendorAsync = ref.watch(subscriptionsProvider);
    final buyerAsync = ref.watch(buyerSubscriptionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN · PLANS',
          title: 'Subscriptions',
          subtitle: 'Manage marketplace subscription plans.',
          actions: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _segment('Vendor', _showVendor, () => setState(() => _showVendor = true)),
                  const SizedBox(width: 4),
                  _segment('Buyer', !_showVendor, () => setState(() => _showVendor = false)),
                ],
              ),
            ),
          ],
        ),
        _showVendor
            ? _buildTable(vendorAsync, title: 'Vendor subscriptions')
            : _buildTable(buyerAsync, title: 'Buyer subscriptions'),
      ],
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? MvColors.primaryDeep : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : MvColors.muted,
          ),
        ),
      ),
    );
  }
}