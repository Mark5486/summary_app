import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/pdf/pdf_text_cleaning.dart';
import '../../domain/entities/summary.dart';
import '../../domain/usecases/summarize_usecases.dart';
import '../../../history/data/models/summary_model.dart';
import '../../../history/domain/usecases/history_usecases.dart';
import 'summarize_state.dart';

class SummarizeCubit extends Cubit<SummarizeState> {
  final SummarizeTextUseCase summarizeUseCase;
  final ExtractTextFromFileUseCase extractFromFileUseCase;
  final ExtractTextFromImageUseCase extractFromImageUseCase;
  final ExtractOcrFromScannedPdfUseCase ocrScannedPdfUseCase;
  final SaveSummaryUseCase saveSummaryUseCase;
  final GetLatestSummaryUseCase getLatestSummaryUseCase;

  SummarizeCubit({
    required this.summarizeUseCase,
    required this.extractFromFileUseCase,
    required this.extractFromImageUseCase,
    required this.ocrScannedPdfUseCase,
    required this.saveSummaryUseCase,
    required this.getLatestSummaryUseCase,
  }) : super(const SummarizeState());

  static const int maxInputChars = 200000;

  static const int previewThresholdChars = 8000;

  static const int previewChars = 2000;

  Uint8List? _pendingPdfBytes;

  static String _capInput(String text) =>
      text.length <= maxInputChars ? text : text.substring(0, maxInputChars);

  void setInput(String text) {
    if (text.length <= maxInputChars) {
      emit(
        state.copyWith(inputText: text, clearFailure: true, clearNotice: true),
      );
      return;
    }

    if (state.inputText.length == maxInputChars) return;
    emit(
      state.copyWith(
        inputText: _capInput(text),
        clearFailure: true,
        notice: 'truncated',
      ),
    );
  }

  void consumeNotice() => emit(state.copyWith(clearNotice: true));

  void clearInput() {
    _pendingPdfBytes = null;
    emit(const SummarizeState());
  }

  Future<void> loadFromFile() async {
    emit(
      state.copyWith(extracting: true, clearFailure: true, clearNotice: true),
    );
    final result = await extractFromFileUseCase();
    result.fold(
      (failure) => emit(
        state.copyWith(
          extracting: false,
          status: SummarizeStatus.failure,
          failure: failure,
        ),
      ),
      (load) {
        _pendingPdfBytes = load.scanned ? load.pdfBytes : null;

        if (load.scanned) {
          emit(
            state.copyWith(
              extracting: false,
              status: SummarizeStatus.idle,
              inputText: '',
              clearPreview: true,
              clearSummary: true,
              clearFailure: true,
              fileInfo: FileLoadInfo(
                isPdf: true,
                wordCount: 0,
                pageCount: load.pageCount,
                pageLimitReached: load.pageLimitReached,
                scanned: true,
              ),
            ),
          );
          return;
        }

        final usePreview = load.text.length > previewThresholdChars;
        emit(
          state.copyWith(
            extracting: false,
            status: SummarizeStatus.idle,
            inputText: _capInput(load.text),
            previewText: usePreview
                ? load.text.substring(0, previewChars)
                : null,
            clearSummary: true,
            clearFailure: true,
            fileInfo: FileLoadInfo(
              isPdf: load.isPdf,
              wordCount: load.wordCount,
              pageCount: load.pageCount,
              pageLimitReached: load.pageLimitReached,
              charLimitReached: load.charLimitReached,
            ),
            notice: load.pageLimitReached
                ? 'pdfLimited'
                : (load.charLimitReached ? 'truncated' : null),
          ),
        );
      },
    );
  }

  Future<void> recognizeImage(XFile image) async {
    emit(state.copyWith(extracting: true, clearFailure: true));
    final result = await extractFromImageUseCase(image);
    result.fold(
      (failure) => emit(
        state.copyWith(
          extracting: false,
          status: SummarizeStatus.failure,
          failure: failure,
        ),
      ),
      (text) => _adoptExtractedText(text, fromOcr: true, isPdf: false),
    );
  }

  Future<void> ocrScannedPdf() async {
    final bytes = _pendingPdfBytes;
    if (bytes == null) return;

    emit(state.copyWith(extracting: true, clearFailure: true, ocrProgress: 0));
    final result = await ocrScannedPdfUseCase(
      bytes,
      onProgress: (p) => emit(state.copyWith(ocrProgress: p)),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          extracting: false,
          status: SummarizeStatus.failure,
          failure: failure,
          clearOcrProgress: true,
        ),
      ),
      (text) {
        emit(state.copyWith(clearOcrProgress: true));
        _adoptExtractedText(text, fromOcr: true, isPdf: true);
      },
    );
  }

  void _adoptExtractedText(
    String text, {
    required bool fromOcr,
    required bool isPdf,
  }) {
    final wasTruncated = text.length > maxInputChars;
    final capped = _capInput(text);
    final usePreview = capped.length > previewThresholdChars;
    emit(
      state.copyWith(
        extracting: false,
        status: SummarizeStatus.idle,
        inputText: capped,
        previewText: usePreview ? capped.substring(0, previewChars) : null,
        clearSummary: true,
        clearFailure: true,
        fileInfo: FileLoadInfo(
          isPdf: isPdf,
          wordCount: PdfTextCleaner.countWords(capped),
          fromOcr: fromOcr,
        ),
        notice: wasTruncated ? 'truncated' : null,
      ),
    );
  }

  Future<void> summarize() async {
    final text = state.inputText.trim();
    if (text.isEmpty) {
      emit(
        state.copyWith(
          status: SummarizeStatus.failure,
          failure: const InputTooShortFailure(),
        ),
      );
      return;
    }

    emit(state.copyWith(status: SummarizeStatus.loading, clearFailure: true));
    final result = await summarizeUseCase(text);

    await result.fold(
      (failure) async {
        emit(state.copyWith(status: SummarizeStatus.failure, failure: failure));
      },
      (summary) async {
        emit(
          state.copyWith(
            status: SummarizeStatus.success,
            summary: summary,
            restoredFromHistory: false,
          ),
        );
        unawaited(_saveQuietly(summary));
      },
    );
  }

  Future<void> restoreLastSummary() async {
    if (_hasActiveContent) return;

    final result = await getLatestSummaryUseCase();
    result.fold((failure) {}, (model) {
      if (_hasActiveContent || model == null) return;
      emit(
        state.copyWith(
          status: SummarizeStatus.idle,
          summary: _modelToSummary(model),
          restoredFromHistory: true,
        ),
      );
    });
  }

  void dismissRestoredSummary() {
    if (!state.restoredFromHistory) return;
    emit(state.copyWith(clearSummary: true));
  }

  bool get _hasActiveContent =>
      state.summary != null || state.inputText.trim().isNotEmpty;

  Summary _modelToSummary(SummaryModel model) => Summary(
    id: model.id,
    createdAt: DateTime.fromMillisecondsSinceEpoch(model.createdAtMs),
    originalText: model.originalText,
    result: SummaryResult(
      points: model.points,
      explanation: model.explanation,
      keywords: model.keywords,
      originalWordCount: model.originalWordCount,
      summaryWordCount: model.summaryWordCount,
    ),
  );

  Future<void> _saveQuietly(Summary summary) async {
    try {
      await saveSummaryUseCase(
        SummaryModel.fromSummary(
          summary.id,
          summary.createdAt,
          summary.originalText,
          summary.result,
        ),
      );
    } catch (_) {}
  }
}
