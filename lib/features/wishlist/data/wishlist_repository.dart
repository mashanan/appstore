import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product.dart';

/// Products the signed-in user saved for later, stored in `users/{uid}/wishlist/{productId}`.
class WishlistRepository {
  WishlistRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final AuthRepository _auth;

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _firestore.collection('users').doc(uid).collection('wishlist');

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user');
    return user.uid;
  }

  /// Saved product ids, most recently saved first.
  Stream<List<String>> watchWishlist(String uid) {
    return _items(uid)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => [for (final doc in snapshot.docs) doc.id]);
  }

  Future<void> add(String productId) {
    return _items(_uid).doc(productId).set({
      'productId': productId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(String productId) => _items(_uid).doc(productId).delete();
}

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(ref.watch(firestoreProvider), ref.watch(authRepositoryProvider));
});

final wishlistIdsProvider = StreamProvider<List<String>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(wishlistRepositoryProvider).watchWishlist(uid);
});

final isWishlistedProvider = Provider.family<bool, String>((ref, productId) {
  return ref.watch(wishlistIdsProvider).value?.contains(productId) ?? false;
});

/// Saved products in wishlist order. Products since removed from the catalog are skipped.
final wishlistProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final ids = ref.watch(wishlistIdsProvider);
  final products = ref.watch(productsProvider);

  if (ids.hasError) return AsyncError(ids.error!, ids.stackTrace ?? StackTrace.current);
  if (products.hasError) return AsyncError(products.error!, products.stackTrace ?? StackTrace.current);

  final idList = ids.value;
  final productList = products.value;
  if (idList == null || productList == null) return const AsyncLoading();

  final productsById = {for (final product in productList) product.id: product};
  return AsyncData([for (final id in idList) ?productsById[id]]);
});
