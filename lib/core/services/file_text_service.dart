import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../errors/exceptions.dart';
import 'file_type_detector.dart';
import 'pdf/pdf_text_cleaning.dart';
import 'pdf/pdf_text_service.dart';

/// نتيجة تحميل ملف — نص + بيانات تعريف للعرض في بطاقة الملف.
class FileLoadResult {
  final String text;

  /// الملف PDF؟
  final bool isPdf;

  /// بايتات الـ PDF الأصلية — محفوظة لو الملف طلع ممسوح ضوئيًا
  /// والمستخدم عايز يشغّل الـ OCR على صفحاته. بتتنفض عند التلخيص/المسح.
  final Uint8List? pdfBytes;

  /// عدد صفحات الـ PDF الإجمالي (نصي = null).
  final int? pageCount;

  /// هل حد الـ 50 صفحة اشتغل؟
  final bool pageLimitReached;

  /// هل حد الـ 200 ألف حرف اشتغل؟
  final bool charLimitReached;

  /// PDF ممسوح ضوئيًا — مفيش نص يتستخرج مباشرة (محتاج OCR).
  final bool scanned;

  /// عدد الكلمات — بيتحسب مرة واحدة عند التحميل.
  final int wordCount;

  const FileLoadResult({
    required this.text,
    required this.isPdf,
    required this.wordCount,
    this.pdfBytes,
    this.pageCount,
    this.pageLimitReached = false,
    this.charLimitReached = false,
    this.scanned = false,
  });
}

/// قراءة نص من ملف محلي — أوفلاين 100%.
///
/// الريفيو: نوع الملف بيتحدد من أول بايتات (magic numbers) مش من
/// الامتداد — %PDF يمشي لقارئ الـ PDF، وأي ملف ثنائي تاني (PK، صور…)
/// يترفض، وغير كده يمشي في مسار النص العادي (UTF-16 → UTF-8 → cp1256).
abstract class FileTextService {
  Future<FileLoadResult> pickAndReadFile();
}

class FileTextServiceImpl implements FileTextService {
  const FileTextServiceImpl();

