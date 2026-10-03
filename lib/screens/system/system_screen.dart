import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class SystemScreen extends ConsumerWidget {
  const SystemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'System Administration',
          subtitle: 'Runtime platform settings.',
        ),
        SmartTable(
          columns: const [
            MvColumn('setting', 'Setting', flex: 2),
            MvColumn('value', 'Value', flex: 2),
            MvColumn('scope', 'Scope'),
            MvColumn('changed', 'Last changed'),
            MvColumn('owner', 'Owner'),
          ],
          rows: _mockSettings(),
          pageSize: 8,
          actionsLabel: 'Actions',
          rowActions: (row) => TableActionBtn(
            icon: 'check',
            tooltip: 'Apply',
            onPressed: () {
              showMvSnack(context, 'Applied “${row['setting']}”.', success: true);
            },
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _mockSettings() {
    return [
      {'setting': 'Maintenance mode', 'value': 'Disabled', 'scope': 'Global', 'changed': shortDate(DateTime(2026, 9, 18)), 'owner': 'Infra'},
      {'setting': 'Feature flags', 'value': 'Preview branch', 'scope': 'Global', 'changed': shortDate(DateTime(2026, 9, 18)), 'owner': 'Platform'},
      {'setting': 'Job queue', 'value': 'Running · 0 backlog', 'scope': 'Worker', 'changed': shortDate(DateTime(2026, 9, 17)), 'owner': 'Infra'},
      {'setting': 'Cache TTL', 'value': '15 minutes', 'scope': 'Global', 'changed': shortDate(DateTime(2026, 9, 15)), 'owner': 'Platform'},
      {'setting': 'Event webhook URL', 'value': 'https://hooks.mvec.rw/events', 'scope': 'Global', 'changed': shortDate(DateTime(2026, 9, 12)), 'owner': 'Integrations'},
      {'setting': 'Image CDN', 'value': 'https://cdn.mvec.rw', 'scope': 'Global', 'changed': shortDate(DateTime(2026, 9, 10)), 'owner': 'Infra'},
      {'setting': 'Environment name', 'value': 'Production', 'scope': 'Global', 'changed': shortDate(DateTime(2026, 9, 08)), 'owner': 'Platform'},
      {'setting': 'API rate cap', 'value': '120 req/min', 'scope': 'Public', 'changed': shortDate(DateTime(2026, 9, 05)), 'owner': 'Infra'},
    ];
  }
}