import 'package:flutter/material.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../constants/app_routes.dart';

/// راوتر بسيط: شل التبويبات على المسار الرئيسي + صفحة Not Found محترمة.
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.initial:
        return MaterialPageRoute(builder: (_) => const HomePage());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(
              child: Text('No route found for: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
