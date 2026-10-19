import 'package:appstore/features/products/domain/product.dart';
import 'package:appstore/features/products/domain/product_search.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product(String id, String title, {String category = 'misc', String? brand, List<String> tags = const []}) {
  return Product(
    id: id,
    title: title,
    description: '',
    category: category,
    price: 10,
    discountPercentage: 0,
    rating: 4,
    stock: 5,
    thumbnail: '',
    images: const [],
    brand: brand,
    tags: tags,
  );
}

void main() {
  final products = [
    _product('1', 'Red Lipstick', category: 'beauty', brand: 'Chic Cosmetics', tags: ['lipstick']),
    _product('2', 'Essence Mascara', category: 'beauty', brand: 'Essence', tags: ['mascara']),
    _product('3', 'iPhone 13 Pro', category: 'smartphones', brand: 'Apple'),
    _product('4', 'Leather Sofa', category: 'home-decoration', tags: ['red', 'lipstick-proof']),
  ];

  List<String> ids(String query) => searchProducts(products, query).map((p) => p.id).toList();

  test('returns everything for an empty or blank query', () {
    expect(ids(''), ['1', '2', '3', '4']);
    expect(ids('   '), ['1', '2', '3', '4']);
  });

  test('is case-insensitive and matches brand and category', () {
    expect(ids('IPHONE'), ['3']);
    expect(ids('apple'), ['3']);
    expect(ids('home decoration'), ['4']);
  });

  test('requires every word to match', () {
    expect(ids('essence mascara'), ['2']);
    expect(ids('essence iphone'), isEmpty);
  });

  test('ranks title matches first', () {
    expect(ids('red lipstick'), ['1', '4']);
  });

  test('filters by category, alone or combined with a query', () {
    List<String> idsIn(String category, [String query = '']) =>
        searchProducts(products, query, category: category).map((p) => p.id).toList();

    expect(idsIn('beauty'), ['1', '2']);
    expect(idsIn('beauty', 'mascara'), ['2']);
    expect(idsIn('smartphones', 'mascara'), isEmpty);
  });
}
