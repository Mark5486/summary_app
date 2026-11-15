import 'arabic_normalizer.dart';

/// جملة واحدة بعد التقطيع.
class Sentence {
  final int index;

  /// النص **الأصلي** للجملة — زي ما المستخدم كاتبه بالظبط
  /// (تشكيل وترقيم) — ده اللي بيتعرض للمستخدم في النقاط.
  final String text;

  /// فاصل الكلمات — متعرّف مرة واحدة بدل ما بيتجمّع مع كل جملة.
  static final RegExp _wordSeparator = RegExp(r'\s+');

  /// ملاحظة: المُنشئ مش `const` عشان الكاش المتأخر (late final) —
  /// ده ثمن بسيط مقابل توفير نص شغل التطبيع مع كل نداء.
  Sentence(this.index, this.text);

  /// الكلمات المتطبّعة — للعدّ والأوزان **بس**، مش للعرض.
  /// بتتحسب مرة واحدة عند أول نداء (المحرك بينادي عليها أكتر من مرة).
  late final List<String> normalizedWords = _computeNormalizedWords();

  List<String> _computeNormalizedWords() {
    final normalized = ArabicNormalizer.normalizeText(text);
    final words = <String>[];
    for (final w in normalized.split(_wordSeparator)) {
      final n = ArabicNormalizer.normalizeWord(w);
      if (n.isNotEmpty) words.add(n);
    }
    return words;
  }
}

/// تقطيع النص لجمل — بيفهم ترقيم عربي وإنجليزي وبيقسم على السطور الجديدة.
///
/// ⚠️ الترتيب مهم: بنقسم على النص الخام **قبل** أي تطبيع — الجملة بتحتفظ
/// بنصها الأصلي للعرض، والتطبيع بيحصل جوّه حساب الكلمات للعدّ بس.
abstract final class SentenceSplitter {
  /// علامات نهاية الجملة: . ! ? ؟ ؛ ; … والسطر الجديد.
  static final RegExp _endings =
      RegExp(r'(?<=[\.\!\?\u061F\u061B;\u2026])\s+|\n+');

  /// أقل عدد حروف لجملة تتحسب (كلمات عرضية زي "و." بتتتجاهل).
  static const int _minSentenceLength = 25;

  static List<Sentence> split(String text) {
    if (text.trim().isEmpty) return const [];

    final parts = text.split(_endings);
    final sentences = <Sentence>[];
    var index = 0;

    for (final part in parts) {
      // الحكم على الطول من النص الخام — جملة متشكّلة ما تتطنشش
      // بسبب حروف التشكيل اللي بتحسب في طولها.
      final raw = part.trim();
      if (raw.length < _minSentenceLength) continue;
      sentences.add(Sentence(index++, raw));
    }

    return sentences;
  }
}
