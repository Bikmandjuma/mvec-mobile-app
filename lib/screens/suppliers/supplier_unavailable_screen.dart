import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/mv_icon.dart';

/// Shown for the supplier portal pages that the web app renders from mock data
/// but the API does not yet expose.
///
/// The web builds these screens from hard-coded seed arrays
/// (`src/pages/SupplierDashboard.jsx`), so copying those numbers would show a
/// supplier fabricated revenue, payouts and staff records as if they were real.
/// This screen keeps the web's navigation intact while saying plainly that the
/// data is not connected yet.
class SupplierUnavailableScreen extends StatelessWidget {
  const SupplierUnavailableScreen({
    super.key,
    required this.feature,
    required this.detail,
    this.icon = 'chart',
  });

  /// Page title, e.g. `Payments & settlements`.
  final String feature;

  /// Why this particular page has no data.
  final String detail;

  final String icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPPLIER PLATFORM',
          title: feature,
          subtitle: 'This page is not connected to the MVEC API yet.',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 40),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: context.mv.surfaceMuted,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: MvIcon(icon, size: 28, color: context.mv.accentDeep),
                ),
                const SizedBox(height: 16),
                Text(
                  'No data available yet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.mv.text,
                  ),
                ),
                const SizedBox(height: 7),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: context.mv.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const InfoBox(
          'The MVEC API does not expose this data for supplier accounts yet. '
          'Nothing shown here is estimated or mocked — it will appear as soon '
          'as the endpoint ships.',
        ),
      ],
    );
  }
}
