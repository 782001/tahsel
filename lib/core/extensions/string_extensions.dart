import 'package:flutter/material.dart';
import 'package:tahsel/core/config/locale/app_localizations.dart';
import 'package:tahsel/core/services/translation_helper.dart';

extension StringExtensions on String {
  /// Translates the string key using the current localization instance.
  /// Matches the easy_localization usage pattern: 'key'.tr()
  String tr({List<String>? args, Map<String, String>? namedArgs}) {
    return AppLocalizations.tr(this, args: args, namedArgs: namedArgs);
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

  /// Formats the phone number for WhatsApp by removing non-digits
  /// and ensuring it starts with the country code (20 for Egypt) without leading zeroes.
  String toWhatsAppFormat() {
    String formattedPhone = replaceAll(RegExp(r'\D'), '');
    if (formattedPhone.startsWith('0020')) {
      formattedPhone = formattedPhone.substring(2);
    } else if (formattedPhone.startsWith('0')) {
      formattedPhone = '20${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('20')) {
      formattedPhone = '20$formattedPhone';
    }
    return formattedPhone;
  }

  /// Cleans emojis and unsupported symbols to avoid PDF font missing glyph exceptions
  String cleanForPdf() {
    if (isEmpty) return this;
    final emojiPattern = RegExp(
      r'[\u{1F600}-\u{1F64F}'
      r'|\u{1F300}-\u{1F5FF}'
      r'|\u{1F680}-\u{1F6FF}'
      r'|\u{1F700}-\u{1F77F}'
      r'|\u{1F780}-\u{1F7FF}'
      r'|\u{1F800}-\u{1F8FF}'
      r'|\u{1F900}-\u{1F9FF}'
      r'|\u{1FA00}-\u{1FA6F}'
      r'|\u{1FA70}-\u{1FAFF}'
      r'|\u{2600}-\u{26FF}'
      r'|\u{2700}-\u{27BF}'
      r'|\u{FE00}-\u{FE0F}'
      r'|\u{1F1E6}-\u{1F1FF}'
      r']+',
      unicode: true,
    );
    return replaceAll(emojiPattern, '').trim();
  }
}

extension NullableStringExtensions on String? {
  /// Returns true if the string is null or empty.
  /// Example: null.isNullOrEmpty // true
  /// Example: ''.isNullOrEmpty // true
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns true if the string is neither null nor empty.
  bool get isNotNullNorEmpty => this != null && this!.isNotEmpty;

  /// Safely cleans emojis from nullable string for PDF rendering
  String cleanForPdf([String defaultValue = '']) {
    if (this == null) return defaultValue;
    return this!.cleanForPdf();
  }
}
