import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' hide Summary;

import '../../../../core/errors/failures.dart';
import '../../../../core/services/file_text_service.dart';
import '../entities/summary.dart';

abstract class SummarizeRepository {
  Future<Either<Failure, Summary>> summarize(String text);

  Future<Either<Failure, FileLoadResult>> extractFromFile();

  Future<Either<Failure, String>> extractFromImage(XFile image);

  Future<Either<Failure, String>> ocrScannedPdf(
    Uint8List pdfBytes, {
    required void Function(double progress) onProgress,
  });
}
