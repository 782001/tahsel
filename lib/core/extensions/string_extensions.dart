import 'package:flutter/material.dart';
import 'package:tahsel/core/config/locale/app_localizations.dart';
import 'package:tahsel/core/services/translation_helper.dart';

extension StringExtensions on String {
  /// Translates the string key using the current localization instance.
  /// Matches the easy_localization usage pattern: 'key'.tr()
  String tr({List<String>? args}) {
    return AppLocalizations.tr(this, args: args);
  }

  /// Translates the string key using a specific [context].
  /// Useful if you want to ensure the lookup happens within a specific widget subtree.
  String loc(BuildContext context) {
    return Loc.tr(context, this);
  }

  /// Parses the string to an [int] or returns null if it cannot be parsed.
  /// Example: '123'.toIntOrNull() // 123
  /// Example: 'abc'.toIntOrNull() // null
  int? toIntOrNull() => int.tryParse(this);

  /// Parses the string to a [double] or returns null if it cannot be parsed.
  /// Example: '12.3'.toDoubleOrNull() // 12.3
  /// Example: 'abc'.toDoubleOrNull() // null
  double? toDoubleOrNull() => double.tryParse(this);

  /// Checks whether the string is a valid email format.
  /// Example: 'test@example.com'.isValidEmail() // true
  bool isValidEmail() {
    final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegExp.hasMatch(this);
  }

  /// Capitalizes the first letter of the string.
  /// Example: 'hello world'.capitalize() // 'Hello world'
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalizes the first letter of each word in the string.
  /// Example: 'hello world'.capitalizeAll() // 'Hello World'
  String capitalizeAll() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }
}

extension NullableStringExtensions on String? {
  /// Returns true if the string is null or empty.
  /// Example: null.isNullOrEmpty // true
  /// Example: ''.isNullOrEmpty // true
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns true if the string is neither null nor empty.
  bool get isNotNullNorEmpty => this != null && this!.isNotEmpty;
}
