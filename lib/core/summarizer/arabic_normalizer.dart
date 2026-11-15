abstract final class ArabicNormalizer {
  static final RegExp _diacritics = RegExp(r'[\u064B-\u0652\u0670\u0640]');

  static final RegExp _nonWord = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);

  static final RegExp _alefForms = RegExp('[\u0623\u0625\u0622\u0671]');

  static final RegExp _horizontalSpaces = RegExp(r'[ \t]+');

  static final RegExp _extraNewlines = RegExp(r'\n{3,}');

  static String normalizeWord(String word) {
    var w = word.replaceAll(_diacritics, '');

    w = w.replaceAll(_alefForms, '\u0627');

    w = w.replaceAll('\u0649', '\u064A');

    w = w.replaceAll('\u0629', '\u0647');
    return w;
  }

  static String normalizeText(String text) {
    var t = text.replaceAll('\u00A0', ' ');
    t = t.replaceAll(_diacritics, '');
    t = t.replaceAll(_nonWord, ' ');
    t = t.replaceAll(_horizontalSpaces, ' ');
    t = t.replaceAll(_extraNewlines, '\n\n');
    return t.trim();
  }
}
