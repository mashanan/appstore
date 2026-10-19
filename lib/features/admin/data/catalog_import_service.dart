import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/firebase/firebase_providers.dart';

typedef ImportResult = ({int products, int categories});

/// Copies the DummyJSON demo catalog into Firestore. Product ids are kept, so
/// running it again overwrites the same documents instead of duplicating them.
class CatalogImportService {
  CatalogImportService(this._firestore, this._client);

  static const _baseUrl = 'https://dummyjson.com/products';

  // Firestore allows 500 writes per batch.
  static const _batchSize = 400;

  final FirebaseFirestore _firestore;
  final http.Client _client;

  Future<ImportResult> importDemoCatalog() async {
    final categories = await _getJson('$_baseUrl/categories') as List;
    final productsJson = await _getJson('$_baseUrl?limit=0') as Map<String, dynamic>;
    final products = productsJson['products'] as List;

    final writes = <(DocumentReference<Map<String, dynamic>>, Map<String, dynamic>)>[
      for (final category in categories)
        (
          _firestore.collection('categories').doc(category['slug'] as String),
          {'slug': category['slug'], 'name': category['name']},
        ),
      for (final product in products)
        (
          _firestore.collection('products').doc('${product['id']}'),
          _toProductDocument(product as Map<String, dynamic>),
        ),
    ];

    for (var start = 0; start < writes.length; start += _batchSize) {
      final batch = _firestore.batch();
      for (final (ref, data) in writes.skip(start).take(_batchSize)) {
        batch.set(ref, data);
      }
      await batch.commit();
    }

    return (products: products.length, categories: categories.length);
  }

  Future<Object?> _getJson(String url) async {
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw http.ClientException('DummyJSON returned ${response.statusCode}', Uri.parse(url));
    }
    return jsonDecode(response.body);
  }

  static Map<String, dynamic> _toProductDocument(Map<String, dynamic> json) {
    return {
      'title': json['title'],
      'description': json['description'],
      'category': json['category'],
      'price': json['price'],
      'discountPercentage': json['discountPercentage'] ?? 0,
      'rating': json['rating'] ?? 0,
      'stock': json['stock'] ?? 0,
      'brand': json['brand'],
      'sku': json['sku'],
      'tags': json['tags'] ?? const [],
      'thumbnail': json['thumbnail'],
      'images': json['images'] ?? const [],
      'warrantyInformation': json['warrantyInformation'],
      'shippingInformation': json['shippingInformation'],
      'returnPolicy': json['returnPolicy'],
      'minimumOrderQuantity': json['minimumOrderQuantity'] ?? 1,
      'reviews': [
        // Reviewer emails are left out on purpose.
        for (final review in json['reviews'] as List? ?? const [])
          {
            'reviewerName': review['reviewerName'],
            'rating': review['rating'],
            'comment': review['comment'],
            'date': review['date'],
          },
      ],
      'source': 'dummyjson',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

final catalogImportServiceProvider = Provider<CatalogImportService>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return CatalogImportService(ref.watch(firestoreProvider), client);
});
