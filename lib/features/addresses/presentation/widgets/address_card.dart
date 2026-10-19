import 'package:flutter/material.dart';

import '../../domain/address.dart';

/// Shows one saved address. Highlighted when [selected].
class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    this.isDefault = false,
    this.selected = false,
    this.onTap,
    this.trailing,
  });

  final SavedAddress address;
  final bool isDefault;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final details = address.address;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: selected ? colorScheme.secondaryContainer : colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? colorScheme.primary : colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(address.label, style: theme.textTheme.titleSmall),
                        if (isDefault)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Text(
                                'Default',
                                style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onPrimaryContainer),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${details.fullName} · ${details.phone}', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      details.singleLine,
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
