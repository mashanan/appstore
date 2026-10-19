import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/constrained_content.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/data/user_repository.dart';
import '../../products/presentation/widgets/product_image.dart';
import '../data/order_repository.dart';
import '../domain/order.dart';
import 'widgets/order_status_chip.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId, this.adminMode = false});

  final String orderId;

  /// Shows the status controls admins use to process the order.
  final bool adminMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderProvider(orderId));
    final order = orderAsync.value;
    final isAdmin = ref.watch(currentUserProvider).value?.isAdmin ?? false;
    final showAdminActions =
        adminMode && isAdmin && order != null && (order.status.next != null || order.status.canCancel);

    return Scaffold(
      appBar: AppBar(title: Text(order == null ? 'Order' : 'Order #${order.number}')),
      bottomNavigationBar: showAdminActions ? _AdminActions(order: order) : null,
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const EmptyState(icon: Icons.cloud_off_outlined, title: 'Could not load this order'),
        data: (order) => order == null
            ? const EmptyState(icon: Icons.search_off, title: 'Order not found')
            : ConstrainedContent(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _StatusCard(order: order),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Items',
                      child: Column(children: [for (final item in order.items) _ItemRow(item: item)]),
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Delivery',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order.shippingAddress.fullName} · ${order.shippingAddress.phone}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(order.shippingAddress.singleLine),
                          const SizedBox(height: 12),
                          _InfoRow(icon: Icons.local_shipping_outlined, text: order.shippingMethod.label),
                          _InfoRow(icon: Icons.payments_outlined, text: order.paymentMethod.label),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Section(title: 'Payment summary', child: _Totals(order: order)),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order});

  static const _steps = [
    (OrderStatus.pending, Icons.receipt_long_outlined),
    (OrderStatus.processing, Icons.inventory_2_outlined),
    (OrderStatus.shipped, Icons.local_shipping_outlined),
    (OrderStatus.delivered, Icons.home_outlined),
  ];

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentStep = _steps.indexWhere((step) => step.$1 == order.status);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Placed ${formatOrderDate(order.createdAt)}', style: theme.textTheme.bodySmall)),
                OrderStatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 20),
            if (order.status == OrderStatus.cancelled)
              Row(
                children: [
                  Icon(Icons.cancel_outlined, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This order was cancelled'
                      '${order.timeOf(OrderStatus.cancelled) == null ? '' : ' on ${formatOrderDate(order.timeOf(OrderStatus.cancelled))}'}.',
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  for (final (index, (status, icon)) in _steps.indexed) ...[
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index <= currentStep ? colorScheme.primary : colorScheme.outlineVariant,
                        ),
                      ),
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              index <= currentStep ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                          child: Icon(
                            icon,
                            size: 18,
                            color: index <= currentStep ? colorScheme.onPrimary : colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          status.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: index == currentStep ? FontWeight.bold : null,
                          ),
                        ),
                        // Keeps every step the same height whether or not it has a date yet.
                        Text(
                          order.timeOf(status) == null || index > currentStep
                              ? ''
                              : DateFormat.MMMd().format(order.timeOf(status)!),
                          style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Admin controls: advance the order one step, or cancel it while still possible.
class _AdminActions extends ConsumerStatefulWidget {
  const _AdminActions({required this.order});

  final Order order;

  @override
  ConsumerState<_AdminActions> createState() => _AdminActionsState();
}

class _AdminActionsState extends ConsumerState<_AdminActions> {
  bool _isUpdating = false;

  static String _actionLabel(OrderStatus next) => switch (next) {
        OrderStatus.processing => 'Start processing',
        OrderStatus.shipped => 'Mark as shipped',
        OrderStatus.delivered => 'Mark as delivered',
        _ => 'Move to ${next.label}',
      };

  Future<void> _run(Future<void> Function() action, String successMessage) async {
    setState(() => _isUpdating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(successMessage), duration: const Duration(seconds: 2)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Could not update the order: $error')));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel order #${widget.order.number}?'),
        content: const Text('The customer will see it as cancelled and the items go back in stock.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep order')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel order')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() => ref.read(orderRepositoryProvider).cancel(widget.order), 'Order cancelled.');
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final next = order.status.next;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 8,
      color: colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (order.status.canCancel)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isUpdating ? null : _cancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: colorScheme.error,
                    ),
                    child: const Text('Cancel order'),
                  ),
                ),
              if (order.status.canCancel && next != null) const SizedBox(width: 12),
              if (next != null)
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _isUpdating
                        ? null
                        : () => _run(
                              () => ref.read(orderRepositoryProvider).updateStatus(order.id, next),
                              'Order marked as ${next.label.toLowerCase()}.',
                            ),
                    child: _isUpdating
                        ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_actionLabel(next)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.go(AppRoutes.productDetail(item.productId)),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox.square(dimension: 56, child: ProductImage(url: item.thumbnail)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${item.quantity} × ${formatPrice(item.unitPrice)}', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(formatPrice(item.total), style: theme.textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget row(String label, String value, {TextStyle? style}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(label, style: style), Text(value, style: style)],
          ),
        );

    return Column(
      children: [
        row('Subtotal', formatPrice(order.subtotal)),
        if (order.discount > 0)
          row('Discount', '-${formatPrice(order.discount)}', style: TextStyle(color: theme.colorScheme.primary)),
        row('Shipping', order.shippingFee == 0 ? 'Free' : formatPrice(order.shippingFee)),
        const Divider(height: 20),
        row('Total', formatPrice(order.total), style: theme.textTheme.titleMedium),
      ],
    );
  }
}
