import 'dart:convert';
import 'dart:typed_data';

import 'package:besbasa/core/services/file_text_service.dart';
import 'package:besbasa/core/services/pdf/arabic_presentation_forms.dart';
import 'package:besbasa/core/services/pdf/pdf_text_cleaning.dart';
import 'package:flutter_test/flutter_test.dart';

/// اختبارات مسار الـ PDF: تطبيع أشكال العرض + إصلاح الاتجاه + التنظيف.
///
/// الحالات مبنية على اللي طلع من فحص ملفات حقيقية:
/// - ملفات wkhtmltopdf/Qt بتطلع منها نص سليم أحيانًا (PDFium بيتعامل
///   مع ToUnicode الصح) — لازم ميتمسّخش.
/// - ملفات مكسورة بتطلع منها Presentation Forms (U+FB50–FEFF) أو
///   سطور معكوسة بصريًا — لازم تتصلح.
void main() {
  group('تطبيع أشكال العرض العربية (Presentation Forms)', () {
    test('الأشكال المتصلة بتترجع لحروف قياسية', () {
      // ﺑ (U+FE91 initial beh) → ب، ﺎ (U+FE8D alef isolated) → ا
      final shaped = '\uFE91\uFE8E'; // بـ + ـا بأشكال العرض
      expect(
        PdfTextCleaner.normalizePresentationForms(shaped),
        '\u0628\u0627', // با
      );
    });

    test('لام-ألف الليغاتور بتتفك لحرفين', () {
      // ﻻ (U+FEFB isolated lam-alef) → لا
      expect(
        PdfTextCleaner.normalizePresentationForms('\uFEFB'),
        '\u0644\u0627',
      );
      // ﻷ (U+FEF7) → لأ
      expect(
        PdfTextCleaner.normalizePresentationForms('\uFEF7'),
        '\u0644\u0623',
      );
    });

    test('النص العادي ميتأثرش خالص', () {
      const normal = 'مرحبا بكم في تطبيق ببساطة';
      expect(
        PdfTextCleaner.normalizePresentationForms(normal),
        normal,
      );
    });

    test('النص الإنجليزي والإيموجي بيمرو زي ما هو', () {
      const mixed = 'Hello 🙂 World 123';
      expect(PdfTextCleaner.normalizePresentationForms(mixed), mixed);
    });

    test('الجدول مكتمل — كل أشكال العرض ليها تعيين', () {
      // بنمشي على كل نطاقات الأشكال: أي حرف متعين يتطبع، وغير كده
      // لازم يكون حرف مش عربي أصلاً (مثل أشكال الأبجدادات التانية).
      var mapped = 0;
      for (var cp = 0xFB50; cp <= 0xFDFF; cp++) {
        if (kArabicPresentationForms.containsKey(cp)) mapped++;
      }
      for (var cp = 0xFE70; cp <= 0xFEFF; cp++) {
        if (kArabicPresentationForms.containsKey(cp)) mapped++;
      }
      // النطاقين مع بعض ~731 مدخل — مش أقل من 700.
      expect(mapped, greaterThan(700));
    });
  });

  group('إصلاح ترتيب السطور المعكوسة (ArabicOrderFixer)', () {
    test('سطر معكوس بصريًا بيتصلح', () {
      // زي ما بيطلع من PDF مولّد بصريًا (سطر حقيقي من arabic_logical.pdf):
      // الحروف مقلوبة والترتيب معكوس.
      const reversed =
          '.عتممو نقتم لكشب ةباتكلاو ةءارقلا ملعت ةيبرعلا ةغللا يف ةيجهنملا بتكلا';
      const expected =
          'الكتب المنهجية في اللغة العربية تعلم القراءة والكتابة بشكل متقن وممتع.';
      expect(ArabicOrderFixer.fix(reversed), expected);
    });

    test('سطر سليم ميتقلبش — PDF عادي ميتأثرش', () {
      const correct =
          'يعد التعليم من أهم العوامل التي تساهم في تطور المجتمعات وبناء الأجيال.';
      expect(ArabicOrderFixer.fix(correct), correct);
    });

    test('سطور معكوسة كتير: السطور الصامتة بتتبع أغلبية المستند', () {
      // سطر طويل معكوس + سطر قصير مفيهوش كلمات معروفة بأي اتجاه.
      const reversedLong =
          '.ةمدقملا ةيحصلا تاذ ةيبنجلا تايدحلاو تامولعملا تانايبلا نيب ةقيرطلا)';
      final single = String.fromCharCodes(
        'كتاب.'.runes.toList().reversed,
      ); // .باتك — سطر قصير صامت (مفيش قرينة في أي اتجاه)
      final result = ArabicOrderFixer.fix('$reversedLong\n$single');
      final lines = result.split('\n');
      expect(lines[0], contains('الطريق'));
      expect(lines[1], 'كتاب.');
    });

    test('النص الإنجليزي ميتلمسش', () {
      const english = 'The quick brown fox jumps over the lazy dog.';
      expect(ArabicOrderFixer.fix(english), english);
    });

    test('النص المختلط: سطر عربي سليم وجنب سطر إنجليزي', () {
      const mixed = 'العلم ضوء.\nHello world';
      expect(ArabicOrderFixer.fix(mixed), mixed);
    });
  });

  group('التنظيف الكامل (PdfTextCleaner.clean)', () {
    test('علامات الاتجاه والحروف الخفية بتتشال', () {
      // LRM + RLM + ZWJ حولين كلام عربي سليم.
      const dirty = '\u200Eمرحبا\u200F بك\u200Dم';
      final cleaned = PdfTextCleaner.clean(dirty);
      expect(cleaned.contains('\u200E'), isFalse);
      expect(cleaned.contains('\u200F'), isFalse);
      expect(cleaned.contains('\u200D'), isFalse);
    });

    test('CRLF بيتحول لـ LF والأسطر الفاضية الزيادة بتتضغط', () {
      const raw = 'سطر أ\r\nسطر ب\r\r\r\n\n\nسطر ج';
      final cleaned = PdfTextCleaner.clean(raw);
      expect(cleaned, 'سطر أ\nسطر ب\n\nسطر ج');
    });

    test('looksEmpty بيكتشف PDF ممسوح ضوئيًا (نص شبه فاضي)', () {
      expect(PdfTextCleaner.looksEmpty(''), isTrue);
      expect(PdfTextCleaner.looksEmpty('   \n  '), isTrue);
      expect(PdfTextCleaner.looksEmpty('كلمة'), isTrue);
      // أقل من 5 كلمات = مفيش تلخيص مفيد.
      expect(PdfTextCleaner.looksEmpty('مفيش نص حقيقي هنا'), isTrue);
      // 5 كلمات وأكتر = نص مفهوم (الحد الفاصل بالظبط).
      expect(PdfTextCleaner.looksEmpty('مفيش نص حقيقي هنا خلاص'), isFalse);
      expect(
        PdfTextCleaner.looksEmpty(
          'نص حقيقي فيه كلمات كفاية عشان نلخصه بشكل مفيد ومفيد جدًا للطلاب',
        ),
        isFalse,
      );
    });

    test('countWords بيعد الكلمات الصح', () {
      expect(PdfTextCleaner.countWords('واحد اتنين  ثلاثة'), 3);
      expect(PdfTextCleaner.countWords(''), 0);
      expect(PdfTextCleaner.countWords('  \n\t '), 0);
    });
  });

  group('سيناريو مستند عربي كامل (زي اللي طلع من الفحص)', () {
    test('نص سليم من PDFium بيمر من غير تغيير في المعنى', () {
      const extracted = 'يعد التعليم من أهم العوامل التي تساهم في تطور المجتمعات\n'
          'وبناء الأجيال القادمة.\n'
          'في مصر يهتم الكثير من الأسر بجودة التعليم لأبنائها.';
      final cleaned = PdfTextCleaner.clean(extracted);
      // نفس السطور بالظبط — مفيش قلب ولا تلفيف.
      expect(cleaned.split('\n').length, 3);
      expect(cleaned, contains('يعد التعليم من أهم العوامل'));
      expect(cleaned, contains('في مصر يهتم الكثير'));
    });

    test('مستند معكوس كامل بيتصلح سطر سطر', () {
      // نفس المستند بس معكوس بصريًا (زي ملفات QT القديمة).
      String reverse(String s) =>
          String.fromCharCodes(s.runes.toList().reversed);
      const logical = [
        'الكتب المنهجية في اللغة العربية تعلم القراءة والكتابة بشكل متقن وممتع.',
        'والقواعد النحوية تساعد على فهم الجمل وتحليلها إلى أجزائها الصحيحة.',
      ];
      final visual = logical.map(reverse).join('\n');
      final cleaned = PdfTextCleaner.clean(visual);
      expect(cleaned, logical.join('\n'));
    });
  });

  group('حمايات decodeBytes بعد إعادة الترتيب', () {
    test('UTF-8 بسيط لسه شغال بعد ما الـ binary signatures اتنقلت للـ detector',
        () {
      final bytes = Uint8List.fromList(utf8.encode('نص عادي جدا في ملف'));
      expect(FileTextServiceImpl.decodeBytes(bytes), 'نص عادي جدا في ملف');
    });
  });
}
