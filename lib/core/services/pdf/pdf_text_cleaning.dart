import 'arabic_presentation_forms.dart';

/// تنظيف وتجهيز النص المستخرج من PDF — Pure Dart عشان يتنفذ في أي isolate:
///
/// 1) إزالة علامات الاتجاه والحروف الخفية (LRM/RLM/ZWJ/BOM…)
/// 2) تطبيع أشكال العرض العربية (Presentation Forms A+B) لحروف قياسية
///    — ملفات PDF قديمة بترسم الحروف بأشكالها المتصلة (U+FB50–FEFF)
///    وده اللي بيطلع "رموز مش مفهومة" لو اتلخص زي ما هو.
/// 3) إصلاح ترتيب السطور المعكوسة بصريًا — بعض المولّدات بترسم السطر
///    بالترتيب البصري من الشمال لليمين، فالنص بيطلع مقلوب. بنقيس كل
///    سطر بالكلمات العربية الشائعة: لو النسخة المعكوسة كلام أكثر، نقلبها.
/// 4) ضغط الأسطر الفاضية الزيادة.
class PdfTextCleaner {
  PdfTextCleaner._();

  /// علامات اتجاه وحروف صفرية العرض — بتتلغى من غير ما تغير المعنى.
  static final RegExp _bidiAndHidden = RegExp(
    '[\u00AD\u061C\u200B-\u200F\u202A-\u202E\u2066-\u2069\uFEFF]',
  );

  static final RegExp _blankRuns = RegExp('\n{3,}');

  /// مسار التنظيف الكامل — بيتنادى على نص كل مستند بعد الاستخراج.
  static String clean(String raw) {
    var t = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    t = t.replaceAll(_bidiAndHidden, '');
    t = normalizePresentationForms(t);
    t = ArabicOrderFixer.fix(t);
    t = t.replaceAll(_blankRuns, '\n\n');
    return t.trim();
  }

  static String normalizePresentationForms(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final replacement = kArabicPresentationForms[rune];
      if (replacement != null) {
        buffer.write(replacement);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  static final RegExp _whitespace = RegExp(r'\s+');

  static int countWords(String text) {
    var count = 0;
    for (final w in text.split(_whitespace)) {
      if (w.trim().isNotEmpty) count++;
    }
    return count;
  }

  /// PDF ممسوح ضوئيًا = استخراج نصي شبه فاضي (صفحة صورة بس).
  static bool looksEmpty(String text) {
    final t = text.trim();
    if (t.length < 20) return true;
    return countWords(t) < 5;
  }
}

/// إصلاح اتجاه السطور العربية المعكوسة بصريًا.
///
/// الفكرة: بنجرب السطر زي ما هو ونسخته المعكوسة (بالـ runes عشان
/// الـ surrogate pairs متتكسرش)، ونعطي نقطة لكل واحد على حسب الكلمات
/// العربية الشائعة والبادئات (ال) — اللي بيطلع كلام أكتر يكسب.
/// قرار "المستند كله معكوس" بيتأخذ من أغلبية السطور، وبعدها السطور
/// الصامتة (مفيهاش كلمات معروفة بأي اتجاه) بتتبع أغلبية المستند.
class ArabicOrderFixer {
  ArabicOrderFixer._();

  /// حرف عربي — نسخة خاصة بالفيسر عشان التصنيف يفضل مكتفًا ذاتيًا.
  static final RegExp _arabicLetter =
      RegExp('[\u0621-\u064A\u064B-\u0652\u0671-\u06D3]');

  static const Set<String> _commonWords = {
    'في', 'من', 'على', 'عن', 'إلى', 'الى', 'هذا', 'هذه', 'ذلك', 'التي',
    'الذي', 'الذين', 'كل', 'بعض', 'بين', 'بعد', 'قبل', 'عند', 'حتى',
    'لكن', 'أن', 'إن', 'أو', 'ثم', 'قد', 'ما', 'هو', 'هي', 'هم', 'كان',
    'كانت', 'يكون', 'مع', 'عبر', 'حيث', 'كما', 'أيضا', 'يتم', 'عام',
    'لأن', 'لكي', 'بينما', 'اللي', 'عشان', 'علي', 'وهو', 'وهي',
  };

  /// فاصل الرموز — بيفصل الكلمات عن علامات الترقيم والرموز.
  static final RegExp _tokenSeparator = RegExp(
    '[^\\p{L}\\p{N}]+',
    unicode: true,
  );

  static bool _hasArabic(String s) => _arabicLetter.hasMatch(s);

  /// نقاط "كلام عربي سليم" في السطر.
  static int score(String line) {
    var score = 0;
    for (final token in line.split(_tokenSeparator)) {
      if (token.isEmpty) continue;
      if (_commonWords.contains(token)) {
        score += 3;
      } else if (token.startsWith('ال') && token.length >= 4) {
        score += 1; // "ال" التعريف في أول الكلمة — قرينة إضافية
      }
    }
    return score;
  }

  static String _reverseRunes(String s) {
    final runes = s.runes.toList();
    return String.fromCharCodes(runes.reversed);
  }

  static String fix(String text) {
    if (!_hasArabic(text)) return text;

    final lines = text.split('\n');
    final flip = List<bool>.filled(lines.length, false);
    var reversedVotes = 0;
    var asIsVotes = 0;

    // المرحلة 1: قرار لكل سطر فيه كلام عربي كفاية.
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!_hasArabic(line)) continue;
      final reversed = _reverseRunes(line);
      final asIsScore = score(line);
      final reversedScore = score(reversed);
      if (reversedScore > asIsScore) {
        flip[i] = true;
        reversedVotes++;
      } else if (asIsScore > reversedScore) {
        asIsVotes++;
      }
      // التعادل = سطر صامت، بيتحسم في المرحلة 2 بأغلبية المستند.
    }

    final majorityReversed = reversedVotes > asIsVotes;

    // المرحلة 2: قلب المفلتر + سطور صامتة بتتبع أغلبية المستند.
    if (reversedVotes > 0) {
      for (var i = 0; i < lines.length; i++) {
        if (flip[i]) {
          lines[i] = _reverseRunes(lines[i]);
          continue;
        }
        if (!majorityReversed) continue;
        final line = lines[i];
        if (!_hasArabic(line)) continue;
        final reversed = _reverseRunes(line);
        if (score(line) == 0 && score(reversed) == 0) {
          lines[i] = reversed;
        }
      }
    }

    return lines.join('\n');
  }
}
