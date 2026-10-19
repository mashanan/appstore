/// Route paths used across the app.
abstract final class AppRoutes {
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const verifyEmail = '/verify-email';

  static const catalog = '/';
  static const cart = '/cart';
  static const checkout = '/cart/checkout';
  static const orders = '/orders';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const addresses = '/profile/addresses';
  static const newAddress = '/addresses/new';
  static const admin = '/admin';
  static const adminOrders = '/admin/orders';

  static String productDetail(String productId) => '/products/$productId';

  static String orderPlaced(String orderId) => '/order-placed/$orderId';

  static String orderDetail(String orderId) => '/orders/$orderId';

  static String adminOrderDetail(String orderId) => '/admin/orders/$orderId';

  static String editAddress(String addressId) => '/addresses/$addressId/edit';
}
