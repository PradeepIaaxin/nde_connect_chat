import 'package:flutter/material.dart';

class MyRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static push({required Widget screen}) {
    return navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }

  static restorablePushNamed({required String screen, Object? arguments}) {
    return navigatorKey.currentState
        ?.restorablePushNamed(screen, arguments: arguments);
  }

  static bool canPop<T extends Object?>([T? result]) {
    bool? canPop = navigatorKey.currentState?.canPop();
    return canPop == true;
  }

  static pop<T extends Object?>([T? result]) {
    bool? canPop = navigatorKey.currentState?.canPop();
    if (canPop != true) return;
    navigatorKey.currentState?.pop(result);
  }

  static pushReplace({required Widget screen}) {
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }

  static pushRemoveUntil({required Widget screen}) {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => screen,
      ),
      (route) => false,
    );
  }

  static void pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    navigatorKey.currentState?.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  static void pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    navigatorKey.currentState?.pushReplacementNamed<T, TO>(routeName,
        arguments: arguments, result: result);
  }

  static void pushNamedAndRemoveUntil<T extends Object?>(
    String newRouteName, {
    RoutePredicate? predicate,
    Object? arguments,
  }) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      newRouteName,
      predicate ?? (route) => false,
);
}
  static pushReplacement({required Widget screen}) {
    return pushReplace(screen: screen);
  }

}


