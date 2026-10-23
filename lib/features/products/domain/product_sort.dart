import 'product.dart';

enum ProductSort {
  /// Keeps the incoming order: alphabetical, or search relevance while searching.
  recommended('Recommended'),
  priceLowToHigh('Price: low to high'),
  priceHighToLow('Price: high to low'),
  topRated('Top rated'),
  biggestDiscount('Biggest discount');

  const ProductSort(this.label);

  final String label;
}

/// Returns [products] in [sort] order. Ties fall back to the title, so the
/// order is the same every time.
List<Product> sortProducts(List<Product> products, ProductSort sort) {
  final int Function(Product, Product) compare;
  switch (sort) {
    case ProductSort.recommended:
      return products;
    case ProductSort.priceLowToHigh:
      compare = (a, b) => a.discountedPrice.compareTo(b.discountedPrice);
    case ProductSort.priceHighToLow:
      compare = (a, b) => b.discountedPrice.compareTo(a.discountedPrice);
    case ProductSort.topRated:
      compare = (a, b) => b.rating.compareTo(a.rating);
    case ProductSort.biggestDiscount:
      compare = (a, b) => b.discountPercentage.compareTo(a.discountPercentage);
  }

  return [...products]..sort((a, b) {
      final result = compare(a, b);
      return result != 0 ? result : a.title.compareTo(b.title);
    });
}
