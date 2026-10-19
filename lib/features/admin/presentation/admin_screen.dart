import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/constrained_content.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/domain/order.dart';
import '../data/catalog_import_service.dart';
import 'admin_guard.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin panel')),
      body: const AdminGuard(
        child: ConstrainedContent(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ManageOrdersCard(),
                SizedBox(height: 12),
                _ImportCatalogCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManageOrdersCard extends ConsumerWidget {
  const _ManageOrdersCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(allOrdersProvider(OrderStatus.pending)).value?.length;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Badge(
          isLabelVisible: (pendingCount ?? 0) > 0,
          label: Text('$pendingCount'),
          child: Icon(Icons.receipt_long_outlined, color: Theme.of(context).colorScheme.primary),
        ),
        title: const Text('Manage orders'),
        subtitle: Text(switch (pendingCount) {
          null => 'Loading…',
          0 => 'No orders waiting',
          1 => '1 order waiting to be processed',
          final count => '$count orders waiting to be processed',
        }),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.adminOrders),
      ),
    );
  }
}

class _ImportCatalogCard extends ConsumerStatefulWidget {
  const _ImportCatalogCard();

  @override
  ConsumerState<_ImportCatalogCard> createState() => _ImportCatalogCardState();
}

class _ImportCatalogCardState extends ConsumerState<_ImportCatalogCard> {
  bool _isImporting = false;

  Future<void> _import() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import demo catalog?'),
        content: const Text(
          'This copies all DummyJSON products and categories into Firestore. '
          'Products imported earlier are overwritten with the original data.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Import')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isImporting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref.read(catalogImportServiceProvider).importDemoCatalog();
      messenger.showSnackBar(
        SnackBar(content: Text('Imported ${result.products} products and ${result.categories} categories.')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $error')));
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_download_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text('Demo catalog', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Fill the store with ~190 products from DummyJSON. Safe to run again.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isImporting ? null : _import,
              icon: _isImporting
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download),
              label: Text(_isImporting ? 'Importing...' : 'Import demo catalog'),
            ),
          ],
        ),
      ),
    );
  }
}
