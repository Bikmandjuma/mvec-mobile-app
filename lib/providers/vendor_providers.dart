import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/utils.dart';
import '../models/catalog.dart';
import '../models/vendor.dart';
import '../models/vendor_product.dart';
import '../services/vendor_service.dart';

/// Vendor dashboard state.
///
/// Follows the admin providers' conventions: services are only reached through
/// `ref.watch`, reads happen in `build`, mutations go through
/// `ref.read(...notifier)` and then invalidate the affected list providers.
final vendorServiceProvider = Provider<VendorService>((ref) => VendorService(ref.watch(apiProvider)));

// ---------- Store profile + verification ----------

/// The signed-in vendor's store. `null` means "no store yet" — the profile
/// screen renders its setup form in that case.
final myStoreProvider = FutureProvider.autoDispose<StoreProfile?>((ref) => ref.watch(vendorServiceProvider).myStore());

// ---------- Overview ----------

final vendorStatsProvider = FutureProvider.autoDispose<VendorStats>((ref) => ref.watch(vendorServiceProvider).stats());

/// Filter state for the unified activity history. Value equality matters: this
/// is a `family` key, so two identical filters must collapse to one request.
class VendorActivityQuery {
  const VendorActivityQuery({this.page = 1, this.limit = 20, this.from, this.to, this.type = allTypes});

  /// Sentinel for "every activity family" — never sent to the API.
  static const allTypes = 'ALL';

  final int page;
  final int limit;
  final DateTime? from;
  final DateTime? to;
  final String type;

  bool get isFiltered => from != null || to != null || type != allTypes;

  VendorActivityQuery copyWith({int? page, DateTime? from, DateTime? to, String? type, bool clearFrom = false, bool clearTo = false}) =>
      VendorActivityQuery(
        page: page ?? this.page,
        limit: limit,
        from: clearFrom ? null : (from ?? this.from),
        to: clearTo ? null : (to ?? this.to),
        type: type ?? this.type,
      );

  @override
  bool operator ==(Object other) =>
      other is VendorActivityQuery &&
      other.page == page &&
      other.limit == limit &&
      other.from == from &&
      other.to == to &&
      other.type == type;

  @override
  int get hashCode => Object.hash(page, limit, from, to, type);
}

final vendorActivityProvider = FutureProvider.autoDispose.family<Paged<VendorActivity>, VendorActivityQuery>(
  (ref, q) => ref.watch(vendorServiceProvider).activity(
        page: q.page,
        limit: q.limit,
        from: q.from,
        to: q.to,
        type: q.type == VendorActivityQuery.allTypes ? null : q.type,
      ),
);

// ---------- Products ----------

/// Filter state for the product list (search, availability, stock health).
class VendorProductQuery {
  const VendorProductQuery({this.page = 1, this.limit = 20, this.search = '', this.status = allStatuses, this.lowStockOnly = false});

  /// Sentinel for "every availability status" — never sent to the API.
  static const allStatuses = 'ALL';

  final int page;
  final int limit;
  final String search;
  final String status;
  final bool lowStockOnly;

  bool get isFiltered => search.isNotEmpty || status != allStatuses || lowStockOnly;

  VendorProductQuery copyWith({int? page, String? search, String? status, bool? lowStockOnly, bool clearSearch = false}) =>
      VendorProductQuery(
        page: page ?? this.page,
        limit: limit,
        search: clearSearch ? '' : (search ?? this.search),
        status: status ?? this.status,
        lowStockOnly: lowStockOnly ?? this.lowStockOnly,
      );

  @override
  bool operator ==(Object other) =>
      other is VendorProductQuery &&
      other.page == page &&
      other.limit == limit &&
      other.search == search &&
      other.status == status &&
      other.lowStockOnly == lowStockOnly;

  @override
  int get hashCode => Object.hash(page, limit, search, status, lowStockOnly);
}

final vendorProductsProvider = FutureProvider.autoDispose.family<Paged<VendorProduct>, VendorProductQuery>(
  (ref, q) => ref.watch(vendorServiceProvider).products(
        page: q.page,
        limit: q.limit,
        search: q.search,
        status: q.status == VendorProductQuery.allStatuses ? null : q.status,
        lowStockOnly: q.lowStockOnly,
      ),
);

/// Categories for the product form's picker. Also refreshed after the inline
/// "+ Add New Category" creator runs.
final vendorCategoriesProvider = FutureProvider.autoDispose<List<CategoryRecord>>((ref) => ref.watch(vendorServiceProvider).categories());

// ---------- Shell search handoff ----------

