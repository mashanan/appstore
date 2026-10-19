import 'package:flutter/widgets.dart';

/// Centers [child] and caps its width so forms and text don't stretch across
/// tablet screens.
class ConstrainedContent extends StatelessWidget {
  const ConstrainedContent({super.key, this.maxWidth = 720, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
