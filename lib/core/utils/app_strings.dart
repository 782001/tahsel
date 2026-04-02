import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/storage/cashhelper.dart';

class AppStrings {
  static const String noRouteFound = 'No Route Found';
  static const String cachedRandomQuote = 'CACHED_RANDOM_QUOTE';
  static const String contentType = 'Content-Type';
  static const String applicationJson = 'application/json';
  static const String serverFailure = 'Server Failure';
  static const String cacheFailure = 'Cache Failure';
  static const String unexpectedError = 'Unexpected Error';
  static const String englishCode = 'en';
  static const String arabicCode = 'ar';
  static const String locale = 'locale';
  static String currentLang = "ar";
  static String userToken =
      sl<CashHelper>().getData(key: 'token') as String? ?? '';

  ///-----------------------------
  ///-----------------------------
  ///---------Language-------------

  static const String language = "language";
  static String no_data = "no_data";
  static String sorry_no_data = "sorry_no_data";
  static const String swipe_down = "swipe_down";
  static const String download_failed = "download_failed";
  static const String slide_to_load_more = "slide_to_load_more";

  // Security Warning Screen
  static const String securityWarningTitle = "security_warning_title";
  static const String securityWarningDescription =
      "security_warning_description";
  static const String securityWarningRootedTitle =
      "security_warning_rooted_title";
  static const String securityWarningRootedSubtitle =
      "security_warning_rooted_subtitle";
  static const String securityWarningDevModeTitle =
      "security_warning_dev_mode_title";
  static const String securityWarningDevModeSubtitle =
      "security_warning_dev_mode_subtitle";
  static const String securityWarningFooter = "security_warning_footer";

  // Error Screen
  static const String errorScreenTitle = "error_screen_title";
  static const String errorScreenDetailsLabel = "error_screen_details_label";
  static const String errorScreenGoBackButton = "error_screen_go_back_button";
}
