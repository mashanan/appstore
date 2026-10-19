import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../products/presentation/widgets/product_image.dart';
import '../../domain/order.dart';
import 'order_status_chip.dart';

/// Order summary used in the customer's history and the admin order list.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap, this.showCustomer = false});

  static const _maxThumbnails = 4;

  final Order order;
  final VoidCallback onTap;

  /// Shows the recipient's name, for admins looking across customers.
  final bool showCustomer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extraItems = order.items.length - _maxThumbnails;
    final subtitle = [
      if (showCustomer) order.shippingAddress.fullName,
      formatOrderDate(order.createdAt),
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order #${order.number}', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(subtitle, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final item in order.items.take(_maxThumbnails))
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox.square(dimension: 52, child: ProductImage(url: item.thumbnail)),
                      ),
                    ),
                  if (extraItems > 0) Text('+$extraItems more', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(formatPrice(order.total), style: theme.textTheme.titleMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
