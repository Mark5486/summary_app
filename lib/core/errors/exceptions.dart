/// استثناءات المحرك — بترميها طبقات الداتا/الدومين وبتتترجم لـ Failures.
sealed class BesbasaException implements Exception {
  const BesbasaException();
}

/// النص فاضي أو أقصر من اللازم للتلخيص.
class InputTooShortException extends BesbasaException {
  const InputTooShortException();
}

/// المستخدم اختار ملف مش نصي/PDF أو الملف ناقص.
class InvalidFileException extends BesbasaException {
  const InvalidFileException();
}

/// الملف أكبر من الحد المسموح (20 ميجا للـ PDF).
class FileTooLargeException extends BesbasaException {
  const FileTooLargeException();
}

/// فشل فتح ملف الـ PDF (بايظ / محمي بكلمة سر / مش PDF حقيقي).
class PdfOpenException extends BesbasaException {
  final String? detail;
  const PdfOpenException([this.detail]);
}

/// المستخدم قفل منتقي الملفات من غير ما يختار.
class FilePickCancelledException extends BesbasaException {
  const FilePickCancelledException();
}

/// الـ OCR رجّع نص فاضي (الصورة مفيهاش نص واضح).
class NoTextFoundException extends BesbasaException {
  const NoTextFoundException();
}

/// فشل الـ OCR (الصلاحيات / المحرك / انتهاء المهلة).
class RecognitionException extends BesbasaException {
  final String? detail;
  const RecognitionException([this.detail]);
}
