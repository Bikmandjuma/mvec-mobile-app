/// Contract for the marketplace home feed data source.
///
/// Concrete implementations can swap between local demo data
/// ([MockHomeService]) and the real backend API without touching
/// the presentation layer or its providers.
abstract class HomeService {
  /// Fetches the home feed payload in a Map structure that mirrors the
  /// backend API response schema (`banners`, `categories`, `products`...).
  ///
  /// Throws an [Exception] when the feed cannot be retrieved.
  Future<Map<String, dynamic>> getHomeFeed();

  /// Returns true when this service is serving local demo data only.
  bool get isDemo;
}