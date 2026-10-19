import 'app_routes.dart';

/// Decides where the router should send the user, or null to stay put.
///
/// Guests can browse the catalog and product pages; anything else sends them
/// to sign in with a `from` parameter, so they come back after signing in.
/// Signed-in users must verify their email before using the app.
String? authRedirect({required Uri uri, required bool signedIn, required bool emailVerified}) {
  final path = uri.path;
  final onAuthScreen = path == AppRoutes.signIn || path == AppRoutes.signUp;
  final isPublic = path == AppRoutes.catalog || path.startsWith('/products/');

  if (!signedIn) {
    if (onAuthScreen || isPublic) return null;
    return Uri(path: AppRoutes.signIn, queryParameters: {'from': uri.toString()}).toString();
  }

  if (!emailVerified) return path == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;

  if (onAuthScreen || path == AppRoutes.verifyEmail) return safeReturnPath(uri.queryParameters['from']);
  return null;
}

/// Only allows in-app paths, so a crafted link can't send users elsewhere.
String safeReturnPath(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) return AppRoutes.catalog;
  return from;
}
