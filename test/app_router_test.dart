import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:besbasa/core/routes/app_router.dart';

void main() {
  group('AppRouter', () {
    test('كل مسار بيرجّع MaterialPageRoute', () {
      expect(
        AppRouter.onGenerateRoute(const RouteSettings(name: '/')),
        isA<MaterialPageRoute<dynamic>>(),
      );
      expect(
        AppRouter.onGenerateRoute(const RouteSettings(name: '/nowhere')),
        isA<MaterialPageRoute<dynamic>>(),
      );
    });
  });
}
