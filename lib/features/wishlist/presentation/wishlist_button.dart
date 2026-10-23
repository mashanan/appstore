import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../auth/data/auth_repository.dart';
import '../data/wishlist_repository.dart';

/// Heart toggle that saves a product to the wishlist. Guests are sent to sign in.
class WishlistButton extends ConsumerWidget {
  const WishlistButton({super.key, required this.productId, this.onImage = false});

  final String productId;

  /// Adds a translucent background so the icon stays visible on photos.
  final bool onImage;

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool saved) async {
    if (ref.read(authStateProvider).value == null) {
      context.go(AppRoutes.signInFrom(GoRouterState.of(context).uri.toString()));
      return;
    }

    HapticFeedback.lightImpact();
    final repository = ref.read(wishlistRepositoryProvider);
    try {
      await (saved ? repository.remove(productId) : repository.add(productId));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Could not update your wishlist. Please try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(isWishlistedProvider(productId));
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: saved ? 'Remove from wishlist' : 'Save to wishlist',
      isSelected: saved,
      visualDensity: onImage ? VisualDensity.compact : null,
      style: onImage ? IconButton.styleFrom(backgroundColor: colorScheme.surface.withValues(alpha: 0.85)) : null,
      icon: const Icon(Icons.favorite_border),
      selectedIcon: Icon(Icons.favorite, color: colorScheme.error),
      onPressed: () => _toggle(context, ref, saved),
    );
  }
}
