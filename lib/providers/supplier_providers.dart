import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/supplier.dart';
import '../services/supplier_service.dart';

final supplierServiceProvider = Provider<SupplierService>(
  (ref) => SupplierService(ref.watch(apiProvider)),
);

/// The signed-in supplier's own profile.
///
/// `SupplierService.profile` already maps the not-yet-onboarded 404 to `null`,
/// so this only has to surface genuine failures (network, 500, auth).
final supplierProfileProvider = FutureProvider<SupplierDetail?>((ref) async {
  return ref.watch(supplierServiceProvider).profile();
});

/// The supplier's wholesale catalogue, unpaginated as the backend returns it.
final supplierProductsProvider = FutureProvider<List<SupplierProduct>>(
  (ref) => ref.watch(supplierServiceProvider).products(),
);

/// Dashboard counters derived from the catalogue — the backend exposes no
/// metrics endpoint.
final supplierMetricsProvider = FutureProvider<SupplierMetrics>(
  (ref) async => SupplierMetrics.fromCatalog(
    await ref.watch(supplierProductsProvider.future),
  ),
);

/// Invalidates everything a profile or catalogue edit can change.
void refreshSupplierData(WidgetRef ref) {
  ref.invalidate(supplierProfileProvider);
  ref.invalidate(supplierProductsProvider);
  ref.invalidate(supplierMetricsProvider);
}
