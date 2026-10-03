import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils.dart';
import '../../../../widgets/common.dart';
import '../../data/models/affiliate_marketing.dart';
import '../providers/affiliate_providers.dart';

/// Affiliate inbox: commission, payout, campaign and verification alerts.
/// Tapping an item marks it read; "Mark all read" clears the badge.
class AffiliateNotificationsScreen extends ConsumerStatefulWidget {
  const AffiliateNotificationsScreen({super.key});

  @override
  ConsumerState<AffiliateNotificationsScreen> createState() => _AffiliateNotificationsScreenState();
}

class _AffiliateNotificationsScreenState extends ConsumerState<AffiliateNotificationsScreen> {
  String? _busyId;

  Future<void> _markRead(AffiliateNotification n) async {
    if (n.isRead) return;
    setState(() => _busyId = n.id);
    try {
      await ref.read(affiliateServiceProvider).markNotificationsRead(n.id);
      if (!mounted) return;
      ref.invalidate(affiliateNotificationsProvider);
    } catch (e) {
      if (!mounted) return;
      showMvSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _markAll(List<AffiliateNotification> all) async {
    final anyUnread = all.any((n) => !n.isRead);
    if (!anyUnread) {
      showMvSnack(context, 'You are all caught up', success: true);
      return;
    }
    try {
      await ref.read(affiliateServiceProvider).markNotificationsRead();
      if (!mounted) return;
      ref.invalidate(affiliateNotificationsProvider);
      showMvSnack(context, 'All notifications read', success: true);
    } catch (e) {
      if (!mounted) return;
      showMvSnack(context, friendlyError(e));
    }
  }

  IconData _icon(String? type) {
    switch (type) {
      case 'COMMISSION':
        return Icons.paid_outlined;
      case 'PAYOUT':
        return Icons.account_balance_wallet_outlined;
      case 'CAMPAIGN':
        return Icons.campaign_outlined;
      case 'VERIFICATION':
        return Icons.verified_user_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(affiliateNotificationsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHead(
          eyebrow: 'Account',
          title: 'Notifications',
          subtitle: 'Updates about your commissions, payouts and campaigns.',
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                final all = ref.read(affiliateNotificationsProvider).valueOrNull ?? const <AffiliateNotification>[];
                _markAll(all);
              },
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('Mark all read'),
            ),
          ],
        ),
        async.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(affiliateNotificationsProvider)),
          data: (items) {
            final sorted = [...items]..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
            if (sorted.isEmpty) {
              return const DataCard(child: EmptyState(message: 'No notifications yet'));
            }
            return DataCard(
              child: Column(
                children: [
                  for (final n in sorted)
                    _item(n),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _item(AffiliateNotification n) {
    final busy = _busyId == n.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = n.isRead ? (isDark ? MvColors.darkMuted : MvColors.muted) : (isDark ? MvColors.darkText : MvColors.ink);
    return InkWell(
      onTap: busy ? null : () => _markRead(n),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .6)))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: n.isRead ? (isDark ? MvColors.darkSurface2 : MvColors.surface2) : MvColors.metricIconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(_icon(n.type), size: 18, color: n.isRead ? (isDark ? MvColors.darkMuted : MvColors.muted) : MvColors.primaryDeep),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          n.title ?? 'Update',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg),
                        ),
                      ),
                      if (n.amount != null) Text(money(n.amount), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: MvColors.primaryDeep)),
                    ],
                  ),
                  if (n.message != null && n.message!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(n.message!, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, height: 1.4, color: isDark ? MvColors.darkMuted : MvColors.muted)),
                  ],
                  const SizedBox(height: 4),
                  Text(shortDateTime(n.createdAt), style: TextStyle(fontSize: 10.5, color: Theme.of(context).hintColor)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!n.isRead) Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6), decoration: const BoxDecoration(color: MvColors.badgeRed, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}