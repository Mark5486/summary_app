import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' hide Summary;
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/file_text_service.dart';
import '../../../../core/services/ocr/text_recognition_service.dart';
import '../../../../core/services/pdf/ocr_image_helper.dart';
import '../../../../core/services/pdf/pdf_text_cleaning.dart';
import '../../../../core/services/pdf/pdf_text_service.dart';
import '../../../../core/summarizer/extractive_summarizer.dart';
import '../../domain/entities/summary.dart';
import '../../domain/repositories/summarize_repository.dart';

class SummarizeRepositoryImpl implements SummarizeRepository {
  final FileTextService fileTextService;
  final TextRecognitionService recognitionService;

  const SummarizeRepositoryImpl({
    required this.fileTextService,
    required this.recognitionService,
  });

  @override
  Future<Either<Failure, Summary>> summarize(String text) async {
    try {
      final result = await compute(ExtractiveSummarizer.summarize, text);

      return Right(
        Summary(
          id: const Uuid().v4(),
          createdAt: DateTime.now(),
          originalText: text.trim(),
          result: result,
        ),
      );
    } on InputTooShortException {
      return const Left(InputTooShortFailure());
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FileLoadResult>> extractFromFile() async {
    try {
      final result = await fileTextService.pickAndReadFile();
      return Right(result);
    } on FilePickCancelledException {
      return const Left(FilePickCancelledFailure());
    } on InvalidFileException {
      return const Left(InvalidFileFailure());
    } on FileTooLargeException {
      return const Left(FileTooLargeFailure());
    } on PdfOpenException {
      return const Left(PdfOpenFailure());
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> extractFromImage(XFile image) async {
    try {
      final text = await recognitionService.recognizeText(image);
      return Right(text);
    } on NoTextFoundException {
      return const Left(NoTextFoundFailure());
    } on RecognitionException catch (e) {
      return Left(RecognitionFailure(e.detail));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> ocrScannedPdf(
    Uint8List pdfBytes, {
    required void Function(double progress) onProgress,
  }) async {
    try {
      final pages = await PdfTextService.renderPagesToPng(
        pdfBytes,
        onProgress: (done, total) =>
            onProgress(total == 0 ? 0 : (done / total) * 0.3),
      );
      if (pages.isEmpty) {
        return const Left(NoTextFoundFailure());
      }

      final buffer = StringBuffer();
      for (var i = 0; i < pages.length; i++) {
        final image = await prepareOcrImage(pages[i], 'page-${i + 1}.png');
        try {
          final text = await recognitionService.recognizeText(image);
          buffer
            ..write(text)
            ..writeln();
        } on NoTextFoundException {
        } finally {
          await disposeOcrImage(image);
        }
        onProgress(0.3 + 0.7 * ((i + 1) / pages.length));
      }

      final combined = PdfTextCleaner.clean(buffer.toString());
      if (combined.isEmpty) {
        return const Left(NoTextFoundFailure());
      }
      return Right(combined);
    } on PdfOpenException {
      return const Left(PdfOpenFailure());
    } on RecognitionException catch (e) {
      return Left(RecognitionFailure(e.detail));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
