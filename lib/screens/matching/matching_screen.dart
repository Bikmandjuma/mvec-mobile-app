import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

const _mockMatches = <Map<String, dynamic>>[
  {'supplier': 'Rwanda Fresh', 'category': 'Produce', 'score': 94, 'price': 185000, 'stock': 240, 'reliability': 96, 'distance': '5 km', 'status': 'MATCHED'},
  {'supplier': 'KigaliTech Hub', 'category': 'Electronics', 'score': 91, 'price': 540000, 'stock': 120, 'reliability': 93, 'distance': '8 km', 'status': 'MATCHED'},
  {'supplier': 'Artisan Link', 'category': 'Handcrafts', 'score': 87, 'price': 96000, 'stock': 310, 'reliability': 88, 'distance': '12 km', 'status': 'MATCHED'},
  {'supplier': 'Gasabo Traders', 'category': 'General', 'score': 83, 'price': 120000, 'stock': 540, 'reliability': 85, 'distance': '3 km', 'status': 'PENDING'},
  {'supplier': 'Mountain Coffee', 'category': 'Beverages', 'score': 80, 'price': 74000, 'stock': 90, 'reliability': 91, 'distance': '22 km', 'status': 'MATCHED'},
  {'supplier': 'Nyanza Textiles', 'category': 'Fashion', 'score': 76, 'price': 210000, 'stock': 65, 'reliability': 79, 'distance': '35 km', 'status': 'PENDING'},
  {'supplier': 'FastMove Logistics', 'category': 'Delivery', 'score': 72, 'price': 45000, 'stock': 0, 'reliability': 83, 'distance': '1 km', 'status': 'PENDING'},
  {'supplier': 'LakeSide Goods', 'category': 'Household', 'score': 68, 'price': 88000, 'stock': 175, 'reliability': 74, 'distance': '15 km', 'status': 'PENDING'},
];

class MatchingScreen extends ConsumerWidget {
  const MatchingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN · INTELLIGENCE',
          title: 'Supplier Matching',
          subtitle: 'AI-ranked supplier matches for marketplace orders.',
        ),
        SmartTable(
          columns: const [
            MvColumn('Supplier', 'Supplier', bold: true),
            MvColumn('Category', 'Category'),
            MvColumn('Score', 'Score'),
            MvColumn('Price', 'Price'),
            MvColumn('Stock', 'Stock'),
            MvColumn('Reliability', 'Reliability'),
            MvColumn('Distance', 'Distance'),
            MvColumn('Status', 'Status'),
          ],
          rows: [
            for (final m in _mockMatches)
              {
                'Supplier': m['supplier'],
                'Category': m['category'],
                'Score': '${m['score']}%',
                'Price': money(m['price'] as num?),
                'Stock': '${m['stock']}',
                'Reliability': '${m['reliability']}%',
                'Distance': m['distance'],
                'Status': StatusChip(
                  m['status'],
                  overrideColor: m['status'].toString().toUpperCase() == 'MATCHED' ? MvColors.successText : MvColors.warningText,
                ),
              },
          ],
          actionsLabel: 'Refresh',
          pageSize: 8,
          rowActions: (_) => TableActionBtn(
            icon: 'arrow',
            tooltip: 'Refresh match',
            onPressed: () => showMvSnack(context, 'Match score refreshed', success: true),
          ),
        ),
      ],
    );
  }
}