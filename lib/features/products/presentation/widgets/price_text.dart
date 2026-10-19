import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/product.dart';

/// Discounted price, with the original price struck through when on sale.
class PriceText extends StatelessWidget {
  const PriceText({super.key, required this.product, this.style});

  final Product product;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceStyle = (style ?? theme.textTheme.titleSmall)?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 6,
      children: [
        Text(formatPrice(product.discountedPrice), style: priceStyle),
        if (product.hasDiscount)
          Text(
            formatPrice(product.price),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }
}
