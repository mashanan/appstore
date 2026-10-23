import 'package:tokoku/features/orders/domain/order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('orders move forward one step at a time', () {
    expect(OrderStatus.pending.next, OrderStatus.processing);
    expect(OrderStatus.processing.next, OrderStatus.shipped);
    expect(OrderStatus.shipped.next, OrderStatus.delivered);
    expect(OrderStatus.delivered.next, isNull);
    expect(OrderStatus.cancelled.next, isNull);
  });

  test('orders can be cancelled only before they ship', () {
    expect(OrderStatus.pending.canCancel, isTrue);
    expect(OrderStatus.processing.canCancel, isTrue);
    expect(OrderStatus.shipped.canCancel, isFalse);
    expect(OrderStatus.delivered.canCancel, isFalse);
    expect(OrderStatus.cancelled.canCancel, isFalse);
  });
}
