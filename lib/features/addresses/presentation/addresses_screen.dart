import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/constrained_content.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/address_repository.dart';
import '../domain/address.dart';
import 'widgets/address_card.dart';

enum _AddressAction { edit, makeDefault, delete }

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  Future<void> _onAction(BuildContext context, WidgetRef ref, _AddressAction action, SavedAddress address,
      {required bool isDefault}) async {
    final repository = ref.read(addressRepositoryProvider);
    switch (action) {
      case _AddressAction.edit:
        await context.push(AppRoutes.editAddress(address.id));
      case _AddressAction.makeDefault:
        await repository.setDefault(address.id);
      case _AddressAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete "${address.label}"?'),
            content: const Text('This address will be removed from your address book.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        );
        if (confirmed == true) await repository.delete(address.id, isDefault: isDefault);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);
    final defaultId = ref.watch(defaultAddressProvider)?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('My addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newAddress),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add address'),
      ),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const EmptyState(icon: Icons.cloud_off_outlined, title: 'Could not load addresses'),
        data: (addresses) {
          if (addresses.isEmpty) {
            return const EmptyState(
              icon: Icons.location_on_outlined,
              title: 'No addresses yet',
              message: 'Save an address to check out faster.',
            );
          }

          return ConstrainedContent(
            child: ListView(
              // Leave room so the last card isn't hidden behind the button.
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                for (final address in addresses)
                  AddressCard(
                    address: address,
                    isDefault: address.id == defaultId,
                    onTap: () => context.push(AppRoutes.editAddress(address.id)),
                    trailing: PopupMenuButton<_AddressAction>(
                      tooltip: 'More options',
                      onSelected: (action) =>
                          _onAction(context, ref, action, address, isDefault: address.id == defaultId),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: _AddressAction.edit, child: Text('Edit')),
                        if (address.id != defaultId)
                          const PopupMenuItem(value: _AddressAction.makeDefault, child: Text('Set as default')),
                        const PopupMenuItem(value: _AddressAction.delete, child: Text('Delete')),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
