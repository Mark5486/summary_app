/// تطبيع النص العربي عشان مقارنة الكلمات تبقى ثابتة:
/// "الأَطباء" و "اطباء" يبقوا نفس الكلمة في عدّاد التكرار.
abstract final class ArabicNormalizer {
  /// التشكيل: فتحة، ضمة، كسرة، سكون، شدة، تنوين، مدّة...
  static final RegExp _diacritics = RegExp(r'[\u064B-\u0652\u0670\u0640]');

  /// أي حاجة مش حرف أو رقم أو مسافة → مسافة (علامات ترقيم ورموز).
  static final RegExp _nonWord = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);

  /// أشكال الألف — متعرّف مرة واحدة (تجميع الـ RegExp جوّه اللوب بيبطّئ
  /// النصوص الطويلة جدًا — تحسين أداء بس، نفس النتيجة بالظبط).
  static final RegExp _alefForms =
      RegExp('[\u0623\u0625\u0622\u0671]');

  /// مسافات متكررة أفقية.
  static final RegExp _horizontalSpaces = RegExp(r'[ \t]+');

  /// أسطر فاضية كتير متتالية.
  static final RegExp _extraNewlines = RegExp(r'\n{3,}');

  /// تطبيع كلمة واحدة للعدّ.
  static String normalizeWord(String word) {
    var w = word.replaceAll(_diacritics, '');
    // أشكال الألف كلها → ا
    w = w.replaceAll(_alefForms, '\u0627');
    // الألف المقصورة → ي
    w = w.replaceAll('\u0649', '\u064A');
    // التاء المربوطة → هاء (توحيد "مدرسة/مدرسه")
    w = w.replaceAll('\u0629', '\u0647');
    return w;
  }

  /// تنظيف نص خام قبل التلخيص: مسافات مضغوطة من غير مساس بالجمل.
  ///
  /// ⚠️ التشكيل بيتشال "بيدين" (الحرف بيفضل كله) — مش بمسافة —
  /// عشان "إِنَّ" تفضل "إن" ومتتفككش "إ ن".
  static String normalizeText(String text) {
    var t = text.replaceAll('\u00A0', ' ');
    t = t.replaceAll(_diacritics, '');
    t = t.replaceAll(_nonWord, ' ');
    t = t.replaceAll(_horizontalSpaces, ' ');
    t = t.replaceAll(_extraNewlines, '\n\n');
    return t.trim();
  }
}
