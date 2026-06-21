import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/customer/presentation/widgets/customer_autocomplete_field.dart';
import 'package:tahsel/features/operation/presentation/widgets/quick_add_sub_tab_header.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';

class PsSessionForm extends StatefulWidget {
  final TextEditingController customerController;
  final TextEditingController deviceController;
  final TextEditingController roomController;
  final TextEditingController rateController;
  final PlayStationMode psMode;
  final ValueChanged<PlayStationMode> onModeChanged;
  final String? customerError;
  final FocusNode customerFocus;
  final FocusNode deviceFocus;
  final FocusNode roomFocus;
  final FocusNode rateFocus;
  final VoidCallback onStartSession;
  final VoidCallback onContactPickerPressed;

  const PsSessionForm({
    super.key,
    required this.customerController,
    required this.deviceController,
    required this.roomController,
    required this.rateController,
    required this.psMode,
    required this.onModeChanged,
    this.customerError,
    required this.customerFocus,
    required this.deviceFocus,
    required this.roomFocus,
    required this.rateFocus,
    required this.onStartSession,
    required this.onContactPickerPressed,
  });

  @override
  State<PsSessionForm> createState() => _PsSessionFormState();
}

class _PsSessionFormState extends State<PsSessionForm> {
  @override
  Widget build(BuildContext context) {
    final isTimeMode = widget.psMode == PlayStationMode.time;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub tabs (By Time vs By Turn)
          QuickAddSubTabHeader(
            selectedMode: widget.psMode,
            onModeChanged: widget.onModeChanged,
          ),
          const SizedBox(height: 20),

          // Customer Name Autocomplete
          Text(
            AppStrings.customerName.tr(),
            style: TextStyles.customStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          CustomerAutocompleteField(
            hint: AppStrings.customerNameHint.tr(),
            controller: widget.customerController,
            errorText: widget.customerError,
            icon: Icons.person_outline,
            suffixIcon: Icons.contact_phone_rounded,
            onSuffixIconPressed: widget.onContactPickerPressed,
            focusNode: widget.customerFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => widget.deviceFocus.requestFocus(),
          ),
          const SizedBox(height: 16),

          // Room and Device row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.deviceLabel.tr(),
                      style: TextStyles.customStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    QuickAddTextField(
                      hint: AppStrings.deviceHint.tr(),
                      hintFontSize: 12,
                      controller: widget.deviceController,
                      icon: Icons.sports_esports_outlined,
                      focusNode: widget.deviceFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => widget.roomFocus.requestFocus(),
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
                      AppStrings.roomLabel.tr(),
                      style: TextStyles.customStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    QuickAddTextField(
                      hint: AppStrings.roomHint.tr(),
                      hintFontSize: 12,
                      controller: widget.roomController,
                      icon: Icons.meeting_room_outlined,
                      focusNode: widget.roomFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => widget.rateFocus.requestFocus(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hourly / Turn Rate
          Text(
            isTimeMode
                ? AppStrings.pricePerHour.tr()
                : AppStrings.pricePerTurn.tr(),
            style: TextStyles.customStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          QuickAddTextField(
            hint: '0.00',
            controller: widget.rateController,
            icon: Icons.payments_outlined,
            isNumber: true,
            suffixText: AppStrings.currencyEgp.tr(),
            focusNode: widget.rateFocus,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => widget.onStartSession(),
          ),
          const SizedBox(height: 20),

          // Start Session Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onStartSession,
              icon: const Icon(Icons.play_circle_outline, color: Colors.white),
              label: Text(
                AppStrings.startSession.tr(),
                style: TextStyles.customStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
