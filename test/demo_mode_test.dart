// Verifies the DEMO_MODE auth gate: with `--dart-define=DEMO_MODE=true` the real
// `AuthController` must sign in locally, without any network round-trip, so the
// app can be presented with no backend running.
//
// This file is only meaningful under that define — `kDemoMode` is resolved at
// compile time. Run it with:
//   flutter test --dart-define=DEMO_MODE=true test/demo_mode_test.dart

import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mvec_mobile/core/api_config.dart';
import 'package:mvec_mobile/features/marketplace/presentation/Screens/main_navigation.dart';
import 'package:mvec_mobile/features/supplier/data/supplier_workspace.dart';
import 'package:mvec_mobile/main.dart';
import 'package:mvec_mobile/providers/auth_provider.dart';
import 'package:mvec_mobile/screens/layout/admin_shell.dart';
import 'package:mvec_mobile/screens/suppliers/supplier_overview_screen.dart';
import 'package:mvec_mobile/screens/suppliers/supplier_shell.dart';
import 'package:mvec_mobile/screens/vendor/vendor_shell.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  // Without the define these cases would exercise the *real* login path and
  // hang on a network call, so skip the whole file.
  group('demo auth gate (--dart-define=DEMO_MODE=true)', () {
    test('demo login opens the app without a backend', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // The real controller — no stub, no secure storage, no network.
      final controller = container.read(authControllerProvider.notifier);
      final ok = await controller.login('admin@gmail.com', 'anything');

      expect(ok, isTrue);
      final session = container.read(authControllerProvider).session;
      expect(session, isNotNull);
      expect(session!.token, 'demo-token');
    }, skip: !kDemoMode);

    testWidgets('an admin identity routes to the control center', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .login('admin@gmail.com', 'anything');

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MvecApp()),
      );
      // The control center loads live providers, so its spinners never settle
      // in a test: pump a bounded number of frames instead of pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(AdminShell), findsOneWidget);
    }, skip: !kDemoMode);

    testWidgets('a buyer identity routes to the marketplace home feed', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .login('buyer@example.com', 'anything');

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MvecApp()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationScreen), findsOneWidget);
    }, skip: !kDemoMode);

    testWidgets('supplier can sign in and advance an order', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final signedIn = await container
          .read(authControllerProvider.notifier)
          .login('supplier@mvec.rw', 'demo123');
      expect(signedIn, isTrue);
      expect(
        container.read(authControllerProvider).session!.user.userType,
        'supplier',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MvecApp()),
      );
      await tester.pumpAndSettle();

      // roleHome() sends a supplier straight to /supplier, so the portal (not
      // the marketplace feed) is the landing screen.
      expect(find.byType(SupplierOverviewScreen), findsOneWidget);
      expect(find.byType(MainNavigationScreen), findsNothing);

      // The 800x600 test viewport is below the 900pt breakpoint, so the
      // supplier shell renders the bottom bar instead of the sidebar.
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();
      expect(find.text('Arabica Coffee Beans'), findsOneWidget);

      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm order'), findsOneWidget);
      await tester.tap(find.text('Confirm order'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmed'), findsWidgets);
    }, skip: !kDemoMode);

    testWidgets('a vendor identity opens the local vendor dashboard', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final signedIn = await container
          .read(authControllerProvider.notifier)
          .login('vendor@umucyo.rw', 'anything');
      expect(signedIn, isTrue);
      expect(
        container.read(authControllerProvider).session!.user.userType,
        'vendor',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MvecApp()),
      );
      await tester.pumpAndSettle();

      // roleHome() sends a vendor straight to /vendor, so the portal (not the
      // marketplace feed) is the landing screen.
      expect(find.byType(VendorShell), findsOneWidget);
      expect(find.byType(MainNavigationScreen), findsNothing);
      expect(find.text('VENDOR PORTAL'), findsWidgets);
    }, skip: !kDemoMode);

    testWidgets('the supplier product form collects only the web fields', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .login('supplier@mvec.rw', 'demo123');

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MvecApp()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add wholesale product'));
      await tester.pumpAndSettle();

      // The seven fields the web supplier form collects, in the same order.
      const webFields = [
        'Product name *',
        'Category *',
        'Wholesale price (RWF) *',
        'Minimum order quantity *',
        'Stock *',
        'Bulk discount (%) *',
        'Description',
      ];
      for (final label in webFields) {
        expect(
          find.text(label),
          findsOneWidget,
          reason: 'the web form has a "$label" field',
        );
      }

      // Fields the web form does not have must not be asked for.
      for (final removed in [
        'Unit',
        'Retail price',
        'Main image URL',
        'Gallery image links',
        'Status',
      ]) {
        expect(
          find.text(removed),
          findsNothing,
          reason: '"$removed" is not part of the web supplier form',
        );
      }

      // Description is the only optional field on the web form.
      expect(find.text('Optional'), findsOneWidget);
    }, skip: !kDemoMode);

    testWidgets('the supplier shell swaps sidebar for bottom nav at 900pt', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .login('supplier@mvec.rw', 'demo123');

      // Wide: the web's permanent .dashboard-sidebar, and no bottom bar.
      // 1200dp crosses the shell's 900dp breakpoint used by the web's
      // MobileBottomNav.css media query.
      tester.view.physicalSize = const Size(1200 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MvecApp()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SupplierSidebar), findsOneWidget);
      expect(find.byType(SupplierBottomBar), findsNothing);

      // Nav groups are collapsible, so open the catalogue group first.
      expect(find.text('Wholesale Products'), findsNothing);
      await tester.tap(find.text('CATALOG & ORDERS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wholesale Products'));
      await tester.pumpAndSettle();
      expect(find.text('Arabica Coffee Beans'), findsOneWidget);

      // Narrow: the bottom bar takes over and the sidebar is gone.
      tester.view.physicalSize = const Size(420 * 2, 900 * 2);
      await tester.pumpAndSettle();
      expect(find.byType(SupplierBottomBar), findsOneWidget);
      expect(find.byType(SupplierSidebar), findsNothing);
      expect(find.byTooltip('Open supplier navigation'), findsOneWidget);
    }, skip: !kDemoMode);

    testWidgets('the "More" sheet exposes the rest of the supplier nav', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .login('supplier@mvec.rw', 'demo123');

      tester.view.physicalSize = const Size(420 * 2, 900 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MvecApp()),
      );
      await tester.pumpAndSettle();

      // The four primary destinations are pinned; the rest live behind More.
      expect(find.text('Payments'), findsOneWidget);
      expect(find.text('Transactions'), findsNothing);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('MVEC Support'), findsOneWidget);
    }, skip: !kDemoMode);

    test(
      'demo supplier data supports catalog, stock, notification and profile edits',
      () async {
        final service = DemoSupplierWorkspaceService();
        final initialProducts = await service.products();
        expect(initialProducts, hasLength(4));
        expect(initialProducts.first.imageUrl, isNotEmpty);

        await service.saveProduct(
          const SupplierProduct(
            id: '',
            name: 'Demo Green Tea',
            category: 'Beverages',
            description: 'Loose-leaf green tea.',
            imageUrl: 'https://example.com/green-tea.jpg',
            price: 5400,
            stock: 18,
            status: 'ACTIVE',
          ),
        );
        final created = (await service.products()).first;
        expect(created.name, 'Demo Green Tea');
        expect(created.imageUrl, 'https://example.com/green-tea.jpg');
        expect(created.price, 5400);
        expect(created.stock, 18);
        expect(created.minimumOrderQuantity, 1);
        expect(created.bulkDiscount, 0);

        await service.saveProduct(
          created.copyWith(minimumOrderQuantity: 6, bulkDiscount: 7),
        );
        final wholesaleProduct = (await service.products()).first;
        expect(wholesaleProduct.minimumOrderQuantity, 6);
        expect(wholesaleProduct.bulkDiscount, 7);

        await service.updateStock(initialProducts.first.id, 83);
        final updatedStock = (await service.products()).firstWhere(
          (product) => product.id == initialProducts.first.id,
        );
        expect(updatedStock.stock, 83);

        await service.updateOrderStatus('MV-4821', 'Confirmed');
        expect((await service.orders()).first.status, 'Confirmed');

        await service.markNotificationRead('sn-1');
        expect((await service.notifications()).first.read, isTrue);

        final original = await service.profile();
        final updated = SupplierProfile(
          businessName: 'Demo Updated Co.',
          email: original.email,
          phone: original.phone,
          address: original.address,
          orderNotifications: false,
          stockNotifications: original.stockNotifications,
        );
        await service.saveProfile(updated, isNewProfile: false);
        expect((await service.profile()).businessName, 'Demo Updated Co.');
        expect((await service.profile()).orderNotifications, isFalse);
      },
      skip: !kDemoMode,
    );

    test('empty demo credentials are rejected', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ok = await container
          .read(authControllerProvider.notifier)
          .login('   ', '');

      expect(ok, isFalse);
      expect(container.read(authControllerProvider).session, isNull);
    }, skip: !kDemoMode);
  });
}
