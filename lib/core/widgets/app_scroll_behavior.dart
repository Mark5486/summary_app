import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// سلوك سكرول موحد للتطبيق كله — مهمة 3.
///
/// المشكلة: على اللاب/الكمبيوتر/الويب مكانش فيه أي دليل بصري إن الصفحة
/// بتتسكرول — المستخدم كان شايف المحتوى مقطوع من غير ما يعرف ينزل.
/// الحل: سكرول بار دايم الظهور على منصات الديسكتوب والويب، ولمس عادي
/// على الموبايل (زي ما هو — الموبايل مش محتاج شريط).
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // الويب على متصفح ديسكتوب أو تطبيق ديسكتوب → سكرول بار دايم.
    final isDesktopLike = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (!isDesktopLike) return child;

    return Scrollbar(
      // controller ممكن يكون null لو الاسكرولابل بيستخدم
      // PrimaryScrollController — الـ Scrollbar بينزل للمحيط تلقائيًا.
      controller: details.controller,
      thumbVisibility: true,
      interactive: true,
      child: child,
    );
  }
}
