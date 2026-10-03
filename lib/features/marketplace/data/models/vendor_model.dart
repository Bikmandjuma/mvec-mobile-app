/// Vendor (store) model mirroring the backend vendor schema
/// (`id`, `name`, `slug`, `rating`, `media.{logo,banner}`, ...).
class Vendor {
  const Vendor({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.logoUrl,
    this.bannerUrl,
    this.rating = 0,
    this.reviewCount = 0,
    this.productCount = 0,
    this.isVerified = false,
    this.isFeatured = false,
  });

  final int id;
  final String name;
  final String slug;
  final String description;
  final String logoUrl;
  final String? bannerUrl;
  final double rating;
  final int reviewCount;
  final int productCount;
  final bool isVerified;
  final bool isFeatured;

  factory Vendor.fromJson(Map<String, dynamic> json) {
    final media = json['media'];
    return Vendor(
      id: _toInt(json['id']),
      name: _toString(json['name']),
      slug: _toString(json['slug']),
      description: _toString(json['description']),
      logoUrl: media is Map
          ? _toString(media['logo'])
          : _toString(json['logo_url'] ?? json['logo'] ?? json['image']),
      bannerUrl: media is Map
          ? media['banner']?.toString()
          : json['banner_url']?.toString(),
      rating: _toDouble(json['rating']),
      reviewCount: _toInt(json['reviewCount'] ?? json['review_count'] ?? json['reviews']),
      productCount: _toInt(json['productCount'] ?? json['product_count']),
      isVerified: json['isVerified'] == true || json['verified'] == true,
      isFeatured: json['isFeatured'] == true || json['featured'] == true,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'slug': slug,
        'description': description,
        'rating': rating,
        'reviewCount': reviewCount,
        'productCount': productCount,
        'isVerified': isVerified,
        'isFeatured': isFeatured,
        'media': <String, dynamic>{
          'logo': logoUrl,
          'banner': bannerUrl,
        },
      };

  static String _toString(dynamic value) => value?.toString() ?? '';

  static double _toDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  static int _toInt(dynamic value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? 0;
}