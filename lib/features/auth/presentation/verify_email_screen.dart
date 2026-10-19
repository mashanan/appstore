import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../data/auth_repository.dart';
import 'auth_error_message.dart';
import 'auth_form_layout.dart';

/// Holds unverified users until they open the link in their verification email.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const _resendCooldown = 30;

  Timer? _pollTimer;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Move on automatically once the user verifies in their email app.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkVerified(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _checkVerified({bool silent = false}) async {
    if (_isChecking) return;
    if (!silent) setState(() => _isChecking = true);
    try {
      final verified = await ref.read(authRepositoryProvider).reloadAndCheckEmailVerified();
      if (verified) {
        // reload() doesn't always emit on userChanges, so re-run the redirect explicitly.
        ref.read(routerProvider).refresh();
      } else if (!silent && mounted) {
        _showMessage('Your email is not verified yet. Please open the link we sent you.');
      }
    } catch (error) {
      if (!silent && mounted) _showMessage(authErrorMessage(error));
    } finally {
      if (!silent && mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (!mounted) return;
      _showMessage('Verification email sent.');
      setState(() => _cooldownSeconds = _resendCooldown);
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return timer.cancel();
        setState(() => _cooldownSeconds--);
        if (_cooldownSeconds <= 0) timer.cancel();
      });
    } catch (error) {
      if (mounted) _showMessage(authErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = ref.watch(authRepositoryProvider).currentUser?.email ?? 'your email';

    return AuthFormLayout(
      title: 'Verify your email',
      subtitle: 'We sent a verification link to $email. Open it to activate your account.',
      children: [
        Text(
          "Can't find it? Check your spam folder.",
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isChecking ? null : _checkVerified,
          child: _isChecking
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("I've verified my email"),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _cooldownSeconds > 0 ? null : _resend,
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(_cooldownSeconds > 0 ? 'Resend email in ${_cooldownSeconds}s' : 'Resend email'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
          child: const Text('Use a different account'),
        ),
      ],
    );
  }
}
