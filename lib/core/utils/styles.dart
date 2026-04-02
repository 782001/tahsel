import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/responsive_text.dart';
import 'app_colors.dart';
import 'app_constants.dart';

class TextStyles {
  static TextStyle font18Weight500White() {
    return TextStyle(
      fontSize: getResponsiveFontSize(fontSize: 18),
      fontWeight: FontWeight.w500,
      fontFamily: AppConstants.fontFamily,
      color: Colors.white,
    );
  }

  static TextStyle appbartext() {
    return TextStyle(
      fontSize: getResponsiveFontSize(fontSize: 28),
      fontWeight: FontWeight.w500,
      fontFamily: AppConstants.fontFamily,
      color: AppColors.actionButton,
    );
  }

  static TextStyle font14Weight400RightAligned() {
    return TextStyle(
      fontSize: getResponsiveFontSize(fontSize: 14),
      fontWeight: FontWeight.w400,
      fontFamily: AppConstants.fontFamily,
      color: AppColors.textColor,
    );
  }

  static TextStyle font18Weight500Action() {
    return TextStyle(
      fontSize: getResponsiveFontSize(fontSize: 18),
      fontWeight: FontWeight.w500,
      fontFamily: AppConstants.fontFamily,
      color: AppColors.actionButton,
    );
  }

  static TextStyle font16Weight400Text() {
    return TextStyle(
      fontSize: getResponsiveFontSize(fontSize: 16),
      fontWeight: FontWeight.w400,
      fontFamily: AppConstants.fontFamily,
      color: AppColors.textColor,
    );
  }

  static TextStyle font16WeightBoldText() {
    return TextStyle(
      fontSize: getResponsiveFontSize(fontSize: 16),
      fontWeight: FontWeight.bold,
      fontFamily: AppConstants.fontFamily,
      color: AppColors.textColor,
    );
  }

  static TextStyle font28WeightBoldWhite() {
    return TextStyle(
      fontSize: getResponsiveFontSize(fontSize: 28),
      fontWeight: FontWeight.bold,
      fontFamily: AppConstants.fontFamily,
      color: Colors.white,
    );
  }

  static TextStyle font28Weight600WhiteTrans() {
    return TextStyle(
      fontSize: getResponsiveFontSize(fontSize: 28),
      fontWeight: FontWeight.w600,
      fontFamily: AppConstants.fontFamily,
      color: Colors.white,
    );
  }
}
