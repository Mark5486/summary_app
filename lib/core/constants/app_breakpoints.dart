/// نقاط توقف التصميم المتكيّف — مهمة 4.
///
/// التطبيق بيتكيّف على 3 أحجام نافذة (نفس مدرسة Material 3):
///
/// - compact  (< 600px)  : موبايل — عمود واحد وشريط تنقل تحت.
/// - medium   (600–1023) : تابلت / لاب ضيّق — محتوى موسّط بعرض مريح.
/// - expanded (≥ 1024px) : لاب / كمبيوتر — ريل تنقل جانبي + استغلال
///   كامل للمساحة (وشاشة التلخيص ممكن تبقى عمودين).
abstract final class AppBreakpoints {
  /// حد الموبايل الأقصى — فوقه بنعتبر الشاشة تابلت/لاب.
  static const double compact = 600;

  /// حد الشاشات العريضة (ديسكتوب) — منه بنبدأ الريل الجانبي.
  static const double expanded = 1024;

  /// أقل عرض للشاشة عشان التلخيص يتحول لعمودين (إدخال جنب النتيجة).
  static const double twoPaneMinWidth = 1200;

  /// عرض المحتوى الأقصى للقراءة المريحة على الشاشات الكبيرة —
  /// السطور الطويلة أوي بتتعب العين.
  static const double maxContentWidth = 720;

  /// تحجيم النافذة من عرضها — دالة نقية عشان تتاختبر بسهولة.
  static WindowSize sizeFromWidth(double width) {
    if (width >= expanded) return WindowSize.expanded;
    if (width >= compact) return WindowSize.medium;
    return WindowSize.compact;
  }
}

/// حجم نافذة التطبيق الحالي.
enum WindowSize { compact, medium, expanded }
