import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/smart_table.dart';
import '../../data/models/affiliate_earnings.dart';
import '../providers/affiliate_providers.dart';

/// Earnings ledger: wallet summary + every commission line, filterable by
/// state (AVAILABLE / PENDING / PAID) like the frontend commissions page.
class AffiliateEarningsScreen extends ConsumerWidget {
  const AffiliateEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(affiliateWalletProvider);
    final commissionsAsync = ref.watch(affiliateCommissionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHead(
          eyebrow: 'Earnings',
          title: 'Earnings',
          subtitle: 'Everything you have earned from referrals and what is available to withdraw.',
          actions: [
            GradientButton(label: 'Withdraw', icon: 'wallet', onPressed: () => context.go('/affiliate/payouts')),
          ],
        ),
        walletAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(affiliateWalletProvider)),
          data: (w) => Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, c) {
                  final chips = <Widget>[
                    _chunk(context, 'AVAILABLE BALANCE', money(w.availableBalance), big: true),
                    _chunk(context, 'PENDING', money(w.pendingBalance)),
                    _chunk(context, 'TOTAL EARNED', money(w.totalEarned)),
                    _chunk(context, 'WITHDRAWN', money(w.totalWithdrawn)),
                  ];
                  if (c.maxWidth > 720) {
                    return Row(
                      children: [
                        for (var i = 0; i < chips.length; i++) ...[
                          if (i > 0) Container(width: 1, height: 46, color: Theme.of(context).dividerColor, margin: const EdgeInsets.symmetric(horizontal: 18)),
                          Expanded(child: chips[i]),
                        ],
                      ],
                    );
                  }
                  return Wrap(
                    spacing: 26,
                    runSpacing: 16,
                    children: chips,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        commissionsAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(affiliateCommissionsProvider)),
          data: (commissions) => DataCard(
            title: 'Commission history',
            subtitle: 'Each referral event that adds commission to your wallet.',
            child: SmartTable(
              emptyMessage: 'No commissions yet',
              columns: const [
                MvColumn('target', 'Product / event', flex: 3),
                MvColumn('type', 'Type', flex: 2),
                MvColumn('order', 'Order', flex: 2),
                MvColumn('amount', 'Amount', flex: 2),
                MvColumn('status', 'Status', flex: 2),
                MvColumn('date', 'Date', flex: 2),
              ],
              rows: [
                for (final c in commissions)
                  {
                    'target': c.title,
                    'type': c.typeLabel,
                    'order': c.order ?? '—',
                    'amount': money(c.amount),
                    'status': c.status ?? 'PENDING',
                    'date': shortDateTime(c.createdAt),
                    '_commission': c,
                  },
              ],
              filterKey: 'status',
              filterLabel: 'Status',
              filterOptions: const ['AVAILABLE', 'PENDING', 'PAID'],
              onRowTap: (row) => _detail(context, row['_commission'] as AffiliateCommission),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chunk(BuildContext context, String label, String value, {bool big = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1, color: Theme.of(context).hintColor)),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: big ? 24 : 18,
            fontWeight: FontWeight.w900,
            fontFamily: 'Manrope',
            color: big ? MvColors.primaryDeep : null,
          ),
        ),
      ],
    );
  }

  Future<void> _detail(BuildContext context, AffiliateCommission c) {
    return showMvDetailModal(
      context,
      title: c.title,
      children: [
        StatusChip(c.status ?? 'PENDING'),
        const SizedBox(height: 16),
        _verifiedRows(context, [
          ('Type', c.typeLabel),
          ('Order', c.order ?? '—'),
          ('Referral link', c.linkCode ?? '—'),
          ('Commission', money(c.amount)),
          ('Rate', c.rate != null ? '${c.rate}%' : '—'),
          ('Order total', money(c.orderTotal)),
          ('Date', shortDateTime(c.createdAt)),
          ('Released', shortDateTime(c.releasedAt)),
        ]),
        if (c.notes != null && c.notes!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(c.notes!, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
          ),
      ],
    );
  }

  Widget _verifiedRows(BuildContext context, List<(String, String)> entries) {
    return Column(
      children: [
        for (final (k, v) in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(k, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor))),
                Text(v, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
      ],
    );
  }
}