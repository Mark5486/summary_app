import 'package:camera/camera.dart';

import 'text_recognition_service.dart';
import 'text_recognition_service_mobile.dart'
    if (dart.library.js_interop) 'text_recognition_service_web.dart';

TextRecognitionService createTextRecognitionService() =>
    TextRecognitionServiceImpl();

typedef RecognizeFn = Future<String> Function(XFile image);
