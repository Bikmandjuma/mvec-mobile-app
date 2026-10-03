import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/app_theme.dart';
import '../../../../models/user.dart';
import '../../../../providers/auth_provider.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../providers/commerce_provider.dart';
import '../providers/home_provider.dart';
import 'categories_screen.dart';
import 'deals_screen.dart';
import 'for_you_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'product_navigation.dart';
import 'search_screen.dart';
import 'shop_screen.dart';
import 'vendors_screen.dart';

/// Root marketplace navigation container.
///
/// Floating bottom bar for the four primary tabs (Home, Shop, For You, Deals)
/// with the cart promoted to a raised centre action, plus a top bar carrying
/// back, search, wishlist, notifications, the dark-mode toggle and the account
/// menu. Everything that does not fit in the bottom bar — All Categories,
/// Vendors, Orders — moved behind the category bar's "More" sheet so nothing
/// from the storefront top-menu design is lost.
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

/// The four primary destinations, in bar order. Outlined glyphs only: the bar
/// sits on a white pill and filled icons read as heavier than the rest.
///
/// [_NavTab.slot] is the position the item occupies in the bottom bar, which is
/// not the same as its index — the cart action is wedged between Shop and
/// For You, so every tab from [2] onwards is shifted one slot to the right.
const List<_NavTab> _tabs = <_NavTab>[
  _NavTab('Home', Icons.home_outlined, slot: 0),
  _NavTab('Shop', Icons.grid_view_outlined, slot: 1),
  _NavTab('For You', Icons.pie_chart_outline_rounded, slot: 3),
  _NavTab('Deals', Icons.favorite_border_rounded, slot: 4),
];

/// Bottom-bar slot occupied by the raised cart action. Deliberately the middle
/// of the five slots so the checkout entry point is thumb-reachable.
const int _kCartSlot = 2;
const int _kSlotCount = 5;

@immutable
class _NavTab {
  const _NavTab(this.label, this.icon, {required this.slot});

  final String label;
  final IconData icon;
  final int slot;
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  Category? _selectedCategory;

  void _select(int index) => setState(() => _currentIndex = index);

  void _toggleTheme() => ref.read(themeModeProvider.notifier).toggle();

  void _selectCategory(Category? category) {
    setState(() {
      _selectedCategory = category;
      // Jump to the Shop tab so the filtered catalog shows instantly.
      _currentIndex = 1;
    });
  }

  void _openAllProducts() {
    setState(() {
      _selectedCategory = null;
      _currentIndex = 1;
    });
  }

  // ---------------------------------------------------------------------------
  // Full-page destinations.
  // ---------------------------------------------------------------------------

