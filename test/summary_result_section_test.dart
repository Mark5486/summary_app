import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:besbasa/features/summarize/domain/entities/summary.dart';
import 'package:besbasa/features/summarize/presentation/cubit/summarize_cubit.dart';
import 'package:besbasa/features/summarize/presentation/cubit/summarize_state.dart';
import 'package:besbasa/features/summarize/presentation/widgets/summary_result_section.dart';
import 'package:mocktail/mocktail.dart';

class _MockSummarizeCubit extends MockCubit<SummarizeState>
    implements SummarizeCubit {}

Summary _makeSummary() => Summary(
  id: 'sid-1',
  createdAt: DateTime(2026, 11, 1),
  originalText: 'نص أصلي طويل للتلخيص التجريبي.',
  result: const SummaryResult(
    points: ['النيل أطول نهر', 'السد العالي يحمي مصر'],
    explanation: 'الفكرة: النيل ومصر',
    keywords: ['النيل'],
    originalWordCount: 50,
    summaryWordCount: 8,
  ),
);

Future<_MockSummarizeCubit> _pumpSection(
  WidgetTester tester, {
  required bool restoredFromHistory,
}) async {
  final cubit = _MockSummarizeCubit();
  whenListen(
    cubit,
    Stream.value(
      SummarizeState(
        summary: _makeSummary(),
        restoredFromHistory: restoredFromHistory,
      ),
    ),
    initialState: const SummarizeState(),
  );

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: BlocProvider<SummarizeCubit>.value(
        value: cubit,
        child: Scaffold(
          body: SingleChildScrollView(
            child: SummaryResultSection(
              summary: _makeSummary(),
              restoredFromHistory: restoredFromHistory,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return cubit;
}

void main() {
  group('SummaryResultSection', () {
    testWidgets('النتيجة الجديدة: عنوان القسم + شارة الحفظ + من غير زرار مسح', (
      tester,
    ) async {
      await _pumpSection(tester, restoredFromHistory: false);

      expect(find.text('النتيجة'), findsOneWidget);

      expect(find.text('محفوظ في السجل ✓'), findsOneWidget);

      expect(find.text('النيل أطول نهر'), findsOneWidget);
      expect(find.text('الفكرة: النيل ومصر'), findsOneWidget);

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('آخر ملخص المترجّع: عنوان مختلف + زرار مسح من الهوم', (
      tester,
    ) async {
      final cubit = await _pumpSection(tester, restoredFromHistory: true);

      expect(find.text('آخر ملخص من السجل'), findsOneWidget);

      expect(find.text('محفوظ في السجل ✓'), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      verify(() => cubit.dismissRestoredSummary()).called(1);
    });
  });
}
