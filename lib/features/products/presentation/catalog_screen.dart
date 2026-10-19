import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/data/auth_repository.dart';
import '../data/product_repository.dart';
import '../domain/product.dart';
import '../domain/product_search.dart';
import 'widgets/category_chips.dart';
import 'widgets/product_card.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _category = null;
    });
  }

  String _noResultsTitle() {
    final query = _query.trim();
    final categoryName = ref
        .read(categoriesProvider)
        .value
        ?.where((c) => c.slug == _category)
        .firstOrNull
        ?.name;

    if (query.isEmpty) return 'No products in $categoryName';
    if (categoryName == null) return 'No results for "$query"';
    return 'No results for "$query" in $categoryName';
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final isGuest = ref.watch(authStateProvider).value == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          if (isGuest)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => context.go(AppRoutes.signIn),
                icon: const Icon(Icons.login),
                label: const Text('Sign in'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SearchBar(
                controller: _searchController,
                hintText: 'Search products, brands, categories',
                leading: const Icon(Icons.search),
                trailing: [
                  if (_query.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: _clearSearch,
                    ),
                ],
                textInputAction: TextInputAction.search,
                elevation: const WidgetStatePropertyAll(0),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
          ),
          CategoryChips(
            selected: _category,
            onSelected: (slug) => setState(() => _category = slug),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load products',
                message: 'Check your connection and try again.',
                action: FilledButton.tonal(
                  onPressed: () => ref.invalidate(productsProvider),
                  child: const Text('Retry'),
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return const EmptyState(
                    icon: Icons.storefront_outlined,
                    title: 'No products yet',
                    message: 'Products added by the store will appear here.',
                  );
                }

                final results = searchProducts(products, _query, category: _category);
                if (results.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: _noResultsTitle(),
                    message: 'Try a different keyword or category.',
                    action: FilledButton.tonal(onPressed: _clearFilters, child: const Text('Clear filters')),
                  );
                }

                return _ProductGrid(products: results);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
            onTap: () => context.go(AppRoutes.productDetail(product.id)),
          );
        },
      ),
    );
  }
}
