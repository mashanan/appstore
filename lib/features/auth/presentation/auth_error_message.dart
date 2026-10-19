import 'package:firebase_auth/firebase_auth.dart';

/// Turns Firebase Auth errors into messages that make sense to users.
String authErrorMessage(Object error) {
  if (error is! FirebaseAuthException) return 'Something went wrong. Please try again.';

  return switch (error.code) {
    'invalid-credential' || 'wrong-password' || 'user-not-found' => 'Incorrect email or password.',
    'invalid-email' => 'Please enter a valid email address.',
    'email-already-in-use' => 'An account with this email already exists.',
    'weak-password' => 'Password must be at least 6 characters.',
    'user-disabled' => 'This account has been disabled.',
    'too-many-requests' => 'Too many attempts. Please wait a moment and try again.',
    'network-request-failed' => 'No internet connection. Please check your network.',
    _ => error.message ?? 'Something went wrong. Please try again.',
  };
}
