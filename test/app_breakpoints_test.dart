import 'package:flutter_test/flutter_test.dart';

import 'package:besbasa/core/constants/app_breakpoints.dart';

void main() {
  group('AppBreakpoints.sizeFromWidth — تحجيم النافذة', () {
    test('الموبايل الضيق → compact', () {
      expect(AppBreakpoints.sizeFromWidth(0), WindowSize.compact);
      // موبايل عادي (iPhone SE / أندرويد صغير).
      expect(AppBreakpoints.sizeFromWidth(360), WindowSize.compact);
      // موبايل كبير — لسه تحت حد التابلت.
      expect(AppBreakpoints.sizeFromWidth(599), WindowSize.compact);
    });

    test('التابلت / اللاب الضيق → medium', () {
      // حد التابلت بالظبط.
      expect(AppBreakpoints.sizeFromWidth(600), WindowSize.medium);
      // تابلت أفقي.
      expect(AppBreakpoints.sizeFromWidth(768), WindowSize.medium);
      // آخر بكسل قبل الديسكتوب.
      expect(AppBreakpoints.sizeFromWidth(1023), WindowSize.medium);
    });

    test('اللاب / الكمبيوتر → expanded', () {
      // حد الديسكتوب بالظبط.
      expect(AppBreakpoints.sizeFromWidth(1024), WindowSize.expanded);
      // لاب شائع.
      expect(AppBreakpoints.sizeFromWidth(1366), WindowSize.expanded);
      // شاشة كمبيوتر كبيرة.
      expect(AppBreakpoints.sizeFromWidth(1920), WindowSize.expanded);
    });
  });

  group('AppBreakpoints — الثوابت نفسها منطقية', () {
    test('الحدود مترتبة ومعقولة', () {
      expect(AppBreakpoints.compact, lessThan(AppBreakpoints.expanded));
      expect(
        AppBreakpoints.twoPaneMinWidth,
        greaterThan(AppBreakpoints.expanded),
      );
      // عرض المحتوى الأقصى يخصص مساحة قراءة مريحة بس مش شاشة كلها.
      expect(
        AppBreakpoints.maxContentWidth,
        greaterThan(AppBreakpoints.compact),
      );
    });
  });
}
