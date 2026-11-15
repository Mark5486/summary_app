import 'dart:typed_data';

/// نوع الملف المكتشف من أول بايتات — مش من الامتداد.
///
/// الريفيو: الامتداد مجرد اقتراح للمنتقي؛ على الويب ممكن تختار "All files"
/// وتحمل أي حاجة. الحكم الحقيقي بيبقى من التواقيع (magic numbers).
enum DetectedFileType { pdf, plainText, binary }

class FileTypeDetector {
  FileTypeDetector._();

  /// %PDF- — المواصفة بتسمح بجُنك صغير قبل العنوان، فبنفّتش على أول 1024 بايت.
  static bool isPdf(Uint8List b) {
    final n = b.length < 1024 ? b.length : 1024;
    for (var i = 0; i + 4 <= n; i++) {
      if (b[i] == 0x25 && b[i + 1] == 0x50 && b[i + 2] == 0x44 && b[i + 3] == 0x46) {
        return true; // %PDF
      }
    }
    return false;
  }

  static DetectedFileType detect(Uint8List b) {
    if (b.isEmpty) return DetectedFileType.binary; // ملف فاضي
    if (isPdf(b)) return DetectedFileType.pdf;
    if (_hasBinarySignature(b)) return DetectedFileType.binary;
    return DetectedFileType.plainText;
  }

  /// تواقيع ملفات ثنائية شائعة — بتترفض قبل أي فك ترميز.
  static bool _hasBinarySignature(Uint8List b) {
    if (b.length < 4) return false;
    // أرشيفات وحزم
    if (b[0] == 0x50 && b[1] == 0x4B) {
      if (b[2] == 0x03 || b[2] == 0x05 || b[2] == 0x07) return true; // zip/docx/xlsx
    }
    if (b[0] == 0xD0 && b[1] == 0xCF && b[2] == 0x11 && b[3] == 0xE0) {
      return true; // OLE2 — doc/xls قديم
    }
    if (b[0] == 0x52 && b[1] == 0x61 && b[2] == 0x72 && b[3] == 0x21) {
      return true; // Rar!
    }
    if (b[0] == 0x37 && b[1] == 0x7A && b[2] == 0xBC && b[3] == 0xAF) {
      return true; // 7z
    }
    if (b[0] == 0x1F && b[1] == 0x8B) return true; // gzip
    // صور
    if (b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return true; // JPEG
    if (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) {
      return true; // PNG
    }
    if (b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x38) {
      return true; // GIF8
    }
    if (b.length > 11 &&
        b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
        b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) {
      return true; // RIFF....WEBP
    }
    if (b.length > 7 &&
        b[4] == 0x66 && b[5] == 0x74 && b[6] == 0x79 && b[7] == 0x70) {
      return true; // ISO BMFF — mp4/mov/heic/avif
    }
    if (b[0] == 0x00 && b[1] == 0x00 && b[2] == 0x01 && b[3] == 0x00) {
      return true; // ICO
    }
    // ⚠️ محتاجين بايتات 14..17 للـ DIB header — فالطول لازم ≥ 18.
    // قبل كده كان الشرط > 14 وده بيقرأ بره حدود أي ملف نصي بيبدأ
    // بـ "BM" طوله 15–17 بايت ويعمل RangeError كراش.
    if (b[0] == 0x42 && b[1] == 0x4D && b.length >= 18) {
      // BMP — بنشيك على الـ DIB header عشان "BM..." النصية ما تتضربش غلط
      final dibSize = b[14] | (b[15] << 8) | (b[16] << 16) | (b[17] << 24);
      if (dibSize == 12 || dibSize == 40 || dibSize == 108 || dibSize == 124) {
        return true;
      }
    }
    // صوت/تنفيذيات
    if (b[0] == 0x4F && b[1] == 0x67 && b[2] == 0x67 && b[3] == 0x53) {
      return true; // OggS
    }
    if (b[0] == 0x66 && b[1] == 0x4C && b[2] == 0x61 && b[3] == 0x43) {
      return true; // fLaC
    }
    if (b[0] == 0x49 && b[1] == 0x44 && b[2] == 0x33) return true; // ID3 (mp3)
    if (b[0] == 0x7F && b[1] == 0x45 && b[2] == 0x4C && b[3] == 0x46) {
      return true; // ELF
    }
    if (b[0] == 0x4D && b[1] == 0x5A) return true; // MZ — exe/dll
    return false;
  }
}
