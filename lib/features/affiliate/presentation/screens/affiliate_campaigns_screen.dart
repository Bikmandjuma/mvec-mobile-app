import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/mv_icon.dart';
import '../../data/models/affiliate_marketing.dart';
import '../providers/affiliate_providers.dart';
import '../widgets/affiliate_widgets.dart';

/// Campaign listing: join promotional campaigns and share their products to
/// earn the campaign commission rate. Ports the frontend campaigns screen.
class AffiliateCampaignsScreen extends ConsumerStatefulWidget {
  const AffiliateCampaignsScreen({super.key});

  @override
  ConsumerState<AffiliateCampaignsScreen> createState() => _AffiliateCampaignsScreenState();
}

class _AffiliateCampaignsScreenState extends ConsumerState<AffiliateCampaignsScreen> {
  String? _joiningId;

  Future<void> _join(AffiliateCampaign c) async {
    setState(() => _joiningId = c.id);
    try {
      await ref.read(affiliateServiceProvider).joinCampaign(c.id ?? '');
      if (!mounted) return;
      showMvSnack(context, 'Joined ${c.name}', success: true);
      ref.invalidate(affiliateCampaignsProvider);
      ref.invalidate(affiliateLinksProvider);
      ref.invalidate(affiliateOverviewProvider);
    } catch (e) {
      if (!mounted) return;
      showMvSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _joiningId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(affiliateCampaignsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHead(eyebrow: 'Promotion', title: 'Campaigns', subtitle: 'Join active campaigns to promote curated products at boosted rates.'),
        async.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(affiliateCampaignsProvider)),
          data: (campaigns) {
            if (campaigns.isEmpty) {
              return const DataCard(child: EmptyState(message: 'No open campaigns right now'));
            }
            return Column(
              children: [
                for (final c in campaigns)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _campaignCard(c),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _campaignCard(AffiliateCampaign c) {
    final joining = _joiningId == c.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: MvColors.metricIconBg, borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: c.banner == null
                        ? const MvIcon('tag', size: 20, color: MvColors.primaryDeep)
                        : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(c.banner!, width: 46, height: 46, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const MvIcon('tag', size: 20, color: MvColors.primaryDeep))),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(c.name ?? 'Campaign', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                          if (c.isLive)
                            StatusChip(c.status ?? 'ACTIVE', overrideColor: MvColors.successText)
                          else
                            StatusChip('ENDED', overrideColor: MvColors.errorText),
                        ],
                      ),
                      if (c.description != null && c.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(c.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor, height: 1.45)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                InlineStat(label: 'Commission', value: '${c.commissionRate ?? 8}%'),
                InlineStat(label: 'Products', value: '${c.productCount}'),
                InlineStat(label: 'Conversions', value: '${c.conversions}'),
                InlineStat(label: 'Earnings', value: money(c.earnings)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.joined
                        ? 'Active in this campaign'
                        : '${c.daysLeft > 0 ? '${c.daysLeft} days left — ' : ''}${_period(c)}',
                    style: TextStyle(fontSize: 11.5, color: isDark ? MvColors.darkMuted : MvColors.muted),
                  ),
                ),
                const SizedBox(width: 12),
                if (c.joined)
                  OutlineMvButton(label: 'Promote', icon: 'plus', onPressed: () => context.go('/affiliate/products'))
                else
                  GradientButton(
                    label: joining ? 'Joining…' : 'Join campaign',
                    icon: 'plus',
                    onPressed: joining ? null : () => _join(c),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _period(AffiliateCampaign c) {
    final s = c.startsAt;
    final e = c.endsAt;
    if (s == null && e == null) return 'Rolling campaign';
    if (s == null) return 'Ends ${shortDate(e)}';
    if (e == null) return 'Starts ${shortDate(s)}';
    return '${shortDate(s)} – ${shortDate(e)}';
  }
}