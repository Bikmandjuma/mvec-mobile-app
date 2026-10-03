import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils.dart';
import '../../../../widgets/charts.dart';
import '../../../../widgets/common.dart';
import '../../data/models/affiliate_earnings.dart';
import '../providers/affiliate_providers.dart';
import '../widgets/affiliate_widgets.dart';

/// Full referral analytics: period picker, metric grid, per-series chart and
/// the best-performing links table. Port of the web dashboard statistics.
class AffiliateStatsScreen extends ConsumerStatefulWidget {
  const AffiliateStatsScreen({super.key});

  @override
  ConsumerState<AffiliateStatsScreen> createState() => _AffiliateStatsScreenState();
}

class _AffiliateStatsScreenState extends ConsumerState<AffiliateStatsScreen> {
  String _range = '30d';
  String _series = 'conversions';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(affiliateStatsProvider(_range));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHead(
          eyebrow: 'Performance',
          title: 'Statistics',
          subtitle: 'How your referral traffic converts to customers and revenue.',
          actions: [PeriodTabs(value: _range, onChanged: (r) => setState(() => _range = r))],
        ),
        async.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(affiliateStatsProvider(_range))),
          data: (s) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _metrics(s),
              const SizedBox(height: 16),
              DataCard(
                title: 'Referral trend',
                subtitle: 'Conversion activity across the selected period.',
                trailing: _seriesToggle(),
                child: FakeBarChart(values: _values(s), labels: s.labels, height: 250),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, c) {
                  final rates = Row(
                    children: [
                      Expanded(child: InlineStat(label: 'Conversion rate', value: '${s.conversionRate.toStringAsFixed(1)}%')),
                      const SizedBox(width: 12),
                      Expanded(child: InlineStat(label: 'Registration rate', value: '${s.registrationRate.toStringAsFixed(1)}%')),
                    ],
                  );
                  final avg = Row(
                    children: [
                      Expanded(child: InlineStat(label: 'Revenue', value: money(s.revenue))),
                      const SizedBox(width: 12),
                      Expanded(child: InlineStat(label: 'Avg commission', value: money(s.averageCommission))),
                    ],
                  );
                  if (c.maxWidth > 720) {
                    return Row(
                      children: [
                        Expanded(child: rates),
                        const SizedBox(width: 16),
                        Expanded(child: avg),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [rates, const SizedBox(height: 16), avg],
                  );
                },
              ),
              const SizedBox(height: 16),
              _topLinks(s),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metrics(AffiliateStats s) {
    return LayoutBuilder(
      builder: (context, c) {
        final twoCols = c.maxWidth > 640;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final m in <MetricCard>[
              MetricCard(label: 'Clicks', value: '${s.clicks}', icon: 'arrow'),
              MetricCard(label: 'Registrations', value: '${s.registrations}', icon: 'user'),
              MetricCard(label: 'Conversions', value: '${s.conversions}', icon: 'check'),
              MetricCard(label: 'Commission', value: money(s.commission), icon: 'wallet'),
            ])
              SizedBox(width: twoCols ? (c.maxWidth - 36) / 4 : (c.maxWidth - 12) / 2, child: m),
          ],
        );
      },
    );
  }

  Widget _seriesToggle() {
    const options = <(String, String)>[('clicks', 'Clicks'), ('registrations', 'Registrations'), ('conversions', 'Conversions')];
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
                color: _series == key ? MvColors.metricIconBg : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _series == key ? MvColors.primaryDeep : (Theme.of(context).brightness == Brightness.dark ? MvColors.darkMuted : MvColors.muted),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<num> _values(AffiliateStats s) {
    switch (_series) {
      case 'clicks':
        return s.clicksSeries;
      case 'registrations':
        return s.registrationsSeries;
      default:
        return s.conversionsSeries;
    }
  }

  Widget _topLinks(AffiliateStats s) {
    return DataCard(
      title: 'Top links',
      subtitle: 'Ranked by commission earned in this period.',
      child: s.topLinks.isEmpty
          ? const EmptyState(message: 'No links yet')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final l in s.topLinks)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.target, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                              Text('${l.clicks} clicks · ${l.conversions} conversions', style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
                            ],
                          ),
                        ),
                        Text(money(l.commission), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: MvColors.primaryDeep)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}