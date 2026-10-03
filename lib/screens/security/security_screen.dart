import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Security',
          subtitle: 'Platform security controls and policies.',
        ),
        SmartTable(
          columns: const [
            MvColumn('control', 'Control', flex: 2),
            MvColumn('area', 'Area'),
            MvColumn('owner', 'Owner'),
            MvColumn('last', 'Last review'),
          ],
          rows: _controls(),
          pageSize: 8,
          actionsLabel: 'Status · Policy',
          rowActions: (row) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusChip(
                row['status']?.toString(),
                overrideColor: row['status'] == 'ACTIVE' ? MvColors.successText : MvColors.warningText,
              ),
              const SizedBox(width: 6),
              TableActionBtn(icon: 'eye', tooltip: 'Review policy', onPressed: () => _review(context, row)),
            ],
          ),
        ),
      ],
    );
  }

  void _review(BuildContext context, Map<String, dynamic> row) {
    showMvDetailModal(
      context,
      title: 'Review policy',
      children: [
        Text(
          row['desc']?.toString() ?? '',
          style: const TextStyle(fontSize: 13.5, height: 1.55),
        ),
        const SizedBox(height: 18),
        KeyValueGrid(entries: [
          MapEntry('Control', row['control']?.toString() ?? '-'),
          MapEntry('Area', row['area']?.toString() ?? '-'),
          MapEntry('Owner', row['owner']?.toString() ?? '-'),
          MapEntry('Status', row['status']?.toString() ?? '-'),
          MapEntry('Last review', row['last']?.toString() ?? '-'),
        ]),
      ],
      footer: Row(
        children: [
          Expanded(
            child: OutlineMvButton(label: 'Close', onPressed: () => Navigator.of(context).pop()),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GradientButton(
              label: 'Approve policy',
              icon: 'check',
              onPressed: () {
                Navigator.of(context).pop();
                showMvSnack(context, 'Policy approved.', success: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _controls() {
    return [
      {
        'control': 'Two-factor authentication for admins',
        'area': 'Access control',
        'owner': 'Platform team',
        'status': 'ACTIVE',
        'last': shortDate(DateTime(2026, 9, 12)),
        'desc': 'All administrator accounts are required to use a time-based one-time password (TOTP) in addition to their credentials. Recovery codes are sealed and rotated on every login.',
      },
      {
        'control': 'Role-based access control',
        'area': 'Access control',
        'owner': 'Platform team',
        'status': 'ACTIVE',
        'last': shortDate(DateTime(2026, 9, 10)),
        'desc': 'Permissions are granted per role (super_admin, support, finance, ops). Each route and API endpoint enforces an explicit permission check on the server.',
      },
      {
        'control': 'Payment webhook HMAC',
        'area': 'Payments',
        'owner': 'Finance team',
        'status': 'ACTIVE',
        'last': shortDate(DateTime(2026, 9, 08)),
        'desc': 'Incoming provider webhooks are verified against a per-provider HMAC secret before the payload is accepted and processed.',
      },
      {
        'control': 'API rate limiting',
        'area': 'Network',
        'owner': 'Infrastructure',
        'status': 'ACTIVE',
        'last': shortDate(DateTime(2026, 9, 05)),
        'desc': 'Public and authenticated endpoints are rate limited per IP and per token. Limits are tuned per route and monitored for saturation.',
      },
      {
        'control': 'Audit logging',
        'area': 'Governance',
        'owner': 'Platform team',
        'status': 'REVIEW',
        'last': shortDate(DateTime(2026, 8, 28)),
        'desc': 'Every privileged action is written to an append-only audit trail, including actor, action, target entity and a timestamp.',
      },
      {
        'control': 'Data encryption at rest',
        'area': 'Data',
        'owner': 'Infrastructure',
        'status': 'ACTIVE',
        'last': shortDate(DateTime(2026, 8, 21)),
        'desc': 'All sensitive records (payments, PII, credentials) are encrypted at rest using AES-256 with keys rotated every 90 days.',
      },
      {
        'control': 'Session expiry',
        'area': 'Access control',
        'owner': 'Platform team',
        'status': 'REVIEW',
        'last': shortDate(DateTime(2026, 8, 15)),
        'desc': 'Admin sessions expire after 12 hours of activity and are revoked on token rotation or password change.',
      },
      {
        'control': 'IP whitelist',
        'area': 'Network',
        'owner': 'Infrastructure',
        'status': 'ACTIVE',
        'last': shortDate(DateTime(2026, 8, 10)),
        'desc': 'Admin-only endpoints accept connections from a maintained allow-list of office and VPN egress IP ranges.',
      },
    ];
  }
}