import 'package:flutter/material.dart';

abstract class NavigationService {
  GlobalKey<NavigatorState> get navigatorKey;

  Future<dynamic> pushNamed(String routeName, {Object? arguments});

  void goBack();
}

class NavigationServiceImpl implements NavigationService {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Future<dynamic> pushNamed(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  @override
  void goBack() => navigatorKey.currentState?.pop();
}
