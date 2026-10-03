import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/nav_items.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../features/supplier/data/supplier_workspace.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/mv_icon.dart';

/// Supplier portal layout, mirroring the web app's `DashboardLayout`.
///
/// At >= 900pt the fixed 250pt sidebar is permanent, exactly as
/// `DashboardLayout.jsx` does with `.dashboard-sidebar`. Below that the
/// sidebar collapses into a drawer and the four primary destinations move to
/// the bottom bar with a "More" sheet behind them — the same 900px gate
/// `MobileBottomNav.jsx` uses. The bottom bar is only ever constructed on a
/// narrow viewport, so a tablet can never render the whole link list inline.
class SupplierShell extends ConsumerStatefulWidget {
  const SupplierShell({super.key, required this.path, required this.child});

  /// The active route, used to highlight the nav and auto-open its group.
  final String path;

  final Widget child;

  @override
  ConsumerState<SupplierShell> createState() => _SupplierShellState();
}

class _SupplierShellState extends ConsumerState<SupplierShell> {
  final _drawerKey = GlobalKey<ScaffoldState>();
  final _search = TextEditingController();
  String? _openGroup;

  static const wideBreakpoint = 900.0;

  @override
  void initState() {
    super.initState();
    _openGroup = SupplierNav.groupFor(widget.path) ?? SupplierNav.groups.first.label;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final group = SupplierNav.groupFor(widget.path);
    if (group != null && _openGroup != group) _openGroup = group;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Unread supplier notices, surfaced on the bell and in the "More" sheet.
  int get _unread =>
      ref.watch(supplierWorkspaceProvider).valueOrNull?.notifications
          .where((notice) => !notice.read)
          .length ??
      0;

  void _toggleGroup(String label) =>
      setState(() => _openGroup = _openGroup == label ? null : label);

  void _goSearch(String text) {
    if (text.trim().isEmpty) return;
    context.go('/supplier/search');
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    final user = ref.watch(currentUserProvider);
    final name = user?.display ?? 'Supplier';

    final content = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isWide ? 28 : 14,
        isWide ? 28 : 18,
        isWide ? 28 : 14,
        isWide ? 28 : 24,
      ),
      child: widget.child,
    );

    final topBar = SupplierTopBar(
      name: name,
      isWide: isWide,
      unread: _unread,
      search: _search,
      onOpenDrawer: () => _drawerKey.currentState?.openDrawer(),
      onSearch: _goSearch,
      onToggleTheme: () => ref.read(themeModeProvider.notifier).toggle(),
    );

    if (isWide) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Row(
          children: [
            SizedBox(
              width: 250,
              child: SupplierSidebar(
                name: name,
                path: widget.path,
                openGroup: _openGroup,
                onToggleGroup: _toggleGroup,
                onSignOut: _signOut,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  topBar,
                  Expanded(child: content),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      key: _drawerKey,
      drawer: SupplierDrawer(
        name: name,
        path: widget.path,
        openGroup: _openGroup,
        onToggleGroup: _toggleGroup,
        onSignOut: _signOut,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          topBar,
          Expanded(child: content),
          SupplierBottomBar(
            path: widget.path,
            onMore: () => _openMoreSheet(context),
          ),
        ],
      ),
    );
  }

  /// The web's `mbn-sheet`: a bottom-sheet grid holding every nav item that is
  /// not one of the four primary bottom-bar destinations.
  void _openMoreSheet(BuildContext context) {
    final primary = SupplierNav.bottomNav.map((item) => item.path).toSet();
    final overflow = SupplierNav.all
        .where((item) => !primary.contains(item.path))
        .toList(growable: false);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(top: 6, bottom: 14),
              decoration: BoxDecoration(
                color: context.mv.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'More',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .3,
                    color: context.mv.text,
                  ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 8,
                        childAspectRatio: .74,
                      ),
                  itemCount: overflow.length,
                  itemBuilder: (_, index) {
                    final item = overflow[index];
                    return _MoreTile(
                      item: item,
                      active: widget.path == item.path,
                      badge: item.path == '/supplier/notifications' ? _unread : 0,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context.go(item.path);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.item,
    required this.active,
    required this.badge,
    required this.onTap,
  });

  final NavItem item;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg =
        active
            ? context.mv.text
            : (context.isDarkMode ? MvColors.darkMuted : const Color(0xFF5B6A71));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: active ? null : context.mv.surfaceMuted,
                    gradient: active ? MvColors.gradient : null,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: MvIcon(
                    item.icon,
                    size: 22,
                    color: active ? Colors.white : context.mv.accentDeep,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: SupplierBadge(badge),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              item.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: fg,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared chrome for the supplier portal: the permanent sidebar, its narrow
/// drawer twin, the top bar and the bottom navigation. Sizes, colours and
/// spacing are lifted from the web app's `styles.css` dashboard rules
/// (`.dashboard-sidebar`, `.dash-header`, `.admin-grouped-nav`,
/// `.mobile-bottom-nav`) so both surfaces read as the same product.

/// The MVEC wordmark plus the portal label, shown at the top of both the
/// sidebar and the drawer.
class _Brand extends StatelessWidget {
  const _Brand({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback:
              (bounds) => MvColors.gradient.createShader(bounds),
          child: Text(
            'MVEC',
            style: GoogleFonts.manrope(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
            color: context.mv.textMuted,
          ),
        ),
      ],
    );
  }
}

/// The account block: avatar, display name and the "Supplier account" caption.
class _Account extends StatelessWidget {
  const _Account(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _MiniAvatar(name, size: 40, fontSize: 14),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              'Supplier account',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: context.mv.textMuted),
            ),
          ],
        ),
      ),
    ],
  );
}

