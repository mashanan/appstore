import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../domain/category.dart';
import '../domain/product.dart';
import '../domain/product_input.dart';

class ProductRepository {
  ProductRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _products => _firestore.collection('products');

  Stream<List<Product>> watchProducts() {
    return _products
        .orderBy('title')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => productFromFirestore(doc.id, doc.data())).toList());
  }

  Stream<Product?> watchProduct(String id) {
    return _products.doc(id).snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : productFromFirestore(snapshot.id, data);
    });
  }

  /// Adds a product and returns its id. Admin only.
  Future<String> createProduct(ProductInput input) async {
    final ref = _products.doc();
    await ref.set({
      ..._inputToFirestore(input),
      'rating': 0,
      'reviews': const [],
      'tags': const [],
      'source': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Updates the editable fields of a product. Admin only.
  Future<void> updateProduct(String id, ProductInput input) {
    return _products.doc(id).update(_inputToFirestore(input));
  }

  /// Deletes a product. Carts show it as unavailable and past orders keep
  /// their own copy, so nothing else needs cleaning up. Admin only.
  Future<void> deleteProduct(String id) => _products.doc(id).delete();

  static Map<String, dynamic> _inputToFirestore(ProductInput input) {
    return {
      'title': input.title,
      'description': input.description,
      'category': input.category,
      'brand': input.brand,
      'price': input.price,
      'discountPercentage': input.discountPercentage,
      'stock': input.stock,
      'images': input.images,
      'thumbnail': input.images.firstOrNull ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Stream<List<Category>> watchCategories() {
    return _firestore.collection('categories').orderBy('name').snapshots().map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              Category(slug: doc.id, name: doc.data()['name'] as String? ?? doc.id),
          ],
        );
  }

  static Product productFromFirestore(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      price: (data['price'] as num? ?? 0).toDouble(),
      discountPercentage: (data['discountPercentage'] as num? ?? 0).toDouble(),
      rating: (data['rating'] as num? ?? 0).toDouble(),
      stock: (data['stock'] as num? ?? 0).toInt(),
      thumbnail: data['thumbnail'] as String? ?? '',
      images: List<String>.from(data['images'] as List? ?? const []),
      brand: data['brand'] as String?,
      tags: List<String>.from(data['tags'] as List? ?? const []),
      warrantyInformation: data['warrantyInformation'] as String?,
      shippingInformation: data['shippingInformation'] as String?,
      returnPolicy: data['returnPolicy'] as String?,
      reviewCount: (data['reviewCount'] as num?)?.toInt(),
      reviews: [
        for (final review in data['reviews'] as List? ?? const [])
          ProductReview(
            reviewerName: review['reviewerName'] as String? ?? 'Anonymous',
            rating: (review['rating'] as num? ?? 0).toInt(),
            comment: review['comment'] as String? ?? '',
            date: DateTime.tryParse(review['date'] as String? ?? ''),
          ),
      ],
    );
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(firestoreProvider));
});

final productsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchProducts();
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(productRepositoryProvider).watchCategories();
});

final productProvider = StreamProvider.family<Product?, String>((ref, id) {
  return ref.watch(productRepositoryProvider).watchProduct(id);
});
