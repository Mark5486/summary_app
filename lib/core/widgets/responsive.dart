import 'package:flutter/material.dart';

import '../constants/app_breakpoints.dart';

class ResponsiveCenter extends StatelessWidget {
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const ResponsiveCenter({
    super.key,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.padding = EdgeInsets.zero,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  WindowSize get windowSize => AppBreakpoints.sizeFromWidth(screenWidth);

  bool get isCompact => windowSize == WindowSize.compact;

  bool get isMedium => windowSize == WindowSize.medium;

  bool get isExpanded => windowSize == WindowSize.expanded;

  bool get isTwoPane => screenWidth >= AppBreakpoints.twoPaneMinWidth;
}
