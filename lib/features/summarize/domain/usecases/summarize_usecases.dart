import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' hide Summary;

import '../../../../core/errors/failures.dart';
import '../../../../core/services/file_text_service.dart';
import '../entities/summary.dart';
import '../repositories/summarize_repository.dart';

/// حالة الاستخدام: لخّص نصًا — نقاط قليلة + شرح مبسط.
class SummarizeTextUseCase {
  final SummarizeRepository repository;

  const SummarizeTextUseCase(this.repository);

  Future<Either<Failure, Summary>> call(String text) =>
      repository.summarize(text);
}

/// حالة الاستخدام: افتح ملفًا محليًا (txt أو PDF) واستخرج نصّه.
class ExtractTextFromFileUseCase {
  final SummarizeRepository repository;

  const ExtractTextFromFileUseCase(this.repository);

  Future<Either<Failure, FileLoadResult>> call() =>
      repository.extractFromFile();
}

/// حالة الاستخدام: اقرأ نصًا من صورة متصوّرة (OCR أوفلاين).
class ExtractTextFromImageUseCase {
  final SummarizeRepository repository;

  const ExtractTextFromImageUseCase(this.repository);

  Future<Either<Failure, String>> call(XFile image) =>
      repository.extractFromImage(image);
}

/// حالة الاستخدام: OCR على صفحات PDF ممسوح ضوئيًا — اختياري وبشريط تقدّم.
class ExtractOcrFromScannedPdfUseCase {
  final SummarizeRepository repository;

  const ExtractOcrFromScannedPdfUseCase(this.repository);

  Future<Either<Failure, String>> call(
    Uint8List pdfBytes, {
    required void Function(double progress) onProgress,
  }) =>
      repository.ocrScannedPdf(pdfBytes, onProgress: onProgress);
}
