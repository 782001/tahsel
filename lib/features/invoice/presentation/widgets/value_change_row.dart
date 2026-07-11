import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_history_entity.dart';
import 'package:tahsel/features/invoice/presentation/widgets/value_pill.dart';

class ValueChangeRow extends StatelessWidget {
  final InvoiceHistoryChangeType changeType;
  final String? oldValue;
  final String? newValue;

  const ValueChangeRow({
    super.key,
    required this.changeType,
    this.oldValue,
    this.newValue,
  });

  @override
  Widget build(BuildContext context) {
    // For notes — just show a simple label
    if (changeType == InvoiceHistoryChangeType.notesUpdated) {
      return Text(
        AppStrings.historyNotesChanged.tr(),
        style: TextStyles.customStyle(
          fontSize: 11,
          color: AppColors.disabledColor,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Row(
      children: [
        if (oldValue != null) ...[
          ValuePill(label: oldValue!, isOld: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: AppColors.disabledColor,
            ),
          ),
        ],
        if (newValue != null) ValuePill(label: newValue!, isOld: false),
      ],
    );
  }
}
