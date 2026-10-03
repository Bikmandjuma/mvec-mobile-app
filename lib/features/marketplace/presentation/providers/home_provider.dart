import 'package:flutter/foundation.dart' hide Category;

import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/vendor_model.dart';
import '../../data/services/home_service.dart';
import '../../data/services/mock_home_service.dart';

/// Promotional banner shown inside the home feed carousel.
class BannerItem {
  const BannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.link,
  });

  final int id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? link;

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    final media = json['media'];
    return BannerItem(
      id: _toInt(json['id']),
      title: _toString(json['title']),
      subtitle: _toString(json['subtitle']),
      imageUrl: media is Map
          ? _toString(media['mainImage'])
          : _toString(json['image_url'] ?? json['image']),
      link: json['link']?.toString(),
    );
  }

  static String _toString(dynamic value) => value?.toString() ?? '';

  static int _toInt(dynamic value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? 0;
}

/// Aggregated data rendered by the home marketplace feed.
class HomeFeed {
  const HomeFeed({
    this.banners = const <BannerItem>[],
    this.categories = const <Category>[],
    this.featuredVendors = const <Vendor>[],
    this.featuredProducts = const <Product>[],
    this.recommendedProducts = const <Product>[],
    this.products = const <Product>[],
    this.recentlyViewed = const <Product>[],
  });

  final List<BannerItem> banners;
  final List<Category> categories;
  final List<Vendor> featuredVendors;
  final List<Product> featuredProducts;
  final List<Product> recommendedProducts;
  final List<Product> products;
  final List<Product> recentlyViewed;

  /// Deals are derived from products carrying a discount.
  List<Product> get deals =>
      products.where((product) => product.onSale).toList();

  /// All known vendors (featured set acts as the default store list).
  List<Vendor> get vendors => featuredVendors;

  factory HomeFeed.fromJson(Map<String, dynamic> json) => HomeFeed(
        banners: _parse(
          json['banners'],
          (map) => BannerItem.fromJson(map),
        ),
        categories: _parse(
          json['categories'],
          Category.fromJson,
        ),
        featuredVendors: _parse(
          json['featuredVendors'],
          Vendor.fromJson,
        ),
        featuredProducts: _parse(
          json['featuredProducts'],
          Product.fromJson,
        ),
        recommendedProducts: _parse(
          json['recommendedProducts'],
          Product.fromJson,
        ),
        products: _parse(
          json['products'],
          Product.fromJson,
        ),
        recentlyViewed: _parse(
          json['recentlyViewed'],
          Product.fromJson,
        ),
      );

  static List<T> _parse<T>(dynamic value, T Function(Map<String, dynamic>) fromJson) {
    if (value is! List<dynamic>) return <T>[];
    return value
        .whereType<Map<dynamic, dynamic>>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

/// State manager for the marketpce home feed.
///
/// Depends on an injected [HomeService] (defaults to [MockHomeService]) so the
/// UI is decoupled from the data source and can switch to the real backend
/// API later without any widget changes.
class HomeProvider extends ChangeNotifier {
  HomeProvider({HomeService? service})
      : _service = service ?? MockHomeService();

  final HomeService _service;

  HomeFeed _feed = const HomeFeed();
  bool _isLoading = true;
  String? _error;

  HomeFeed get feed => _feed;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Whether the current data comes from the local mock service.
  bool get isDemo => _service.isDemo;

  List<BannerItem> get banners => _feed.banners;
  List<Category> get categories => _feed.categories;
  List<Vendor> get vendors => _feed.vendors;
  List<Product> get featuredProducts => _feed.featuredProducts;
  List<Product> get recommendedProducts => _feed.recommendedProducts;
  List<Product> get products => _feed.products;
  List<Product> get recentlyViewed => _feed.recentlyViewed;
  List<Product> get deals => _feed.deals;

  /// Loads the home feed from the injected service and notifies listeners.
  Future<void> loadHomeFeed() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final payload = await _service.getHomeFeed();
      _feed = HomeFeed.fromJson(payload);
    } catch (e) {
      _error = 'Could not load the home feed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tracks a product as recently viewed (deduplicated, capped at 12).
  void addRecentlyViewed(Product product) {
    final updated = List<Product>.of(_feed.recentlyViewed)
      ..removeWhere((item) => item.id == product.id)
      ..insert(0, product);
    if (updated.length > 12) {
      updated.removeRange(12, updated.length);
    }
    _feed = HomeFeed(
      banners: _feed.banners,
      categories: _feed.categories,
      featuredVendors: _feed.featuredVendors,
      featuredProducts: _feed.featuredProducts,
      recommendedProducts: _feed.recommendedProducts,
      products: _feed.products,
      recentlyViewed: updated,
    );
    notifyListeners();
  }
}