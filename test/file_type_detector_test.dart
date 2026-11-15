import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:besbasa/core/services/file_type_detector.dart';

void main() {
  group('FileTypeDetector — باج BMP RangeError', () {
    test('ملف نصي بيبدأ بـ "BM" بطول 15–17 بايت مبيعملش RangeError', () {
      // حالة الريفيو بالحرف: نص عادي بيبدأ بحرفين B و M وطوله
      // 15 أو 16 أو 17 بايت — الكود القديم كان بيقرأ b[15..17]
      // بره حدود الملف ويعمل RangeError كراش.
      for (final len in [15, 16, 17]) {
        final bytes = utf8.encode('BM${'x' * (len - 2)}');
        expect(bytes.length, len);
        expect(
          FileTypeDetector.detect(Uint8List.fromList(bytes)),
          DetectedFileType.plainText,
          reason: 'طول $len بايت كان بيكرّش قبل الإصلاح',
        );
      }
    });

    test('ملف BMP حقيقي (DIB header صحيح) بيتكتشف ثنائي', () {
      // 14 بايت file header + بداية DIB header بقيمة 40
      final bmp = <int>[
        0x42, 0x4D, // "BM"
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // باقي الـ file header
        0x28, 0x00, 0x00, 0x00, // dibSize = 40 (little-endian)
      ];
      expect(
        FileTypeDetector.detect(Uint8List.fromList(bmp)),
        DetectedFileType.binary,
      );
    });

    test('ملف "BM" قصير (أقل من 18 بايت) يفضل نص عادي', () {
      final bytes = utf8.encode('BM short text');
      expect(
        FileTypeDetector.detect(Uint8List.fromList(bytes)),
        DetectedFileType.plainText,
      );
    });
  });
}
