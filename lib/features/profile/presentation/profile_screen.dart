import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/constrained_content.dart';
import '../../addresses/data/address_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/user_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).value;
    final defaultAddress = ref.watch(defaultAddressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ConstrainedContent(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 28,
                child: Text(
                  (user?.displayName.isNotEmpty ?? false) ? user!.displayName[0].toUpperCase() : '?',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              title: Text(user?.displayName ?? '', style: theme.textTheme.titleMedium),
              subtitle: Text([user?.email, user?.phone].whereType<String>().join('\n')),
              isThreeLine: user?.phone != null,
            ),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit profile'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.editProfile),
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('My addresses'),
              subtitle: Text(
                defaultAddress?.address.singleLine ?? 'No address saved yet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.addresses),
            ),
            if (user?.isAdmin ?? false)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin panel'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.admin),
              ),
            const Divider(height: 32),
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text('Sign out', style: TextStyle(color: theme.colorScheme.error)),
              onTap: () => ref.read(authRepositoryProvider).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