  void _pushPage(Widget child, {String? title}) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder:
            (routeContext) => Scaffold(
              backgroundColor: routeContext.mv.page,
              appBar: AppBar(title: Text(title ?? '')),
              body: SafeArea(child: child),
            ),
      ),
    );
  }

  void _openSearch([String query = '']) =>
      _pushPage(SearchScreen(initialQuery: query), title: 'Search');

  void _openVendors() => _pushPage(const VendorsScreen(), title: 'Vendors');

  void _openOrders() => _pushPage(const OrdersScreen(), title: 'My Orders');

  void _openCategories() {
    _pushPage(
      CategoriesScreen(
        onCategoryTap: (category) {
          _selectCategory(category);
          Navigator.of(context).pop();
        },
      ),
      title: 'All Categories',
    );
  }

  void _openWishlist(BuildContext context) =>
      openWishlist(context, context.read<CommerceProvider>());

  void _openCart(BuildContext context) =>
      openCart(context, context.read<CommerceProvider>());

  void _openMore() => _scaffoldKey.currentState?.openDrawer();

  Widget _buildMoreDrawer() {
    final isDark = context.isDarkMode;
    final mv = context.mv;
    return Drawer(
      backgroundColor: mv.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 16, 18),
              child: Row(
                children: <Widget>[
                  Icon(Icons.grid_view_outlined, color: mv.accentDeep),
                  const SizedBox(width: 12),
                  Text('More', style: AppTextStyles.title(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: <Widget>[
                  _MoreDrawerAction(
                    icon: Icons.grid_view_outlined,
                    label: 'All categories',
                    onTap: () {
                      Navigator.of(context).pop();
                      _openCategories();
                    },
                  ),
                  _MoreDrawerAction(
                    icon: Icons.store_mall_directory_outlined,
                    label: 'Vendors',
                    onTap: () {
                      Navigator.of(context).pop();
                      _openVendors();
                    },
                  ),
                  _MoreDrawerAction(
                    icon: Icons.receipt_long_outlined,
                    label: 'Orders & history',
                    onTap: () {
                      Navigator.of(context).pop();
                      _openOrders();
                    },
                  ),
                  _MoreDrawerAction(
                    icon: Icons.favorite_border,
                    label: 'My wishlist',
                    onTap: () {
                      Navigator.of(context).pop();
                      _openWishlist(context);
                    },
                  ),
                  _MoreDrawerAction(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    onTap: () {
                      Navigator.of(context).pop();
                      _openNotifications();
                    },
                  ),
                  _MoreDrawerAction(
                    icon: isDark ? Icons.light_mode : Icons.dark_mode,
                    label: isDark ? 'Light mode' : 'Dark mode',
                    onTap: () {
                      Navigator.of(context).pop();
                      _toggleTheme();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _MoreDrawerAction(
              icon: Icons.logout,
              label: 'Sign out',
              destructive: true,
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(authControllerProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Account sheet: identity, a shortcut to the dashboard for admins and sign out.
  // ---------------------------------------------------------------------------

  Future<void> _openProfile() async {
    final user = ref.read(currentUserProvider);
    final isDark = context.isDarkMode;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.mv.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder:
          (sheetContext) => _SheetScaffold(
            children: [
              _AccountHeader(user: user),
              const Divider(height: 26),
              if (user != null && user.userType == 'super_admin')
                _SheetAction(
                  icon: Icons.dashboard_outlined,
                  label: 'Go to dashboard',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).pop();
                  },
                ),
              _SheetAction(
                icon: Icons.shopping_bag_outlined,
                label: 'My orders',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openOrders();
                },
              ),
              _SheetAction(
                icon: Icons.favorite_border,
                label: 'My wishlist',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openWishlist(context);
                },
              ),
              _SheetAction(
                icon: isDark ? Icons.light_mode : Icons.dark_mode,
                label: isDark ? 'Light mode' : 'Dark mode',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _toggleTheme();
                },
              ),
              _SheetAction(
                icon: Icons.logout,
                label: 'Sign out',
                destructive: true,
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await ref.read(authControllerProvider.notifier).logout();
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildMoreDrawer(),
      backgroundColor: context.mv.page,

      body: SafeArea(
        child: Column(
          children: [
            _buildTopNavigation(context, provider.categories),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: <Widget>[
                  HomeScreen(
                    onBrowseAll: _openAllProducts,
                    onViewDeals: () => _select(3),
                    onCategoryTap: _selectCategory,
                  ),
                  ShopScreen(
                    key: ValueKey<int?>(_selectedCategory?.id),
                    initialCategory: _selectedCategory,
                  ),
                  const ForYouScreen(),
                  const DealsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFloatingBottomNav(),
    );
  }

  // ---------------------------------------------------------------------------
  // Top navigation: back, search context, wishlist/notifications badges, the
  // dark-mode toggle and the account menu. The cart deliberately lives in the
  // bottom bar now, not here.
  // ---------------------------------------------------------------------------

  Widget _buildTopNavigation(BuildContext context, List<Category> categories) {
    final commerce = context.watch<CommerceProvider>();

    return Container(
      color: context.mv.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 2, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Menu',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.menu, size: 22),
                  onPressed: _openMore,
                ),
                Expanded(
                  child: _SearchTrigger(
                    products: context.watch<HomeProvider>().products,
                    onSubmit: _openSearch,
                  ),
                ),
                _TopBarAction(
                  icon: Icons.favorite_border,
                  tooltip: 'Wishlist',
                  count: commerce.wishlistItems.length,
                  countKey: 'home-wishlist-count',
                  onPressed: () => _openWishlist(context),
                ),
                _TopBarAction(
                  icon: Icons.notifications_none_rounded,
                  tooltip: 'Notifications',
                  countKey: 'home-notifications-count',
                  onPressed: _openNotifications,
                ),
                _ThemeToggleButton(
                  isDark: context.isDarkMode,
                  onTap: _toggleTheme,
                ),
                IconButton(
                  tooltip: 'Account',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.person_outline),
                  onPressed: _openProfile,
                ),
              ],
            ),
          ),
          if (_currentIndex != 1) ...<Widget>[
            const SizedBox(height: 4),
            _CategoriesBar(
              key: const ValueKey<String>('category-bar'),
              categories: categories,
              selected: _selectedCategory,
              onSelected: _selectCategory,
            ),
          ],
          const Divider(height: 1),
        ],
      ),
    );
  }

  void _openNotifications() =>
      _pushPage(const _NotificationsPage(), title: 'Notifications');

  // ---------------------------------------------------------------------------
  // Floating bottom navigation bar: a rounded white pill that hovers clear of
  // the screen edge. Only the active tab's icon and label take the sky-blue
  // accent and a small sky-blue pill slides underneath it; the cart is promoted
  // to a raised centre action so checkout is always one tap away.
  // ---------------------------------------------------------------------------

  Widget _buildFloatingBottomNav() {
    final mv = context.mv;
    final commerce = context.watch<CommerceProvider>();
    final cartCount = commerce.cartItems.fold<int>(
      0,
      (count, item) => count + item.quantity,
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Container(
          key: const ValueKey<String>('bottom-nav-bar'),
          height: 68,
          decoration: BoxDecoration(
            color: mv.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: mv.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: mv.shadow,
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slotWidth = constraints.maxWidth / _kSlotCount;
              final activeSlot = _tabs[_currentIndex].slot;
              const indicatorWidth = 20.0;
              return Stack(
                // The raised cart action overhangs the pill's top edge, so the
                // stack must not clip it.
                clipBehavior: Clip.none,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      for (var slot = 0; slot < _kSlotCount; slot++)
                        slot == _kCartSlot
                            ? _buildCartAction(cartCount)
                            : _buildNavItem(slot),
                    ],
                  ),
                  // The indicator rides beneath the active tab.
                  AnimatedPositioned(
                    key: const ValueKey<String>('bottom-nav-indicator'),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    left:
                        slotWidth * activeSlot +
                        (slotWidth - indicatorWidth) / 2,
                    bottom: 6,
                    width: indicatorWidth,
                    height: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.skyBlueSolid,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Tab item for a bottom-bar slot. Slots with no tab return an empty box so
  /// the cart keeps its centred position.
  Widget _buildNavItem(int slot) {
    final index = _tabs.indexWhere((tab) => tab.slot == slot);
    if (index < 0) return const Expanded(child: SizedBox.shrink());
    final tab = _tabs[index];
    final selected = _currentIndex == index;
    final color = selected ? AppColors.skyBlueSolid : context.mv.textMuted;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: () => _select(index),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  scale: selected ? 1.1 : 1,
                  child: Icon(tab.icon, size: 22, color: color),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    color: color,
                  ),
                  child: Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Raised sky-blue cart action in the middle slot. It is an action rather than
  /// a tab — it opens the cart page and never takes the sliding indicator, so
  /// the pill count on it is the only always-visible cart affordance.
  Widget _buildCartAction(int cartCount) {
    return Expanded(
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, -12),
          child: Semantics(
            button: true,
            label: 'Cart',
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.skyBlueSolid.withValues(alpha: 0.36),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Badge(
                key: const ValueKey<String>('bottom-cart-badge'),
                isLabelVisible: cartCount > 0,
                backgroundColor: AppColors.error,
                textColor: Colors.white,
                label: Text(cartCount > 99 ? '99+' : '$cartCount'),
                child: Material(
                  color: AppColors.skyBlueSolid,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _openCart(context),
                    child: const SizedBox(
                      width: 52,
                      height: 52,
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search trigger shown in the top bar.
// ---------------------------------------------------------------------------

class _SearchTrigger extends StatefulWidget {
  const _SearchTrigger({required this.products, required this.onSubmit});

  final List<Product> products;
  final ValueChanged<String> onSubmit;

  @override
  State<_SearchTrigger> createState() => _SearchTriggerState();
}

class _SearchTriggerState extends State<_SearchTrigger> {
  final List<String> _recentSearches = <String>[
    'Wireless headphones',
    'Summer fashion',
  ];
  static const List<String> _trendingSearches = <String>[
    'Summer style',
    'Home essentials',
  ];

  Iterable<String> _options(TextEditingValue value) {
    final query = value.text.trim().toLowerCase();
    if (query.isEmpty) {
      return <String>[..._recentSearches, ..._trendingSearches];
    }
    return widget.products
        .where(
          (product) => <String>[
            product.name,
            product.brand ?? '',
            product.categoryName ?? '',
            product.vendorName ?? '',
          ].join(' ').toLowerCase().contains(query),
        )
        .map((product) => product.name)
        .toSet()
        .take(5);
  }

  void _submit(String value) {
    final term = value.trim();
    if (term.isEmpty) return;
    _recentSearches.remove(term);
    _recentSearches.insert(0, term);
    if (_recentSearches.length > 4) _recentSearches.removeLast();
    widget.onSubmit(term);
  }

  @override
  Widget build(BuildContext context) {
    final mv = context.mv;
    return RawAutocomplete<String>(
      optionsBuilder: _options,
      onSelected: _submit,
      optionsViewBuilder: (context, onSelected, options) {
        final optionList = options.toList();
        final recent = optionList.where(_recentSearches.contains).toList();
        final trending = optionList.where(_trendingSearches.contains).toList();
        final products =
            optionList
                .where(
                  (option) =>
                      !_recentSearches.contains(option) &&
                      !_trendingSearches.contains(option),
                )
                .toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: mv.surface,
            elevation: 10,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320, maxWidth: 300),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: <Widget>[
                  if (recent.isNotEmpty) ...<Widget>[
                    _suggestionHeading('Recent searches', mv.textMuted),
                    for (final option in recent)
                      _suggestionOption(option, onSelected),
                  ],
                  if (trending.isNotEmpty) ...<Widget>[
                    _suggestionHeading('Trending', mv.textMuted),
                    for (final option in trending)
                      _suggestionOption(option, onSelected),
                  ],
                  if (products.isNotEmpty) ...<Widget>[
                    _suggestionHeading('Products', mv.textMuted),
                    for (final option in products)
                      _suggestionOption(option, onSelected),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      fieldViewBuilder:
          (context, controller, focusNode, onFieldSubmitted) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submit(controller.text),
                style: TextStyle(color: mv.text, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search products, brands & more...',
                  hintStyle: TextStyle(color: mv.textMuted, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: mv.textMuted, size: 19),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 42,
                  ),
                  filled: true,
                  fillColor: mv.surfaceMuted,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: mv.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: mv.accentDeep, width: 1.2),
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _suggestionHeading(String title, Color color) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
    child: Text(
      title,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
    ),
  );

  Widget _suggestionOption(
    String option,
    AutocompleteOnSelected<String> onSelected,
  ) => InkWell(
    onTap: () => onSelected(option),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: <Widget>[
          Icon(
            _recentSearches.contains(option)
                ? Icons.history
                : _trendingSearches.contains(option)
                ? Icons.trending_up
                : Icons.search,
            size: 17,
            color: context.mv.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              option,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.mv.text, fontSize: 13),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Wishlist/notification/cart icon button with a count badge, pinned to the
/// top bar. The badge uses the sky-blue accent rather than the M3 error red.
class _TopBarAction extends StatelessWidget {
  const _TopBarAction({
    required this.icon,
    required this.tooltip,
    required this.countKey,
    required this.onPressed,
    this.count = 0,
  });

  final IconData icon;
  final String tooltip;
  final int count;
  final String countKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
      icon: Badge(
        key: ValueKey<String>(countKey),
        isLabelVisible: count > 0,
        backgroundColor: AppColors.primary,
        textColor: Colors.white,
        label: Text(count > 99 ? '99+' : '$count'),
        child: Icon(icon),
      ),
    );
  }
}

/// Dark-mode switch in the top bar. Rendered as a distinct circular control so
/// it reads as a mode switch rather than another top-bar shortcut.
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder:
                (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
            child: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              key: ValueKey<bool>(isDark),
              size: 18,
              color: context.mv.accentDeep,
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder inbox: the storefront has no notification feed yet, but the
/// top-bar bell needs a destination so the action is never dead.
class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.notifications_none_rounded,
              size: 56,
              color: context.mv.accentDeep,
            ),
            const SizedBox(height: 12),
            Text('No new notifications', style: AppTextStyles.title(context)),
            const SizedBox(height: 4),
            Text(
              'Order updates and vendor offers will show up here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category bar: a compact label and horizontal chip strip.
// ---------------------------------------------------------------------------

class _CategoriesBar extends StatelessWidget {
  const _CategoriesBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<Category> categories;
  final Category? selected;
  final ValueChanged<Category?> onSelected;

  @override
  Widget build(BuildContext context) {
    final mv = context.mv;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
          child: Row(
            children: [
              Icon(Icons.category_outlined, size: 16, color: mv.textMuted),
              const SizedBox(width: 6),
              Text(
                'Categories',
                style: AppTextStyles.caption(
                  context,
                ).copyWith(color: mv.text, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = index == 0 ? null : categories[index - 1];
              final active =
                  category == null
                      ? selected == null
                      : selected?.id == category.id;
              return _CategoryPill(
                label: category?.name ?? 'All',
                active: active,
                onTap: () => onSelected(category),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MoreDrawerAction extends StatelessWidget {
  const _MoreDrawerAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : context.mv.text;
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: TextStyle(fontSize: 14, color: color)),
      onTap: onTap,
    );
  }
}

/// Pill-style category chip.
///
/// Colour rule: **only** the selected chip takes the sky-blue accent, as a flat
/// fill behind white text. Everything else is a neutral recessed fill with muted
/// text — the strip must never show a row of blue pills, so the accent is
/// applied on the `active` branch alone and nowhere else.
///
/// The fill resolves once, here, so the [Material] is the single source of
/// colour. Deriving it twice (material for light, a decorator for dark) let the
/// two disagree about what an unselected chip looked like in dark mode.
class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mv = context.mv;
    final fill =
        active
            ? AppColors.skyBlueSolid
            : context.isDarkMode
            ? mv.surfaceMuted
            : AppColors.chipNeutral;

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                color: active ? Colors.white : mv.textMuted,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account sheet widgets.
// ---------------------------------------------------------------------------

/// Chrome shared by the account sheet: the grab handle followed by the action rows.
///
/// The rows live in a shrink-wrapped [ListView] rather than a plain column
/// because a modal bottom sheet is only allowed 9/16 of the screen height by
/// default. Six rows plus the handle overflow that on a 640dp phone, and a
/// non-scrolling column has nowhere to put the excess.
class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 12),
        children: <Widget>[
          const SizedBox(height: 18),
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: context.mv.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({this.user});

  final UserRecord? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.display ?? 'Guest';
    final detail = user?.email ?? user?.phone ?? 'Not signed in';
    final mv = context.mv;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: MvColors.gradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: mv.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: mv.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : context.mv.text;
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: TextStyle(fontSize: 14, color: color)),
      onTap: onTap,
    );
  }
}
