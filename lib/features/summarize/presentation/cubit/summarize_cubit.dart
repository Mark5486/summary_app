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

/// عقل شاشة التلخيص: إدخال ← (ملف/كاميرا) ← تلخيص ← حفظ تلقائي في السجل.
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

  /// ⚡ أقصى طول للنص في خانة الإدخال — حماية من تجميد الواجهة مع
  /// النصوص الضخمة (كل ميعاد الـ TextField بيتحمل التقسيم ده بأمان).
  static const int maxInputChars = 200000;

  /// فوق الحد ده النص مبيتحشرش في الـ TextField — وضع معاينة.
  static const int previewThresholdChars = 8000;

  /// طول معاينة النص الكبير.
  static const int previewChars = 2000;

  /// بايتات آخر PDF اتحمّل — بره الحالة (bytes متتقسمش في props)
  /// وبتتفضل موجودة لو الملف طلع ممسوح ضوئيًا والمستخدم شغّل OCR.
  Uint8List? _pendingPdfBytes;

  /// قص النص فوق الحد — بيرجّع النص المقصوص بس.
  static String _capInput(String text) =>
      text.length <= maxInputChars ? text : text.substring(0, maxInputChars);

  void setInput(String text) {
    if (text.length <= maxInputChars) {
      emit(state.copyWith(
        inputText: text,
        clearFailure: true,
        clearNotice: true,
      ));
      return;
    }

    // فوق الحد: نقص مرة واحدة بس ومن غير سبام إشعارات مع كل ضغطة.
    if (state.inputText.length == maxInputChars) return;
    emit(state.copyWith(
      inputText: _capInput(text),
      clearFailure: true,
      notice: 'truncated',
    ));
  }

  /// الـ UI بينادي عليها بعد ما يعرض الإشعار.
  void consumeNotice() => emit(state.copyWith(clearNotice: true));

  void clearInput() {
    _pendingPdfBytes = null;
    emit(const SummarizeState());
  }

  /// قراءة نص من ملف محلي (txt أو PDF) ووضعه في الإدخال.
  ///
  /// الريفيو: النص الكبير مش بيتحشر في الـ TextField — بيتعرض أول
  /// 2000 حرف كمعاينة (ريدي-أونلي) والنص الكامل بيفضل هنا في الـ cubit.
  Future<void> loadFromFile() async {
    emit(state.copyWith(
      extracting: true,
      clearFailure: true,
      clearNotice: true,
    ));
    final result = await extractFromFileUseCase();
    result.fold(
      (failure) => emit(state.copyWith(
        extracting: false,
        status: SummarizeStatus.failure,
        failure: failure,
      )),
      (load) {
        _pendingPdfBytes = load.scanned ? load.pdfBytes : null;

        // PDF ممسوح ضوئيًا — بطاقة خاصة فيها زرار OCR، من غير نص.
        if (load.scanned) {
          emit(state.copyWith(
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
          ));
          return;
        }

        final usePreview = load.text.length > previewThresholdChars;
        emit(state.copyWith(
          extracting: false,
          status: SummarizeStatus.idle,
          inputText: _capInput(load.text),
          previewText: usePreview ? load.text.substring(0, previewChars) : null,
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
        ));
      },
    );
  }

  /// قراءة نص من صورة متصوّرة (OCR) ووضعه في خانة الإدخال.
  Future<void> recognizeImage(XFile image) async {
    emit(state.copyWith(extracting: true, clearFailure: true));
    final result = await extractFromImageUseCase(image);
    result.fold(
      (failure) => emit(state.copyWith(
        extracting: false,
        status: SummarizeStatus.failure,
        failure: failure,
      )),
      (text) => _adoptExtractedText(text, fromOcr: true, isPdf: false),
    );
  }

  /// OCR على صفحات PDF ممسوح ضوئيًا — بزرار في بطاقة الملف + شريط تقدّم.
  Future<void> ocrScannedPdf() async {
    final bytes = _pendingPdfBytes;
    if (bytes == null) return;

    emit(state.copyWith(
      extracting: true,
      clearFailure: true,
      ocrProgress: 0,
    ));
    final result = await ocrScannedPdfUseCase(
      bytes,
      onProgress: (p) => emit(state.copyWith(ocrProgress: p)),
    );
    result.fold(
      (failure) => emit(state.copyWith(
        extracting: false,
        status: SummarizeStatus.failure,
        failure: failure,
        clearOcrProgress: true,
      )),
      (text) {
        emit(state.copyWith(clearOcrProgress: true));
        _adoptExtractedText(text, fromOcr: true, isPdf: true);
      },
    );
  }

  /// توحيد استقبال النص المستخرج في الإدخال.
  ///
  /// [fromOcr] = النص اتقرأ بالـ OCR (كاميرا أو PDF ممسوح) —
  /// [isPdf] = هل المصدر نفسه PDF؟ — الاتنين حاجات مختلفة
  /// (ريفيو: كانت isPdf بتاخد قيمة fromOcr فصورة الكاميرا
  /// بتتسجل على إنها PDF بالغلط).
  void _adoptExtractedText(
    String text, {
    required bool fromOcr,
    required bool isPdf,
  }) {
    // علم القص بيتحسب قبل القص — بعد القص طول النص أقصى من الحد
    // بالتعريف فالشرط هيبقى ميت (ريفيو: الرسالة عمرها ما كانت بتظهر).
    final wasTruncated = text.length > maxInputChars;
    final capped = _capInput(text);
    final usePreview = capped.length > previewThresholdChars;
    emit(state.copyWith(
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
    ));
  }

  /// التلخيص نفسه + حفظ تلقائي في السجل عند النجاح.
  Future<void> summarize() async {
    final text = state.inputText.trim();
    if (text.isEmpty) {
      // الـ UI بيعرض emptyInput على الحالة دي من غير ما ينادي أصلاً —
      // الحماية هنا احتياطية.
      emit(state.copyWith(
        status: SummarizeStatus.failure,
        failure: const InputTooShortFailure(),
      ));
      return;
    }

    emit(state.copyWith(status: SummarizeStatus.loading, clearFailure: true));
    final result = await summarizeUseCase(text);

    await result.fold(
      (failure) async {
        emit(state.copyWith(status: SummarizeStatus.failure, failure: failure));
      },
      (summary) async {
        // ⚡ عرض النتيجة فورًا — الحفظ بيشتغل في الخلفية من غير انتظار
        // (الريفيو: ماتعملش await للحفظ قبل ما تعرض).
        // ملخص جديد معناه إن ده مش "آخر ملخص مترجّع" — العلم بتنضف.
        emit(state.copyWith(
          status: SummarizeStatus.success,
          summary: summary,
          restoredFromHistory: false,
        ));
        unawaited(_saveQuietly(summary));
      },
    );
  }

  /// ترجيع آخر ملخص من السجل للهوم — بيشتغل مرة عند فتح التطبيق.
  ///
  /// هادئة بالكامل: سجل فاضي أو فشل تخزين = مفيش حاجة تترجع ومن غير
  /// إشعارات. ومبيعملش حاجة لو فيه نتيجة شغالة أو إدخال حالي —
  /// مش هنبوظ على اللي المستخدم عامله.
  Future<void> restoreLastSummary() async {
    if (_hasActiveContent) return;

    final result = await getLatestSummaryUseCase();
    result.fold(
      // فشل التخزين هنا مش مهم — رجوع آخر ملخص مكمال مش أساسي.
      (failure) {},
      (model) {
        // المستخدم بدأ يكتب في اللحظة اللي بنرجّع فيها؟ مفيش رجوع.
        if (_hasActiveContent || model == null) return;
        emit(state.copyWith(
          status: SummarizeStatus.idle,
          summary: _modelToSummary(model),
          restoredFromHistory: true,
        ));
      },
    );
  }

  /// مسح "آخر ملخص" من الهوم بس — السجل نفسه مبيتلمس.
  void dismissRestoredSummary() {
    if (!state.restoredFromHistory) return;
    emit(state.copyWith(clearSummary: true));
  }

  /// فيه شغل المستخدم الحالي (نتيجة أو إدخال)؟ — بوابة الرجوع من السجل.
  bool get _hasActiveContent =>
      state.summary != null || state.inputText.trim().isNotEmpty;

  /// تحويل موديل التخزين لكيان الملخص — نفس الحقول بالظبط.
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

  /// حفظ هادئ — التخزين ما بيرميش، وملوش علاقة بعرض النتيجة.
  Future<void> _saveQuietly(Summary summary) async {
    try {
      await saveSummaryUseCase(SummaryModel.fromSummary(
        summary.id,
        summary.createdAt,
        summary.originalText,
        summary.result,
      ));
    } catch (_) {
      // تجاهل هادئ — التلخيص أهم من السجل.
    }
  }
}
