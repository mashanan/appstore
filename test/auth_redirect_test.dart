import 'package:tokoku/core/router/auth_redirect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? redirect(String location, {bool signedIn = false, bool verified = false}) =>
      authRedirect(uri: Uri.parse(location), signedIn: signedIn, emailVerified: verified);

  group('guests', () {
    test('can browse the catalog and product pages', () {
      expect(redirect('/'), isNull);
      expect(redirect('/products/12'), isNull);
      expect(redirect('/sign-in'), isNull);
    });

    test('are sent to sign in, remembering where they were going', () {
      expect(redirect('/cart'), '/sign-in?from=%2Fcart');
      expect(redirect('/orders/abc'), '/sign-in?from=%2Forders%2Fabc');
    });
  });

  test('unverified users must verify their email first', () {
    expect(redirect('/', signedIn: true), '/verify-email');
    expect(redirect('/verify-email', signedIn: true), isNull);
  });

  group('verified users', () {
    test('leave the auth screens for where they were going', () {
      expect(redirect('/sign-in?from=%2Fcart', signedIn: true, verified: true), '/cart');
      expect(redirect('/sign-in', signedIn: true, verified: true), '/');
      expect(redirect('/verify-email', signedIn: true, verified: true), '/');
    });

    test('are never sent outside the app', () {
      expect(redirect('/sign-in?from=https://evil.example', signedIn: true, verified: true), '/');
      expect(redirect('/sign-in?from=//evil.example', signedIn: true, verified: true), '/');
    });

    test('stay where they are elsewhere', () {
      expect(redirect('/cart', signedIn: true, verified: true), isNull);
    });
  });
}
