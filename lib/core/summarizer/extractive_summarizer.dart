import 'dart:math' as math;

import '../errors/exceptions.dart';
import 'sentence_splitter.dart';
import 'stopwords.dart';

/// نتيجة التلخيص: نقاط قليلة + شرح مبسط + إحصائيات صغيرة.
class SummaryResult {
  /// أهم 3–5 جمل — مرتّبة على ترتيب ظهورها في النص الأصلي.
  final List<String> points;

  /// شرح مبسط من سطرين: الفكرة الأساسية + أهم الكلمات.
  final String explanation;

  /// أهم الكلمات (keywords) بالترتيب.
  final List<String> keywords;

  /// عدد كلمات النص الأصلي (قبل الفلترة).
  final int originalWordCount;

  /// عدد كلمات النقاط — عشان المستخدم يشوف مقدار الاختصار.
  final int summaryWordCount;

  const SummaryResult({
    required this.points,
    required this.explanation,
    required this.keywords,
    required this.originalWordCount,
    required this.summaryWordCount,
  });

  /// نسبة الاختصار 0..1 (0.8 يعني اتلخص 80%).
  double get compressionRatio {
    if (originalWordCount == 0) return 0;
    return 1 - (summaryWordCount / originalWordCount);
  }
}

/// ⭐ محرك التلخيص الاستخلاصي — أوفلاين 100% (Dart خالص).
///
/// الخوارزمية:
/// 1. تطبيع النص وتقطيعه لجمل.
/// 2. عدّ تكرار الكلمات المهمة (بعد إسقاط كلمات التوقف).
/// 3. وزن كل جملة = مجموع أوزان كلماتها ÷ √طولها (عشان الجمل الطويلة
///    ما تكسبش بمجرد إنها طويلة) + بونص بسيط لجمل الافتتاحية.
/// 4. أعلى 3–5 جمل بترتيبها الأصلي = النقاط.
/// 5. أعلى الكلمات تكرارًا = keywords، ومنها بيتكوّن الشرح المبسّط.
abstract final class ExtractiveSummarizer {
  /// أقل عدد كلمات يشتغل معاه التلخيص.
  static const int minWordCount = 30;

  /// أقصى عدد نقاط.
  static const int maxPoints = 5;

  /// أقصى عدد كلمات مفتاحية في الشرح.
  static const int maxKeywords = 4;

  /// أقصى طول للحرف الواحد في النقطة (بتتقص عند حدود كلمة).
  static const int _maxPointChars = 180;

