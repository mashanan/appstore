import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/product_repository.dart';

/// Horizontally scrolling category filter. [selected] is a category slug, or
/// null for "All".
class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key, required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    if (categories.isEmpty) return const SizedBox.shrink();

    final options = <(String?, String)>[
      (null, 'All'),
      for (final category in categories) (category.slug, category.name),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (slug, name) = options[index];
          return Center(
            child: ChoiceChip(
              label: Text(name),
              selected: slug == selected,
              showCheckmark: false,
              onSelected: (_) => onSelected(slug),
            ),
          );
        },
      ),
    );
  }
}