/// Seed for the product list's search box, set by the shell's top-bar search so
/// typing there lands the vendor on an already-filtered product list.
class VendorSearchSeed extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value.trim();

  void clear() => state = '';
}

final vendorSearchSeedProvider = NotifierProvider<VendorSearchSeed, String>(VendorSearchSeed.new);

// ---------- Mutations ----------

/// In-flight state shared by every vendor write operation, so a form can show
/// one spinner and surface one message.
///
/// Carries the outcome as data rather than raising a snackbar from here: a
/// Riverpod notifier has no `BuildContext`, so the calling screen reads
/// [success] / [error] back and shows it against its own context.
class VendorMutationState {
  const VendorMutationState({this.busy = false, this.error, this.success});

  final bool busy;

  /// Failure message from the last write, if it failed.
  final String? error;

  /// Confirmation message from the last write, if it succeeded.
  final String? success;

  bool get hasError => error != null && error!.isNotEmpty;
}

/// Base for the vendor write controllers: owns the busy / error / success
/// state and the invalidation pipeline every write goes through.
abstract class VendorWriteController extends Notifier<VendorMutationState> {
  @override
  VendorMutationState build() => const VendorMutationState();

  /// Runs [action] behind the busy flag, refreshes what the write affects, and
  /// records the outcome. Returns whether it succeeded.
  Future<bool> write(
    Future<Object?> Function() action, {
    required String success,
    void Function()? extra,
  }) async {
    state = const VendorMutationState(busy: true);
    try {
      await action();
      // Catalogue writes invalidate the whole family, so whichever page or
      // filter the vendor is on reflects the change.
      ref.invalidate(vendorProductsProvider);
      extra?.call();
      state = VendorMutationState(success: success);
      return true;
    } catch (e) {
      state = VendorMutationState(error: friendlyError(e));
      return false;
    }
  }
}

/// Store-scoped writes: the profile save and the verification document upload.
class VendorStoreController extends VendorWriteController {
  /// Persists the store profile and refreshes everything derived from it.
  Future<bool> saveProfile(Map<String, dynamic> body) => write(
        () => ref.read(vendorServiceProvider).updateStore(body),
        success: 'Store profile updated',
        extra: () {
          ref.invalidate(myStoreProvider);
          ref.invalidate(vendorStatsProvider);
        },
      );

  /// Uploads verification documents and moves the store into review.
  Future<bool> submitDocuments(List<Map<String, String>> documents) => write(
        () => ref.read(vendorServiceProvider).submitDocuments(documents),
        success: 'Documents submitted for review',
        extra: () => ref.invalidate(myStoreProvider),
      );
}

final vendorStoreControllerProvider = NotifierProvider<VendorStoreController, VendorMutationState>(VendorStoreController.new);

/// Catalogue writes: create, update, availability toggle, remove, and the
/// inline category creator.
class VendorProductController extends VendorWriteController {
  Future<bool> createProduct(Map<String, dynamic> body) => write(
        () => ref.read(vendorServiceProvider).createProduct(body),
        success: 'Product added',
        extra: () => ref.invalidate(vendorActivityProvider),
      );

  Future<bool> updateProduct(String id, Map<String, dynamic> body) => write(
        () => ref.read(vendorServiceProvider).updateProduct(id, body),
        success: 'Product updated',
        extra: () => ref.invalidate(vendorActivityProvider),
      );

  /// Publishes or unpublishes a listing without opening the edit form.
  Future<bool> setAvailability(String id, String status) => write(
        () => ref.read(vendorServiceProvider).setAvailability(id, status),
        success: status == VendorProductStatus.active ? 'Product is live' : 'Product hidden',
        extra: () {
          // Availability moves money, so the dashboard counters move too.
          ref.invalidate(vendorStatsProvider);
          ref.invalidate(vendorActivityProvider);
        },
      );

  /// Soft-deletes a listing.
  Future<bool> removeProduct(String id) => write(
        () => ref.read(vendorServiceProvider).removeProduct(id),
        success: 'Product removed',
      );

  /// Creates a category from inside the product form ("+ Add New Category") and
  /// returns it so the picker can select it straight away.
  Future<CategoryRecord?> createCategory(String name) async {
    state = const VendorMutationState(busy: true);
    try {
      final created = await ref.read(vendorServiceProvider).createCategory(name);
      ref.invalidate(vendorCategoriesProvider);
      state = const VendorMutationState(success: 'Category created');
      return created;
    } catch (e) {
      state = VendorMutationState(error: friendlyError(e));
      return null;
    }
  }
}

final vendorProductControllerProvider = NotifierProvider<VendorProductController, VendorMutationState>(VendorProductController.new);
