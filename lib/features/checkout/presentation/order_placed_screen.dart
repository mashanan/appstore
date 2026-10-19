import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/domain/order.dart';

class OrderPlacedScreen extends ConsumerWidget {
  const OrderPlacedScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final order = ref.watch(orderProvider(orderId)).value;

    return PopScope(
      // There's no checkout to go back to, so back returns to the shop.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.catalog);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.check_circle, size: 88, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('Order placed!', style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      'Thank you for shopping with us. We will let you know when your order ships.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (order != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _DetailRow('Order number', '#${order.number}'),
                              _DetailRow('Items', '${order.itemCount}'),
                              _DetailRow('Delivery', order.shippingMethod.label),
                              _DetailRow('Payment', order.paymentMethod.label),
                              const Divider(height: 20),
                              _DetailRow('Total', formatPrice(order.total), emphasize: true),
                            ],
                          ),
                        ),
                      )
                    else
                      const Center(child: CircularProgressIndicator()),
                    if (order?.paymentMethod == PaymentMethod.bankTransfer) ...[
                      const SizedBox(height: 12),
                      Text(
                        'This is a demo, so no bank transfer is needed.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.go(AppRoutes.orders),
                      child: const Text('View my orders'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.go(AppRoutes.catalog),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: const Text('Continue shopping'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize ? Theme.of(context).textTheme.titleMedium : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
