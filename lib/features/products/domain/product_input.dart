/// The fields an admin can edit on a product. Ratings and reviews are left
/// alone when saving.
class ProductInput {
  const ProductInput({
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.discountPercentage,
    required this.stock,
    required this.images,
    this.brand,
  });

  final String title;
  final String description;
  final String category;
  final String? brand;
  final double price;
  final double discountPercentage;
  final int stock;

  /// Web URLs or `image:<id>` references. The first one is the thumbnail.
  final List<String> images;
}
