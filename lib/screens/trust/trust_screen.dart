import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

const _mockTrust = <Map<String, dynamic>>[
  {'party': 'Rwanda Fresh', 'type': 'Vendor', 'score': 91, 'completion': 98, 'refundRate': 2, 'disputeRate': 1, 'rating': 4.8, 'trend': 'POSITIVE'},
  {'party': 'KigaliTech Hub', 'type': 'Vendor', 'score': 86, 'completion': 94, 'refundRate': 5, 'disputeRate': 3, 'rating': 4.5, 'trend': 'POSITIVE'},
  {'party': 'Artisan Link', 'type': 'Vendor', 'score': 84, 'completion': 96, 'refundRate': 6, 'disputeRate': 2, 'rating': 4.6, 'trend': 'POSITIVE'},
  {'party': 'Gasabo Traders', 'type': 'Vendor', 'score': 71, 'completion': 88, 'refundRate': 11, 'disputeRate': 7, 'rating': 3.9, 'trend': 'NEGATIVE'},
  {'party': 'Mountain Coffee', 'type': 'Vendor', 'score': 88, 'completion': 97, 'refundRate': 3, 'disputeRate': 2, 'rating': 4.7, 'trend': 'POSITIVE'},
  {'party': 'Nyanza Textiles', 'type': 'Vendor', 'score': 68, 'completion': 85, 'refundRate': 14, 'disputeRate': 9, 'rating': 3.7, 'trend': 'NEGATIVE'},
  {'party': 'Jean Bosco', 'type': 'Buyer', 'score': 79, 'completion': 92, 'refundRate': 8, 'disputeRate': 4, 'rating': 4.2, 'trend': 'POSITIVE'},
  {'party': 'Aline U.', 'type': 'Buyer', 'score': 63, 'completion': 78, 'refundRate': 19, 'disputeRate': 12, 'rating': 3.5, 'trend': 'NEGATIVE'},
];

class TrustScreen extends ConsumerWidget {
  const TrustScreen({super.key});

  Future<void> _showDetail(BuildContext context, Map<String, dynamic> t) async {
    await showMvDetailModal(
      context,
      title: 'TRUST PROFILE',
      children: [
        KeyValueGrid(entries: [
          MapEntry('Party', t['party'].toString()),
          MapEntry('Type', t['type'].toString()),
          MapEntry('Trust score', '${t['score']}/100'),
          MapEntry('Order completion', '${t['completion']}%'),
          MapEntry('Refund rate', '${t['refundRate']}%'),
          MapEntry('Dispute rate', '${t['disputeRate']}%'),
          MapEntry('Rating', '★ ${t['rating']}'),
          MapEntry('Trend', t['trend'].toString()),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN · INTELLIGENCE',
          title: 'Trust Scores',
          subtitle: 'Trustworthiness metrics for marketplace parties.',
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: MetricCard(label: 'Avg trust score', value: '87', icon: 'shield')),
            const SizedBox(width: 12),
            Expanded(child: MetricCard(label: 'Low trust', value: '12', icon: 'users')),
            const SizedBox(width: 12),
            Expanded(child: MetricCard(label: 'High risk', value: '4', icon: 'bell')),
          ],
        ),
        const SizedBox(height: 14),
        SmartTable(
          columns: const [
            MvColumn('Party', 'Party', bold: true),
            MvColumn('Type', 'Type'),
            MvColumn('Score', 'Score'),
            MvColumn('Completion', 'Completion'),
            MvColumn('Refund rate', 'Refund rate'),
            MvColumn('Dispute rate', 'Dispute rate'),
            MvColumn('Rating', 'Rating'),
            MvColumn('Trend', 'Trend'),
          ],
          rows: [
            for (final t in _mockTrust)
              {
                'Party': t['party'],
                'Type': t['type'],
                'Score': '${t['score']}',
                'Completion': '${t['completion']}%',
                'Refund rate': '${t['refundRate']}%',
                'Dispute rate': '${t['disputeRate']}%',
                'Rating': '★ ${t['rating']}',
                'Trend': StatusChip(
                  t['trend'],
                  overrideColor: t['trend'].toString().toUpperCase() == 'POSITIVE' ? MvColors.successText : MvColors.errorText,
                ),
                '_t': t,
              },
          ],
          actionsLabel: 'Details',
          pageSize: 8,
          rowActions: (row) => TableActionBtn(
            icon: 'eye',
            tooltip: 'View profile',
            onPressed: () => _showDetail(context, row['_t'] as Map<String, dynamic>),
          ),
        ),
      ],
    );
  }
}