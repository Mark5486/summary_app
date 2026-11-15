import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:camera/camera.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:besbasa/core/errors/failures.dart';
import 'package:besbasa/core/services/file_text_service.dart';
import 'package:besbasa/features/summarize/domain/entities/summary.dart';
import 'package:besbasa/features/summarize/domain/usecases/summarize_usecases.dart';
import 'package:besbasa/features/summarize/presentation/cubit/summarize_cubit.dart';
import 'package:besbasa/features/summarize/presentation/cubit/summarize_state.dart';
import 'package:besbasa/features/history/data/models/summary_model.dart';
import 'package:besbasa/features/history/domain/usecases/history_usecases.dart';
import 'package:mocktail/mocktail.dart';

class _MockSummarizeUseCase extends Mock implements SummarizeTextUseCase {}

class _MockExtractFile extends Mock implements ExtractTextFromFileUseCase {}

class _MockExtractImage extends Mock implements ExtractTextFromImageUseCase {}

class _MockOcrScannedPdf extends Mock
    implements ExtractOcrFromScannedPdfUseCase {}

class _MockSaveSummary extends Mock implements SaveSummaryUseCase {}

class _MockGetLatest extends Mock implements GetLatestSummaryUseCase {}

const _longArabicText = 'نهر النيل هو أطول نهر في العالم ويمر عبر عشر دولة '
    'قبل أن يصل إلى البحر المتوسط في الشمال. يعتمد مصر على مياه النيل في '
    'الزراعة والشرب بشكل شبه كامل عبر التاريخ الطويل. السد العالي في أسوان '
    'يحمي مصر من الفيضانات ويخزن المياه للزراعة الصيفية كل سنة. الدلتا شمال '
    'مصر هي أخصب أراضي الزراعة بسبب طمي النيل العريق عبر آلاف السنين.';

Summary _makeSummary() => Summary(
      id: 'sid-1',
      createdAt: DateTime(2026, 11, 1),
      originalText: _longArabicText,
      result: const SummaryResult(
        points: ['النيل أطول نهر', 'السد العالي يحمي مصر'],
        explanation: 'الفكرة: النيل ومصر',
        keywords: ['النيل'],
        originalWordCount: 50,
        summaryWordCount: 8,
      ),
    );

/// موديل بنفس بيانات الملخص — زي ما التخزين بيحفظه ويرجّعه.
SummaryModel _makeModel() {
  final s = _makeSummary();
  return SummaryModel.fromSummary(s.id, s.createdAt, s.originalText, s.result);
}

SummarizeCubit _buildCubit({
  required _MockSummarizeUseCase summarize,
  required _MockSaveSummary save,
  _MockGetLatest? getLatest,
  _MockExtractFile? extractFile,
  _MockExtractImage? extractImage,
  _MockOcrScannedPdf? ocrScannedPdf,
}) {
  // لو محدش مكيّف مكتبة السجل بنتصرف هادي: سجل فاضي = مفيش رجوع.
  final latest = getLatest ??
      (_MockGetLatest()
        ..stubEmptyHistory());
  return SummarizeCubit(
    summarizeUseCase: summarize,
    extractFromFileUseCase: extractFile ?? _MockExtractFile(),
    extractFromImageUseCase: extractImage ?? _MockExtractImage(),
    ocrScannedPdfUseCase: ocrScannedPdf ?? _MockOcrScannedPdf(),
    saveSummaryUseCase: save,
    getLatestSummaryUseCase: latest,
  );
}

extension _GetLatestStub on _MockGetLatest {
  void stubEmptyHistory() => when(() => call())
      .thenAnswer((_) async => const Right<Failure, SummaryModel?>(null));

  void stubLatest(SummaryModel model) =>
      when(() => call()).thenAnswer((_) async => Right<Failure, SummaryModel?>(model));
}

