import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  Future<void> _showDetail(BuildContext context, ReviewRecord r) async {
    await showMvDetailModal(
      context,
      title: 'REVIEW MODERATION',
      children: [
        KeyValueGrid(entries: [
          MapEntry('Product', r.product ?? '—'),
          MapEntry('Author', r.author ?? '—'),
          MapEntry('Rating', r.rating == null ? '—' : '★ $r.rating'),
          MapEntry('Status', r.status ?? '—'),
          MapEntry('Date', shortDate(r.createdAt)),
        ]),
        const SizedBox(height: 16),
        Text((r.comment ?? '').isEmpty ? 'No comment provided.' : r.comment!, style: const TextStyle(fontSize: 13, height: 1.5)),
      ],
      footer: Row(
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: OutlineMvButton(
                label: 'Remove',
                icon: 'trash',
                onPressed: () {
                  Navigator.pop(context);
                  showMvSnack(context, 'Review removed', success: false);
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GradientButton(
              label: 'Approve',
              icon: 'check',
              expanded: true,
              onPressed: () {
                Navigator.pop(context);
                showMvSnack(context, 'Review approved', success: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN · QUALITY',
          title: 'Product Reviews',
          subtitle: 'Moderate product reviews across the marketplace.',
        ),
        reviewsAsync.when(
          data: (reviews) {
            final filterOptions = <String>{
              for (final r in reviews)
                if ((r.status ?? '').isNotEmpty) r.status!.toUpperCase(),
            }.toList()
              ..sort();
            return SmartTable(
              columns: const [
                MvColumn('Review', 'Review', bold: true),
                MvColumn('Product', 'Product'),
                MvColumn('Author', 'Author'),
                MvColumn('Rating', 'Rating'),
                MvColumn('Status', 'Status'),
              ],
              rows: [
                for (final r in reviews)
                  {
                    'Review': r.comment ?? '—',
                    'Product': r.product ?? '—',
                    'Author': r.author ?? '—',
                    'Rating': r.rating == null ? '—' : '★ $r.rating',
                    'Status': StatusChip(r.status),
                    '_r': r,
                  },
              ],
              actionsLabel: 'Moderate',
              pageSize: 8,
              filterKey: 'status',
              filterLabel: 'Status',
              filterOptions: filterOptions,
              rowActions: (row) => TableActionBtn(
                icon: 'eye',
                tooltip: 'Moderate review',
                onPressed: () => _showDetail(context, row['_r'] as ReviewRecord),
              ),
            );
          },
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(reviewsProvider)),
          loading: () => const LoadingState(),
        ),
      ],
    );
  }
}