import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/nav_items.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../widgets/mv_icon.dart';
import '../../affiliate_nav.dart';
import '../providers/affiliate_providers.dart';

/// Mirrors the frontend `DashboardLayout` for the affiliate role: topbar with
/// search/theme/notifications/avatar, a grouped drawer and a mobile bottom
/// bar carrying the four primary items + "More".
///
/// When the backing service is in demo mode (backend unreachable), a slim
/// banner under the topbar tells the tester the data is bundled.
class AffiliateShell extends ConsumerStatefulWidget {
  const AffiliateShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;

  @override
  ConsumerState<AffiliateShell> createState() => _AffiliateShellState();
}

class _AffiliateShellState extends ConsumerState<AffiliateShell> {
  final _drawerKey = GlobalKey<ScaffoldState>();
  String? _openGroup;

  @override
  void initState() {
    super.initState();
    _openGroup = AffiliateNav.groupFor(widget.path) ?? AffiliateNav.groups.first.label;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final g = AffiliateNav.groupFor(widget.path);
    if (g != null && _openGroup != g) _openGroup = g;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final name = user?.display ?? 'Affiliate';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: _drawerKey,
      drawer: _buildDrawer(name, user?.email ?? ''),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildTopbar(name),
          if (ref.watch(affiliateDemoModeProvider)) _buildDemoBanner(isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
              child: widget.child,
            ),
          ),
          _buildBottomNav(name),
        ],
      ),
    );
  }

  Widget _buildDemoBanner(bool isDark) {
    final reason = ref.watch(affiliateDemoReasonProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: isDark ? MvColors.darkSurface2 : MvColors.infoBoxBg,
      child: Row(
        children: [
          const MvIcon('shield', size: 14, color: MvColors.primaryDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason ?? 'Showing bundled demo data while the affiliate API is unreachable.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? MvColors.darkMuted : MvColors.infoBoxText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TOP BAR ────────────────────────────────────────────────────────────
  Widget _buildTopbar(String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? MvColors.darkText : MvColors.ink;
    final unread = ref.watch(affiliateNotificationsProvider).valueOrNull?.where((n) => !n.isRead).length ?? 0;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? MvColors.darkSurface : Colors.white,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _drawerKey.currentState?.openDrawer(),
            icon: MvIcon('menu', color: ink),
            tooltip: 'Menu',
          ),
          Expanded(
            child: Container(
              height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? MvColors.darkSurface2 : const Color(0xFFF7FAFB),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: isDark ? MvColors.darkBorder : const Color(0xFFE0E5E8)),
              ),
              child: Row(
                children: [
                  MvIcon('search', size: 16, color: isDark ? MvColors.darkMuted : const Color(0xFF9AA5AA)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Promote, track, earn',
                      style: TextStyle(fontSize: 12.5, color: isDark ? MvColors.darkMuted : const Color(0xFF9AA5AA)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: MvIcon(isDark ? 'sun' : 'moon', color: ink),
            tooltip: 'Toggle theme',
          ),
          IconButton(
            onPressed: () => context.go('/affiliate/notifications'),
            tooltip: 'Notifications',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                MvIcon('bell', color: ink),
                if (unread > 0)
                  Positioned(
                    top: -3,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      height: 16,
                      constraints: const BoxConstraints(minWidth: 16),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: MvColors.badgeRed, borderRadius: BorderRadius.all(Radius.circular(9))),
                      child: Text('$unread', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
          InkWell(
            onTap: () => context.go('/affiliate/profile'),
            borderRadius: BorderRadius.circular(17),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(gradient: MvColors.gradient, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(initials(name), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── DRAWER (grouped accordion) ─────────────────────────────────────────
  Widget _buildDrawer(String name, String email) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? MvColors.darkMuted : const Color(0xFF8A969C);
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'MVEC',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Manrope',
                          foreground: Paint()
                            ..shader = MvColors.gradient.createShader(const Rect.fromLTWH(0, 0, 120, 30)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'AFFILIATE PLATFORM',
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 1.3, color: MvColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(gradient: MvColors.gradient, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text(initials(name), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 3),
                            Text('Affiliate account', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(color: Theme.of(context).dividerColor, height: 26),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                children: [
                  for (final group in AffiliateNav.groups) _group(group, isDark),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Divider(color: Theme.of(context).dividerColor, height: 1),
                  const SizedBox(height: 8),
                  _bottomLink('View marketplace', 'home', () {
                    Navigator.pop(context);
                    context.go('/home');
                  }),
                  _bottomLink('Sign out', 'logout', () async {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (mounted) context.go('/login');
                  }, danger: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(NavGroup group, bool isDark) {
    final open = _openGroup == group.label;
    final hasActive = group.items.any((i) => _isActive(i.path));
    final fg = hasActive
        ? MvColors.primaryDeep
        : (isDark ? const Color(0xFFB9CBD3) : const Color(0xFF4C5A62));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _openGroup = open ? null : group.label),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.label.toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4, color: fg),
                    ),
                  ),
                  MvIcon('arrow', size: 14, color: fg) //
                      .rotate(open ? 90 : 0),
                ],
              ),
            ),
          ),
        ),
        if (open)
          for (final item in group.items)
            _item(item, isDark, indent: true),
      ],
    );
  }

  Widget _item(NavItem item, bool isDark, {bool indent = false}) {
    final active = _isActive(item.path);
    final fg = active
        ? MvColors.primaryDeep
        : (isDark ? MvColors.darkMuted : const Color(0xFF6B7780));
    return Padding(
      padding: EdgeInsets.fromLTRB(indent ? 12 : 0, 0, 0, 1),
      child: Material(
        color: active ? (isDark ? MvColors.darkSurface2 : MvColors.metricIconBg) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.pop(context);
            context.go(item.path);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                MvIcon(item.icon, size: 16, color: fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomLink(String label, String icon, VoidCallback onTap, {bool danger = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = danger ? MvColors.dangerIcon : (isDark ? MvColors.darkMuted : const Color(0xFF6B7780));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                MvIcon(icon, size: 16, color: fg),
                const SizedBox(width: 12),
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── MOBILE BOTTOM NAV ──────────────────────────────────────────────────
  Widget _buildBottomNav(String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? MvColors.darkSurface : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final item in AffiliateNav.bottomNav)
              Expanded(child: _bottomItem(item, isDark)),
            Expanded(
              child: InkWell(
                onTap: () => _drawerKey.currentState?.openDrawer(),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MvIcon('menu', size: 18, color: isDark ? MvColors.darkMuted : const Color(0xFF6B7780)),
                      const SizedBox(height: 3),
                      Text('More', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: isDark ? MvColors.darkMuted : const Color(0xFF6B7780))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomItem(NavItem item, bool isDark) {
    final active = _isActive(item.path);
    final fg = active
        ? MvColors.primaryDeep
        : (isDark ? MvColors.darkMuted : const Color(0xFF6B7780));
    return InkWell(
      onTap: () => context.go(item.path),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MvIcon(item.icon, size: 18, color: fg),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(fontSize: 9.5, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: fg),
            ),
          ],
        ),
      ),
    );
  }

  bool _isActive(String path) => widget.path == path || (widget.path.startsWith(path) && path != '/affiliate');
}

extension _RotateX on Widget {
  Widget rotate(double deg) => Transform.rotate(angle: deg * 3.141592653589793 / 180, child: this);
}