/// One collapsible nav group (`.nav-group`).
class _NavGroup extends StatelessWidget {
  const _NavGroup({
    required this.group,
    required this.path,
    required this.openGroup,
    required this.onToggle,
    required this.onNavigate,
  });

  final NavGroup group;
  final String path;
  final String? openGroup;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final isOpen = openGroup == group.label;
    final hasActive = group.items.any((item) => _isActive(path, item.path));
    final fg =
        hasActive
            ? context.mv.accentDeep
            : context.isDarkMode
            ? const Color(0xFFB9CBD3)
            : const Color(0xFF4C5A62);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onToggle(group.label),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .4,
                        color: fg,
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: (isOpen ? 1 : 0) * 3.141592653589793 / 2,
                    child: MvIcon('arrow', size: 14, color: fg),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isOpen)
          for (final item in group.items)
            _NavLink(
              item: item,
              active: _isActive(path, item.path),
              onTap: () => onNavigate(item.path),
            ),
      ],
    );
  }
}

/// One nav destination (`.dashboard-sidebar nav a`).
class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg =
        active
            ? context.mv.accentDeep
            : context.isDarkMode
            ? MvColors.darkMuted
            : const Color(0xFF6B7780);
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 1),
      child: Material(
        color:
            active
                ? (context.isDarkMode ? MvColors.darkSurface2 : MvColors.metricIconBg)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                MvIcon(item.icon, size: 16, color: fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "View marketplace" / "Sign out" footer (`.dash-bottom`).
class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({
    required this.onMarketplace,
    required this.onSignOut,
  });

  final VoidCallback onMarketplace;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(color: context.mv.border, height: 1),
          const SizedBox(height: 8),
          _FooterLink(
            label: 'View marketplace',
            icon: 'home',
            onTap: onMarketplace,
          ),
          _FooterLink(
            label: 'Sign out',
            icon: 'logout',
            onTap: onSignOut,
            danger: true,
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final String icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg =
        danger
            ? MvColors.dangerIcon
            : (context.isDarkMode ? MvColors.darkMuted : const Color(0xFF6B7780));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              MvIcon(icon, size: 16, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Unread counter badge used on the bell and the Notifications nav entry.
class SupplierBadge extends StatelessWidget {
  const SupplierBadge(this.count, {super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      height: 16,
      constraints: const BoxConstraints(minWidth: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: MvColors.badgeRed,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

bool _isActive(String path, String target) =>
    path == target || (path.startsWith(target) && target != '/supplier');

/// The fixed 250pt sidebar shown on wide viewports, matching the web's
/// permanent `.dashboard-sidebar`. Like the web, the unread count lives only
/// on the header bell — the nav itself carries no badges.
class SupplierSidebar extends StatelessWidget {
  const SupplierSidebar({
    super.key,
    required this.name,
    required this.path,
    required this.openGroup,
    required this.onToggleGroup,
    required this.onSignOut,
  });

  final String name;
  final String path;
  final String? openGroup;
  final ValueChanged<String> onToggleGroup;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.mv.surface,
        border: Border(right: BorderSide(color: context.mv.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Brand(label: 'SUPPLIER PLATFORM'),
                  const SizedBox(height: 18),
                  _Account(name),
                  Divider(color: context.mv.border, height: 26),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                children: [
                  for (final group in SupplierNav.groups)
                    _NavGroup(
                      group: group,
                      path: path,
                      openGroup: openGroup,
                      onToggle: onToggleGroup,
                      onNavigate: (target) => context.go(target),
                    ),
                ],
              ),
            ),
            _SidebarFooter(
              onMarketplace: () => context.go('/home'),
              onSignOut: onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}

/// The narrow-viewport drawer: the same content as [SupplierSidebar], presented
/// off-canvas behind the top bar's menu button.
class SupplierDrawer extends StatelessWidget {
  const SupplierDrawer({
    super.key,
    required this.name,
    required this.path,
    required this.openGroup,
    required this.onToggleGroup,
    required this.onSignOut,
  });

  final String name;
  final String path;
  final String? openGroup;
  final ValueChanged<String> onToggleGroup;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 270,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Brand(label: 'SUPPLIER PLATFORM'),
                  const SizedBox(height: 18),
                  _Account(name),
                  Divider(color: context.mv.border, height: 26),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                children: [
                  for (final group in SupplierNav.groups)
                    _NavGroup(
                      group: group,
                      path: path,
                      openGroup: openGroup,
                      onToggle: onToggleGroup,
                      onNavigate: (target) {
                        Navigator.pop(context);
                        context.go(target);
                      },
                    ),
                ],
              ),
            ),
            _SidebarFooter(
              onMarketplace: () {
                Navigator.pop(context);
                // '/': '/' resolves through roleHome(), which would bounce a
                // supplier straight back to '/supplier'.
                context.go('/home');
              },
              onSignOut: onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sticky header: menu button (narrow only), search, theme toggle,
/// notifications bell with its unread badge, and the account avatar — the same
/// contents as the web's `.dash-header`.
class SupplierTopBar extends StatelessWidget {
  const SupplierTopBar({
    super.key,
    required this.name,
    required this.isWide,
    required this.unread,
    required this.search,
    required this.onOpenDrawer,
    required this.onSearch,
    required this.onToggleTheme,
  });

  final String name;
  final bool isWide;
  final int unread;
  final TextEditingController search;
  final VoidCallback onOpenDrawer;
  final ValueChanged<String> onSearch;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final ink = context.mv.text;
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.mv.surface,
        border: Border(bottom: BorderSide(color: context.mv.border)),
      ),
      child: Row(
        children: [
          if (!isWide)
            IconButton(
              onPressed: onOpenDrawer,
              icon: MvIcon('menu', color: ink),
              tooltip: 'Open supplier navigation',
            ),
          Expanded(
            child: Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                color: context.mv.surfaceMuted,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: context.mv.border),
              ),
              child: Row(
                children: [
                  MvIcon('search', size: 16, color: context.mv.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: search,
                      onSubmitted: onSearch,
                      style: TextStyle(fontSize: 13, color: ink),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search…',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: context.mv.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onToggleTheme,
            icon: MvIcon(context.isDarkMode ? 'sun' : 'moon', color: ink),
            tooltip: 'Toggle theme',
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => context.go('/supplier/notifications'),
                icon: MvIcon('bell', color: ink),
                tooltip: 'Notifications',
              ),
              if (unread > 0)
                Positioned(top: 4, right: 4, child: SupplierBadge(unread)),
            ],
          ),
          InkWell(
            onTap: () => context.go('/supplier/settings'),
            borderRadius: BorderRadius.circular(17),
            child: _MiniAvatar(name),
          ),
        ],
      ),
    );
  }
}

/// Gradient avatar showing the account initials.
class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar(this.name, {this.size = 34, this.fontSize = 12});

  final String name;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      gradient: MvColors.gradient,
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Text(
      initials(name),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
    ),
  );
}

/// Narrow-viewport bottom bar: the four primary destinations plus "More"
/// (`.mobile-bottom-nav`). Active state is a colour change, not a filled pill,
/// matching the web.
class SupplierBottomBar extends StatelessWidget {
  const SupplierBottomBar({
    super.key,
    required this.path,
    required this.onMore,
  });

  final String path;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final idle = context.isDarkMode ? MvColors.darkMuted : const Color(0xFF7C8990);
    return Container(
      decoration: BoxDecoration(
        color: context.mv.surface,
        border: Border(top: BorderSide(color: context.mv.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          child: Row(
            children: [
              for (final item in SupplierNav.bottomNav)
                Expanded(
                  child: _BottomItem(
                    item: item,
                    active: path == item.path,
                    idleColor: idle,
                  ),
                ),
              Expanded(
                child: _BottomMore(
                  onTap: onMore,
                  idleColor: idle,
                  active: !SupplierNav.bottomNav.any(
                    (item) => item.path == path,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.item,
    required this.active,
    required this.idleColor,
  });

  final NavItem item;
  final bool active;
  final Color idleColor;

  @override
  Widget build(BuildContext context) {
    final fg = active ? context.mv.accentDeep : idleColor;
    return InkWell(
      onTap: () => context.go(item.path),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MvIcon(item.icon, size: 21, color: fg),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomMore extends StatelessWidget {
  const _BottomMore({
    required this.onTap,
    required this.idleColor,
    required this.active,
  });

  final VoidCallback onTap;
  final Color idleColor;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final fg = active ? context.mv.accentDeep : idleColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MvIcon('grid', size: 21, color: fg),
            const SizedBox(height: 3),
            Text(
              'More',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small status pill with an explicit label (the shared `StatusChip`
/// title-cases the raw status, which reads badly for verification states).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, required this.label});

  final String? status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final fg = statusColor(status ?? 'UNKNOWN');
    final bg = fg == MvColors.successText
        ? MvColors.successBg
        : fg == MvColors.warningText
            ? MvColors.warningBg
            : fg == MvColors.errorText
                ? MvColors.errorBg
                : MvColors.neutralBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: fg, letterSpacing: .3)),
    );
  }
}
