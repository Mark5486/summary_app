import 'dart:async';

import 'package:camera/camera.dart' as camera;
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

import '../../errors/exceptions.dart';
import 'text_recognition_service.dart';

class TextRecognitionServiceImpl implements TextRecognitionService {
  static const String _languages = 'ara+eng';

  static const Duration _recognitionTimeout = Duration(seconds: 60);

  @override
  Future<String> recognizeText(camera.XFile image) async {
    try {
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
