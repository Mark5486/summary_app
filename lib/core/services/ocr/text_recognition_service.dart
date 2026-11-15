import 'package:camera/camera.dart';

/// واجهة قراءة النص من الصورة (OCR) — أوفلاين.
/// التنفيذ بيتحدد تلقائيًا: Tesseract على الموبايل / Tesseract.js على الويب.
abstract class TextRecognitionService {
  Future<String> recognizeText(XFile image);
}
