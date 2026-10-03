import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils.dart';
import '../../../../widgets/charts.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/mv_icon.dart';
import '../../data/models/affiliate_earnings.dart';
import '../../data/models/affiliate_marketing.dart';
import '../../data/models/affiliate_profile.dart';
import '../providers/affiliate_providers.dart';
import '../widgets/affiliate_widgets.dart';

/// Affiliate landing page — port of `Mvec_frontend/src/pages/AffiliateDashboard.jsx`:
/// referral identity, live metrics, chart, wallet and top-performing links.
class AffiliateDashboardScreen extends ConsumerStatefulWidget {
  const AffiliateDashboardScreen({super.key});

  @override
  ConsumerState<AffiliateDashboardScreen> createState() =>
      _AffiliateDashboardScreenState();
}

class _AffiliateDashboardScreenState
    extends ConsumerState<AffiliateDashboardScreen> {
  String _range = '30d';
  String _series = 'conversions';

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(affiliateProfileProvider);
    final overviewAsync = ref.watch(affiliateOverviewProvider);
    final statsAsync = ref.watch(affiliateStatsProvider(_range));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHead(
          eyebrow: 'Affiliate',
          title: 'Dashboard',
          subtitle:
              profileAsync.valueOrNull?.display == null
                  ? 'Track your referrals and earnings'
                  : 'Welcome back, ${profileAsync.valueOrNull!.display}',
          actions: [
            GradientButton(
              label: 'Promote product',
              icon: 'plus',
              onPressed: () => context.go('/affiliate/products'),
            ),
          ],
        ),
        profileAsync.when(
          loading: () => const LoadingState(),
          error:
              (e, _) => ErrorState(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(affiliateProfileProvider),
              ),
          data: (profile) {
            if (!profile.isVerified) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ProfileVerificationBanner(profile: profile),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        _identityRow(profileAsync, overviewAsync),
        const SizedBox(height: 16),
        _metrics(overviewAsync),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final chart = _chartCard(statsAsync);
            final wallet = _walletCard(overviewAsync);
            if (constraints.maxWidth > 820) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: chart),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: wallet),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [chart, const SizedBox(height: 16), wallet],
            );
          },
        ),
        const SizedBox(height: 16),
        _topLinks(statsAsync),
      ],
    );
  }

  Widget _identityRow(
    AsyncValue<AffiliateProfile> profileAsync,
    AsyncValue<AffiliateOverview> overviewAsync,
  ) {
    final overview = overviewAsync.valueOrNull;
    return LayoutBuilder(
      builder: (context, c) {
        final twoCols = c.maxWidth > 640;
        final codeCard = profileAsync.when(
          loading:
              () => const Card(
                child: SizedBox(height: 120, child: LoadingState()),
              ),
          error:
              (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'Profile unavailable',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
          data: (p) => ReferralCodeCard(profile: p, onCopied: () {}),
        );
        final summary = Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PERFORMANCE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: MvColors.primaryDeep,
                  ),
                ),
                const SizedBox(height: 14),
                _statLine('Total clicks', '${overview?.clicks ?? 0}', 'arrow'),
                _statLine(
                  'Registrations',
                  '${overview?.registrations ?? 0}',
                  'user',
                ),
                _statLine(
                  'Conversions',
                  '${overview?.conversions ?? 0}',
                  'check',
                ),
                _statLine(
                  'Active links',
                  '${overview?.activeLinks ?? 0}',
                  'tag',
                ),
                Divider(color: Theme.of(context).dividerColor, height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _statLine(
                        'Commission',
                        money(overview?.wallet.totalEarned ?? 0),
                        'wallet',
                      ),
                    ),
                    Expanded(
                      child: _statLine(
                        'Revenue',
                        money(overview?.stats.revenue ?? 0),
                        'wallet',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        if (twoCols) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: codeCard),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: summary),
            ],
          );
        }
        return Column(
          children: [codeCard, const SizedBox(height: 12), summary],
        );
      },
    );
  }

  Widget _statLine(String label, String value, String icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          MvIcon(icon, size: 14, color: Theme.of(context).hintColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _metrics(AsyncValue<AffiliateOverview> overviewAsync) {
    final o = overviewAsync.valueOrNull;
    return LayoutBuilder(
      builder: (context, c) {
        final twoCols = c.maxWidth > 640;
        final oneCol = c.maxWidth <= 380;
        final items = <Widget>[
          MetricCard(
            label: 'Clicks',
            value: '${o?.clicks ?? 0}',
            icon: 'arrow',
          ),
          MetricCard(
            label: 'Registrations',
            value: '${o?.registrations ?? 0}',
            icon: 'user',
          ),
          MetricCard(
            label: 'Conversions',
            value: '${o?.conversions ?? 0}',
            icon: 'check',
          ),
          MetricCard(
            label: 'Commission',
            value: money(o?.wallet.totalEarned ?? 0),
            icon: 'wallet',
          ),
        ];
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final it in items)
              SizedBox(
                width:
                    twoCols
                        ? (c.maxWidth - 36) / 4
                        : oneCol
                        ? c.maxWidth
                        : (c.maxWidth - 12) / 2,
                child: it,
              ),
          ],
        );
      },
    );
  }

  Widget _chartCard(AsyncValue<AffiliateStats> statsAsync) {
    return statsAsync.when(
      loading:
          () => const Card(child: SizedBox(height: 320, child: LoadingState())),
      error:
          (e, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: ErrorState(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(affiliateStatsProvider(_range)),
              ),
            ),
          ),
      data:
          (s) => DataCard(
            title: 'Referral performance',
            subtitle:
                'You earn on every referral that registers and purchases.',
            trailing: PeriodTabs(
              value: _range,
              onChanged: (r) => setState(() => _range = r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _seriesToggle(),
                const SizedBox(height: 14),
                FakeBarChart(
                  values: _seriesValues(s),
                  labels: s.labels,
                  height: 220,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    InlineStat(
                      label: 'Conversion rate',
                      value: '${s.conversionRate.toStringAsFixed(1)}%',
                    ),
                    InlineStat(
                      label: 'Avg commission',
                      value: money(s.averageCommission),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _seriesToggle() {
    const options = [
      ('clicks', 'Clicks'),
      ('registrations', 'Registrations'),
      ('conversions', 'Conversions'),
    ];
    return Wrap(
      spacing: 8,
      children: [
        for (final (key, label) in options)
          InkWell(
            onTap: () => setState(() => _series = key),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    _series == key ? MvColors.metricIconBg : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color:
                      _series == key
                          ? MvColors.primaryDeep
                          : (Theme.of(context).brightness == Brightness.dark
                              ? MvColors.darkMuted
                              : MvColors.muted),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<num> _seriesValues(AffiliateStats s) {
    switch (_series) {
      case 'clicks':
        return s.clicksSeries;
      case 'registrations':
        return s.registrationsSeries;
      default:
        return s.conversionsSeries;
    }
  }

  Widget _walletCard(AsyncValue<AffiliateOverview> overviewAsync) {
    final o = overviewAsync.valueOrNull;
    final wallet = o?.wallet;
    return DataCard(
      title: 'Wallet',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVAILABLE BALANCE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            money(wallet?.availableBalance ?? 0),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontFamily: 'Manrope',
              color: MvColors.primaryDeep,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            wallet?.canWithdraw ?? false
                ? 'You can request a withdrawal'
                : 'You need ${money(wallet?.shortfall ?? 10000)} more to withdraw',
            style: TextStyle(
              fontSize: 11,
              color:
                  wallet?.canWithdraw ?? false
                      ? MvColors.successText
                      : Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 18),
          _walletRow('Total earned', money(wallet?.totalEarned ?? 0)),
          _walletRow('Pending', money(wallet?.pendingBalance ?? 0)),
          _walletRow('Withdrawn', money(wallet?.totalWithdrawn ?? 0)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: 'Withdraw',
                  icon: 'wallet',
                  onPressed: () => context.go('/affiliate/payouts'),
                  expanded: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlineMvButton(
                  label: 'Earnings',
                  icon: 'wallet',
                  onPressed: () => context.go('/affiliate/earnings'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _walletRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _topLinks(AsyncValue<AffiliateStats> statsAsync) {
    final links = statsAsync.valueOrNull?.topLinks ?? const <AffiliateLink>[];
    return DataCard(
      title: 'Top-performing links',
      subtitle: 'Your best referral traffic, ranked by commission earned.',
      trailing: TextButton(
        onPressed: () => context.go('/affiliate/links'),
        child: const Text('View all'),
      ),
      child:
          links.isEmpty
              ? const EmptyState(message: 'No links yet')
              : Column(
                children: [
                  for (final l in links)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: MvColors.metricIconBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: MvIcon(
                                'tag',
                                size: 15,
                                color: MvColors.primaryDeep,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.target,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${l.conversions} conversions · ${l.clicks} clicks',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            money(l.commission),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: MvColors.primaryDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
    );
  }
}

/// Verified-box port for the dashboard, with a link to profile verification.
class ProfileVerificationBanner extends StatelessWidget {
  const ProfileVerificationBanner({super.key, required this.profile});
  final AffiliateProfile profile;

  @override
  Widget build(BuildContext context) {
    final pending =
        profile.verificationStatus == 'PENDING' ||
        profile.verificationStatus == 'UNDER_REVIEW';
    final rejected = profile.verificationStatus == 'REJECTED';
    return VerifiedBox(
      pending
          ? 'Verification in progress'
          : rejected
          ? 'Verification needs attention'
          : 'Verify your account to unlock payouts',
      pending
          ? 'Your documents are being reviewed. You can keep sharing links in the meantime.'
          : rejected
          ? (profile.verificationNote ??
              'Your verification was not approved. Update your documents and resubmit.')
          : 'Verified affiliates can request withdrawals and access higher commission tiers. Complete your identity verification to get started.',
      icon: 'shield',
    );
  }
}
