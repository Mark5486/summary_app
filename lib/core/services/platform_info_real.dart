import 'dart:io';

/// معلومات المنصة الحقيقية — للمنصات اللي فيها dart:io.
bool get isWindows => Platform.isWindows;
bool get isMobilePlatform => Platform.isAndroid || Platform.isIOS;
