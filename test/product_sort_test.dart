import 'package:tokoku/features/products/domain/product.dart';
import 'package:tokoku/features/products/domain/product_sort.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product(String title, {double price = 10, double discount = 0, double rating = 4}) {
  return Product(
    id: title,
    title: title,
    description: '',
    category: 'misc',
    price: price,
    discountPercentage: discount,
    rating: rating,
    stock: 5,
    thumbnail: '',
    images: const [],
  );
}

void main() {
  final products = [
    _product('Banana', price: 20, rating: 3),
    _product('Apple', price: 100, discount: 50, rating: 5),
    _product('Cherry', price: 30, discount: 10, rating: 4),
  ];

  List<String> titles(ProductSort sort) => sortProducts(products, sort).map((p) => p.title).toList();

  test('recommended keeps the incoming order', () {
    expect(titles(ProductSort.recommended), ['Banana', 'Apple', 'Cherry']);
  });

  test('sorts by the price customers actually pay', () {
    // Apple costs 50 after its discount, Cherry 27, Banana 20.
    expect(titles(ProductSort.priceLowToHigh), ['Banana', 'Cherry', 'Apple']);
    expect(titles(ProductSort.priceHighToLow), ['Apple', 'Cherry', 'Banana']);
  });

  test('sorts by rating and by discount', () {
    expect(titles(ProductSort.topRated), ['Apple', 'Cherry', 'Banana']);
    expect(titles(ProductSort.biggestDiscount), ['Apple', 'Cherry', 'Banana']);
  });

  test('breaks ties by title', () {
    final tied = [_product('Zebra'), _product('Ant'), _product('Moth')];
    expect(sortProducts(tied, ProductSort.topRated).map((p) => p.title), ['Ant', 'Moth', 'Zebra']);
  });

  test('does not change the original list', () {
    sortProducts(products, ProductSort.priceLowToHigh);
    expect(products.first.title, 'Banana');
  });
}
