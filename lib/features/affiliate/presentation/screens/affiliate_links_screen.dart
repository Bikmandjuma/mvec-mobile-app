import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/mv_icon.dart';
import '../../data/models/affiliate_marketing.dart';
import '../../data/models/affiliate_profile.dart';
import '../providers/affiliate_providers.dart';
import '../widgets/affiliate_widgets.dart';

/// Every referral link the affiliate owns, with per-link performance, an
/// active toggle and a delete action. Mirrors `My Links` on the web console.
class AffiliateLinksScreen extends ConsumerStatefulWidget {
  const AffiliateLinksScreen({super.key});

  @override
  ConsumerState<AffiliateLinksScreen> createState() => _AffiliateLinksScreenState();
}

class _AffiliateLinksScreenState extends ConsumerState<AffiliateLinksScreen> {
  String? _busyId;

  Future<void> _toggle(AffiliateLink l, bool active) async {
    setState(() => _busyId = l.id);
    try {
      await ref.read(affiliateServiceProvider).setLinkActive(l.id ?? '', active);
      if (!mounted) return;
      ref.invalidate(affiliateLinksProvider);
      showMvSnack(context, active ? 'Link activated' : 'Link paused', success: true);
    } catch (e) {
      if (!mounted) return;
      showMvSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _delete(AffiliateLink l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete link?'),
        content: Text('This removes the link "${l.target}" and stops tracking.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: MvColors.errorText))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busyId = l.id);
    try {
      await ref.read(affiliateServiceProvider).deleteLink(l.id ?? '');
      if (!mounted) return;
      ref.invalidate(affiliateLinksProvider);
      showMvSnack(context, 'Link deleted', success: true);
    } catch (e) {
      if (!mounted) return;
      showMvSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _createGeneral() async {
    try {
      final link = await ref.read(affiliateServiceProvider).generateLink(label: 'General promotion');
      if (!mounted) return;
      ref.invalidate(affiliateLinksProvider);
      showMvSnack(context, 'Link created', success: true);
      await showMvDetailModal(
        context,
        title: 'General referral link',
        children: [
          VerifiedBox('Ready to share', 'This link routes people to the storefront with your referral code.'),
          const SizedBox(height: 16),
          ReferralCodeCard(profile: AffiliateProfile(referralCode: link.code)),
        ],
      );
    } catch (e) {
      if (!mounted) return;
      showMvSnack(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(affiliateLinksProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHead(
          eyebrow: 'Promotion',
          title: 'My Links',
          subtitle: 'Manage your referral links and track performance.',
          actions: [
            GradientButton(label: 'General link', icon: 'plus', onPressed: _createGeneral),
          ],
        ),
        async.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(affiliateLinksProvider)),
          data: (links) {
            if (links.isEmpty) {
              return const DataCard(child: EmptyState(message: 'You have no links yet — create your first one'));
            }
            return Column(
              children: [
                for (final l in links)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _linkCard(l),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _linkCard(AffiliateLink l) {
    final busy = _busyId == l.id;
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: MvColors.metricIconBg, borderRadius: BorderRadius.circular(9)),
                  child: Center(child: MvIcon('tag', size: 18, color: l.isActive ? MvColors.primaryDeep : Theme.of(context).hintColor)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.target, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(l.label ?? l.code ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: isDark ? MvColors.darkMuted : MvColors.muted)),
                    ],
                  ),
                ),
                Switch(
                  value: l.isActive,
                  onChanged: busy ? null : (v) => _toggle(l, v),
                  activeTrackColor: MvColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => copyToClipboard(context, l.shareUrl),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: isDark ? MvColors.darkSurface2 : MvColors.surface2, borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    MvIcon('copy', size: 13, color: isDark ? MvColors.darkMuted : MvColors.muted),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l.shareUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: isDark ? MvColors.darkMuted : MvColors.muted))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                InlineStat(label: 'Clicks', value: '${l.clicks}'),
                InlineStat(label: 'Registrations', value: '${l.registrations}'),
                InlineStat(label: 'Conversions', value: '${l.conversions}'),
                InlineStat(label: 'Commission', value: money(l.commission)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Created ${shortDate(l.createdAt)}${l.lastClickedAt != null ? ' · last click ${shortDate(l.lastClickedAt)}' : ''}',
                    style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
                  ),
                ),
                IconButton(
                  onPressed: busy ? null : () => _delete(l),
                  tooltip: 'Delete link',
                  icon: MvIcon('trash', size: 18, color: MvColors.dangerIcon),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}