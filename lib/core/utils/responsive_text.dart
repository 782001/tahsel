import 'package:flutter/material.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/services/injection_container.dart';

double getResponsiveFontSize({required double fontSize}) {
  final context = sl<NavigatorService>().context;

  if (context == null) return fontSize;

  double scaleFactor = getScaleFactor(context);
  double responsiveFontSize = fontSize * scaleFactor;

  double lowerLimit = fontSize * .8;
  double upperLimit = fontSize * 1.2;

  return responsiveFontSize.clamp(lowerLimit, upperLimit);
}

double getScaleFactor(BuildContext context) {
  double width = MediaQuery.sizeOf(context).width;

  if (width < 600) {
    return width / 375;
  } else if (width < 900) {
    return width / 700;
  } else {
    return width / 1000;
  }
}
