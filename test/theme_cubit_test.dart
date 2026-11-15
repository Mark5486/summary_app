import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:besbasa/core/services/local_storage_service.dart';
import 'package:besbasa/core/theme/cubit/theme_cubit.dart';
import 'package:besbasa/core/theme/cubit/theme_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements LocalStorageService {}

void main() {
  late _MockStorage storage;

  setUp(() {
    storage = _MockStorage();
    when(() => storage.setString(any(), any())).thenAnswer((_) async {});
    when(() => storage.getString(any())).thenReturn(null);
    when(() => storage.remove(any())).thenAnswer((_) async {});
  });

  group('ThemeCubit', () {
    test('الحالة الافتراضية تتبع النظام', () {
      final cubit = ThemeCubit(storage);
      expect(cubit.state.mode, ThemeMode.system);
    });

    blocTest<ThemeCubit, ThemeState>(
      'toggle بيبدّل للغامق ويحفظ',
      build: () => ThemeCubit(storage),
      act: (cubit) => cubit.toggle(),
      expect: () => [
        const ThemeState(mode: ThemeMode.dark),
      ],
      verify: (_) {
        verify(() => storage.setString('besbasa_theme_mode', 'dark'))
            .called(1);
      },
    );

    blocTest<ThemeCubit, ThemeState>(
      'toggle مرتين يرجّع للفاتح',
      build: () => ThemeCubit(storage),
      act: (cubit) async {
        await cubit.toggle();
        await cubit.toggle();
      },
      expect: () => [
        const ThemeState(mode: ThemeMode.dark),
        const ThemeState(mode: ThemeMode.light),
      ],
    );

    test('ensureLoaded بيقرأ الثيم الغامق المحفوظ', () async {
      when(() => storage.getString('besbasa_theme_mode')).thenReturn('dark');
      final cubit = ThemeCubit(storage);
      await cubit.ensureLoaded();
      expect(cubit.state.mode, ThemeMode.dark);
    });

    test('ensureLoaded بيقرأ الثيم الفاتح المحفوظ', () async {
      when(() => storage.getString('besbasa_theme_mode')).thenReturn('light');
      final cubit = ThemeCubit(storage);
      await cubit.ensureLoaded();
      expect(cubit.state.mode, ThemeMode.light);
    });

    test('قيمة محفوظة غريبة = يتبع النظام', () async {
      when(() => storage.getString('besbasa_theme_mode')).thenReturn('sepia');
      final cubit = ThemeCubit(storage);
      await cubit.ensureLoaded();
      expect(cubit.state.mode, ThemeMode.system);
    });
  });
}
