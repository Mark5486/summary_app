import 'dart:convert';
import 'dart:typed_data';

import 'package:besbasa/core/services/file_text_service.dart';
import 'package:besbasa/core/services/pdf/arabic_presentation_forms.dart';
import 'package:besbasa/core/services/pdf/pdf_text_cleaning.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('تطبيع أشكال العرض العربية (Presentation Forms)', () {
    test('الأشكال المتصلة بتترجع لحروف قياسية', () {
      final shaped = '\uFE91\uFE8E';
      expect(PdfTextCleaner.normalizePresentationForms(shaped), '\u0628\u0627');
    });

    test('لام-ألف الليغاتور بتتفك لحرفين', () {
      expect(
        PdfTextCleaner.normalizePresentationForms('\uFEFB'),
        '\u0644\u0627',
      );

      expect(
        PdfTextCleaner.normalizePresentationForms('\uFEF7'),
        '\u0644\u0623',
      );
    });

    test('النص العادي ميتأثرش خالص', () {
      const normal = 'مرحبا بكم في تطبيق ببساطة';
      expect(PdfTextCleaner.normalizePresentationForms(normal), normal);
    });

    test('النص الإنجليزي والإيموجي بيمرو زي ما هو', () {
      const mixed = 'Hello 🙂 World 123';
      expect(PdfTextCleaner.normalizePresentationForms(mixed), mixed);
    });

    test('الجدول مكتمل — كل أشكال العرض ليها تعيين', () {
      var mapped = 0;
      for (var cp = 0xFB50; cp <= 0xFDFF; cp++) {
        if (kArabicPresentationForms.containsKey(cp)) mapped++;
      }
      for (var cp = 0xFE70; cp <= 0xFEFF; cp++) {
        if (kArabicPresentationForms.containsKey(cp)) mapped++;
      }

      expect(mapped, greaterThan(700));
    });
  });

  group('إصلاح ترتيب السطور المعكوسة (ArabicOrderFixer)', () {
    test('سطر معكوس بصريًا بيتصلح', () {
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
      const reversedLong =
          '.ةمدقملا ةيحصلا تاذ ةيبنجلا تايدحلاو تامولعملا تانايبلا نيب ةقيرطلا)';
      final single = String.fromCharCodes('كتاب.'.runes.toList().reversed);
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

      expect(PdfTextCleaner.looksEmpty('مفيش نص حقيقي هنا'), isTrue);

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
      const extracted =
          'يعد التعليم من أهم العوامل التي تساهم في تطور المجتمعات\n'
          'وبناء الأجيال القادمة.\n'
          'في مصر يهتم الكثير من الأسر بجودة التعليم لأبنائها.';
      final cleaned = PdfTextCleaner.clean(extracted);

      expect(cleaned.split('\n').length, 3);
      expect(cleaned, contains('يعد التعليم من أهم العوامل'));
      expect(cleaned, contains('في مصر يهتم الكثير'));
    });

    test('مستند معكوس كامل بيتصلح سطر سطر', () {
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
    test(
      'UTF-8 بسيط لسه شغال بعد ما الـ binary signatures اتنقلت للـ detector',
      () {
        final bytes = Uint8List.fromList(utf8.encode('نص عادي جدا في ملف'));
        expect(FileTextServiceImpl.decodeBytes(bytes), 'نص عادي جدا في ملف');
      },
    );
  });
}
