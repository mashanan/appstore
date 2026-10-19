import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product.dart';
import '../domain/cart.dart';

/// The signed-in user's cart. Only product ids and quantities are stored;
/// names, prices and stock always come from the live product documents.
class CartRepository {
  CartRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final AuthRepository _auth;

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _firestore.collection('users').doc(uid).collection('cartItems');

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user');
    return user.uid;
  }

  Stream<List<CartEntry>> watchCart(String uid) {
    return _items(uid).orderBy('addedAt', descending: true).snapshots().map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              CartEntry(productId: doc.id, quantity: (doc.data()['quantity'] as num? ?? 0).toInt()),
          ],
        );
  }

  /// Adds [quantity] of [product], capped at its stock. Returns the new quantity in the cart.
  Future<int> add(Product product, {int quantity = 1}) {
    final ref = _items(_uid).doc(product.id);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final current = (snapshot.data()?['quantity'] as num? ?? 0).toInt();
      final next = min(current + quantity, product.stock);

      if (snapshot.exists) {
        transaction.update(ref, {'quantity': next});
      } else {
        transaction.set(ref, {
          'productId': product.id,
          'quantity': next,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
      return next;
    });
  }

  /// Sets the quantity of a cart item, removing it when [quantity] is zero or less.
  Future<void> setQuantity(String productId, int quantity) {
    final ref = _items(_uid).doc(productId);
    return quantity <= 0 ? ref.delete() : ref.update({'quantity': quantity});
  }

  Future<void> remove(String productId) => _items(_uid).doc(productId).delete();

  Future<void> clear() async {
    final snapshot = await _items(_uid).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(firestoreProvider), ref.watch(authRepositoryProvider));
});

final cartEntriesProvider = StreamProvider<List<CartEntry>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(cartRepositoryProvider).watchCart(uid);
});

/// Cart entries joined with the live catalog.
final cartItemsProvider = Provider<AsyncValue<List<CartItem>>>((ref) {
  final entries = ref.watch(cartEntriesProvider);
  final products = ref.watch(productsProvider);

  if (entries.hasError) return AsyncError(entries.error!, entries.stackTrace ?? StackTrace.current);
  if (products.hasError) return AsyncError(products.error!, products.stackTrace ?? StackTrace.current);

  final entryList = entries.value;
  final productList = products.value;
  if (entryList == null || productList == null) return const AsyncLoading();

  final productsById = {for (final product in productList) product.id: product};
  return AsyncData([
    for (final entry in entryList)
      CartItem(productId: entry.productId, quantity: entry.quantity, product: productsById[entry.productId]),
  ]);
});

/// Total number of units in the cart, for the navigation badge.
final cartCountProvider = Provider<int>((ref) {
  final entries = ref.watch(cartEntriesProvider).value ?? const [];
  return entries.fold(0, (total, entry) => total + entry.quantity);
});

/// How many units of a product are already in the cart.
final cartQuantityProvider = Provider.family<int, String>((ref, productId) {
  final entries = ref.watch(cartEntriesProvider).value ?? const [];
  return entries.where((entry) => entry.productId == productId).firstOrNull?.quantity ?? 0;
});
