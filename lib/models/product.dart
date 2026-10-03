class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? oldPrice;
  final int stock;
  final List<String> images; // Images uploaded by the vendor
  final List<String> colors;
  final List<String> sizes;
  final Vendor vendor;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.oldPrice,
    required this.stock,
    required this.images,
    required this.colors,
    required this.sizes,
    required this.vendor,
  });
}

class Vendor {
  final String id;
  final String name;
  final String logo;
  final double rating;
  final int totalProducts;

  Vendor({
    required this.id,
    required this.name,
    required this.logo,
    required this.rating,
    required this.totalProducts,
  });
}