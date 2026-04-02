import 'dart:io';

import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/routes/app_routes.dart';

class SecurityService {
  /// Configuration to enable or disable the security service
  static bool isEnabled = true;

  /// Configuration to enable or disable data obfuscation
  static bool isObfuscationEnabled = true;

  /// Helper to obfuscate sensitive strings if enabled
  static String obfuscateData(String data) {
    if (!isObfuscationEnabled || data.length < 4) return data;
    return '${data.substring(0, 2)}****${data.substring(data.length - 2)}';
  }

  /// Check if the device is jailbroken or rooted
  static Future<bool> isJailbroken() async {
    try {
      return await FlutterJailbreakDetection.jailbroken;
    } catch (e) {
      return false;
    }
  }

  /// Check if developer mode / ADB is enabled (Android only)
  static Future<bool> isDeveloperModeEnabled() async {
    try {
      return await FlutterJailbreakDetection.developerMode;
    } catch (e) {
      return false;
    }
  }

  /// Check for VPN active
  static Future<bool> isVpnActive() async {
    try {
      List<NetworkInterface> interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.any,
      );
      return interfaces.any(
        (interface) =>
            interface.name.contains('tun') ||
            interface.name.contains('ppp') ||
            interface.name.contains('pptp') ||
            interface.name.contains('l2tp') ||
            interface.name.contains('ipsec'),
      );
    } catch (e) {
      return false;
    }
  }

  /// Main security check logic
  static Future<void> checkSecurity() async {
    if (!isEnabled) return;

    final isRooted = await isJailbroken();
    final isDevMode = await isDeveloperModeEnabled();

    if (isRooted || isDevMode) {
      nav().pushNamedAndRemoveUntil(
        AppRoutes.securityWarning,
        arguments: {'isRooted': isRooted, 'isDevMode': isDevMode},
      );
    }
  }
}
