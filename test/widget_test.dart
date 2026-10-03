// Smoke tests for the merged MVEC app: the authentication flow (login /
// registration / forgot password) and the role-based routing behind it, plus
// the marketplace shell (floating bottom nav, home feed, cart, wishlist).

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mvec_mobile/core/api_client.dart';
import 'package:mvec_mobile/core/theme.dart';
import 'package:mvec_mobile/core/utils/app_theme.dart';
import 'package:mvec_mobile/features/marketplace/presentation/Screens/home_screen.dart';
import 'package:mvec_mobile/features/marketplace/presentation/Screens/main_navigation.dart';
import 'package:mvec_mobile/features/marketplace/presentation/providers/commerce_provider.dart';
import 'package:mvec_mobile/main.dart';
import 'package:mvec_mobile/models/product.dart';
import 'package:mvec_mobile/models/supplier.dart';
import 'package:mvec_mobile/models/user.dart';
import 'package:mvec_mobile/providers/auth_provider.dart';
import 'package:mvec_mobile/screens/auth/auth_validation.dart';
import 'package:mvec_mobile/screens/suppliers/supplier_shell.dart';

Product _demoProduct() => Product(
  id: 'p1',
  name: 'Test Product',
  description: 'A product used by the provider tests.',
  price: 10,
  oldPrice: 12,
  stock: 5,
  images: const <String>[],
  colors: const <String>[],
  sizes: const <String>[],
  vendor: Vendor(
    id: 'v1',
    name: 'Test Vendor',
    logo: '',
    rating: 4.5,
    totalProducts: 1,
  ),
);

/// Like [_pumpSignedIn] but for dashboards, whose live providers never settle
/// (they poll the network), so we advance a bounded number of frames instead.
Future<void> _pumpDashboard(WidgetTester tester, String role) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _StubAuthController(_user(role)),
        ),
      ],
      child: const MvecApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

/// Auth controller stub so a test can boot the app as a signed-in role
/// without touching secure storage or the network.
class _StubAuthController extends AuthController {
  _StubAuthController(this.user);

  final UserRecord? user;

  @override
  AuthState build() => AuthState(
    session:
        user == null ? null : AuthSession(token: 'test-token', user: user!),
  );
}

UserRecord _user(String role) => UserRecord(
  id: 'u1',
  fullname: 'Test User',
  email: 'test@example.com',
  role: role,
);

/// Boots the signed-out app (login screen).
Future<void> _pumpSignedOut(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: MvecApp()));
  await tester.pumpAndSettle();
}

/// Boots the app as [role]; the router then sends the user to the landing
/// route for that role.
Future<void> _pumpSignedIn(WidgetTester tester, String role) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _StubAuthController(_user(role)),
        ),
      ],
      child: const MvecApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// The marketplace is served by mock data in tests, so the home feed and its
/// product grids always have content.
Future<void> _pumpMarketplace(WidgetTester tester) async {
  await _pumpSignedIn(tester, 'buyer');
  expect(find.byType(MainNavigationScreen), findsOneWidget);
}

/// Matches [matching] inside the floating bottom bar. Several bottom-bar glyphs
/// (`grid_view_outlined`, `shopping_bag_outlined`) also appear elsewhere in the
/// storefront, so bar assertions must be scoped.
Finder inBottomNav(Finder matching) => find.descendant(
  of: find.byKey(const ValueKey<String>('bottom-nav-bar')),
  matching: matching,
);

/// Matches [matching] inside the category strip under the top bar.
Finder inCategoryBar(Finder matching) => find.descendant(
  of: find.byKey(const ValueKey<String>('category-bar')),
  matching: matching,
);

/// Colour the bottom-nav icon for [icon] is currently painted in.
Color? _iconColor(WidgetTester tester, IconData icon) =>
    tester.widget<Icon>(inBottomNav(find.byIcon(icon))).color;

