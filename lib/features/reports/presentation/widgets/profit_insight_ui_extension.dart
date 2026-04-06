import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/features/reports/domain/entities/profit_insight.dart';

extension ProfitInsightUIExtension on ProfitInsight {
  String get message => messageKey.tr(args: [
        difference.abs().toStringAsFixed(1),
        netProfit.abs().toStringAsFixed(1),
      ]);

  Color get color {
    switch (status) {
      case ProfitInsightStatus.increase:
        return AppColors.success;
      case ProfitInsightStatus.loss:
        return AppColors.error;
      case ProfitInsightStatus.same:
      case ProfitInsightStatus.none:
        return AppColors.blackLight;
    }
  }
}
