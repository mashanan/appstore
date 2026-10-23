import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shop_fallback_scope.dart';
import '../../products/presentation/widgets/product_card.dart';
import '../data/wishlist_repository.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShopFallbackScope(
      child: Scaffold(
        appBar: AppBar(leading: ShopFallbackScope.leading(context), title: const Text('Wishlist')),
        body: ref
            .watch(wishlistProductsProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  const EmptyState(icon: Icons.cloud_off_outlined, title: 'Could not load your wishlist'),
              data: (products) {
                if (products.isEmpty) {
                  return EmptyState(
                    icon: Icons.favorite_border,
                    title: 'Your wishlist is empty',
                    message: 'Tap the heart on any product to save it for later.',
                    action: FilledButton.tonal(
                      onPressed: () => context.go(AppRoutes.catalog),
                      child: const Text('Browse products'),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) => GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Breakpoints.gridColumns(constraints.maxWidth),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        hero: false,
                        onTap: () => context.push(AppRoutes.productDetail(product.id)),
                      );
                    },
                  ),
                );
              },
            ),
      ),
    );
  }
}
