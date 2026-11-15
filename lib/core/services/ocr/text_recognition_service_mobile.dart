// Engine: Tesseract 4 — Mobile only, selected via conditional import.
//
// الخصوصية: ملفات اللغة (ara+eng) مدمجة مع التطبيق في assets/tessdata —
// القراءة كلها أوفلاين بالكامل ومفيش أي صورة بتسيب الجهاز.

import 'dart:async';

import 'package:camera/camera.dart' as camera;
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

import '../../errors/exceptions.dart';
import 'text_recognition_service.dart';

class TextRecognitionServiceImpl implements TextRecognitionService {
  /// عربي + إنجليزي — نفس لغات الواجهة.
  static const String _languages = 'ara+eng';

  /// نفس حماية تطبيق عين: لو المحرك علق، الاستئناف ميحبسش الشاشة.
  static const Duration _recognitionTimeout = Duration(seconds: 60);

  @override
  Future<String> recognizeText(camera.XFile image) async {
    try {
      // ⚡ PSM 6: الصورة كلها كتلة نص واحدة + الحفاظ على المسافات —
      // أدق بكتير للصفحات المكتظة من إن تقسيم الصفحات التلقائي يقصّف
      // معظم الكلام (صفحة 1600 كلمة كانت بتطلع منها كلمات معدودة).
      // Android بيدعمهم رسميًا في الكود بتاع الـ plugin، و iOS بيتجاهلهم بهدوء.
      const args = <String, String>{
        'psm': '6',
        'preserve_interword_spaces': '1',
      };

      final raw = await FlutterTesseractOcr.extractText(
        image.path,
        language: _languages,
        args: args,
      ).timeout(_recognitionTimeout);

      final text = raw.trim();
      if (text.isEmpty) {
        throw const NoTextFoundException();
      }

      return text;
    } on NoTextFoundException {
      rethrow;
    } on TimeoutException {
      throw const RecognitionException('timeout');
    } catch (_) {
      throw const RecognitionException();
    }
  }
}
