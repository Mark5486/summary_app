import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:besbasa/core/localization/cubit/locale_cubit.dart';
import 'package:besbasa/core/routes/app_router.dart';
import 'package:besbasa/core/services/local_storage_service.dart';
import 'package:besbasa/core/theme/app_theme.dart';
import 'package:besbasa/core/theme/cubit/theme_cubit.dart';
import 'package:besbasa/core/utils/service_locator.dart';
import 'package:besbasa/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _initDi() async {
  await getIt.reset();
  await setupServiceLocator();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BesbasaApp (widget smoke)', () {
    testWidgets('التطبيق بيفتح على شاشة التلخيص بالاسم والعنوان العربي', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageServiceImpl(prefs);

      await _initDi();

      final themeCubit = ThemeCubit(storage);
      final localeCubit = LocaleCubit(storage);
      await themeCubit.ensureLoaded();
      await localeCubit.ensureLoaded();

      await tester.pumpWidget(
        BesbasaApp(themeCubit: themeCubit, localeCubit: localeCubit),
      );
      await tester.pumpAndSettle();

      expect(find.text('ببساطة'), findsOneWidget);
      expect(find.text('أي منهج… ببساطة شديدة'), findsOneWidget);

      expect(find.text('لخّصه ببساطة'), findsOneWidget);

      expect(find.text('تلخيص'), findsOneWidget);
      expect(find.text('السجل'), findsOneWidget);
      expect(find.text('الإعدادات'), findsOneWidget);
    });

    testWidgets('عربي افتراضي RTL وبعدين الإنجليزي بيقلب الاتجاه', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageServiceImpl(prefs);

      await _initDi();

      final themeCubit = ThemeCubit(storage);
      final localeCubit = LocaleCubit(storage);
      await themeCubit.ensureLoaded();
      await localeCubit.ensureLoaded();

      await tester.pumpWidget(
        BesbasaApp(themeCubit: themeCubit, localeCubit: localeCubit),
      );
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.locale, const Locale('ar'));
      expect(
        materialApp.localizationsDelegates,
        contains(GlobalMaterialLocalizations.delegate),
      );
      expect(materialApp.supportedLocales, contains(const Locale('en')));

      await localeCubit.setLanguage('en');
      await tester.pumpAndSettle();

      final updated = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(updated.locale, const Locale('en'));
      expect(find.text('Summarize simply'), findsOneWidget);
    });

    testWidgets('الثيم الغامق بيتطبق على MaterialApp', (tester) async {
      SharedPreferences.setMockInitialValues({
        'besbasa_theme_mode': 'dark',
        'besbasa_locale': 'ar',
      });

      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageServiceImpl(prefs);

      await _initDi();

      final themeCubit = ThemeCubit(storage);
      final localeCubit = LocaleCubit(storage);
      await themeCubit.ensureLoaded();
      await localeCubit.ensureLoaded();

      await tester.pumpWidget(
        BesbasaApp(themeCubit: themeCubit, localeCubit: localeCubit),
      );
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.dark);
      expect(materialApp.darkTheme, same(DarkTheme.theme));
      expect(materialApp.theme, same(LightTheme.theme));
      expect(materialApp.onGenerateRoute, same(AppRouter.onGenerateRoute));
    });
  });
}
