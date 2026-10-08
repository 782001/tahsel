import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/shared/widgets/buttons/quick_action_button.dart';

class RecordPaymentButton extends StatelessWidget {
  final VoidCallback? onTap;
  const RecordPaymentButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return QuickActionButton(
      label: AppStrings.invoiceRecordPayment.tr(),
      icon: Icons.add_card_rounded,
      onPressed: onTap,
    );
  }
}
