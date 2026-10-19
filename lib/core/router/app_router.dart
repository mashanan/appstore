import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/addresses/presentation/address_form_screen.dart';
import '../../features/addresses/presentation/addresses_screen.dart';
import '../../features/admin/presentation/admin_orders_screen.dart';
import '../../features/admin/presentation/admin_products_screen.dart';
import '../../features/admin/presentation/admin_screen.dart';
import '../../features/admin/presentation/product_form_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/checkout/presentation/order_placed_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/products/presentation/catalog_screen.dart';
import '../../features/products/presentation/product_detail_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../widgets/app_shell.dart';
import 'app_routes.dart';
import 'auth_redirect.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final authRefresh = _StreamListenable(authRepository.userChanges());

  final router = GoRouter(
    initialLocation: AppRoutes.catalog,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final user = authRepository.currentUser;
      return authRedirect(uri: state.uri, signedIn: user != null, emailVerified: user?.emailVerified ?? false);
    },
    routes: [
      GoRoute(path: AppRoutes.signIn, builder: (context, state) => const SignInScreen()),
      GoRoute(path: AppRoutes.signUp, builder: (context, state) => const SignUpScreen()),
      GoRoute(path: AppRoutes.verifyEmail, builder: (context, state) => const VerifyEmailScreen()),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminScreen(),
        routes: [
          GoRoute(
            path: 'products',
            builder: (context, state) => const AdminProductsScreen(),
            routes: [
              GoRoute(path: 'new', builder: (context, state) => const ProductFormScreen()),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) => ProductFormScreen(productId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: 'orders',
            builder: (context, state) => const AdminOrdersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => OrderDetailScreen(orderId: state.pathParameters['id']!, adminMode: true),
              ),
            ],
          ),
        ],
      ),
      // Address forms sit outside the shell so they can be pushed from checkout and profile alike.
      GoRoute(path: AppRoutes.newAddress, builder: (context, state) => const AddressFormScreen()),
      GoRoute(
        path: '/addresses/:id/edit',
        builder: (context, state) => AddressFormScreen(addressId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/order-placed/:id',
        builder: (context, state) => OrderPlacedScreen(orderId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.catalog,
              builder: (context, state) => const CatalogScreen(),
              routes: [
                GoRoute(
                  path: 'products/:id',
                  builder: (context, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.cart,
              builder: (context, state) => const CartScreen(),
              routes: [
                GoRoute(path: 'checkout', builder: (context, state) => const CheckoutScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.orders,
              builder: (context, state) => const OrdersScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => OrderDetailScreen(orderId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(path: 'edit', builder: (context, state) => const EditProfileScreen()),
                GoRoute(path: 'addresses', builder: (context, state) => const AddressesScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authRefresh.dispose();
  });
  return router;
});

/// Re-runs the router's redirect every time [stream] emits, e.g. on sign-in and sign-out.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
