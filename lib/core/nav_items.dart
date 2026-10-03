class NavItem {
  const NavItem(this.label, this.path, this.icon);
  final String label;
  final String path;
  final String icon;
}

class NavGroup {
  const NavGroup(this.label, this.items);
  final String label;
  final List<NavItem> items;
}

/// Full admin navigation. Groups mirror the frontend `adminNavGroups`
/// (accordion sidebar), plus the two dedicated management features
/// (Buyers, Account) the admin console requires.
class AdminNav {
  AdminNav._();

  static const groups = <NavGroup>[
    NavGroup('Overview', [NavItem('Overview', '/admin', 'grid')]),
    NavGroup('Insights', [
      NavItem('Analytics', '/admin/analytics', 'chart'),
      NavItem('Reports', '/admin/reports', 'chart'),
      NavItem('Recommendations', '/admin/recommendations', 'chart'),
      NavItem('Supplier Matching', '/admin/matching', 'users'),
      NavItem('Trust Scores', '/admin/trust', 'chart'),
      NavItem('Reviews', '/admin/reviews', 'chart'),
    ]),
    NavGroup('People & Stores', [
      NavItem('Users', '/admin/users', 'users'),
      NavItem('Vendors', '/admin/vendors', 'shop'),
      NavItem('Suppliers', '/admin/suppliers', 'shop'),
      NavItem('Affiliates', '/admin/affiliates', 'users'),
      NavItem('Buyers', '/admin/buyers', 'users'),
      NavItem('Supplier Acquisition', '/admin/supplier-acquisition', 'users'),
      NavItem('Vendor Acquisition', '/admin/vendor-acquisition', 'users'),
    ]),
    NavGroup('Catalog', [
      NavItem('Products', '/admin/products', 'box'),
      NavItem('Categories', '/admin/categories', 'tag'),
    ]),
    NavGroup('Orders & Payments', [
      NavItem('Orders', '/admin/orders', 'cart'),
      NavItem('Payments', '/admin/payments', 'wallet'),
      NavItem('Transactions', '/admin/transactions', 'wallet'),
      NavItem('Commissions', '/admin/commissions', 'wallet'),
      NavItem('Commission Rules', '/admin/commission-rules', 'wallet'),
      NavItem('Financial Ledger', '/admin/ledger', 'wallet'),
      NavItem('Deliveries', '/admin/deliveries', 'box'),
      NavItem('Refunds', '/admin/refunds', 'wallet'),
      NavItem('Disputes', '/admin/disputes', 'bell'),
    ]),
    NavGroup('Growth', [
      NavItem('Advertising', '/admin/advertising', 'tag'),
      NavItem('Subscriptions', '/admin/subscriptions', 'wallet'),
    ]),
    NavGroup('Platform', [
      NavItem('Languages', '/admin/languages', 'grid'),
      NavItem('Locations', '/admin/locations', 'shop'),
      NavItem('Audit Logs', '/admin/audit-logs', 'box'),
      NavItem('Security', '/admin/security', 'settings'),
      NavItem('System Administration', '/admin/system', 'settings'),
      NavItem('Settings', '/admin/settings', 'settings'),
      NavItem('Fraud & Risk', '/admin/risk', 'bell'),
      NavItem('Account', '/admin/account', 'user'),
    ]),
    NavGroup('Communication', [
      NavItem('Messages', '/admin/messages', 'users'),
      NavItem('Notifications', '/admin/notifications', 'bell'),
      NavItem('MVEC Support', '/admin/support', 'bell'),
    ]),
  ];

  static List<NavItem> get all => [for (final g in groups) ...g.items];

  /// Primary items shown directly in the mobile bottom bar (frontend
  /// `mobilePrimaryByRole.super_admin`) + a "More" entry that opens the
  /// grouped drawer.
  static const bottomNav = <NavItem>[
    NavItem('Overview', '/admin', 'grid'),
    NavItem('Vendors', '/admin/vendors', 'shop'),
    NavItem('Orders', '/admin/orders', 'cart'),
    NavItem('Ledger', '/admin/ledger', 'wallet'),
  ];

  /// Find the group containing a path (used to auto-open the drawer group).
  static String? groupFor(String path) {
    for (final g in groups) {
      if (g.items.any(
        (i) =>
            i.path == path || (path.startsWith(i.path) && i.path != '/admin'),
      )) {
        return g.label;
      }
    }
    return null;
  }
}

