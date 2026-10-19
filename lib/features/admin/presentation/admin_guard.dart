import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/empty_state.dart';
import '../../auth/data/user_repository.dart';

/// Shows [child] only to admins. Firestore rules are the real protection;
/// this keeps non-admins from seeing screens that would just fail.
class AdminGuard extends ConsumerWidget {
  const AdminGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(currentUserProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => const EmptyState(icon: Icons.error_outline, title: 'Could not load your account'),
          data: (user) => (user?.isAdmin ?? false)
              ? child
              : const EmptyState(
                  icon: Icons.lock_outline,
                  title: 'Admins only',
                  message: 'Your account does not have access to this page.',
                ),
        );
  }
}
