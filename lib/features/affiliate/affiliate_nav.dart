import '../../core/nav_items.dart';

/// Affiliate navigation mirroring the web frontend's `affiliateNavGroups`
/// plus the extra Statistics and Settings routes the mobile module ships.
class AffiliateNav {
  AffiliateNav._();

  static const groups = <NavGroup>[
    NavGroup('Overview', [
      NavItem('Dashboard', '/affiliate', 'grid'),
    ]),
    NavGroup('Promotion', [
      NavItem('Promote Products', '/affiliate/products', 'box'),
      NavItem('Campaigns', '/affiliate/campaigns', 'tag'),
      NavItem('My Links', '/affiliate/links', 'tag'),
    ]),
    NavGroup('Performance', [
      NavItem('Statistics', '/affiliate/stats', 'chart'),
    ]),
    NavGroup('Earnings', [
      NavItem('Earnings', '/affiliate/earnings', 'wallet'),
      NavItem('Withdrawals', '/affiliate/payouts', 'wallet'),
    ]),
    NavGroup('Account', [
      NavItem('Profile', '/affiliate/profile', 'user'),
      NavItem('Notifications', '/affiliate/notifications', 'bell'),
      NavItem('Settings', '/affiliate/settings', 'settings'),
    ]),
  ];

  static List<NavItem> get all => [for (final g in groups) ...g.items];

  /// Primary items shown directly in the mobile bottom bar, matching the
  /// frontend `mobilePrimaryByRole.affiliate` + a "More" entry.
  static const bottomNav = <NavItem>[
    NavItem('Dashboard', '/affiliate', 'grid'),
    NavItem('Links', '/affiliate/links', 'tag'),
    NavItem('Earnings', '/affiliate/earnings', 'wallet'),
    NavItem('Withdrawals', '/affiliate/payouts', 'wallet'),
  ];

  /// Group label owning a path (used to auto-open the drawer group).
  static String? groupFor(String path) {
    for (final g in groups) {
      if (g.items.any((i) => i.path == path || (path.startsWith(i.path) && i.path != '/affiliate'))) {
        return g.label;
      }
    }
    return null;
  }
}