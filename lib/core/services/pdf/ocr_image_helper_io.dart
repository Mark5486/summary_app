import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

/// موبايل/ويندوز: Tesseract المحلي بيقرا من مسار ملف حقيقي —
/// فبنكتب صفحة الـ PDF المرسومة في مجلد مؤقت ونمسرحها بعد القراءة.
Future<XFile> prepareOcrImage(Uint8List bytes, String name) async {
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/besbasa_ocr_$name';
  await File(path).writeAsBytes(bytes, flush: true);
  return XFile(path);
}

Future<void> disposeOcrImage(XFile file) async {
  try {
    final f = File(file.path);
    if (await f.exists()) {
      await f.delete();
    }
  } catch (_) {
    // مسح الملف المؤقت مش حاجة تتوقف عليها العملية.
  }
}
