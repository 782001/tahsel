import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert' show json;
import 'app_localizations_delegate.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// Global access to the current localization instance.
  static AppLocalizations? _instance;
  static AppLocalizations? get current => _instance;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      AppLocalizationsDelegate();

  /// Static initialization for a specific locale. 
  /// This can be called from Cubit/State Management before the UI rebuilds.
  static Future<AppLocalizations> init(Locale locale) async {
    final localization = AppLocalizations(locale);
    await localization.load();
    _instance = localization;
    return localization;
  }

  late Map<String, String> _localizedStrings;

  Future<void> load() async {
    String jsonString =
        await rootBundle.loadString('lang/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map<String, String>((key, value) {
      return MapEntry(key, value.toString());
    });
    _instance = this; // Update static instance
  }

  /// Static translation helper for String extensions
  static String tr(String key, {List<String>? args}) {
    String value = _instance?._localizedStrings[key] ?? key;
    if (args != null && args.isNotEmpty) {
      // Standard replacement for {0}, {1}, etc.
      for (int i = 0; i < args.length; i++) {
        value = value.replaceAll('{$i}', args[i]);
      }
      
      // Explicitly support historical and named placeholders used in the project.
      if (args.length >= 1) {
        value = value.replaceAll('{percentage}', args[0]);
        value = value.replaceAll('{amount}', args[0]);
        value = value.replaceAll('{difference}', args[0]);
      }
      
      if (args.length >= 2) {
        value = value.replaceAll('{netProfit}', args[1]);
        // Also support index-based if needed, though replaced by names above for 0/1
        value = value.replaceAll('{amount}', args[1]);
      }
    }
    return value;
  }

  String? translate(String key) => _localizedStrings[key];
  bool get isEnLocale => locale.languageCode == 'en';
}