/// Supplier portal navigation.
///
/// Mirrors the web app's `supplierNavGroups` in `src/data/navItems.jsx`
/// group-for-group and item-for-item, so the mobile portal presents the same
/// information architecture as the website. Every path stays under `/supplier`
/// so the supplier-only guard in `router.dart` applies.
class SupplierNav {
  SupplierNav._();

  static const groups = <NavGroup>[
    NavGroup('Overview', [
      NavItem('Dashboard', '/supplier', 'grid'),
    ]),
    NavGroup('Catalog & Orders', [
      NavItem('Wholesale Products', '/supplier/products', 'box'),
      NavItem('Inventory', '/supplier/inventory', 'grid'),
      NavItem('Vendor Orders', '/supplier/orders', 'cart'),
      NavItem('Supply Requests', '/supplier/supply-requests', 'cart'),
      NavItem('Delivery & Settlement', '/supplier/delivery', 'box'),
    ]),
    NavGroup('Finance & Insights', [
      NavItem('Payments', '/supplier/payments', 'wallet'),
      NavItem('Transactions', '/supplier/transactions', 'wallet'),
      NavItem('Analytics', '/supplier/analytics', 'chart'),
      NavItem('Reports', '/supplier/reports', 'chart'),
      NavItem('Reviews', '/supplier/reviews', 'heart'),
    ]),
    NavGroup('Team & Settings', [
      NavItem('Team / Staff', '/supplier/team', 'users'),
      NavItem('Settings', '/supplier/settings', 'settings'),
    ]),
    NavGroup('Support', [
      NavItem('Messages', '/supplier/messages', 'users'),
      NavItem('Notifications', '/supplier/notifications', 'bell'),
      NavItem('MVEC Support', '/supplier/support', 'bell'),
    ]),
  ];

  static List<NavItem> get all => [for (final g in groups) ...g.items];

  /// The four primary items pinned to the mobile bottom bar, plus "More"
  /// (the drawer) — the same split the web uses in `MobileBottomNav.jsx`.
  static const bottomNav = <NavItem>[
    NavItem('Dashboard', '/supplier', 'grid'),
    NavItem('Products', '/supplier/products', 'box'),
    NavItem('Orders', '/supplier/orders', 'cart'),
    NavItem('Payments', '/supplier/payments', 'wallet'),
  ];

  /// Find the group containing a path (used to auto-open the drawer group).
  static String? groupFor(String path) {
    for (final g in groups) {
      if (g.items.any((i) => i.path == path || (path.startsWith(i.path) && i.path != '/supplier'))) {
        return g.label;
      }
    }
    return null;
  }
}

/// Vendor portal navigation.
///
/// Same shape as [AdminNav] (accordion groups + mobile bottom bar) so the
/// vendor shell can be a drop-in mirror of the admin shell, with every path
/// rooted at `/vendor`.
class VendorNav {
  VendorNav._();

  static const root = '/vendor';

  static const groups = <NavGroup>[
    NavGroup('Overview', [NavItem('Overview', '/vendor', 'grid')]),
    NavGroup('Orders & earnings', [
      NavItem('Orders', '/vendor/orders', 'cart'),
      NavItem('Sales & earnings', '/vendor/sales', 'wallet'),
    ]),
    NavGroup('Store', [
      NavItem('Products', '/vendor/products', 'box'),
      NavItem('Store Profile', '/vendor/profile', 'user'),
      NavItem('Account settings', '/vendor/settings', 'settings'),
    ]),
    NavGroup('Communication', [
      NavItem('Notifications', '/vendor/notifications', 'bell'),
    ]),
  ];

  static List<NavItem> get all => [for (final g in groups) ...g.items];

  /// Primary items for the mobile bottom bar, plus a "More" entry that opens
  /// the grouped drawer (added by the shell).
  static const bottomNav = <NavItem>[
    NavItem('Overview', '/vendor', 'grid'),
    NavItem('Orders', '/vendor/orders', 'cart'),
    NavItem('Sales', '/vendor/sales', 'wallet'),
    NavItem('Settings', '/vendor/settings', 'settings'),
  ];

  /// The drawer group containing a path, used to auto-open the right accordion.
  static String? groupFor(String path) {
    for (final g in groups) {
      if (g.items.any(
        (i) => i.path == path || (path.startsWith(i.path) && i.path != root),
      )) {
        return g.label;
      }
    }
    return null;
  }
}
