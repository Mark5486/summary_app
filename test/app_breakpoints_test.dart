import 'package:flutter_test/flutter_test.dart';

import 'package:besbasa/core/constants/app_breakpoints.dart';

void main() {
  group('AppBreakpoints.sizeFromWidth — تحجيم النافذة', () {
    test('الموبايل الضيق → compact', () {
      expect(AppBreakpoints.sizeFromWidth(0), WindowSize.compact);

      expect(AppBreakpoints.sizeFromWidth(360), WindowSize.compact);

      expect(AppBreakpoints.sizeFromWidth(599), WindowSize.compact);
    });

    test('التابلت / اللاب الضيق → medium', () {
      expect(AppBreakpoints.sizeFromWidth(600), WindowSize.medium);

      expect(AppBreakpoints.sizeFromWidth(768), WindowSize.medium);

      expect(AppBreakpoints.sizeFromWidth(1023), WindowSize.medium);
    });

    test('اللاب / الكمبيوتر → expanded', () {
      expect(AppBreakpoints.sizeFromWidth(1024), WindowSize.expanded);

      expect(AppBreakpoints.sizeFromWidth(1366), WindowSize.expanded);

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

      expect(
        AppBreakpoints.maxContentWidth,
        greaterThan(AppBreakpoints.compact),
      );
    });
  });
}
