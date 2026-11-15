import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/summary.dart';

/// حالة شاشة التلخيص — واضحة ومحصورة.
enum SummarizeStatus { idle, loading, success, failure }

/// بيانات آخر ملف اتحمّل (txt/PDF) — بتغذّي بطاقة الملف في الـ UI.
///
/// عدد الكلمات بيتحسب مرة واحدة عند التحميل (الريفيو: ماتحسبش مع
/// كل rebuild) — لما المستخدم يكتب بيتم التقدير في العرض نفسه.
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

  /// النص اللي في خانة الإدخال — النص الكامل بيفضل هنا (في الـ cubit)
  /// حتى في وضع المعاينة، عشان التلخيص يشتغل على الأصل.
  final String inputText;

  /// الملخص الناتج (في حالة النجاح).
  final Summary? summary;

  /// الفشل الحالي (في حالة الفشل) — الـ UI بيوترجمه لرسالة.
  final Failure? failure;

  /// هل في عملية OCR/قراءة ملف شغالة؟ (لودينج منفصل عن التلخيص)
  final bool extracting;

  /// إشعار عابر (زي قص النص الكبير) — بيتنضف بعد عرضه.
  final String? notice;

  /// بيانات آخر ملف اتحمّل — null لو المستخدم بيكتب بنفسه.
  final FileLoadInfo? fileInfo;

  /// وضع المعاينة: النص الكبير مش بيتحشر في الـ TextField — بيتعرض
  /// أول 2000 حرف بس (ريدي-أونلي) والنص الكامل متخزن في inputText.
  final String? previewText;

  /// تقدّم الـ OCR على PDF ممسوح ضوئيًا (0..1) — null لما ميشتغلش.
  final double? ocrProgress;

  /// هل الملخص المعروض مترجّع من السجل (آخر ملخص على الهوم) و مش نتيجة
  /// تلخيص حديثة؟ — الـ UI بيتستخدمه عشان يغيّر عنوان القسم ويعرض زرار المسح.
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
      // مسح الملخص معناه إنه مش "آخر ملخص مترجّع" كمان — مسح واحد ينضف الاتنين.
      restoredFromHistory:
          clearSummary ? false : (restoredFromHistory ?? this.restoredFromHistory),
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
