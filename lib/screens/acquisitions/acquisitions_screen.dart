import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class AcquisitionScreen extends ConsumerWidget {
  const AcquisitionScreen({super.key, required this.type});

  final String type;

  static const _vendorSeed = [
    ['Kigali Wines', 'hello@kigaliwines.rw', 'Beverages', 'Verified', 'Onboard catalog'],
    ['Lipton Teas', 'sales@liptonteas.rw', 'Groceries', 'Invited', 'Send intro call'],
    ['Zara Fits', 'zara@zarafits.rw', 'Fashion', 'Applied', 'Schedule verification'],
    ["Carl's Electronics", 'sales@carlselectronics.rw', 'Electronics', 'Onboarding', 'Upload catalog'],
    ['Fresh Produce Co', 'fresh@produceco.rw', 'Agriculture', 'Review', 'Review documents'],
    ['Urban Moto', 'info@urbanmoto.rw', 'Automotive', 'Invited', 'Follow up'],
  ];

  static const _supplierSeed = [
    ['PlumbPro', 'plumb@plumbpro.rw', 'Construction & Plumbing', 'Verified', 'Onboard supplies'],
    ['SteelWorks', 'sales@steelworks.rw', 'Building Materials', 'Applied', 'Schedule verification'],
    ['AgroSeeds', 'grow@agroseeds.rw', 'Agriculture', 'Onboarding', 'Upload catalog'],
    ['Textile Plus', 'textile@plus.rw', 'Textiles', 'Invited', 'Send intro call'],
    ['SolarKit', 'hello@solar-kit.rw', 'Energy', 'Review', 'Review documents'],
    ['ChemSupply', 'chem@chemsupply.rw', 'Chemicals', 'Invited', 'Follow up'],
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVendor = type == 'vendor';
    final seed = isVendor ? _vendorSeed : _supplierSeed;
    final rows = seed
        .map((r) => {
              'business': r[0],
              'contact': r[1],
              'category': r[2],
              'stage': StatusChip(r[3]),
              'next': r[4],
            })
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'MVEC GROWTH',
          title: isVendor ? 'Vendor Acquisition' : 'Supplier Acquisition',
          subtitle: 'Value proposition and acquisition pipeline.',
          actions: const [GradientButton(label: 'Export pipeline', icon: 'arrow')],
        ),
        DataCard(
          title: 'Value proposition',
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Step('1', 'Register & onboard'),
              _Step('2', 'Get verified'),
              _Step('3', 'List your catalog'),
              _Step('4', 'Start selling'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        DataCard(
          title: 'Acquisition pipeline',
          child: rows.isEmpty
              ? const EmptyState(message: 'No pipeline records found')
              : SmartTable(
                  columns: const [
                    MvColumn('business', 'Business', bold: true),
                    MvColumn('contact', 'Contact'),
                    MvColumn('category', 'Category'),
                    MvColumn('stage', 'Stage'),
                    MvColumn('next', 'Next step'),
                  ],
                  rows: rows,
                  actionsLabel: '',
                  csvFileName: isVendor ? 'vendor-pipeline' : 'supplier-pipeline',
                ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.label);

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: MvColors.metricIconBg, shape: BoxShape.circle),
            child: Text(
              number,
              style: const TextStyle(fontFamily: 'Manrope', fontSize: 11, fontWeight: FontWeight.w800, color: MvColors.primaryDeep),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}