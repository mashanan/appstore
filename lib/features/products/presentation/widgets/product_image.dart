import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/image_repository.dart';

/// Product photo from either a web URL or an `image:<id>` stored in Firestore,
/// with a neutral placeholder and a broken-image fallback.
class ProductImage extends ConsumerWidget {
  const ProductImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(color: colorScheme.surfaceContainerHighest);
    final broken = ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.broken_image_outlined, color: colorScheme.outline),
    );

    if (url.isEmpty) return placeholder;

    if (ImageRepository.isStoredImage(url)) {
      return ref.watch(storedImageProvider(ImageRepository.idOf(url))).when(
            loading: () => placeholder,
            error: (error, _) => broken,
            data: (bytes) => bytes == null
                ? broken
                : Image.memory(bytes, fit: fit, gaplessPlayback: true, errorBuilder: (_, _, _) => broken),
          );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, url) => placeholder,
      errorWidget: (context, url, error) => broken,
    );
  }
}
