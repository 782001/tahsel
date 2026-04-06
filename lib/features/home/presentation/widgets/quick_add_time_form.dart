import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';
import 'package:tahsel/features/customer/presentation/widgets/customer_autocomplete_field.dart';

class QuickAddTimeForm extends StatelessWidget {
  final TextEditingController customerController;
  final TextEditingController hourlyRateController;
  final int durationMinutes;
  final VoidCallback onDurationAdd;
  final VoidCallback onDurationRemove;

  const QuickAddTimeForm({
    super.key,
    required this.customerController,
    required this.hourlyRateController,
    required this.durationMinutes,
    required this.onDurationAdd,
    required this.onDurationRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.customerName.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        CustomerAutocompleteField(
          hint: AppStrings.customerNameHint.tr(),
          controller: customerController,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.pricePerHour.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  QuickAddTextField(
                    hint: '0.00',
                    controller: hourlyRateController,
                    isNumber: true,
                    suffixText: AppStrings.currencyEgp.tr(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.timeDuration.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildCounterField(value: '$durationMinutes'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterField({required String value}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.stitchSurfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF2E7D32)),
            onPressed: onDurationAdd,
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.red),
            onPressed: onDurationRemove,
          ),
        ],
      ),
    );
  }
}
