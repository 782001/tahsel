import 'package:flutter/material.dart';
import 'package:tahsel/core/services/injection_container.dart';

NavigatorService nav() => sl<NavigatorService>();

class NavigatorService {
  // Singleton
  static final NavigatorService _instance = NavigatorService._internal();
  factory NavigatorService() => _instance;
  NavigatorService._internal();

  // Global key
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Current context
  BuildContext? get context => navigatorKey.currentContext;

  /// Push a new page
  Future<T?> push<T>(Widget page) {
    return navigatorKey.currentState!.push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Push replacement
  Future<T?> pushReplacement<T, TO>(Widget page) {
    return navigatorKey.currentState!.pushReplacement<T, TO>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Push named route
  Future<T?> pushNamed<T>(String routeName) {
    return navigatorKey.currentState!.pushNamed<T>(routeName);
  }

  /// Push named route with arguments
  Future<T?> pushNamedWithArgs<T>({
    required String routeName,
    required Object? arguments,
  }) {
    return navigatorKey.currentState!.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  /// Push named and remove all previous routes
  Future<T?> pushNamedAndRemoveUntil<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      routeName,
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }

  /// Pop current page
  void pop<T extends Object?>([T? result]) {
    navigatorKey.currentState!.pop<T>(result);
  }

  /// Pop until a certain route
  void popUntil(String routeName) {
    navigatorKey.currentState!.popUntil(ModalRoute.withName(routeName));
  }

  /// Check if navigator can pop
  bool canPop() => navigatorKey.currentState!.canPop();
}
