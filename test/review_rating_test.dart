import 'package:appstore/features/orders/domain/order.dart';
import 'package:appstore/features/reviews/domain/rating.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('addRating', () {
    test('uses the new rating when there are none yet', () {
      expect(addRating(currentAverage: 0, count: 0, newRating: 4), 4);
    });

    test('averages the new rating in', () {
      expect(addRating(currentAverage: 4, count: 3, newRating: 2), 3.5);
      expect(addRating(currentAverage: 5, count: 1, newRating: 1), 3);
    });

    test('rounds to two decimals', () {
      expect(addRating(currentAverage: 4.94, count: 3, newRating: 5), 4.96);
    });
  });

  test('customers can cancel only pending orders', () {
    expect(OrderStatus.pending.canCustomerCancel, isTrue);
    for (final status in [OrderStatus.processing, OrderStatus.shipped, OrderStatus.delivered, OrderStatus.cancelled]) {
      expect(status.canCustomerCancel, isFalse, reason: status.name);
    }
  });
}
