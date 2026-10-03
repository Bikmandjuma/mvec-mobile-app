import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class LocationsScreen extends ConsumerWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = ref.watch(zonesProvider);
    final rows = switch (zones) {
      AsyncData(:final value) when value.isNotEmpty => value.map(_zoneRow).toList(),
      _ => _mockZones(),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Locations',
          subtitle: 'Coverage, provinces and delivery fees.',
        ),
        SmartTable(
          columns: const [
            MvColumn('province', 'Province', flex: 3),
            MvColumn('districts', 'Districts'),
            MvColumn('sectors', 'Sectors'),
            MvColumn('fee', 'Delivery fee', flex: 2),
          ],
          rows: rows,
          pageSize: 8,
          actionsLabel: 'Coverage',
          rowActions: (row) => StatusChip(
            row['coverage']?.toString(),
            overrideColor: row['coverage'] == 'FULL' ? MvColors.successText : MvColors.warningText,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _zoneRow(Map<String, dynamic> z) {
    return {
      'province': (z['province'] ?? z['name'] ?? 'Unknown').toString(),
      'districts': _count(z['districts']) ?? _count(z['districtCount']) ?? 0,
      'sectors': _count(z['sectors']) ?? _count(z['sectorCount']) ?? 0,
      'fee': money((z['fee'] ?? z['deliveryFee'] ?? z['feeRwf']) as num?),
      'coverage': (z['coverage'] ?? z['status'] ?? 'FULL').toString().toUpperCase(),
    };
  }

  int? _count(Object? v) => v is int ? v : (v is num ? v.toInt() : (v is String ? int.tryParse(v) : null));

  List<Map<String, dynamic>> _mockZones() => const [
        {'province': 'Kigali City', 'districts': 3, 'sectors': 35, 'fee': 1000, 'coverage': 'FULL'},
        {'province': 'Northern Province', 'districts': 5, 'sectors': 17, 'fee': 2000, 'coverage': 'PARTIAL'},
        {'province': 'Southern Province', 'districts': 8, 'sectors': 14, 'fee': 2000, 'coverage': 'FULL'},
        {'province': 'Eastern Province', 'districts': 7, 'sectors': 24, 'fee': 1500, 'coverage': 'FULL'},
        {'province': 'Western Province', 'districts': 7, 'sectors': 14, 'fee': 2500, 'coverage': 'PARTIAL'},
      ];
}