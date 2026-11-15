import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:besbasa/core/localization/cubit/locale_cubit.dart';
import 'package:besbasa/core/localization/cubit/locale_state.dart';
import 'package:besbasa/core/services/local_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements LocalStorageService {}

void main() {
  late _MockStorage storage;

  setUp(() {
    storage = _MockStorage();
    when(() => storage.setString(any(), any()))
        .thenAnswer((_) async {});
    when(() => storage.getString(any())).thenReturn(null);
    when(() => storage.remove(any())).thenAnswer((_) async {});
  });

  group('LocaleCubit', () {
    test('الحالة الافتراضية عربي', () {
      final cubit = LocaleCubit(storage);
      expect(cubit.state.languageCode, 'ar');
      expect(cubit.state.isArabic, isTrue);
    });

    blocTest<LocaleCubit, LocaleState>(
      'setLanguage بيبدّل للإنجليزي ويحفظ',
      build: () => LocaleCubit(storage),
      act: (cubit) => cubit.setLanguage('en'),
      expect: () => [
        const LocaleState(languageCode: 'en'),
      ],
      verify: (_) {
        verify(() => storage.setString('besbasa_locale', 'en')).called(1);
      },
    );

    blocTest<LocaleCubit, LocaleState>(
      'toggle بيرجّع للعربي',
      build: () {
        final cubit = LocaleCubit(storage);
        cubit.emit(const LocaleState(languageCode: 'en'));
        return cubit;
      },
      act: (cubit) => cubit.toggle(),
      expect: () => [const LocaleState(languageCode: 'ar')],
    );

    test('كود لغة غريب بيتتجاهل', () async {
      final cubit = LocaleCubit(storage);
      await cubit.setLanguage('fr');
      expect(cubit.state.languageCode, 'ar');
      verifyNever(() => storage.setString(any(), any()));
    });

    test('ensureLoaded بيقرأ اللغة المحفوظة', () async {
      when(() => storage.getString('besbasa_locale')).thenReturn('en');
      final cubit = LocaleCubit(storage);
      await cubit.ensureLoaded();
      expect(cubit.state.languageCode, 'en');
    });
  });
}
