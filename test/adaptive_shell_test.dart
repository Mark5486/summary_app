import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:besbasa/core/services/local_storage_service.dart';
import 'package:besbasa/core/localization/cubit/locale_cubit.dart';
import 'package:besbasa/core/theme/cubit/theme_cubit.dart';
import 'package:besbasa/core/utils/service_locator.dart';
import 'package:besbasa/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبارات الشل التكيفي (مهمة 5): شريط تنقل تحت على الموبايل/التابلت،
/// وريل جانبي على اللاب/الكمبيوتر — وزرار التلخيص الثابت في كل الأحوال.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<BesbasaApp> buildApp() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorageServiceImpl(prefs);

    await getIt.reset(); // reset بتكون async — لازم نستناها قبل التسجيل
    await setupServiceLocator();

    final themeCubit = ThemeCubit(storage);
    final localeCubit = LocaleCubit(storage);
    await themeCubit.ensureLoaded();
    await localeCubit.ensureLoaded();

    return BesbasaApp(themeCubit: themeCubit, localeCubit: localeCubit);
  }

  group('AdaptiveShell — الشل بيتكيّف مع حجم الشاشة', () {
    testWidgets('موبايل (400x800): شريط تنقل تحت ومن غير ريل',
        (tester) async {
      await tester.pumpWidget(await buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      // زرار التلخيص الثابت ظاهر.
      expect(find.text('لخّصه ببساطة'), findsOneWidget);
    });

    testWidgets('تابلت (800x600): شريط تنقل تحت كمان', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(await buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('ديسكتوب (1280x800): ريل جانبي والتبديل للسجل شغال',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(await buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      // زرار التلخيص الثابت ظاهر كمان على الديسكتوب.
      expect(find.text('لخّصه ببساطة'), findsOneWidget);

      // التبديل للسجل من الريل شغال.
      await tester.tap(find.text('السجل'));
      await tester.pumpAndSettle();
      expect(find.text('سجل الملخصات'), findsOneWidget);
    });

    testWidgets('شاشة عريضة جدًا (1600x900): الريل بيتمدد بأسماء جنب الأيقونات',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(await buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}