  static SummaryResult summarize(String text) {
    final sentences = SentenceSplitter.split(text);
    final originalWordCount = _countWords(text);

    if (sentences.isEmpty || originalWordCount < minWordCount) {
      // المستخدم هيشوف رسالة واضحة — المحرك ما يخترعش ملخص من نص ناقص.
      throw const InputTooShortException();
    }

    // 1) عدّ تكرار الكلمات المهمة.
    final freq = <String, int>{};
    for (final sentence in sentences) {
      for (final word in sentence.normalizedWords) {
        final lower = word.toLowerCase();
        if (Stopwords.isStopword(lower) || word.length < 2) continue;
        freq[word] = (freq[word] ?? 0) + 1;
      }
    }

    if (freq.isEmpty) {
      throw const InputTooShortException();
    }

    final maxFreq = freq.values.reduce((a, b) => a > b ? a : b);

    double wordWeight(String w) => (freq[w] ?? 0) / maxFreq;

    // 2) وزن كل جملة.
    final scored = <_ScoredSentence>[];
    for (final sentence in sentences) {
      final words = sentence.normalizedWords;
      if (words.isEmpty) continue;

      var sum = 0.0;
      var meaningful = 0;
      for (final w in words) {
        final lower = w.toLowerCase();
        if (Stopwords.isStopword(lower)) continue;
        sum += wordWeight(w);
        meaningful++;
      }

      // جملة من غير ولا كلمة مهمة → مستبعدة.
      if (meaningful == 0) continue;

      final lengthPenalty = math.sqrt(words.length).clamp(1.0, double.infinity);
      var score = sum / lengthPenalty;

      // بونص افتتاحي: أول جملتين غالبًا بيحددوا الموضوع.
      if (sentence.index < 2) score *= 1.15;

      scored.add(_ScoredSentence(sentence, score));
    }

    if (scored.isEmpty) {
      throw const InputTooShortException();
    }

    // 3) عدد النقاط حسب حجم النص — "نقاط قليلة" زي ما المستخدم عايز:
    //    نص قصير → 3 نقاط، متوسط → 4، طويل → 5.
    int targetPoints;
    if (sentences.length > 24) {
      targetPoints = maxPoints;
    } else if (sentences.length > 10) {
      targetPoints = 4;
    } else {
      targetPoints = 3;
    }
    final pointCount =
        scored.length < targetPoints ? scored.length : targetPoints;

    // 4) أعلى الجمل ثم إعادة ترتيبها على الأصل.
    scored.sort((a, b) => b.score.compareTo(a.score));
    final top = scored.take(pointCount).toList()
      ..sort((a, b) => a.sentence.index.compareTo(b.sentence.index));

    final points = top.map((s) => _trimToWordLimit(s.sentence.text)).toList();

    // 5) الكلمات المفتاحية + الشرح المبسط.
    final sortedWords = freq.keys.toList()
      ..sort((a, b) => freq[b]!.compareTo(freq[a]!));
    final keywords = sortedWords.take(maxKeywords).toList();

    final explanation = _buildExplanation(keywords, top.first.sentence.text,
        isArabic: _isArabicText(text));

    final summaryWordCount = points.fold<int>(
      0,
      (total, p) => total + _countWords(p),
    );

    return SummaryResult(
      points: points,
      explanation: explanation,
      keywords: keywords,
      originalWordCount: originalWordCount,
      summaryWordCount: summaryWordCount,
    );
  }

  /// الشرح المبسط: جملة واحدة قصيرة بتجمع الفكرة وأهم الكلمات —
  /// بلغة النص نفسه (عربي أو إنجليزي).
  static String _buildExplanation(
    List<String> keywords,
    String firstPoint, {
    required bool isArabic,
  }) {
    final kw = keywords.take(3).join(isArabic ? ' و' : ', ');
    final shortPoint = _trimToWordLimit(firstPoint, 120);

    if (isArabic) {
      return 'الفكرة الأساسية بتدور حول: $kw\nوأهم جملة: $shortPoint';
    }
    return 'The main idea revolves around: $kw\nKey sentence: $shortPoint';
  }

  /// هل النص عربي؟ (عدّ الحروف العربية مقابل اللاتينية)
  static bool _isArabicText(String text) {
    var arabic = 0;
    var latin = 0;
    for (final rune in text.runes) {
      if (rune >= 0x0600 && rune <= 0x06FF) {
        arabic++;
      } else if ((rune >= 0x41 && rune <= 0x5A) ||
          (rune >= 0x61 && rune <= 0x7A)) {
        latin++;
      }
    }
    return arabic >= latin;
  }

  static String _trimToWordLimit(String text, [int maxChars = _maxPointChars]) {
    final t = text.trim();
    if (t.length <= maxChars) return t;
    final cut = t.substring(0, maxChars);
    final lastSpace = cut.lastIndexOf(' ');
    return lastSpace > 40 ? '${cut.substring(0, lastSpace)}…' : '$cut…';
  }

  static final RegExp _whitespace = RegExp(r'\s+');

  static int _countWords(String text) {
    var count = 0;
    for (final w in text.split(_whitespace)) {
      if (w.trim().isNotEmpty) count++;
    }
    return count;
  }
}

class _ScoredSentence {
  final Sentence sentence;
  final double score;
  const _ScoredSentence(this.sentence, this.score);
}