void main() {
  late _MockSummarizeUseCase summarizeUseCase;
  late _MockSaveSummary saveSummaryUseCase;

  setUpAll(() {
    registerFallbackValue(_FakeXFile());
    registerFallbackValue(_FakeSummaryModel());
    // fallback لتوقيع كولباك التقدّم في ocrScannedPdf
    registerFallbackValue<void Function(double)>((_) {});
    // fallback لبايتات الـ PDF اللي بتتدى لـ ocrScannedPdf —
    // من غيره any() على Uint8List بترمي MissingRegisterFallbackValueError.
    registerFallbackValue<Uint8List>(Uint8List(0));
  });

  setUp(() {
    summarizeUseCase = _MockSummarizeUseCase();
    saveSummaryUseCase = _MockSaveSummary();

    when(() => saveSummaryUseCase.call(any()))
        .thenAnswer((_) async => const Right(null));
  });

  group('SummarizeCubit', () {
    test('الحالة الأولية فاضية وساكتة', () {
      final cubit = _buildCubit(
        summarize: summarizeUseCase,
        save: saveSummaryUseCase,
      );
      expect(cubit.state.status, SummarizeStatus.idle);
      expect(cubit.state.inputText, '');
      expect(cubit.state.summary, isNull);
    });

    blocTest<SummarizeCubit, SummarizeState>(
      'setInput بيحدّث النص وبيمسح الفشل',
      build: () => _buildCubit(
        summarize: summarizeUseCase,
        save: saveSummaryUseCase,
      ),
      act: (cubit) => cubit.setInput('نص جديد'),
      expect: () => [
        predicate<SummarizeState>(
          (s) => s.inputText == 'نص جديد' && s.failure == null,
        ),
      ],
    );

    blocTest<SummarizeCubit, SummarizeState>(
      'summarize النص القصير بيفشل من غير ما ينادي اليوز كيس',
      setUp: () {
        when(() => summarizeUseCase.call(any()))
            .thenAnswer((_) async => const Left(InputTooShortFailure()));
      },
      build: () => _buildCubit(
        summarize: summarizeUseCase,
        save: saveSummaryUseCase,
      ),
      act: (cubit) async {
        cubit.setInput('نص قصير');
        await cubit.summarize();
      },
      expect: () => [
        const SummarizeState(inputText: 'نص قصير'),
        predicate<SummarizeState>(
          (s) => s.status == SummarizeStatus.loading && s.inputText == 'نص قصير',
        ),
        predicate<SummarizeState>((s) =>
            s.status == SummarizeStatus.failure &&
            s.failure is InputTooShortFailure),
      ],
    );

    blocTest<SummarizeCubit, SummarizeState>(
      'summarize النجاح بيحفظ في السجل تلقائيًا',
      setUp: () {
        when(() => summarizeUseCase.call(any()))
            .thenAnswer((_) async => Right(_makeSummary()));
      },
      build: () => _buildCubit(
        summarize: summarizeUseCase,
        save: saveSummaryUseCase,
      ),
      act: (cubit) => cubit.summarize(),
      seed: () => const SummarizeState(inputText: _longArabicText),
      expect: () => [
        predicate<SummarizeState>(
          (s) => s.status == SummarizeStatus.loading && s.inputText != '',
        ),
        predicate<SummarizeState>(
          (s) =>
              s.status == SummarizeStatus.success &&
              s.summary?.result.points.length == 2,
        ),
      ],
      verify: (_) {
        verify(() => saveSummaryUseCase.call(any())).called(1);
      },
    );

    blocTest<SummarizeCubit, SummarizeState>(
      'فشل التخزين مش بيوقف نجاح التلخيص',
      setUp: () {
        when(() => summarizeUseCase.call(any()))
            .thenAnswer((_) async => Right(_makeSummary()));
        when(() => saveSummaryUseCase.call(any()))
            .thenAnswer((_) async => const Left(StorageFailure('disk')));
      },
      build: () => _buildCubit(
        summarize: summarizeUseCase,
        save: saveSummaryUseCase,
      ),
      act: (cubit) => cubit.summarize(),
      seed: () => const SummarizeState(inputText: _longArabicText),
      expect: () => [
        predicate<SummarizeState>(
          (s) => s.status == SummarizeStatus.loading && s.inputText != '',
        ),
        predicate<SummarizeState>((s) => s.status == SummarizeStatus.success),
      ],
    );

    blocTest<SummarizeCubit, SummarizeState>(
      'clearInput بيرجّع الحالة الأولية',
      build: () => _buildCubit(
        summarize: summarizeUseCase,
        save: saveSummaryUseCase,
      ),
      act: (cubit) async {
        cubit.setInput('نص');
        cubit.clearInput();
      },
      expect: () => [
        predicate<SummarizeState>((s) => s.inputText == 'نص'),
        const SummarizeState(),
      ],
    );
  });

  group('آخر ملخص على الهوم (رجوع من السجل)', () {
    // بناء cubit — متغير لتتبّع آخر mock للسجل عشان الـ verifyNever.
    late _MockGetLatest capturedLatest;

    test('restoreLastSummary بيرجّع آخر ملخص من السجل', () async {
      final getLatest = _MockGetLatest()..stubLatest(_makeModel());
      final cubit = _buildCubit(
        summarize: summarizeUseCase,
        save: saveSummaryUseCase,
        getLatest: getLatest,
      );
      await cubit.restoreLastSummary();

      expect(cubit.state.summary, isNotNull);
      expect(cubit.state.summary!.result.points.length, 2);
      expect(cubit.state.summary!.result.explanation, 'الفكرة: النيل ومصر');
      expect(cubit.state.restoredFromHistory, isTrue);
      expect(cubit.state.status, SummarizeStatus.idle);
    });

    blocTest<SummarizeCubit, SummarizeState>(
      'restoreLastSummary مبيعملش حاجة لو فيه نتيجة معروضة',
      build: () {
        capturedLatest = _MockGetLatest()..stubLatest(_makeModel());
        return _buildCubit(
          summarize: summarizeUseCase,
          save: saveSummaryUseCase,
          getLatest: capturedLatest,
        );
      },
      seed: () => SummarizeState(summary: _makeSummary()),
      act: (cubit) => cubit.restoreLastSummary(),
      expect: () => [],
      verify: (_) => verifyNever(() => capturedLatest.call()),
    );

    test('restoreLastSummary مبيعملش حاجة لو فيه إدخال شغال', () async {
      final getLatest = _MockGetLatest()..stubLatest(_makeModel());
      final cubit = _buildCubit(
        summarize: summarizeUseCase,
        save: saveSummaryUseCase,
        getLatest: getLatest,
      );
      cubit.setInput('المستخدم بيكتب دلوقتي');

      await cubit.restoreLastSummary();

      verifyNever(() => getLatest.call());
      expect(cubit.state.summary, isNull);
    });

    test('restoreLastSummary بيسكت مع سجل فاضي', () async {
      final getLatest = _MockGetLatest()..stubEmptyHistory();
      final cubit = _buildCubit(
        summarize: summarizeUseCase,
        save: saveSummaryUseCase,
        getLatest: getLatest,
      );
      await cubit.restoreLastSummary();

      expect(cubit.state.summary, isNull);
      expect(cubit.state.restoredFromHistory, isFalse);
    });

    test('dismissRestoredSummary بيمسح آخر ملخص من الهوم بس', () async {
      final getLatest = _MockGetLatest()..stubLatest(_makeModel());
      final cubit = _buildCubit(
        summarize: summarizeUseCase,
        save: saveSummaryUseCase,
        getLatest: getLatest,
      );
      await cubit.restoreLastSummary();
      expect(cubit.state.restoredFromHistory, isTrue);

      cubit.dismissRestoredSummary();

      expect(cubit.state.summary, isNull);
      expect(cubit.state.restoredFromHistory, isFalse);
    });

    blocTest<SummarizeCubit, SummarizeState>(
      'dismissRestoredSummary مبيعملش حاجة لنتيجة حديثة',
      build: () => _buildCubit(
        summarize: summarizeUseCase,
        save: saveSummaryUseCase,
      ),
      seed: () => SummarizeState(summary: _makeSummary()),
      act: (cubit) => cubit.dismissRestoredSummary(),
      // الحرس منع الإصدار خلاص — النتيجة الحديثة فاضية على مكانها.
      expect: () => [],
    );

    blocTest<SummarizeCubit, SummarizeState>(
      'تلخيص جديد بعد رجوع آخر ملخص بينضف وسم "آخر ملخص"',
      setUp: () {
        when(() => summarizeUseCase.call(any()))
            .thenAnswer((_) async => Right(_makeSummary()));
      },
      build: () => _buildCubit(
        summarize: summarizeUseCase,
        save: saveSummaryUseCase,
      ),
      seed: () => SummarizeState(
        inputText: _longArabicText,
        summary: _makeSummary(),
        restoredFromHistory: true,
      ),
      act: (cubit) => cubit.summarize(),
      expect: () => [
        predicate<SummarizeState>(
          (s) => s.status == SummarizeStatus.loading,
        ),
        predicate<SummarizeState>(
          (s) =>
              s.status == SummarizeStatus.success &&
              s.restoredFromHistory == false,
        ),
      ],
    );
  });

  group('استقبال نص الـ OCR (ريفيو: isPdf ≠ fromOcr + إشعار القص)', () {
    test('صورة الكاميرا: fromOcr = true و isPdf = false — الصورة مش PDF',
        () async {
      final extractImage = _MockExtractImage();
      when(() => extractImage.call(any()))
          .thenAnswer((_) async => const Right('نص مقروء من صورة بالكاميرا'));

      final cubit = _buildCubit(
        summarize: summarizeUseCase,
        save: saveSummaryUseCase,
        extractImage: extractImage,
      );
      await cubit.recognizeImage(_FakeXFile());

      final info = cubit.state.fileInfo!;
      expect(info.fromOcr, isTrue);
      // الإصلاح: كان isPdf بياخد true بالغلط من fromOcr.
      expect(info.isPdf, isFalse);
      expect(cubit.state.inputText, 'نص مقروء من صورة بالكاميرا');
      expect(cubit.state.notice, isNull);
    });

    test('OCR على PDF ممسوح: المصدر PDF فعلًا — isPdf = true', () async {
      final extractFile = _MockExtractFile();
      when(() => extractFile.call()).thenAnswer((_) async => Right(FileLoadResult(
            text: '',
            isPdf: true,
            wordCount: 0,
            pdfBytes: Uint8List(4),
            pageCount: 3,
            scanned: true,
          )));

      final ocr = _MockOcrScannedPdf();
      when(() => ocr.call(any(), onProgress: any(named: 'onProgress')))
          .thenAnswer((_) async => const Right('نص الـ OCR من الـ PDF'));

      final cubit = _buildCubit(
        summarize: summarizeUseCase,
        save: saveSummaryUseCase,
        extractFile: extractFile,
        ocrScannedPdf: ocr,
      );
      await cubit.loadFromFile(); // بيسجّل بايتات الـ PDF الممسوح
      await cubit.ocrScannedPdf();

      final info = cubit.state.fileInfo!;
      expect(info.fromOcr, isTrue);
      expect(info.isPdf, isTrue); // هنا فعلاً PDF — الاتنين متفرقين صح
      expect(cubit.state.inputText, 'نص الـ OCR من الـ PDF');
    });

    test('نص OCR أطول من الحد: إشعار truncated بيظهر والنص متقص', () async {
      // كان بيتقص الأول وبعدين بيتسأل "هل المقصوص أطول من الحد؟"
      // فالإجابة كانت دايمًا لأ — الرسالة عمرها ما كانت بتظهر (ريفيو).
      final longText = 'كلمة ' * 45000; // 225 ألف حرف > 200 ألف
      final extractImage = _MockExtractImage();
      when(() => extractImage.call(any())).thenAnswer((_) async => Right(longText));

      final cubit = _buildCubit(
        summarize: summarizeUseCase,
        save: saveSummaryUseCase,
        extractImage: extractImage,
      );
      await cubit.recognizeImage(_FakeXFile());

      expect(cubit.state.notice, 'truncated');
      expect(cubit.state.inputText.length, SummarizeCubit.maxInputChars);
    });
  });
}

class _FakeXFile extends Fake implements XFile {}

class _FakeSummaryModel extends Fake implements SummaryModel {}
