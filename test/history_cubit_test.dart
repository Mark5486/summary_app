import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:besbasa/core/errors/failures.dart';
import 'package:besbasa/features/history/data/models/summary_model.dart';
import 'package:besbasa/features/history/domain/usecases/history_usecases.dart';
import 'package:besbasa/features/history/presentation/cubit/history_cubit.dart';
import 'package:besbasa/features/history/presentation/cubit/history_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetHistory extends Mock implements GetHistoryUseCase {}

class _MockDeleteSummary extends Mock implements DeleteSummaryUseCase {}

class _MockClearHistory extends Mock implements ClearHistoryUseCase {}

SummaryModel _entry(String id, String text, {int ms = 1730000000000}) =>
    SummaryModel(
      id: id,
      createdAtMs: ms,
      originalText: text,
      points: ['نقطة واحدة عن النص'],
      explanation: 'شرح مبسط',
      keywords: const ['كلمة'],
      originalWordCount: 40,
      summaryWordCount: 6,
    );

void main() {
  late _MockGetHistory getHistory;
  late _MockDeleteSummary deleteSummary;
  late _MockClearHistory clearHistory;

  setUp(() {
    getHistory = _MockGetHistory();
    deleteSummary = _MockDeleteSummary();
    clearHistory = _MockClearHistory();

    when(
      () => deleteSummary.call(any()),
    ).thenAnswer((_) async => const Right<Failure, void>(null));
    when(
      () => clearHistory.call(),
    ).thenAnswer((_) async => const Right<Failure, void>(null));
  });

  HistoryCubit buildCubit() => HistoryCubit(
    getHistoryUseCase: getHistory,
    deleteSummaryUseCase: deleteSummary,
    clearHistoryUseCase: clearHistory,
  );

  group('HistoryCubit', () {
    test('الحالة الأولية فاضية', () {
      final cubit = buildCubit();
      expect(cubit.state.entries, isEmpty);
      expect(cubit.state.query, '');
      expect(cubit.state.filtered, isEmpty);
    });

    blocTest<HistoryCubit, HistoryState>(
      'load بيحمّل المدخلات مرتّبة الأحدث الأول',
      setUp: () {
        when(() => getHistory.call()).thenAnswer(
          (_) async => Right([
            _entry('new', 'ملخص جديد', ms: 1730000001000),
            _entry('old', 'ملخص قديم', ms: 1730000000000),
          ]),
        );
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        predicate<HistoryState>(
          (s) => s.entries.length == 2 && s.entries.first.id == 'new',
        ),
      ],
    );

    blocTest<HistoryCubit, HistoryState>(
      'search بيفلتر المدخلات بالكلمة',
      setUp: () {
        when(() => getHistory.call()).thenAnswer(
          (_) async => Right([
            _entry('a', 'نص عن النيل والزراعة'),
            _entry('b', 'نص عن الفضاء والكواكب'),
          ]),
        );
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        cubit.search('النيل');
      },
      expect: () => [
        predicate<HistoryState>((s) => s.entries.length == 2),
        predicate<HistoryState>(
          (s) => s.filtered.length == 1 && s.filtered.first.id == 'a',
        ),
      ],
    );

    blocTest<HistoryCubit, HistoryState>(
      'delete بيشيل من القايمة ويطلع توست',
      setUp: () {
        when(
          () => getHistory.call(),
        ).thenAnswer((_) async => Right([_entry('a', 'نص عن النيل')]));
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.delete('a');
      },
      expect: () => [
        predicate<HistoryState>((s) => s.entries.length == 1),
        predicate<HistoryState>(
          (s) => s.entries.isEmpty && s.toast == 'deleted',
        ),
      ],
      verify: (_) {
        verify(() => deleteSummary.call('a')).called(1);
      },
    );

    blocTest<HistoryCubit, HistoryState>(
      'clearAll بيفضّي السجل والبحث',
      setUp: () {
        when(
          () => getHistory.call(),
        ).thenAnswer((_) async => Right([_entry('a', 'نص')]));
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        cubit.search('نص');
        await cubit.clearAll();
      },
      expect: () => [
        predicate<HistoryState>((s) => s.entries.length == 1),
        predicate<HistoryState>((s) => s.query == 'نص'),
        predicate<HistoryState>(
          (s) => s.entries.isEmpty && s.query.isEmpty && s.toast == 'deleted',
        ),
      ],
    );

    blocTest<HistoryCubit, HistoryState>(
      'consumeToast بيمسح التوست',
      build: buildCubit,
      act: (cubit) async {
        cubit.emit(const HistoryState(toast: 'deleted'));
        cubit.consumeToast();
      },
      expect: () => [
        const HistoryState(toast: 'deleted'),
        const HistoryState(),
      ],
    );
  });
}
