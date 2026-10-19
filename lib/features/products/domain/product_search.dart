import 'product.dart';

/// Filters [products] by [category] (a slug, or null for all) and by [query],
/// matching title, brand, category and tags.
///
/// Every word in the query must match somewhere, so "red lipstick" finds a
/// product titled "Red Lipstick" but also one tagged "red" in the lipstick
/// category. Products whose title contains the whole query come first.
List<Product> searchProducts(List<Product> products, String query, {String? category}) {
  final inCategory = category == null ? products : products.where((p) => p.category == category).toList();

  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return inCategory;

  final terms = normalizedQuery.split(RegExp(r'\s+'));
  final titleMatches = <Product>[];
  final otherMatches = <Product>[];

  for (final product in inCategory) {
    final title = product.title.toLowerCase();
    final searchable = [
      title,
      product.brand?.toLowerCase() ?? '',
      product.category.replaceAll('-', ' ').toLowerCase(),
      ...product.tags.map((tag) => tag.toLowerCase()),
    ].join(' ');

    if (!terms.every(searchable.contains)) continue;
    (title.contains(normalizedQuery) ? titleMatches : otherMatches).add(product);
  }

  return [...titleMatches, ...otherMatches];
}
