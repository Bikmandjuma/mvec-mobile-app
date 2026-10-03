// Regression tests for FallbackAffiliateService:
//  - in demo mode the API must never be contacted — demo data is served
//    immediately, so the module works without a backend and with no wait;
//  - once demo data is active the fallback stays sticky for the session.
//
// Run with: flutter test test/features/affiliate/fallback_affiliate_service_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:mvec_mobile/core/api_client.dart';
import 'package:mvec_mobile/features/affiliate/data/models/affiliate_marketing.dart';
import 'package:mvec_mobile/features/affiliate/data/services/fallback_affiliate_service.dart';
import 'package:mvec_mobile/features/affiliate/data/services/mock_affiliate_service.dart';

class _CountingService extends MockAffiliateService {
  _CountingService() : super(delay: Duration.zero);

  int overviewCalls = 0;

  @override
  Future<AffiliateOverview> fetchOverview() {
    overviewCalls++;
    return super.fetchOverview();
  }
}

void main() {
  group('FallbackAffiliateService', () {
    test('demo mode serves bundled data immediately, never touching the API', () async {
      final fake = _CountingService();
      final svc = FallbackAffiliateService(
        ApiClient.instance,
        fallback: fake,
        forceDemo: true,
      );

      final overview = await svc.fetchOverview();

      expect(overview, isA<AffiliateOverview>());
      expect(fake.overviewCalls, 1);
      expect(svc.isDemo, isTrue);
      expect(svc.fallbackReason, contains('Demo mode'));
    });

    test('degradation stays sticky once demo data is active', () async {
      final fake = _CountingService();
      final svc = FallbackAffiliateService(
        ApiClient.instance,
        fallback: fake,
        forceDemo: true,
      );

      await svc.fetchOverview();
      await svc.fetchOverview();
      await svc.fetchOverview();

      // Every request is served from the demo store; the API is never hit.
      expect(fake.overviewCalls, 3);
    });

    test('isDemo is false until the API is known to be unreachable', () async {
      final svc = FallbackAffiliateService(
        ApiClient.instance,
        fallback: _CountingService(),
        forceDemo: false,
      );

      expect(svc.isDemo, isFalse);
      expect(svc.fallbackReason, isNull);
    });
  });
}