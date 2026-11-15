import 'dart:convert';
import 'dart:typed_data';

import 'package:besbasa/core/errors/exceptions.dart';
import 'package:besbasa/core/services/file_text_service.dart';
import 'package:besbasa/core/services/file_type_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileTextServiceImpl.decodeBytes', () {
    final arabicText =
        'مرحبا بكم في تطبيق ببساطة للتلخيص البسيط وهو تطبيق يلخص '
        'النصوص الطويلة بشكل مبسط جدا للطلاب وبيحافظ على الترتيب';

    test('UTF-8 عادي بيترجع زي ما هو', () {
      final bytes = Uint8List.fromList(utf8.encode(arabicText));
      expect(FileTextServiceImpl.decodeBytes(bytes), arabicText);
    });

    test('UTF-16 LE بـ BOM (Notepad "Unicode") بيترجع الكلام الصح', () {
      final bytes = <int>[
        0xFF,
        0xFE,
        ...arabicText.codeUnits.expand((u) => [u & 0xFF, u >> 8]),
      ];
      expect(
        FileTextServiceImpl.decodeBytes(Uint8List.fromList(bytes)),
        arabicText,
      );
    });

    test('UTF-16 BE بـ BOM بيترجع الكلام الصح', () {
      final bytes = <int>[
        0xFE,
        0xFF,
        ...arabicText.codeUnits.expand((u) => [u >> 8, u & 0xFF]),
      ];
      expect(
        FileTextServiceImpl.decodeBytes(Uint8List.fromList(bytes)),
        arabicText,
      );
    });

    test('UTF-16 LE من غير BOM بيترجع الكلام الصح', () {
      final bytes = arabicText.codeUnits
          .expand((u) => [u & 0xFF, u >> 8])
          .toList(growable: false);
      expect(
        FileTextServiceImpl.decodeBytes(Uint8List.fromList(bytes)),
        arabicText,
      );
    });

    test('Windows-1256 بيترجع حروف عربية', () {
      final bytes = Uint8List.fromList([0xE3, 0xE1, 0xC7]);
      expect(FileTextServiceImpl.decodeBytes(bytes), 'ملا');
    });

    test('ملف binary (رموز تحكم) بيرفض برسالة واضحة مش يتلخص عباريض', () {
      final pattern = [0x01, 0x02, 0x7F, 0x0B, 0x0C, 0x1F, 0x2E, 0x3A];
      final bytes = Uint8List.fromList(
        List.generate(320, (i) => pattern[i % pattern.length]),
      );

      expect(
        () => FileTextServiceImpl.decodeBytes(bytes),
        throwsA(isA<InvalidFileException>()),
      );
    });

    test('ملف PDF (%PDF) بيتكشف من الماجيك نمبر — مش نص', () {
      final pdfHeader = utf8.encode(
        '%PDF-1.4\n%âãÏÓ\n1 0 obj\n<</Creator (wkhtmltopdf 0.12.6)>>\n',
      );
      final filler = List.generate(120, (i) => 0x41 + (i % 26));
      final bytes = Uint8List.fromList([...pdfHeader, ...filler]);

      expect(FileTypeDetector.detect(bytes), DetectedFileType.pdf);
      expect(FileTypeDetector.isPdf(bytes), isTrue);
    });

    test('ملف ZIP/DOCX (PK\\x03\\x04) بيتكشف ثنائي وبيترفض', () {
      final bytes = Uint8List.fromList([
        0x50,
        0x4B,
        0x03,
        0x04,
        ...List.generate(100, (i) => (i * 7 + 1) % 255 + 1),
      ]);

      expect(FileTypeDetector.detect(bytes), DetectedFileType.binary);
    });

    test('ملف فارغ بيتكشف ثنائي', () {
      expect(
        FileTypeDetector.detect(Uint8List.fromList([])),
        DetectedFileType.binary,
      );
    });

    test('ملف عربي نصي عادي بيتكشف نص', () {
      final bytes = Uint8List.fromList(utf8.encode(arabicText));
      expect(FileTypeDetector.detect(bytes), DetectedFileType.plainText);
    });

    test('بايتات صفر من غير BOM ومش UTF-16 بترفض', () {
      final bytes = Uint8List.fromList(
        List.generate(120, (i) => i == 60 ? 0 : 0x41 + (i % 26)),
      );

      expect(
        () => FileTextServiceImpl.decodeBytes(bytes),
        throwsA(isA<InvalidFileException>()),
      );
    });
  });
}
