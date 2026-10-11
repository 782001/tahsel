import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/customer/domain/entities/customer_entity.dart';
import 'package:tahsel/features/customer/presentation/widgets/customer_autocomplete_field.dart';

class CreateInvoiceCustomerField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final VoidCallback onContactTap;
  final bool canPickContact;
  final ValueChanged<CustomerEntity>? onSelected;

  const CreateInvoiceCustomerField({
    super.key,
    required this.controller,
    required this.hint,
    required this.label,
    required this.onContactTap,
    this.canPickContact = true,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.customStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 6),
        CustomerAutocompleteField(
          controller: controller,
          hint: hint,
          suffixIcon: canPickContact ? Icons.contact_phone_rounded : null,
          onSuffixIconPressed: canPickContact ? onContactTap : null,
          onSelected: onSelected,
        ),
      ],
    );
  }
}
