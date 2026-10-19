import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Network image with a neutral placeholder and a broken-image fallback.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(color: colorScheme.surfaceContainerHighest);

    if (url.isEmpty) return placeholder;

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, url) => placeholder,
      errorWidget: (context, url, error) => ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(Icons.broken_image_outlined, color: colorScheme.outline),
      ),
    );
  }
}
