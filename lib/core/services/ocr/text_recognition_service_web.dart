import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:camera/camera.dart' as camera;

import '../../errors/exceptions.dart';
import 'text_recognition_service.dart';

@JS('Tesseract.recognize')
external JSPromise<JSAny> _tesseractRecognize(
  JSAny image,
  JSString languages,
  JSAny? options,
);

class TextRecognitionServiceImpl implements TextRecognitionService {
  static const String _languages = 'ara+eng';

  static const Duration _recognitionTimeout = Duration(seconds: 60);

  @override
  Future<String> recognizeText(camera.XFile image) async {
    try {
      final bytes = await image.readAsBytes();

      final dataUrl = 'data:${_mimeType(bytes)};base64,${base64Encode(bytes)}';

      final options = <String, dynamic>{
        'params': <String, String>{
          'tessedit_pageseg_mode': '6',
          'preserve_interword_spaces': '1',
        },
      }.jsify();

      final result = await _tesseractRecognize(
        dataUrl.toJS,
        _languages.toJS,
        options,
      ).toDart.timeout(_recognitionTimeout);

      final data = (result as JSObject).getProperty<JSObject>('data'.toJS);
      final text = data.getProperty<JSString>('text'.toJS).toDart;

      if (text.trim().isEmpty) {
        throw const NoTextFoundException();
      }

      return text.trim();
    } on NoTextFoundException {
      rethrow;
    } on TimeoutException {
      throw const RecognitionException('timeout');
    } catch (_) {
      throw const RecognitionException();
    }
  }

  String _mimeType(List<int> bytes) {
    final isPng = bytes.length > 4 && bytes[0] == 0x89 && bytes[1] == 0x50;

    return isPng ? 'image/png' : 'image/jpeg';
  }
}
