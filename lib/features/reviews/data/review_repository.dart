import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../products/domain/product.dart';
import '../domain/rating.dart';

class AlreadyReviewedException implements Exception {
  const AlreadyReviewedException();

  @override
  String toString() => 'You have already reviewed this product.';
}

/// Customer reviews, stored in `products/{productId}/reviews/{uid}`: one per
/// customer per product, and only for products from a delivered order.
class ReviewRepository {
  ReviewRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final AuthRepository _auth;

  CollectionReference<Map<String, dynamic>> _reviews(String productId) =>
      _firestore.collection('products').doc(productId).collection('reviews');

  /// Customer reviews for a product, newest first.
  Stream<List<ProductReview>> watchReviews(String productId) {
    return _reviews(productId).orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              ProductReview(
                reviewerName: doc.data()['reviewerName'] as String? ?? 'Customer',
                rating: (doc.data()['rating'] as num? ?? 0).toInt(),
                comment: doc.data()['comment'] as String? ?? '',
                date: (doc.data()['createdAt'] as Timestamp?)?.toDate(),
              ),
          ],
        );
  }

  Stream<bool> watchHasReviewed(String productId, String uid) {
    return _reviews(productId).doc(uid).snapshots().map((snapshot) => snapshot.exists);
  }

  /// Saves the review and folds its rating into the product's average, in one transaction.
  Future<void> submit({
    required String productId,
    required String orderId,
    required int rating,
    required String comment,
  }) {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user');

    final productRef = _firestore.collection('products').doc(productId);
    final reviewRef = _reviews(productId).doc(user.uid);

    return _firestore.runTransaction((transaction) async {
      final product = await transaction.get(productRef);
      final review = await transaction.get(reviewRef);
      final data = product.data();
      if (data == null) throw StateError('This product is no longer available.');
      if (review.exists) throw const AlreadyReviewedException();

      final count = (data['reviewCount'] as num?)?.toInt() ?? (data['reviews'] as List? ?? const []).length;
      final average = (data['rating'] as num? ?? 0).toDouble();

      transaction.set(reviewRef, {
        'rating': rating,
        'comment': comment,
        'reviewerName': user.displayName ?? 'Customer',
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(productRef, {
        'rating': addRating(currentAverage: average, count: count, newRating: rating),
        'reviewCount': count + 1,
      });
    });
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(firestoreProvider), ref.watch(authRepositoryProvider));
});

final productReviewsProvider = StreamProvider.family<List<ProductReview>, String>((ref, productId) {
  return ref.watch(reviewRepositoryProvider).watchReviews(productId);
});

final hasReviewedProvider = StreamProvider.family<bool, String>((ref, productId) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(false);
  return ref.watch(reviewRepositoryProvider).watchHasReviewed(productId, uid);
});
