import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/order.dart';

/// Color used for an order status across the app.
Color orderStatusColor(BuildContext context, OrderStatus status) {
  return switch (status) {
    OrderStatus.pending => Colors.orange,
    OrderStatus.processing => Colors.blue,
    OrderStatus.shipped => Colors.indigo,
    OrderStatus.delivered => Colors.green,
    OrderStatus.cancelled => Theme.of(context).colorScheme.error,
  };
}

/// e.g. "Oct 19, 2026 · 3:42 PM", or "Just now" while the server timestamp is pending.
String formatOrderDate(DateTime? date) {
  if (date == null) return 'Just now';
  return '${DateFormat.yMMMd().format(date)} · ${DateFormat.jm().format(date)}';
}

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(context, status);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          status.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
