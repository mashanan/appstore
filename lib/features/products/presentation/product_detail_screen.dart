import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../cart/data/cart_repository.dart';
import '../../cart/presentation/widgets/quantity_stepper.dart';
import '../data/product_repository.dart';
import '../domain/product.dart';
import 'widgets/price_text.dart';
import 'widgets/product_image.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const EmptyState(icon: Icons.cloud_off_outlined, title: 'Could not load this product'),
        data: (product) => product == null
            ? const EmptyState(icon: Icons.search_off, title: 'Product not found')
            : _ProductDetailBody(product: product),
      ),
      bottomNavigationBar: productAsync.value == null ? null : _AddToCartBar(product: productAsync.value!),
    );
  }
}

class _ProductDetailBody extends StatelessWidget {
  const _ProductDetailBody({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final gallery = _ImageGallery(product: product);
    final info = _ProductInfo(product: product);

    // Tablets show the gallery and the details side by side.
    if (context.windowSize == WindowSize.expanded) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Padding(padding: const EdgeInsets.all(24), child: gallery)),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: info)),
        ],
      );
    }

    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              gallery,
              Padding(padding: const EdgeInsets.all(16), child: info),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageGallery extends StatefulWidget {
  const _ImageGallery({required this.product});

  final Product product;

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.images.isEmpty ? [product.thumbnail] : product.images;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ColoredBox(
            color: colorScheme.surfaceContainerLow,
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) {
                final image = ProductImage(url: images[index], fit: BoxFit.contain);
                return index == 0 ? Hero(tag: 'product-${product.id}', child: image) : image;
              },
            ),
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? colorScheme.primary : colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.brand != null) Text(product.brand!.toUpperCase(), style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(product.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 20, color: Colors.amber),
            const SizedBox(width: 4),
            Text('${product.rating.toStringAsFixed(1)} · ${product.reviews.length} reviews', style: muted),
          ],
        ),
        const SizedBox(height: 16),
        PriceText(product: product, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          product.inStock ? '${product.stock} in stock' : 'Out of stock',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: product.inStock ? theme.colorScheme.primary : theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 24),
        Text('Description', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(product.description, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        for (final (icon, text) in [
          (Icons.local_shipping_outlined, product.shippingInformation),
          (Icons.verified_user_outlined, product.warrantyInformation),
          (Icons.assignment_return_outlined, product.returnPolicy),
        ])
          if (text != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(icon),
              title: Text(text),
            ),
        if (product.reviews.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Reviews', style: theme.textTheme.titleMedium),
          for (final review in product.reviews) _ReviewTile(review: review),
        ],
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ProductReview review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(review.reviewerName, style: theme.textTheme.titleSmall)),
              if (review.date != null) Text(DateFormat.yMMMd().format(review.date!), style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 16,
                  color: Colors.amber,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(review.comment, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _AddToCartBar extends ConsumerStatefulWidget {
  const _AddToCartBar({required this.product});

  final Product product;

  @override
  ConsumerState<_AddToCartBar> createState() => _AddToCartBarState();
}

class _AddToCartBarState extends ConsumerState<_AddToCartBar> {
  int _quantity = 1;
  bool _isAdding = false;

  Future<void> _addToCart(int quantity) async {
    setState(() => _isAdding = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(cartRepositoryProvider).add(widget.product, quantity: quantity);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Added $quantity to your cart.'),
          duration: const Duration(seconds: 2),
          // Snack bars with an action stay until dismissed by default; this one shouldn't.
          persist: false,
          action: SnackBarAction(
            label: 'View cart',
            onPressed: () {
              if (mounted) context.go(AppRoutes.cart);
            },
          ),
        ));
      if (mounted) setState(() => _quantity = 1);
    } catch (error) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not add to cart. Please try again.')));
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final inCart = ref.watch(cartQuantityProvider(product.id));
    final maxAddable = product.stock - inCart;
    // The cart may change elsewhere, so keep the picked quantity within what's left.
    final quantity = maxAddable < 1 ? 1 : (_quantity > maxAddable ? maxAddable : _quantity);

    final String label;
    if (!product.inStock) {
      label = 'Out of stock';
    } else if (maxAddable <= 0) {
      label = 'All stock is in your cart';
    } else {
      label = 'Add to cart';
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (inCart > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('$inCart already in your cart', style: Theme.of(context).textTheme.bodySmall),
              ),
            Row(
              children: [
                if (maxAddable > 0) ...[
                  QuantityStepper(
                    value: quantity,
                    max: maxAddable,
                    onChanged: _isAdding ? null : (value) => setState(() => _quantity = value),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: maxAddable > 0 && !_isAdding ? () => _addToCart(quantity) : null,
                    icon: _isAdding
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.add_shopping_cart),
                    label: Text(label),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
