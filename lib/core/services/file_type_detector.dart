import 'dart:typed_data';

enum DetectedFileType { pdf, plainText, binary }

class FileTypeDetector {
  FileTypeDetector._();

  static bool isPdf(Uint8List b) {
    final n = b.length < 1024 ? b.length : 1024;
    for (var i = 0; i + 4 <= n; i++) {
      if (b[i] == 0x25 &&
          b[i + 1] == 0x50 &&
          b[i + 2] == 0x44 &&
          b[i + 3] == 0x46) {
        return true;
      }
    }
    return false;
  }

  static DetectedFileType detect(Uint8List b) {
    if (b.isEmpty) return DetectedFileType.binary;
    if (isPdf(b)) return DetectedFileType.pdf;
    if (_hasBinarySignature(b)) return DetectedFileType.binary;
    return DetectedFileType.plainText;
  }

  static bool _hasBinarySignature(Uint8List b) {
    if (b.length < 4) return false;

    if (b[0] == 0x50 && b[1] == 0x4B) {
      if (b[2] == 0x03 || b[2] == 0x05 || b[2] == 0x07) return true;
    }
    if (b[0] == 0xD0 && b[1] == 0xCF && b[2] == 0x11 && b[3] == 0xE0) {
      return true;
    }
    if (b[0] == 0x52 && b[1] == 0x61 && b[2] == 0x72 && b[3] == 0x21) {
      return true;
    }
    if (b[0] == 0x37 && b[1] == 0x7A && b[2] == 0xBC && b[3] == 0xAF) {
      return true;
    }
    if (b[0] == 0x1F && b[1] == 0x8B) return true;

    if (b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return true;
    if (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) {
      return true;
    }
    if (b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x38) {
      return true;
    }
    if (b.length > 11 &&
        b[0] == 0x52 &&
        b[1] == 0x49 &&
        b[2] == 0x46 &&
        b[3] == 0x46 &&
        b[8] == 0x57 &&
        b[9] == 0x45 &&
        b[10] == 0x42 &&
        b[11] == 0x50) {
      return true;
    }
    if (b.length > 7 &&
        b[4] == 0x66 &&
        b[5] == 0x74 &&
        b[6] == 0x79 &&
        b[7] == 0x70) {
      return true;
    }
    if (b[0] == 0x00 && b[1] == 0x00 && b[2] == 0x01 && b[3] == 0x00) {
      return true;
    }

    if (b[0] == 0x42 && b[1] == 0x4D && b.length >= 18) {
      final dibSize = b[14] | (b[15] << 8) | (b[16] << 16) | (b[17] << 24);
      if (dibSize == 12 || dibSize == 40 || dibSize == 108 || dibSize == 124) {
        return true;
      }
    }

    if (b[0] == 0x4F && b[1] == 0x67 && b[2] == 0x67 && b[3] == 0x53) {
      return true;
    }
    if (b[0] == 0x66 && b[1] == 0x4C && b[2] == 0x61 && b[3] == 0x43) {
      return true;
    }
    if (b[0] == 0x49 && b[1] == 0x44 && b[2] == 0x33) return true;
    if (b[0] == 0x7F && b[1] == 0x45 && b[2] == 0x4C && b[3] == 0x46) {
      return true;
    }
    if (b[0] == 0x4D && b[1] == 0x5A) return true;
    return false;
  }
}
