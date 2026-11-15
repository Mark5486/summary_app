import 'arabic_normalizer.dart';

/// جملة واحدة بعد التقطيع — مع موقعها الأصلي عشان نحافظ على الترتيب.
class Sentence {
  final int index;
  final String text;

  /// فاصل الكلمات — متعرّف مرة واحدة بدل ما بيتجمّع مع كل جملة.
  static final RegExp _wordSeparator = RegExp(r'\s+');

  /// ملاحظة: المُنشئ مش `const` عشان الكاش المتأخر (late final) —
  /// ده ثمن بسيط مقابل توفير نص شغل التطبيع مع كل نداء.
  Sentence(this.index, this.text);

  /// الكلمات المتطبّعة — بتتحسب **مرة واحدة فقط** عند أول نداء
  /// (المحرك بينادي عليها أكتر من مرة: عدّ التكرار + حساب الأوزان —
  /// التخزين المؤقت ده بيوفّر نص الشغل بدون أي تغيير في النتيجة).
  late final List<String> normalizedWords = _computeNormalizedWords();

  List<String> _computeNormalizedWords() {
    final raw = text.split(_wordSeparator);
    final words = <String>[];
    for (final w in raw) {
      final n = ArabicNormalizer.normalizeWord(w);
      if (n.isNotEmpty) words.add(n);
    }
    return words;
  }
}

/// تقطيع النص لجمل — بيفهم ترقيم عربي وإنجليزي وبيقسم على السطور الجديدة.
///
/// ⚠️ الترتيب مهم: بنقسم على النص الخام **قبل** التطبيع —
/// لأن التطبيع بيستبدل علامات الترقيم بمسافات.
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
      // التطبيع بيحصل **بعد** التقطيع — جملة جملة.
      final s = ArabicNormalizer.normalizeText(part);
      if (s.length < _minSentenceLength) continue;
      sentences.add(Sentence(index++, s));
    }

    return sentences;
  }
}