  @override
  Future<FileLoadResult> pickAndReadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['txt', 'text', 'md', 'log', 'csv', 'pdf'],
      withData: true,
    );

    final file = result?.files.singleOrNull;
    if (file == null) {
      throw const FilePickCancelledException();
    }

    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const InvalidFileException();
    }

    // ⛔/✅ الحكم من الماجيك نمبر — مش من الامتداد.
    switch (FileTypeDetector.detect(bytes)) {
      case DetectedFileType.pdf:
        return _loadPdf(bytes);

      case DetectedFileType.binary:
        // تواقيع ثنائية واضحة (zip/Word/صور/تنفيذيات) — رفض فوري.
        throw const InvalidFileException();

      case DetectedFileType.plainText:
        return _loadPlainText(bytes);
    }
  }

  /// مسار الـ PDF: حد حجم ← استخراج pdfrx ← تنظيف وتطبيع —
  /// ولو النص طلع شبه فاضي يبقى الملف ممسوح ضوئيًا (شوف scanned).
  Future<FileLoadResult> _loadPdf(Uint8List bytes) async {
    if (bytes.length > PdfTextService.maxFileSizeBytes) {
      throw const FileTooLargeException();
    }

    final extracted = await PdfTextService.extract(bytes);
    final scanned = PdfTextCleaner.looksEmpty(extracted.text);

    return FileLoadResult(
      text: scanned ? '' : extracted.text,
      isPdf: true,
      pdfBytes: bytes,
      pageCount: extracted.pageCount,
      pageLimitReached: extracted.pageLimitReached,
      charLimitReached: extracted.charLimitReached,
      scanned: scanned,
      wordCount: scanned ? 0 : PdfTextCleaner.countWords(extracted.text),
    );
  }

  /// مسار النص العادي — نفس سلوك القديم بالظبط.
  Future<FileLoadResult> _loadPlainText(Uint8List bytes) async {
    // ⚡ فك الترميز في isolate منفصل — الملفات الكبيرة متتجمدش الواجهة.
    final text = (await compute(decodeBytes, bytes)).trim();
    if (text.isEmpty) {
      throw const InvalidFileException();
    }

    return FileLoadResult(
      text: text,
      isPdf: false,
      wordCount: PdfTextCleaner.countWords(text),
    );
  }

  /// فك الترميز: UTF-16 (بـ BOM أو من غيره) → UTF-8 → Windows-1256.
  /// لو النص النهائي طلع رموز مش كلام (ملف مش نصي أصلًا) بنرمي
  /// InvalidFileException — رسالة واضحة بدل ما نلخص عباريض.
  @visibleForTesting
  static String decodeBytes(Uint8List bytes) {
    // 0) BOM بتاع UTF-16 — ملفات Notepad القديمة (اختيار "Unicode").
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      final text = _decodeUtf16(bytes.sublist(2), littleEndian: true);
      _guardAgainstGarbage(text);
      return text;
    }
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      final text = _decodeUtf16(bytes.sublist(2), littleEndian: false);
      _guardAgainstGarbage(text);
      return text;
    }

    // 1) UTF-16 من غير BOM — النص بيسيب بايتات صفر مميزة.
    if (_looksLikeUtf16(bytes)) {
      final le = _decodeUtf16(bytes, littleEndian: true);
      final be = _decodeUtf16(bytes, littleEndian: false);
      final leScore = _countArabic(le) + _latinLetters(le);
      final beScore = _countArabic(be) + _latinLetters(be);
      final text = leScore >= beScore ? le : be;
      _guardAgainstGarbage(text);
      return text;
    }

    // 2) ⛔ أي بايت صفر بعد استبعاد UTF-16 = ملف ثنائي — بنرفضه فورًا
    //    بدل ما نفكّه غلط ونلخص رموز.
    if (bytes.contains(0)) {
      throw const InvalidFileException();
    }

    // 3) UTF-8 الأول، ولو فشل: Windows-1256 (الشائع في ملفات
    //    Notepad العربي القديمة).
    String best;
    try {
      best = utf8.decode(bytes);
    } on FormatException {
      best = _decodeWindows1256(bytes);
    }

    // UTF-8 نجح بس ممكن يكون الملف أصلاً cp1256 والفك ده طلع عباريض —
    // لو مفيش ولا حرف عربي رغم إن الملف فيه بايتات العربية المميزة نجرّب الجدول.
    final arabicInUtf8 = _countArabic(best);
    if (arabicInUtf8 == 0 && _hasCp1256ArabicSignature(bytes)) {
      final asCp1256 = _decodeWindows1256(bytes);
      if (_countArabic(asCp1256) > 0) return asCp1256;
    }

    _guardAgainstGarbage(best);
    return best;
  }

  /// حروف وكلمات كويسة عشان نقيس بيها جودة الفك.
  static final RegExp _badChars =
      RegExp('[\x00-\x08\x0B\x0C\x0E-\x1F\x7F\uFFFD]');

  static final RegExp _letterOrDigit =
      RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// ⛔ لو النص طلع رموز تحكّم ورموز غريبة أكتر منه كلام — يبقى الملف
  /// مش نصي أصلًا (bin/ضغط/ترميز مجهول) وبنرفضه برسالة واضحة.
  static void _guardAgainstGarbage(String s) {
    if (s.length < 60) return; // نصوص قصيرة ما بنحكمش عليها

    final badRatio = _badChars.allMatches(s).length / s.length;
    if (badRatio > 0.25) {
      throw const InvalidFileException();
    }

    final letterRatio = _letterOrDigit.allMatches(s).length / s.length;
    if (letterRatio < 0.30) {
      throw const InvalidFileException();
    }
  }

  /// نص UTF-16 حقيقي بيسيب أصفار مميزة (البايت العالي/الواطي بيبقى 0).
  static bool _looksLikeUtf16(Uint8List bytes) {
    final n = bytes.length < 1024 ? bytes.length : 1024;
    var zeros = 0;
    for (var i = 0; i < n; i++) {
      if (bytes[i] == 0) zeros++;
    }
    return zeros * 32 >= n; // ≥ 3% أصفار
  }

  /// فك UTF-16 يدوي — وحدات 16-بت، والـ surrogate pairs بتتركب تلقائي.
  static String _decodeUtf16(Uint8List bytes, {required bool littleEndian}) {
    final units = <int>[];
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      units.add(
        littleEndian
            ? bytes[i] | (bytes[i + 1] << 8)
            : (bytes[i] << 8) | bytes[i + 1],
      );
    }
    return String.fromCharCodes(units);
  }

  static int _latinLetters(String s) {
    var count = 0;
    for (final rune in s.runes) {
      if ((rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A)) {
        count++;
      }
    }
    return count;
  }

  static int _countArabic(String s) =>
      RegExp('[\u0600-\u06FF]').allMatches(s).length;

  /// بايتات موجودة في نطاق الحروف العربية في cp1256 (D8-DF + C0-CF).
  static bool _hasCp1256ArabicSignature(Uint8List bytes) {
    var hits = 0;
    for (final b in bytes) {
      if ((b >= 0xC0 && b <= 0xDF) || (b >= 0xD8 && b <= 0xDF)) {
        hits++;
        if (hits >= 5) return true;
      }
    }
    return hits >= 5;
  }

  /// جدول Windows-1256 الرسمي من 0x80 لـ 0xFF (مولّد ومتحقق منه).
  /// البايتات ASCII العادية (0–127) بتتكتب زي ما هي.
  static const List<String> _cp1256 = [
    '\u20AC','\u067E','\u201A','\u0192','\u201E','\u2026','\u2020','\u2021',
    '\u02C6','\u2030','\u0679','\u2039','\u0152','\u0686','\u0698','\u0688',
    '\u06AF','\u2018','\u2019','\u201C','\u201D','\u2022','\u2013','\u2014',
    '\u06A9','\u2122','\u0691','\u203A','\u0153','\u200C','\u200D','\u06BA',
    '\u00A0','\u060C','\u00A2','\u00A3','\u00A4','\u00A5','\u00A6','\u00A7',
    '\u00A8','\u00A9','\u06BE','\u00AB','\u00AC','\u00AD','\u00AE','\u00AF',
    '\u00B0','\u00B1','\u00B2','\u00B3','\u00B4','\u00B5','\u00B6','\u00B7',
    '\u00B8','\u00B9','\u061B','\u00BB','\u00BC','\u00BD','\u00BE','\u061F',
    '\u06C1','\u0621','\u0622','\u0623','\u0624','\u0625','\u0626','\u0627',
    '\u0628','\u0629','\u062A','\u062B','\u062C','\u062D','\u062E','\u062F',
    '\u0630','\u0631','\u0632','\u0633','\u0634','\u0635','\u0636','\u00D7',
    '\u0637','\u0638','\u0639','\u063A','\u0640','\u0641','\u0642','\u0643',
    '\u00E0','\u0644','\u00E2','\u0645','\u0646','\u0647','\u0648','\u00E7',
    '\u00E8','\u00E9','\u00EA','\u00EB','\u0649','\u064A','\u00EE','\u00EF',
    '\u064B','\u064C','\u064D','\u064E','\u00F4','\u064F','\u0650','\u00F7',
    '\u0651','\u00F9','\u0652','\u00FB','\u00FC','\u200E','\u200F','\u06D2',
  ];

  static String _decodeWindows1256(Uint8List bytes) {
    final buffer = StringBuffer();
    for (final b in bytes) {
      if (b < 0x80) {
        buffer.writeCharCode(b);
      } else {
        final index = b - 0x80;
        buffer.write(
          index < _cp1256.length ? _cp1256[index] : '\uFFFD',
        );
      }
    }
    return buffer.toString();
  }
}
