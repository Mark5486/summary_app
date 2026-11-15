import 'package:camera/camera.dart';

import 'text_recognition_service.dart';
import 'text_recognition_service_mobile.dart'
    if (dart.library.js_interop) 'text_recognition_service_web.dart';

/// مصنع الـ OCR — بيختار المحرك الصح حسب المنصة:
/// - موبايل/ويندوز (dart:io) → Tesseract 4 المدمج
/// - ويب (dart:js_interop) → Tesseract.js
TextRecognitionService createTextRecognitionService() =>
    TextRecognitionServiceImpl();

// واجهة معلنة عشان الـ analyzer يفضل متحقق من كلاسات التنفيذ.
typedef RecognizeFn = Future<String> Function(XFile image);
