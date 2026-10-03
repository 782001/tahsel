import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/features/reports/domain/entities/profit_insight.dart';

extension ProfitInsightUIExtension on ProfitInsight {
  String getMessage(bool isShop) {
    String finalKey = messageKey;
    if (isShop && messageKey == 'insight_income_up_cafe') {
      finalKey = 'insight_income_up_shop';
    }
    return finalKey.tr(
      args: [
        difference.abs().toSmartAmount(),
        if (status == ProfitInsightStatus.loss &&
            netProfit.abs().toSmartAmount() != "0.0")
          "-${netProfit.abs().toSmartAmount()}"
        else
          netProfit.abs().toSmartAmount(),
      ],
    );
  }

  String get message => getMessage(false);

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
