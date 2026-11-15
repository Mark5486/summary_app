import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:besbasa/core/errors/failures.dart';
import 'package:besbasa/features/history/data/models/summary_model.dart';
import 'package:besbasa/features/history/domain/repositories/history_repository.dart';
import 'package:besbasa/features/history/domain/usecases/history_usecases.dart';
import 'package:besbasa/features/summarize/domain/entities/summary.dart';
import 'package:mocktail/mocktail.dart';

class _MockHistoryRepository extends Mock implements HistoryRepository {}

SummaryModel _makeModel() => SummaryModel.fromSummary(
      'sid-9',
      DateTime(2026, 11, 2),
      'نص أصلي طويل نسبيًا للتلخيص التجريبي هنا.',
      const SummaryResult(
        points: ['نقطة أولى', 'نقطة تانية'],
        explanation: 'شرح مبسط',
        keywords: ['كلمة'],
        originalWordCount: 40,
        summaryWordCount: 7,
      ),
    );

void main() {
  late _MockHistoryRepository repository;
  late GetLatestSummaryUseCase useCase;

  setUp(() {
    repository = _MockHistoryRepository();
    useCase = GetLatestSummaryUseCase(repository);
  });

  test('بيرجّع آخر ملخص من المستودع', () async {
    final model = _makeModel();
    when(() => repository.latest()).thenAnswer((_) async => model);

    final result = await useCase();

    expect(result.isRight(), isTrue);
    result.fold(
      (_) => fail('المفروض نجاح'),
      (m) => expect(m, same(model)),
    );
    verify(() => repository.latest()).called(1);
  });

  test('بيرجّع Right(null) لو السجل فاضي — مش غلطة', () async {
    when(() => repository.latest()).thenAnswer((_) async => null);

    final result = await useCase();

    expect(result.isRight(), isTrue);
    result.fold(
      (_) => fail('المفروض نجاح حتى مع سجل فاضي'),
      (m) => expect(m, isNull),
    );
  });

  test('بيحوّل استثناء التخزين لـ StorageFailure', () async {
    when(() => repository.latest()).thenThrow(Exception('disk full'));

    final result = await useCase();

    expect(result.isLeft(), isTrue);
    result.fold(
      (f) => expect(f, isA<StorageFailure>()),
      (_) => fail('المفروض فشل'),
    );
  });
}
