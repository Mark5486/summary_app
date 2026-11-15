import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' hide Summary;

import '../../../../core/errors/failures.dart';
import '../../../../core/services/file_text_service.dart';
import '../entities/summary.dart';

/// مستودع التلخيص — واجهة الطبقة الدومين.
abstract class SummarizeRepository {
  /// يلخّص نصًا مكتوبًا/ملصوقًا.
  Future<Either<Failure, Summary>> summarize(String text);

  /// يفتح ملفًا محليًا (txt أو PDF) ويرجّع النص + بيانات التحميل.
  Future<Either<Failure, FileLoadResult>> extractFromFile();

  /// يقرأ نصًا من صورة متصوّرة (OCR أوفلاين).
  Future<Either<Failure, String>> extractFromImage(XFile image);

  /// يشغّل OCR على صفحات PDF ممسوح ضوئيًا (رسم الصفحات ← Tesseract).
  Future<Either<Failure, String>> ocrScannedPdf(
    Uint8List pdfBytes, {
    required void Function(double progress) onProgress,
  });
}
