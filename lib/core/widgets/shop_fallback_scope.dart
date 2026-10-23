import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';

/// For full-screen pages that are usually pushed but can also be opened
/// directly, e.g. right after signing in. With nothing to go back to, back
/// leads to the shop instead of closing the app.
class ShopFallbackScope extends StatelessWidget {
  const ShopFallbackScope({super.key, required this.child});

  final Widget child;

  /// App bar leading widget: the default back button when there is a page to
  /// return to, otherwise one that goes to the shop.
  static Widget? leading(BuildContext context) {
    return context.canPop() ? null : BackButton(onPressed: () => context.go(AppRoutes.catalog));
  }

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.catalog);
      },
      child: child,
    );
  }
}
