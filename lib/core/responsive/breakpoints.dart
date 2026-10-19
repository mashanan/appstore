import 'package:flutter/widgets.dart';

/// Material 3 window size classes.
enum WindowSize { compact, medium, expanded }

abstract final class Breakpoints {
  /// Phones in portrait.
  static const double medium = 600;

  /// Large tablets and unfolded foldables.
  static const double expanded = 840;

  static WindowSize of(double width) {
    if (width >= expanded) return WindowSize.expanded;
    if (width >= medium) return WindowSize.medium;
    return WindowSize.compact;
  }

  /// Number of product grid columns for the available [width].
  static int gridColumns(double width) => switch (of(width)) {
        WindowSize.compact => 2,
        WindowSize.medium => 3,
        WindowSize.expanded => width >= 1200 ? 5 : 4,
      };
}

extension ResponsiveContext on BuildContext {
  WindowSize get windowSize => Breakpoints.of(MediaQuery.sizeOf(this).width);

  bool get isCompact => windowSize == WindowSize.compact;
}
