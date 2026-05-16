import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  static bool isMobile(BuildContext context) {
    if (kIsWeb) return false;
    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return false;
      }
    } catch (_) {}
    return MediaQuery.of(context).size.width < 900;
  }

  static bool isDesktop(BuildContext context) {
    if (kIsWeb) return true;
    try {
      if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) &&
          MediaQuery.of(context).size.width >= 600) {
        return true;
      }
    } catch (_) {}
    return MediaQuery.of(context).size.width >= 900;
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktop(context)) {
      return desktop;
    }
    return mobile;
  }
}
