import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Audit Logs',
          subtitle: 'Platform security audit trail.',
          actions: [
            OutlineMvButton(
              label: 'Download report',
              icon: 'arrow',
              onPressed: () => showMvSnack(context, 'Audit log export queued.', success: true),
            ),
          ],
        ),
        SmartTable(
          columns: const [
            MvColumn('id', 'ID'),
            MvColumn('actor', 'Actor', flex: 2),
            MvColumn('action', 'Action', flex: 2),
            MvColumn('entity', 'Entity', flex: 2),
            MvColumn('date', 'Date'),
          ],
          rows: _mockLogs(),
          pageSize: 8,
          actionsLabel: 'Category',
          rowActions: (row) => StatusChip(row['category']?.toString()),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _mockLogs() {
    return [
      {'id': 'VND-0002', 'actor': 'admin@mvec.rw', 'action': 'Verify', 'entity': 'Vendor VND-0002', 'category': 'VERIFICATION', 'date': shortDate(DateTime(2026, 9, 20))},
      {'id': 'USR-012', 'actor': 'admin@mvec.rw', 'action': 'Block', 'entity': 'User USR-012', 'category': 'ACCOUNT', 'date': shortDate(DateTime(2026, 9, 20))},
      {'id': 'ORD-0098', 'actor': 'finance@mvec.rw', 'action': 'Refund', 'entity': 'Order ORD-0098', 'category': 'PAYMENT', 'date': shortDate(DateTime(2026, 9, 19))},
      {'id': 'ADM-0003', 'actor': 'admin@mvec.rw', 'action': 'Update', 'entity': 'Commission rule', 'category': 'SETTINGS', 'date': shortDate(DateTime(2026, 9, 18))},
      {'id': 'SUP-0007', 'actor': 'admin@mvec.rw', 'action': 'Approve', 'entity': 'Supplier SUP-0007', 'category': 'VERIFICATION', 'date': shortDate(DateTime(2026, 9, 18))},
      {'id': 'PRD-0111', 'actor': 'vendor@shop.rw', 'action': 'Publish', 'entity': 'Product PRD-0111', 'category': 'CATALOG', 'date': shortDate(DateTime(2026, 9, 17))},
      {'id': 'USR-088', 'actor': 'support@mvec.rw', 'action': 'Resolve', 'entity': 'Support case SPT-009', 'category': 'SUPPORT', 'date': shortDate(DateTime(2026, 9, 17))},
      {'id': 'SYS-001', 'actor': 'ops@mvec.rw', 'action': 'Deploy', 'entity': 'Platform release v2.4', 'category': 'SYSTEM', 'date': shortDate(DateTime(2026, 9, 16))},
      {'id': 'PAY-044', 'actor': 'finance@mvec.rw', 'action': 'Release', 'entity': 'Payout PAY-044', 'category': 'PAYMENT', 'date': shortDate(DateTime(2026, 9, 16))},
      {'id': 'CAT-002', 'actor': 'admin@mvec.rw', 'action': 'Create', 'entity': 'Category CAT-002', 'category': 'CATALOG', 'date': shortDate(DateTime(2026, 9, 15))},
      {'id': 'USR-121', 'actor': 'owner@mvec.rw', 'action': 'Restore', 'entity': 'User USR-121', 'category': 'ACCOUNT', 'date': shortDate(DateTime(2026, 9, 15))},
      {'id': 'KEY-003', 'actor': 'ops@mvec.rw', 'action': 'Refresh', 'entity': 'Webhook HMAC key', 'category': 'SECURITY', 'date': shortDate(DateTime(2026, 9, 14))},
    ];
  }
}