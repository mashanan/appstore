/// A product category, stored in `categories/{slug}`.
class Category {
  const Category({required this.slug, required this.name});

  /// Matches [Product.category].
  final String slug;
  final String name;
}
