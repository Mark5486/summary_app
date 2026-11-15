import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/summary.dart';

enum SummarizeStatus { idle, loading, success, failure }

class FileLoadInfo extends Equatable {
  final bool isPdf;
  final int wordCount;
  final int? pageCount;
  final bool pageLimitReached;
  final bool charLimitReached;
  final bool scanned;
  final bool fromOcr;

  const FileLoadInfo({
    required this.isPdf,
    required this.wordCount,
    this.pageCount,
    this.pageLimitReached = false,
    this.charLimitReached = false,
    this.scanned = false,
    this.fromOcr = false,
  });

  @override
  List<Object?> get props => [
    isPdf,
    wordCount,
    pageCount,
    pageLimitReached,
    charLimitReached,
    scanned,
    fromOcr,
  ];
}

class SummarizeState extends Equatable {
  final SummarizeStatus status;

  final String inputText;

  final Summary? summary;

  final Failure? failure;

  final bool extracting;

  final String? notice;

  final FileLoadInfo? fileInfo;

  final String? previewText;

  final double? ocrProgress;

  final bool restoredFromHistory;

  const SummarizeState({
    this.status = SummarizeStatus.idle,
    this.inputText = '',
    this.summary,
    this.failure,
    this.extracting = false,
    this.notice,
    this.fileInfo,
    this.previewText,
    this.ocrProgress,
    this.restoredFromHistory = false,
  });

  SummarizeState copyWith({
    SummarizeStatus? status,
    String? inputText,
    Summary? summary,
    Failure? failure,
    bool? extracting,
    String? notice,
    FileLoadInfo? fileInfo,
    String? previewText,
    double? ocrProgress,
    bool clearSummary = false,
    bool clearFailure = false,
    bool clearNotice = false,
    bool clearFileInfo = false,
    bool clearPreview = false,
    bool clearOcrProgress = false,
    bool? restoredFromHistory,
  }) {
    return SummarizeState(
      status: status ?? this.status,
      inputText: inputText ?? this.inputText,
      summary: clearSummary ? null : (summary ?? this.summary),

      restoredFromHistory: clearSummary
          ? false
          : (restoredFromHistory ?? this.restoredFromHistory),
      failure: clearFailure ? null : (failure ?? this.failure),
      extracting: extracting ?? this.extracting,
      notice: clearNotice ? null : (notice ?? this.notice),
      fileInfo: clearFileInfo ? null : (fileInfo ?? this.fileInfo),
      previewText: clearPreview ? null : (previewText ?? this.previewText),
      ocrProgress: clearOcrProgress ? null : (ocrProgress ?? this.ocrProgress),
    );
  }

  @override
  List<Object?> get props => [
    status,
    inputText,
    summary,
    failure,
    extracting,
    notice,
    fileInfo,
    previewText,
    ocrProgress,
    restoredFromHistory,
  ];
}
