import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/constrained_content.dart';
import '../../../core/widgets/empty_state.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/domain/order.dart';
import '../../orders/presentation/widgets/order_card.dart';
import 'admin_guard.dart';

/// Every customer's orders, filterable by status.
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  OrderStatus? _status = OrderStatus.pending;

  @override
  Widget build(BuildContext context) {
    final filters = <(OrderStatus?, String)>[
      (null, 'All'),
      for (final status in OrderStatus.values) (status, status.label),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Manage orders')),
      body: AdminGuard(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final (status, label) = filters[index];
                  return Center(
                    child: ChoiceChip(
                      label: Text(label),
                      selected: status == _status,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _status = status),
                    ),
                  );
                },
              ),
            ),
            Expanded(child: _OrderList(status: _status)),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends ConsumerWidget {
  const _OrderList({required this.status});

  final OrderStatus? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(allOrdersProvider(status)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load orders',
            message: 'If you just deployed indexes, wait a minute and retry.',
            action: FilledButton.tonal(
              onPressed: () => ref.invalidate(allOrdersProvider(status)),
              child: const Text('Retry'),
            ),
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return EmptyState(
                icon: Icons.inbox_outlined,
                title: status == null ? 'No orders yet' : 'No ${status!.label.toLowerCase()} orders',
              );
            }

            return ConstrainedContent(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: orders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return OrderCard(
                    order: order,
                    showCustomer: true,
                    onTap: () => context.push(AppRoutes.adminOrderDetail(order.id)),
                  );
                },
              ),
            );
          },
        );
  }
}
