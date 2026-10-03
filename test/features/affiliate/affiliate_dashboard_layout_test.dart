import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mvec_mobile/core/theme.dart';
import 'package:mvec_mobile/features/affiliate/data/models/affiliate_earnings.dart';
import 'package:mvec_mobile/features/affiliate/data/models/affiliate_marketing.dart';
import 'package:mvec_mobile/features/affiliate/data/models/affiliate_profile.dart';
import 'package:mvec_mobile/features/affiliate/presentation/providers/affiliate_providers.dart';
import 'package:mvec_mobile/features/affiliate/presentation/screens/affiliate_dashboard_screen.dart';

void main() {
  testWidgets('affiliate dashboard stacks chart and wallet on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          affiliateProfileProvider.overrideWith(
            (ref) async => const AffiliateProfile(
              fullName: 'Test Affiliate',
              verificationStatus: 'VERIFIED',
            ),
          ),
          affiliateOverviewProvider.overrideWith(
            (ref) async => const AffiliateOverview(),
          ),
          affiliateStatsProvider.overrideWith(
            (ref, range) async => const AffiliateStats(
              labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
              clicksSeries: [2, 4, 3, 5, 4, 6, 5],
              registrationsSeries: [1, 1, 2, 1, 2, 2, 3],
              conversionsSeries: [0, 1, 1, 2, 1, 2, 2],
            ),
          ),
        ],
        child: MaterialApp(
          theme: lightAppTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: AffiliateDashboardScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Referral performance'), findsOneWidget);
    expect(find.text('Wallet'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Wallet')).dy,
      greaterThan(tester.getTopLeft(find.text('Referral performance')).dy),
    );
    final layoutException = tester.takeException();
    if (layoutException != null) {
      debugPrint(tester.binding.renderViews.first.toStringDeep());
    }
    expect(layoutException, isNull);
  });
}
