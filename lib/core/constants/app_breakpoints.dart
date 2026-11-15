abstract final class AppBreakpoints {
  static const double compact = 600;

  static const double expanded = 1024;

  static const double twoPaneMinWidth = 1200;

  static const double maxContentWidth = 720;

  static WindowSize sizeFromWidth(double width) {
    if (width >= expanded) return WindowSize.expanded;
    if (width >= compact) return WindowSize.medium;
    return WindowSize.compact;
  }
}

enum WindowSize { compact, medium, expanded }
