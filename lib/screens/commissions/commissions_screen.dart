import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class CommissionsScreen extends ConsumerWidget {
  const CommissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commissionsAsync = ref.watch(commissionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Commissions',
          subtitle: 'Platform commission records.',
        ),
        commissionsAsync.when(
          data: (rules) => SmartTable(
            columns: const [
              MvColumn('Commission', 'Commission', bold: true),
              MvColumn('Type', 'Type'),
              MvColumn('Target', 'Target'),
              MvColumn('Rate', 'Rate'),
              MvColumn('Status', 'Status'),
            ],
            rows: [
              for (final r in rules)
                {
                  'Commission': r.name ?? '—',
                  'Type': r.ruleType ?? '—',
                  'Target': r.target ?? '—',
                  'Rate': r.rateLabel,
                  'Status': r.active == true ? 'ACTIVE' : 'INACTIVE',
                },
            ],
            pageSize: 8,
          ),
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(commissionsProvider)),
          loading: () => const LoadingState(),
        ),
      ],
    );
  }
}