/// Effective colour of a bottom-nav [label], resolved through the animated
/// default text style the bar applies. Scoped to the bar because the active
/// tab's screen can repeat the same word as its own heading.
Color? _labelColor(WidgetTester tester, String label) =>
    DefaultTextStyle.of(
      tester.element(inBottomNav(find.text(label))),
    ).style.color;

/// Background the marketplace scaffold is currently filled with.
Color? _scaffoldBackground(WidgetTester tester) =>
    tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor;

void main() {
  // Keep widget tests offline and deterministic: never fetch fonts at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;

  group('validation helpers', () {
    test('email / phone validation', () {
      expect(validateEmailOrPhone(''), isNotNull);
      expect(validateEmailOrPhone('not-an-email'), isNotNull);
      expect(validateEmailOrPhone('72xxxxxx'), isNotNull);
      expect(validateEmailOrPhone('user@example.com'), isNull);
      expect(validateEmailOrPhone('+250791234567'), isNull);
      expect(validatePhone('abcd'), isNotNull);
      expect(validatePhone('+250 791 234 567'), isNull);
      expect(validateEmail(''), isNull);
      expect(validateEmail('bad'), isNotNull);
    });

    test('password validation', () {
      expect(validatePassword(''), isNotNull);
      expect(validatePassword('123'), isNotNull);
      expect(validatePassword('123456'), isNull);
      expect(validateConfirmPassword('123', '456'), isNotNull);
      expect(validateConfirmPassword('456', '456'), isNull);
    });

    test('full name and otp validation', () {
      expect(validateFullName('Narada'), isNotNull);
      expect(validateFullName('Narada Test'), isNull);
      expect(validateOtp('123'), isNotNull);
      expect(validateOtp('abcdef'), isNotNull);
      expect(validateOtp('123456'), isNull);
    });
  });

  group('role routing', () {
    test('super admin goes to the dashboard', () {
      expect(roleHome(_user('super_admin')), '/admin');
    });

    test('supplier lands on the supplier portal', () {
      expect(roleHome(_user('supplier')), '/supplier');
    });

    test('vendor goes to the vendor portal', () {
      expect(roleHome(_user('vendor')), '/vendor');
    });

    test('affiliate goes to the affiliate center', () {
      expect(roleHome(_user('affiliate')), '/affiliate');
    });

    test('buyer lands on the home feed', () {
      expect(roleHome(_user('buyer')), '/home');
    });
  });

  group('app boot', () {
    testWidgets('boots to the login screen', (tester) async {
      await _pumpSignedOut(tester);

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Email or telephone'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('empty login submit shows validation errors', (tester) async {
      await _pumpSignedOut(tester);

      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email or telephone.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
    });

    testWidgets('invalid email shows a validation error', (tester) async {
      await _pumpSignedOut(tester);

      await tester.enterText(find.byType(TextFormField).first, 'bad@email');
      await tester.enterText(find.byType(TextFormField).last, 'password1');
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
    });
  });

  group('registration', () {
    Future<void> openRegister(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Create one'));
      await tester.tap(find.text('Create one'));
      await tester.pumpAndSettle();
    }

    testWidgets('opens from the login screen and shows four user types', (
      tester,
    ) async {
      await _pumpSignedOut(tester);
      await openRegister(tester);

      expect(find.text('Create your account'), findsOneWidget);
      for (final role in ['Buyer', 'Vendor', 'Supplier', 'Affiliate']) {
        expect(find.text(role), findsOneWidget, reason: role);
      }
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Telephone'), findsOneWidget);
    });

    testWidgets('selecting a vendor shows the company field', (tester) async {
      await _pumpSignedOut(tester);
      await openRegister(tester);

      expect(find.text('Company name'), findsNothing);

      await tester.tap(find.text('Vendor'));
      await tester.pumpAndSettle();

      expect(find.text('Company name'), findsOneWidget);
    });

    testWidgets('register validation catches missing and mismatched fields', (
      tester,
    ) async {
      await _pumpSignedOut(tester);
      await openRegister(tester);

      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your full name.'), findsOneWidget);
      expect(find.text('Enter your telephone number.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);

      // Field order for a buyer: name, telephone, email, password, confirm.
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(3), 'password1');
      await tester.enterText(fields.at(4), 'password2');
      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });
  });

  group('forgot password', () {
    testWidgets('opens from login and renders the request form', (
      tester,
    ) async {
      await _pumpSignedOut(tester);

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(find.text('Email or telephone'), findsOneWidget);
      expect(find.text('Send code'), findsOneWidget);
    });

    testWidgets('validates the identity before sending', (tester) async {
      await _pumpSignedOut(tester);

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email or telephone.'), findsOneWidget);
    });
  });

  group('signed-in routing', () {
    testWidgets('a buyer lands on the marketplace home feed', (tester) async {
      await _pumpSignedIn(tester, 'buyer');

      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Welcome back'), findsNothing);
    });

    testWidgets('a super admin lands on the control-center dashboard', (
      tester,
    ) async {
      // The dashboard loads live providers, so its spinners never settle in a
      // test: pump a bounded number of frames instead of pumpAndSettle.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => _StubAuthController(_user('super_admin')),
            ),
          ],
          child: const MvecApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('SUPER ADMIN DASHBOARD'), findsOneWidget);
      expect(find.byType(MainNavigationScreen), findsNothing);
      expect(find.text('Welcome back'), findsNothing);
    });

    testWidgets('a vendor lands on the vendor portal', (tester) async {
      // Like the admin dashboard, the portal loads live providers, so pump a
      // bounded number of frames instead of pumpAndSettle.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => _StubAuthController(_user('vendor')),
            ),
          ],
          child: const MvecApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // "VENDOR PORTAL" is the shell's top-bar eyebrow and the overview
      // header, so it renders more than once.
      expect(find.text('VENDOR PORTAL'), findsWidgets);
      expect(find.byType(MainNavigationScreen), findsNothing);
      expect(find.text('Welcome back'), findsNothing);
    });
  });

  group('marketplace shell', () {
    testWidgets('renders the floating bottom nav, categories and home feed', (
      tester,
    ) async {
      await _pumpMarketplace(tester);

      // Bottom nav carries the four primary destinations as light outlined
      // glyphs, icon and label.
      expect(inBottomNav(find.byIcon(Icons.home_outlined)), findsOneWidget);
      expect(
        inBottomNav(find.byIcon(Icons.grid_view_outlined)),
        findsOneWidget,
      );
      expect(
        inBottomNav(find.byIcon(Icons.pie_chart_outline_rounded)),
        findsOneWidget,
      );
      expect(
        inBottomNav(find.byIcon(Icons.favorite_border_rounded)),
        findsOneWidget,
      );
      for (final label in <String>['Home', 'Shop', 'For You', 'Deals']) {
        expect(inBottomNav(find.text(label)), findsOneWidget, reason: label);
      }

      // The cart is the raised centre action of the bottom bar.
      expect(
        inBottomNav(find.byIcon(Icons.shopping_bag_outlined)),
        findsOneWidget,
      );

      expect(find.text('MVEC MARKETPLACE'), findsOneWidget);
      expect(find.text('Shop. Sell.\nGrow together.'), findsOneWidget);

      // Top bar keeps search, wishlist, notifications, the dark-mode toggle and
      // account reachable — the cart moved down to the bottom bar.
      expect(find.byType(TextField).first, findsOneWidget);
      expect(find.byTooltip('Wishlist'), findsOneWidget);
      expect(find.byTooltip('Notifications'), findsOneWidget);
      expect(find.byTooltip('Switch to dark mode'), findsOneWidget);
      expect(find.byTooltip('Account'), findsOneWidget);
      expect(find.byTooltip('Cart'), findsNothing);

      // The category strip stays expanded while sidebar destinations remain
      // available through the single hamburger control.
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('More'), findsNothing);
      expect(find.byIcon(Icons.category_outlined), findsOneWidget);

      expect(find.textContaining('demo data'), findsOneWidget);
    });

    testWidgets('only the active tab takes the sky-blue accent', (
      tester,
    ) async {
      await _pumpMarketplace(tester);

      final palette = MvPalette.light();
      // Home starts selected: sky-blue icon and label, muted neighbours.
      expect(_iconColor(tester, Icons.home_outlined), AppColors.skyBlueSolid);
      expect(_labelColor(tester, 'Home'), AppColors.skyBlueSolid);
      expect(_iconColor(tester, Icons.grid_view_outlined), palette.textMuted);
      expect(_labelColor(tester, 'Shop'), palette.textMuted);

      // Switching tabs moves the accent and slides the indicator along.
      final before = tester.getTopLeft(
        find.byKey(const ValueKey<String>('bottom-nav-indicator')),
      );
      await tester.tap(inBottomNav(find.byIcon(Icons.grid_view_outlined)));
      await tester.pumpAndSettle();
      final after = tester.getTopLeft(
        find.byKey(const ValueKey<String>('bottom-nav-indicator')),
      );

      expect(
        _iconColor(tester, Icons.grid_view_outlined),
        AppColors.skyBlueSolid,
      );
      expect(_labelColor(tester, 'Shop'), AppColors.skyBlueSolid);
      expect(_iconColor(tester, Icons.home_outlined), palette.textMuted);
      expect(_labelColor(tester, 'Home'), palette.textMuted);
      expect(after.dx, greaterThan(before.dx));

      // The bar splits into five slots, not four: Home→Shop advances one slot,
      // while Home→Deals crosses the cart's centre slot and advances four. That
      // asymmetry is what proves the cart really occupies a slot of its own.
      final slotWidth =
          (tester
                  .getSize(find.byKey(const ValueKey<String>('bottom-nav-bar')))
                  .width -
              2) /
          5;
      expect(after.dx - before.dx, closeTo(slotWidth, 1));

      await tester.tap(inBottomNav(find.byIcon(Icons.favorite_border_rounded)));
      await tester.pumpAndSettle();
      final deals = tester.getTopLeft(
        find.byKey(const ValueKey<String>('bottom-nav-indicator')),
      );
      expect(deals.dx - before.dx, closeTo(slotWidth * 4, 1));
      expect(_labelColor(tester, 'Deals'), AppColors.skyBlueSolid);
      expect(_labelColor(tester, 'Shop'), palette.textMuted);
    });

    testWidgets('only the selected category pill is sky-blue', (tester) async {
      await _pumpMarketplace(tester);

      /// Fill painted behind the category chip labelled [label].
      Color chipFill(String label) =>
          tester
              .widget<Material>(
                find
                    .ancestor(
                      of: inCategoryBar(find.text(label)),
                      matching: find.byType(Material),
                    )
                    .first,
              )
              .color!;

      /// Colour of the category chip's own label text, resolved through the
      /// animated default text style the pill applies.
      Color? chipText(String label) =>
          DefaultTextStyle.of(
            tester.element(inCategoryBar(find.text(label))),
          ).style.color;

      // "All" starts selected: the one chip allowed to carry the accent.
      expect(chipFill('All'), AppColors.skyBlueSolid);
      expect(chipText('All'), Colors.white);

      // Everything else is neutral grey, never sky-blue.
      final muted = MvPalette.light().textMuted;
      for (final label in <String>['Electronics', 'Fashion', 'Home & Garden']) {
        expect(chipFill(label), AppColors.chipNeutral, reason: label);
        expect(chipFill(label), isNot(AppColors.skyBlueSolid), reason: label);
        expect(chipText(label), muted, reason: label);
      }

      // Selecting a category hands the accent over, and hands over cleanly:
      // still exactly one sky-blue chip in the strip.
      await tester.tap(
        inCategoryBar(find.widgetWithText(InkWell, 'Electronics')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('category-bar')), findsNothing);

      await tester.tap(inBottomNav(find.byIcon(Icons.home_outlined)));
      await tester.pumpAndSettle();

      expect(chipFill('Electronics'), AppColors.skyBlueSolid);
      expect(chipText('Electronics'), Colors.white);
      expect(chipFill('All'), AppColors.chipNeutral);
      expect(chipFill('Fashion'), AppColors.chipNeutral);
    });

    testWidgets('the dark-mode toggle flips every surface and text colour', (
      tester,
    ) async {
      await _pumpMarketplace(tester);

      expect(_scaffoldBackground(tester), MvColors.page);
      expect(_labelColor(tester, 'Home'), AppColors.skyBlueSolid);

      await tester.tap(find.byTooltip('Switch to dark mode'));
      await tester.pumpAndSettle();

      // Surfaces step up to the dark card colour and text turns light, so
      // nothing disappears once the theme flips.
      final dark = MvPalette.dark();
      expect(_scaffoldBackground(tester), MvColors.darkPage);
      expect(_labelColor(tester, 'Home'), AppColors.skyBlueSolid);
      expect(_labelColor(tester, 'Deals'), dark.textMuted);

      // The control now offers the way back.
      expect(find.byTooltip('Switch to light mode'), findsOneWidget);

      await tester.tap(find.byTooltip('Switch to light mode'));
      await tester.pumpAndSettle();
      expect(_scaffoldBackground(tester), MvColors.page);
    });

    testWidgets('the dark theme keeps the marketplace legible', (tester) async {
      // Boot straight into dark mode through the shared preference.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'mvec.theme_mode': 'dark',
      });
      final prefs = await SharedPreferences.getInstance();
      addTearDown(
        () => SharedPreferences.setMockInitialValues(<String, Object>{}),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith(
              () => _StubAuthController(_user('buyer')),
            ),
          ],
          child: const MvecApp(),
        ),
      );
      await tester.pumpAndSettle();

      final dark = MvPalette.dark();
      expect(_scaffoldBackground(tester), MvColors.darkPage);
      // Body copy is light, and the sky-blue accent still stands out on it.
      expect(_labelColor(tester, 'Deals'), dark.textMuted);
      expect(_iconColor(tester, Icons.home_outlined), AppColors.skyBlueSolid);
      expect(
        Theme.of(
          tester.element(find.byType(HomeScreen)),
        ).textTheme.bodyMedium!.color,
        dark.text,
      );
    });

    testWidgets('the shell lays out on a small phone without overflowing', (
      tester,
    ) async {
      // 360dp is the narrowest screen the storefront has to survive now that
      // the top bar also carries notifications and the dark-mode toggle.
      tester.view.physicalSize = const Size(360 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await _pumpMarketplace(tester);

      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(find.byTooltip('Switch to dark mode'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('bottom-nav-indicator')),
        findsOneWidget,
      );
    });

    testWidgets('tapping a bottom nav icon switches the body', (tester) async {
      await _pumpMarketplace(tester);

      await tester.tap(
        inBottomNav(find.byIcon(Icons.pie_chart_outline_rounded)),
      );
      await tester.pumpAndSettle();

      // The For You screen renders its sections once it is active.
      expect(find.text('Recently Viewed'), findsOneWidget);
    });

    testWidgets('tapping a category pill filters the shop catalog', (
      tester,
    ) async {
      await _pumpMarketplace(tester);

      // Category pills jump straight to the Shop tab.
      await tester.tap(
        inCategoryBar(find.widgetWithText(InkWell, 'Electronics')),
      );
      await tester.pumpAndSettle();

      // Electronics product visible, Fashion product filtered out.
      expect(find.text('Gaming Mechanical Keyboard'), findsOneWidget);
      expect(find.text('Linen Summer Dress'), findsNothing);
    });

    testWidgets('opens search plus every destination behind the More drawer', (
      tester,
    ) async {
      await _pumpMarketplace(tester);

      expect(find.byTooltip('Menu'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);
      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsOneWidget);
      expect(tester.getTopLeft(find.byType(Drawer)).dx, 0);
      await tester.tapAt(const Offset(350, 400));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      expect(find.text('Recent searches'), findsOneWidget);
      await tester.tap(find.text('Wireless headphones'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('result(s) for "Wireless headphones"'),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();

      // All Categories, Vendors and Orders are reached from the hamburger
      // sidebar, without duplicate category-strip controls.
      expect(find.text('All categories'), findsNothing);
      expect(find.byTooltip('Vendors'), findsNothing);

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('All categories'), findsOneWidget);
      expect(find.text('Vendors'), findsOneWidget);
      expect(find.text('Orders & history'), findsOneWidget);
      expect(find.text('My wishlist'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);

      await tester.tap(find.text('All categories'));
      await tester.pumpAndSettle();
      expect(find.text('All Categories'), findsWidgets);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vendors'));
      await tester.pumpAndSettle();
      expect(find.text('Vendors'), findsWidgets);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Orders & history'));
      await tester.pumpAndSettle();
      expect(find.text('My Orders'), findsWidgets);
    });

    testWidgets('the More drawer is dismissible without navigating', (
      tester,
    ) async {
      await _pumpMarketplace(tester);

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Orders & history'), findsOneWidget);

      await tester.tapAt(const Offset(350, 100));
      await tester.pumpAndSettle();

      expect(find.text('Orders & history'), findsNothing);
      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });
  });

  group('marketplace cart and wishlist', () {
    /// Scrolls the home feed far enough to bring the product rows onstage.
    Future<void> scrollToProducts(WidgetTester tester) async {
      final homeList =
          find
              .descendant(
                of: find.byType(HomeScreen),
                matching: find.byType(ListView),
              )
              .first;
      await tester.drag(homeList, const Offset(0, -650));
      await tester.pumpAndSettle();
    }

    Badge badgeFor(WidgetTester tester, String countKey) =>
        tester.widget<Badge>(find.byKey(ValueKey<String>(countKey)));

    testWidgets('product cards add directly to cart and wishlist', (
      tester,
    ) async {
      await _pumpMarketplace(tester);
      await scrollToProducts(tester);

      expect(find.byTooltip('Add to cart'), findsWidgets);
      expect(badgeFor(tester, 'bottom-cart-badge').isLabelVisible, isFalse);

      await tester.tap(find.byTooltip('Add to cart').first);
      await tester.pumpAndSettle();
      expect((badgeFor(tester, 'bottom-cart-badge').label as Text).data, '1');

      await tester.tap(find.byTooltip('Add to wishlist').first);
      await tester.pumpAndSettle();
      expect((badgeFor(tester, 'home-wishlist-count').label as Text).data, '1');
    });

    testWidgets('adding a wishlisted product to cart clears the wishlist', (
      tester,
    ) async {
      await _pumpMarketplace(tester);
      await scrollToProducts(tester);

      await tester.tap(find.byTooltip('Add to wishlist').first);
      await tester.pumpAndSettle();
      expect(badgeFor(tester, 'home-wishlist-count').isLabelVisible, isTrue);

      await tester.tap(find.byTooltip('Add to cart').first);
      await tester.pumpAndSettle();

      expect(badgeFor(tester, 'home-wishlist-count').isLabelVisible, isFalse);
      expect((badgeFor(tester, 'bottom-cart-badge').label as Text).data, '1');

      await tester.tap(inBottomNav(find.byIcon(Icons.shopping_bag_outlined)));
      await tester.pumpAndSettle();
      expect(find.text('My Cart'), findsOneWidget);
      expect(
        find.textContaining('Wireless Over-Ear Headphones'),
        findsOneWidget,
      );
    });

    testWidgets('product detail opens, adds to cart and reaches the cart', (
      tester,
    ) async {
      await _pumpMarketplace(tester);
      await scrollToProducts(tester);

      await tester.tap(find.text('Wireless Over-Ear Headphones').first);
      await tester.pumpAndSettle();

      expect(find.text('In Stock (42)'), findsOneWidget);
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.byTooltip('Open wishlist'), findsOneWidget);
      expect(find.byTooltip('Open cart'), findsOneWidget);

      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Open cart'));
      await tester.pumpAndSettle();
      expect(find.text('My Cart'), findsOneWidget);
      expect(find.textContaining('Wireless Over-Ear Headphones'), findsWidgets);
    });

    testWidgets('wishlist page moves an item into the cart', (tester) async {
      await _pumpMarketplace(tester);
      await scrollToProducts(tester);

      await tester.tap(find.byTooltip('Add to wishlist').first);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Wishlist'));
      await tester.pumpAndSettle();
      expect(find.text('My Wishlist'), findsOneWidget);
      expect(find.text('Wireless Over-Ear Headphones'), findsWidgets);

      // The cart starts empty, so the wishlist app bar hides its badge.
      final wishlistCartBadge = tester.widget<Badge>(
        find.byKey(const ValueKey<String>('wishlist-cart-count')),
      );
      expect(wishlistCartBadge.isLabelVisible, isFalse);

      await tester.tap(find.text('Move to Cart'));
      await tester.pumpAndSettle();
      expect(find.text('Your wishlist is empty'), findsOneWidget);

      // Moving the item in must light the wishlist app-bar cart badge, so the
      // count is the same one the bottom nav and home top bar show.
      final badgeAfterMove = tester.widget<Badge>(
        find.byKey(const ValueKey<String>('wishlist-cart-count')),
      );
      expect(badgeAfterMove.isLabelVisible, isTrue);
      expect((badgeAfterMove.label as Text).data, '1');

      await tester.tap(find.byTooltip('Open cart'));
      await tester.pumpAndSettle();
      expect(find.text('My Cart'), findsOneWidget);
      // The cart line and the confirmation snackbar both name the product.
      expect(find.textContaining('Wireless Over-Ear Headphones'), findsWidgets);
    });
  });

  group('providers', () {
    test('commerce provider keeps cart and wishlist in sync', () {
      final provider = CommerceProvider();
      final product = _demoProduct();

      expect(provider.isWishlisted(product), isFalse);
      provider.toggleWishlist(product);
      expect(provider.isWishlisted(product), isTrue);
      expect(provider.wishlistItems, hasLength(1));

      provider.addToCart(product);
      expect(provider.isWishlisted(product), isFalse);
      expect(provider.cartItems, hasLength(1));

      provider.addToCart(product);
      expect(provider.cartItems.single.quantity, 2);

      provider.clearCart();
      expect(provider.cartItems, isEmpty);
    });
  });

  group('supplier models', () {
    test('profile is unverified until the backend says otherwise', () {
      final s = SupplierDetail.fromJson({
        'id': 's1',
        'businessName': 'Rwanda Fresh',
      });
      expect(s.display, 'Rwanda Fresh');
      expect(s.isVerified, isFalse);
      expect(s.isPending, isFalse);
      // No verification state and no account status reported yet.
      expect(s.effectiveStatus, 'UNVERIFIED');
    });

    test('verified suppliers report verified regardless of account status', () {
      final s = SupplierDetail.fromJson({
        'id': 's1',
        'status': 'ACTIVE',
        'verificationStatus': 'VERIFIED',
      });
      expect(s.isVerified, isTrue);
      expect(s.effectiveStatus, 'VERIFIED');
    });

    test('a supplier without a profile is reported as not onboarded', () {
      final s = SupplierDetail.fromJson({'id': 's1'});
      expect(s.isOnboarded, isFalse);
      expect(s.display, 'Unnamed supplier');
    });

    test('stock quantity drives the availability label', () {
      SupplierProduct at(int stock, {int? moq}) => SupplierProduct.fromJson({
        'id': 'p1',
        'name': 'Coffee',
        'stockQuantity': stock,
        if (moq != null) 'moq': moq,
      });

      expect(at(0).isOutOfStock, isTrue);
      expect(at(0).stockStatus, 'Out of Stock');
      // Low stock is derived from the MOQ: fewer units left than one order needs.
      expect(at(3, moq: 5).isLowStock, isTrue);
      expect(at(50, moq: 5).stockStatus, 'In Stock');
    });

    test('metrics are derived from the catalogue', () {
      final m = SupplierMetrics.fromCatalog([
        SupplierProduct.fromJson({
          'id': 'p1',
          'name': 'Coffee',
          'status': 'ACTIVE',
          'stockQuantity': 10,
          'wholesalePrice': 1000,
        }),
        SupplierProduct.fromJson({
          'id': 'p2',
          'name': 'Sugar',
          'stockQuantity': 0,
        }),
        SupplierProduct.fromJson({
          'id': 'p3',
          'name': 'Archived thing',
          'status': 'ARCHIVED',
          'stockQuantity': 4,
          'wholesalePrice': 500,
        }),
      ]);

      expect(m.totalProducts, 3);
      expect(m.activeProducts, 1);
      expect(m.outOfStockProducts, 1);
      // Archived products are skipped entirely by `fromCatalog`.
      expect(m.totalUnitsInStock, 10);
      expect(m.totalCatalogValue, 10000);
    });

    test('bulk discount is applied to the effective unit price', () {
      final p = SupplierProduct.fromJson({
        'id': 'p1',
        'name': 'Coffee',
        'wholesalePrice': 1000,
        'bulkDiscount': 25,
      });
      expect(p.effectivePrice, 750);
    });
  });

  group('supplier portal routing', () {
    testWidgets('a supplier lands on the supplier dashboard shell', (
      tester,
    ) async {
      await _pumpDashboard(tester, 'supplier');

      expect(find.byType(SupplierShell), findsOneWidget);
      expect(find.text('SUPPLIER PLATFORM'), findsOneWidget);
      expect(find.text('Supplier dashboard'), findsOneWidget);
      // The topbar is search-driven; the brand sits in the sidebar, which
      // only builds above the 900pt breakpoint.
      expect(find.widgetWithText(TextField, 'Search…'), findsOneWidget);
    });

    testWidgets('a buyer is kept out of the supplier portal', (tester) async {
      await _pumpSignedIn(tester, 'buyer');

      expect(find.byType(SupplierShell), findsNothing);
      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });
  });

  // Regression cover for the "Supplier profile not found. Please complete
  // onboarding." error that surfaced on every supplier action. `ApiClient`'s
  // error interceptor rejects with a *DioException* carrying the real
  // ApiException in `error`, so `on ApiException` never matched and the
  // not-yet-onboarded 404 escaped as a hard error instead of an empty profile.
  group('api error status extraction', () {
    DioException intercepted(int status, String message) => DioException(
      requestOptions: RequestOptions(path: '/suppliers/me/profile'),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/suppliers/me/profile'),
        statusCode: status,
        data: <String, dynamic>{'message': message},
      ),
      type: DioExceptionType.badResponse,
      error: ApiException(message, statusCode: status),
    );

    test('reads the status from a bare ApiException', () {
      expect(statusCodeOf(ApiException('nope', statusCode: 404)), 404);
    });

    test('reads the status from the interceptor-wrapped DioException', () {
      // This is the exact shape the interceptor rejects with.
      expect(statusCodeOf(intercepted(404, 'not onboarded')), 404);
    });

    test('a 404 is distinguishable from a real failure', () {
      expect(statusCodeOf(intercepted(500, 'boom')), 500);
      expect(statusCodeOf(intercepted(404, 'not onboarded')), 404);
    });

    test('a network failure has no status', () {
      expect(
        statusCodeOf(
          DioException(
            requestOptions: RequestOptions(path: '/suppliers/me/profile'),
            type: DioExceptionType.connectionError,
          ),
        ),
        isNull,
      );
    });
  });
}
