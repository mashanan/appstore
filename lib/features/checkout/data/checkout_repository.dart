import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../addresses/data/address_repository.dart';
import '../../addresses/domain/address.dart';
import '../../auth/data/auth_repository.dart';
import '../../cart/domain/cart.dart';
import '../../orders/domain/order.dart';
import '../../products/data/product_repository.dart';

/// A problem the customer can fix, such as an item that sold out meanwhile.
class CheckoutException implements Exception {
  const CheckoutException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CheckoutRepository {
  CheckoutRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final AuthRepository _auth;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user');
    return user.uid;
  }

  /// Places an order for [entries] in one transaction: re-checks stock and
  /// prices against the live catalog, saves the order, reduces stock and
  /// empties the cart. Returns the new order id.
  Future<String> placeOrder({
    required List<CartEntry> entries,
    required ShippingAddress address,
    required ShippingMethod shippingMethod,
    required PaymentMethod paymentMethod,
  }) {
    if (entries.isEmpty) throw const CheckoutException('Your cart is empty.');

    final uid = _uid;
    final products = _firestore.collection('products');
    final cartItems = _firestore.collection('users').doc(uid).collection('cartItems');
    final orderRef = _firestore.collection('orders').doc();

    return _firestore.runTransaction((transaction) async {
      // Transactions must do all reads before any writes.
      final items = <CartItem>[];
      for (final entry in entries) {
        final snapshot = await transaction.get(products.doc(entry.productId));
        final data = snapshot.data();
        items.add(CartItem(
          productId: entry.productId,
          quantity: entry.quantity,
          product: data == null ? null : ProductRepository.productFromFirestore(snapshot.id, data),
        ));
      }

      for (final item in items) {
        final product = item.product;
        if (product == null) throw const CheckoutException('An item in your cart is no longer available.');
        if (!item.isAvailable) throw CheckoutException('${product.title} is out of stock.');
        if (item.exceedsStock) {
          throw CheckoutException('Only ${product.stock} of ${product.title} left. Please update your cart.');
        }
      }

      final summary = CartSummary.of(items);
      transaction.set(orderRef, {
        'userId': uid,
        'items': [
          for (final item in items)
            {
              'productId': item.productId,
              'title': item.product!.title,
              'thumbnail': item.product!.thumbnail,
              'unitPrice': _roundCents(item.product!.discountedPrice),
              'originalUnitPrice': item.product!.price,
              'quantity': item.quantity,
            },
        ],
        'subtotal': _roundCents(summary.subtotal),
        'discount': _roundCents(summary.discount),
        'shippingFee': shippingMethod.fee,
        'total': _roundCents(summary.total + shippingMethod.fee),
        'status': OrderStatus.pending.name,
        'shippingAddress': AddressRepository.addressToMap(address),
        'shippingMethod': shippingMethod.name,
        'paymentMethod': paymentMethod.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      for (final item in items) {
        transaction.update(products.doc(item.productId), {'stock': item.product!.stock - item.quantity});
        transaction.delete(cartItems.doc(item.productId));
      }

      return orderRef.id;
    });
  }

  static double _roundCents(double amount) => (amount * 100).roundToDouble() / 100;
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(ref.watch(firestoreProvider), ref.watch(authRepositoryProvider));
});
