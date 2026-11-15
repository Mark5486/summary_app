import 'arabic_normalizer.dart';

class Sentence {
  final int index;

  final String text;

  static final RegExp _wordSeparator = RegExp(r'\s+');

  Sentence(this.index, this.text);

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

abstract final class SentenceSplitter {
  static final RegExp _endings = RegExp(
    r'(?<=[\.\!\?\u061F\u061B;\u2026])\s+|\n+',
  );

  static const int _minSentenceLength = 25;

  static List<Sentence> split(String text) {
    if (text.trim().isEmpty) return const [];

    final parts = text.split(_endings);
    final sentences = <Sentence>[];
    var index = 0;

    for (final part in parts) {
      final raw = part.trim();
      if (raw.length < _minSentenceLength) continue;
      sentences.add(Sentence(index++, raw));
    }

    return sentences;
  }
}
