import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:besbasa/features/summarize/presentation/cubit/summarize_cubit.dart';
import 'package:besbasa/features/summarize/presentation/cubit/summarize_state.dart';
import 'package:besbasa/features/summarize/presentation/view/summarize_view.dart';
import 'package:mocktail/mocktail.dart';

class _MockSummarizeCubit extends MockCubit<SummarizeState>
    implements SummarizeCubit {}

Widget _wrap(SummarizeCubit cubit) => MaterialApp(
  locale: const Locale('ar'),
  supportedLocales: const [Locale('ar'), Locale('en')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: BlocProvider<SummarizeCubit>.value(
    value: cubit,
    child: const SummarizeView(),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SummarizeView — وضع المعاينة (مهمة 2) والزرار الثابت (مهمة 1)', () {
    testWidgets(
      'ملف كبير: معاينة قابلة للتحديد بدل خانة الإدخال + زرار مسح + زرار تلخيص ثابت',
      (tester) async {
        final cubit = _MockSummarizeCubit();

        whenListen(
          cubit,
          Stream.value(
            SummarizeState(
              inputText: 'نص كامل طويل جدًا ' * 500,
              previewText: 'أول جزء من النص للمعاينة',
              fileInfo: const FileLoadInfo(
                isPdf: true,
                wordCount: 5000,
                pageCount: 12,
              ),
            ),
          ),
          initialState: const SummarizeState(),
        );

        await tester.pumpWidget(_wrap(cubit));
        await tester.pump();

        expect(find.byType(SelectableText), findsOneWidget);
        expect(find.text('أول جزء من النص للمعاينة'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);

        expect(find.text('مسح'), findsOneWidget);
        expect(find.byIcon(Icons.clear_all), findsOneWidget);

        expect(find.text('5000 كلمة'), findsOneWidget);

        expect(find.text('لخّصه ببساطة'), findsOneWidget);
      },
    );

    testWidgets('الوضع العادي: خانة إدخال عادية ومن غير زرار مسح', (
      tester,
    ) async {
      final cubit = _MockSummarizeCubit();
      whenListen(
        cubit,
        Stream.value(const SummarizeState()),
        initialState: const SummarizeState(),
      );

      await tester.pumpWidget(_wrap(cubit));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(SelectableText), findsNothing);

      expect(find.text('مسح'), findsNothing);

      expect(find.text('لخّصه ببساطة'), findsOneWidget);
    });
  });
}
