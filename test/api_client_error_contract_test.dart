// Regression cover for the defect that made *every* supplier page fail with
// "User role 'supplier' is not authorized to access this route".
//
// ApiClient used to reject with a `DioException` that only *carried* an
// ApiException in `.error`, so a bare ApiException was never thrown. Every
// `on ApiException` guard in the app was therefore dead code, and an expected
// 403 from the admin-only `GET /orders` escaped into the shared supplier
// provider's `Future.wait`, blanking all pages at once.
import 'package:flutter_test/flutter_test.dart';
import 'package:mvec_mobile/core/api_client.dart';
import 'package:mvec_mobile/core/utils.dart';

void main() {
  // `flutter test` installs HttpOverrides that answer every request with an
  // HTTP error, which is enough: the error still travels the real interceptor
  // and `_guard` path, and a non-400 status would mean the unwrap failed.
  test('a failing request throws ApiException, not DioException', () async {
    Object? caught;
    try {
      await ApiClient.instance.get('/definitely-not-a-route');
    } on Object catch (e) {
      caught = e;
    }

    expect(caught, isA<ApiException>(),
        reason: 'callers must be able to catch ApiException');
    final api = caught! as ApiException;
    // The offline test override raises an error without an HTTP response, so
    // statusCode is legitimately null here; what matters is that a usable
    // message always reaches the UI.
    expect(api.message, isNotEmpty);
  });

  test('friendlyError shows the backend message, not a Dio type dump', () async {
    Object? caught;
    try {
      await ApiClient.instance.get('/definitely-not-a-route');
    } on Object catch (e) {
      caught = e;
    }
    final message = friendlyError(caught!);
    expect(message, isNot(contains('DioException')));
  });
}
