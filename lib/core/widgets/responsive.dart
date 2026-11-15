import 'package:flutter/material.dart';

import '../constants/app_breakpoints.dart';

/// توسيط المحتوى بعرض أقصى على الشاشات الكبيرة — مهام 4 و 6.
///
/// من غيره المحتوى كان بيتبصط على عرض الشاشة كله على اللاب/الكمبيوتر
/// وسطور القراءة كانت بتبقى أوي. على الموبايل مالوش تأثير (الشاشة
/// أضيق من الحد الأقصى أصلًا).
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

/// وصول سريع لحجم النافذة من أي مكان في الـ UI.
///
/// الاستخدام: `context.isExpanded` أو `context.windowSize`.
extension ResponsiveContext on BuildContext {
  /// عرض النافذة الحالي (بيتحدد تلقائيًا مع تغيير حجم النافذة).
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// حجم النافذة المحسوب من نقاط التوقف.
  WindowSize get windowSize => AppBreakpoints.sizeFromWidth(screenWidth);

  /// موبايل (< 600px) — عمود واحد وشريط تنقل تحت.
  bool get isCompact => windowSize == WindowSize.compact;

  /// تابلت / لاب ضيّق (600–1023px).
  bool get isMedium => windowSize == WindowSize.medium;

  /// لاب / كمبيوتر (≥ 1024px) — ريل جانبي ومساحة كاملة.
  bool get isExpanded => windowSize == WindowSize.expanded;

  /// الشاشة عريضة كفاية للتلخيص بعمودين (إدخال جنب النتيجة).
  bool get isTwoPane => screenWidth >= AppBreakpoints.twoPaneMinWidth;
}
