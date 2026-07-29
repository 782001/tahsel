import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/responsive_text.dart';
import 'package:tahsel/core/utils/styles.dart';

void showSuccessToast(String message) {
  if (!kIsWeb && Platform.isWindows) {
    _showDesktopSnackBar(
      message: message,
      backgroundColor: AppColors.green,
      icon: Icons.check_circle_rounded,
    );
    return;
  }

  try {
    Fluttertoast.showToast(
      msg: message,
      fontAsset: Assets.fontsDGAgnadeenRegular,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 1,
      backgroundColor: AppColors.green,
      textColor: AppColors.whiteColor,
      fontSize: getResponsiveFontSize(fontSize: 14),
    );
  } catch (_) {
    _showDesktopSnackBar(
      message: message,
      backgroundColor: AppColors.green,
      icon: Icons.check_circle_rounded,
    );
  }
}

void showfailureToast(String message) {
  if (!kIsWeb && Platform.isWindows) {
    _showDesktopSnackBar(
      message: message,
      backgroundColor: AppColors.redColor,
      icon: Icons.error_outline_rounded,
    );
    return;
  }

  try {
    Fluttertoast.showToast(
      msg: message,
      fontAsset: Assets.fontsDGAgnadeenRegular,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 1,
      backgroundColor: AppColors.redColor,
      textColor: AppColors.whiteColor,
      fontSize: getResponsiveFontSize(fontSize: 14),
    );
  } catch (_) {
    _showDesktopSnackBar(
      message: message,
      backgroundColor: AppColors.redColor,
      icon: Icons.error_outline_rounded,
    );
  }
}

void _showDesktopSnackBar({
  required String message,
  required Color backgroundColor,
  required IconData icon,
}) {
  try {
    final messengerState = nav().scaffoldMessengerKey.currentState;
    if (messengerState != null) {
      messengerState.hideCurrentSnackBar();
      messengerState.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyles.customStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  } catch (_) {}
}
