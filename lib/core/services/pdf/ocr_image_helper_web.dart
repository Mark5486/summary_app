import 'dart:typed_data';

import 'package:camera/camera.dart';

/// ويب: مفيش ملفات مؤقتة — XFile من الذاكرة مباشرة (البيانات هي اللي بتتقرا).
Future<XFile> prepareOcrImage(Uint8List bytes, String name) async =>
    XFile.fromData(bytes, name: name, mimeType: 'image/png');

Future<void> disposeOcrImage(XFile file) async {}
