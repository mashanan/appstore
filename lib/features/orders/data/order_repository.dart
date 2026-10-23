import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../addresses/data/address_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/order.dart';

class OrderRepository {
  OrderRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders => _firestore.collection('orders');

  /// The user's orders, newest first. Needs the (userId, createdAt) index in firestore.indexes.json.
  Stream<List<Order>> watchUserOrders(String uid) {
    return _orders
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_toOrders);
  }

  /// Every customer's orders, newest first, optionally only those in [status].
  /// Admin only. Filtering needs the (status, createdAt) index.
  Stream<List<Order>> watchAllOrders({OrderStatus? status}) {
    Query<Map<String, dynamic>> query = _orders;
    if (status != null) query = query.where('status', isEqualTo: status.name);
    return query.orderBy('createdAt', descending: true).snapshots().map(_toOrders);
  }

  Stream<Order?> watchOrder(String id) {
    return _orders.doc(id).snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : orderFromFirestore(snapshot.id, data);
    });
  }

  /// Moves an order to [status] and records when it happened. Admin only.
  Future<void> updateStatus(String orderId, OrderStatus status) {
    return _orders.doc(orderId).update({
      'status': status.name,
      'statusUpdatedAt.${status.name}': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cancels an order and puts its items back in stock.
  ///
  /// Admins can cancel until the order ships; customers only their own
  /// pending orders. For customers, each restocked product records the order
  /// id so Firestore rules can check the cancellation is real.
  Future<void> cancel(Order order, {required CancelledBy by}) {
    final orderRef = _orders.doc(order.id);
    final products = _firestore.collection('products');

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(orderRef);
      final status = OrderStatus.values.asNameMap()[snapshot.data()?['status']];
      final allowed = by == CancelledBy.admin ? status?.canCancel : status?.canCustomerCancel;
      if (allowed != true) throw StateError('This order can no longer be cancelled.');

      // Read every product first; transactions can't read after writing.
      final productSnapshots = [for (final item in order.items) await transaction.get(products.doc(item.productId))];

      for (final (index, item) in order.items.indexed) {
        // Skip products that were deleted from the catalog since the order was placed.
        if (productSnapshots[index].exists) {
          transaction.update(products.doc(item.productId), {
            'stock': FieldValue.increment(item.quantity),
            if (by == CancelledBy.customer) 'restockedByOrder': order.id,
          });
        }
      }
      transaction.update(orderRef, {
        'status': OrderStatus.cancelled.name,
        'statusUpdatedAt.${OrderStatus.cancelled.name}': FieldValue.serverTimestamp(),
        'cancelledBy': by.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static List<Order> _toOrders(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return [for (final doc in snapshot.docs) orderFromFirestore(doc.id, doc.data())];
  }

  static Order orderFromFirestore(String id, Map<String, dynamic> data) {
    double number(Object? value) => (value as num? ?? 0).toDouble();
    final statuses = OrderStatus.values.asNameMap();

    return Order(
      id: id,
      userId: data['userId'] as String? ?? '',
      items: [
        for (final item in data['items'] as List? ?? const [])
          OrderItem(
            productId: item['productId'] as String? ?? '',
            title: item['title'] as String? ?? '',
            thumbnail: item['thumbnail'] as String? ?? '',
            unitPrice: number(item['unitPrice']),
            originalUnitPrice: number(item['originalUnitPrice']),
            quantity: (item['quantity'] as num? ?? 0).toInt(),
          ),
      ],
      subtotal: number(data['subtotal']),
      discount: number(data['discount']),
      shippingFee: number(data['shippingFee']),
      total: number(data['total']),
      status: statuses[data['status']] ?? OrderStatus.pending,
      shippingAddress: AddressRepository.addressFromMap(data['shippingAddress'] as Map<String, dynamic>? ?? const {}),
      shippingMethod: ShippingMethod.values.asNameMap()[data['shippingMethod']] ?? ShippingMethod.standard,
      paymentMethod: PaymentMethod.values.asNameMap()[data['paymentMethod']] ?? PaymentMethod.card,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      statusTimes: {
        for (final MapEntry(:key, :value) in (data['statusUpdatedAt'] as Map? ?? const {}).entries)
          if (statuses[key] != null && value is Timestamp) statuses[key]!: value.toDate(),
      },
      cancelledBy: CancelledBy.values.asNameMap()[data['cancelledBy']],
    );
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(firestoreProvider));
});

final userOrdersProvider = StreamProvider<List<Order>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(orderRepositoryProvider).watchUserOrders(uid);
});

/// All orders for the admin panel; null shows every status.
final allOrdersProvider = StreamProvider.family<List<Order>, OrderStatus?>((ref, status) {
  return ref.watch(orderRepositoryProvider).watchAllOrders(status: status);
});

final orderProvider = StreamProvider.family<Order?, String>((ref, id) {
  return ref.watch(orderRepositoryProvider).watchOrder(id);
});
