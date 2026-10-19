import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/constrained_content.dart';
import '../../../core/widgets/empty_state.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product.dart';
import '../../products/domain/product_search.dart';
import '../../products/presentation/widgets/product_image.dart';
import 'admin_guard.dart';

/// Searchable list of every product, with add, edit and delete.
class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  static const _lowStock = 5;

  String _query = '';

  Future<void> _delete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${product.title}"?'),
        content: const Text('It disappears from the shop. Past orders keep their copy of it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(productRepositoryProvider).deleteProduct(product.id);
      messenger.showSnackBar(const SnackBar(content: Text('Product deleted.'), duration: Duration(seconds: 2)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not delete the product. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage products')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newProduct),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: AdminGuard(
        child: ref.watch(productsProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => const EmptyState(icon: Icons.cloud_off_outlined, title: 'Could not load products'),
              data: (products) {
                final results = searchProducts(products, _query);

                return ConstrainedContent(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: SearchBar(
                          hintText: 'Search ${products.length} products',
                          leading: const Icon(Icons.search),
                          elevation: const WidgetStatePropertyAll(0),
                          onChanged: (value) => setState(() => _query = value),
                        ),
                      ),
                      Expanded(
                        child: results.isEmpty
                            ? const EmptyState(icon: Icons.search_off, title: 'No matching products')
                            : ListView.separated(
                                // Leave room so the last row isn't hidden behind the button.
                                padding: const EdgeInsets.only(bottom: 96),
                                itemCount: results.length,
                                separatorBuilder: (context, index) => const Divider(height: 1, indent: 88),
                                itemBuilder: (context, index) {
                                  final product = results[index];
                                  final lowStock = product.stock <= _lowStock;
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox.square(
                                        dimension: 56,
                                        child: ProductImage(url: product.thumbnail),
                                      ),
                                    ),
                                    title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    subtitle: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(text: '${formatPrice(product.discountedPrice)} · '),
                                          TextSpan(
                                            text: product.inStock ? '${product.stock} in stock' : 'Out of stock',
                                            style: lowStock
                                                ? TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                    onTap: () => context.push(AppRoutes.editProduct(product.id)),
                                    trailing: IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _delete(product),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}
