import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

const _mockSignals = <Map<String, dynamic>>[
  {'id': 'R1', 'signal': 'Repeat purchase probability', 'source': 'Purchase history', 'weight': 92, 'enabled': true, 'updated': '21 Sep 2026'},
  {'id': 'R2', 'signal': 'Category affinity', 'source': 'Browse sessions', 'weight': 88, 'enabled': true, 'updated': '21 Sep 2026'},
  {'id': 'R3', 'signal': 'Price sensitivity', 'source': 'Cart analytics', 'weight': 81, 'enabled': true, 'updated': '20 Sep 2026'},
  {'id': 'R4', 'signal': 'Cross-sell opportunity', 'source': 'Order pairs', 'weight': 74, 'enabled': true, 'updated': '20 Sep 2026'},
  {'id': 'R5', 'signal': 'Regional demand', 'source': 'Geo signals', 'weight': 67, 'enabled': true, 'updated': '19 Sep 2026'},
  {'id': 'R6', 'signal': 'Seasonal uplift', 'source': 'Calendar events', 'weight': 60, 'enabled': true, 'updated': '19 Sep 2026'},
  {'id': 'R7', 'signal': 'Similar vendor ranking', 'source': 'Vendor graph', 'weight': 53, 'enabled': true, 'updated': '18 Sep 2026'},
  {'id': 'R8', 'signal': 'Review sentiment boost', 'source': 'Review NLP', 'weight': 47, 'enabled': true, 'updated': '18 Sep 2026'},
];

final _signalsProvider = StateProvider<List<Map<String, dynamic>>>((ref) => _mockSignals);

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  Widget _toggleChip(WidgetRef ref, Map<String, dynamic> signal) {
    final enabled = signal['enabled'] == true;
    final fg = enabled ? MvColors.successText : MvColors.neutralText;
    return InkWell(
      onTap: () {
        ref.read(_signalsProvider.notifier).state = [
          for (final s in ref.read(_signalsProvider))
            if (s['id'] == signal['id']) {...s, 'enabled': s['enabled'] != true} else s,
        ];
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: enabled ? MvColors.successBg : MvColors.neutralBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: fg.withValues(alpha: .35)),
        ),
        child: Text(
          enabled ? 'Enabled' : 'Disabled',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: fg),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signals = ref.watch(_signalsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN · INTELLIGENCE',
          title: 'Recommendations',
          subtitle: 'Signals powering personalised recommendations.',
        ),
        DataCard(
          child: InfoBox('These signals drive personalized product recommendations across the marketplace. Toggle a signal to enable or disable it.'),
        ),
        const SizedBox(height: 14),
        SmartTable(
          columns: const [
            MvColumn('Signal', 'Signal', bold: true),
            MvColumn('Source', 'Source'),
            MvColumn('Weight', 'Weight'),
            MvColumn('Enabled', 'Enabled'),
            MvColumn('Last updated', 'Last updated'),
          ],
          rows: [
            for (final s in signals)
              {
                'Signal': s['signal']?.toString() ?? '—',
                'Source': s['source']?.toString() ?? '—',
                'Weight': '${s['weight']}%',
                'Enabled': StatusChip(s['enabled'] == true ? 'ENABLED' : 'DISABLED', overrideColor: s['enabled'] == true ? MvColors.successText : MvColors.neutralText),
                'Last updated': s['updated']?.toString() ?? '—',
                '_s': s,
              },
          ],
          actionsLabel: 'Status',
          pageSize: 8,
          rowActions: (row) => _toggleChip(ref, row['_s'] as Map<String, dynamic>),
        ),
      ],
    );
  }
}