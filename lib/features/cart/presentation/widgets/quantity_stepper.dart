import 'package:flutter/material.dart';

/// Compact − value + control. Buttons disable at [min] and [max].
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    required this.max,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease quantity',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove),
            onPressed: onChanged == null || value <= min ? null : () => onChanged!(value - 1),
          ),
          SizedBox(
            width: 28,
            child: Text('$value', textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
          ),
          IconButton(
            tooltip: 'Increase quantity',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add),
            onPressed: onChanged == null || value >= max ? null : () => onChanged!(value + 1),
          ),
        ],
      ),
    );
  }
}
