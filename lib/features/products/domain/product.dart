class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.thumbnail,
    required this.images,
    this.brand,
    this.tags = const [],
    this.warrantyInformation,
    this.shippingInformation,
    this.returnPolicy,
    this.reviews = const [],
    this._reviewCount,
  });

  final String id;
  final String title;
  final String description;

  /// Category slug, matching a document id in `categories`.
  final String category;

  /// Price in USD before discount.
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String thumbnail;
  final List<String> images;
  final String? brand;
  final List<String> tags;
  final String? warrantyInformation;
  final String? shippingInformation;
  final String? returnPolicy;
  /// Reviews that came with the imported catalog. Customer reviews live in
  /// `products/{id}/reviews`.
  final List<ProductReview> reviews;

  final int? _reviewCount;

  /// How many reviews [rating] averages over, including customer reviews.
  int get reviewCount => _reviewCount ?? reviews.length;

  bool get hasDiscount => discountPercentage > 0;

  double get discountedPrice => price * (1 - discountPercentage / 100);

  bool get inStock => stock > 0;
}

class ProductReview {
  const ProductReview({
    required this.reviewerName,
    required this.rating,
    required this.comment,
    this.date,
  });

  final String reviewerName;
  final int rating;
  final String comment;
  final DateTime? date;
}
