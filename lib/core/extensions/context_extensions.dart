import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  /// Gives access to [MediaQueryData] for the current context.
  /// Example: context.mediaQuery.size.width
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Gives access to [ThemeData] for the current context.
  /// Example: context.theme.primaryColor
  ThemeData get theme => Theme.of(this);

  /// Gives access to [TextTheme] for the current context.
  TextTheme get textTheme => theme.textTheme;

  /// Gives semantic access to screen width.
  double get screenWidth => mediaQuery.size.width;

  /// Gives semantic access to screen height.
  double get screenHeight => mediaQuery.size.height;

  /// Navigation shortcuts

  /// Pushes a new route.
  Future<dynamic> push(Widget page) =>
      Navigator.of(this).push(MaterialPageRoute(builder: (_) => page));

  /// Replaces the current route.
  Future<dynamic> pushReplacement(Widget page) => Navigator.of(
    this,
  ).pushReplacement(MaterialPageRoute(builder: (_) => page));

  /// Removes all previous routes and pushes a new one.
  Future<dynamic> pushAndRemoveUntil(Widget page) =>
      Navigator.of(this).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => page),
        (route) => false,
      );

  /// Pops the current route.
  void pop([dynamic result]) => Navigator.of(this).pop(result);

  /// Shows a standard snackbar.
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 500),
      ),
    );
  }

  /// Removes focus from the current text field.
  void unfocus() => FocusScope.of(this).unfocus();
}
