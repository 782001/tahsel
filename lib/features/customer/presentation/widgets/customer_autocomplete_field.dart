import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import '../cubit/customer_cubit.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final String? errorText;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const CustomerAutocompleteField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.errorText,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<CustomerEntity>(
      textEditingController: controller,
      focusNode: focusNode ?? FocusNode(),
      optionsBuilder: (TextEditingValue textEditingValue) {
        return context.read<CustomerCubit>().getSuggestions(textEditingValue.text);
      },
      displayStringForOption: (CustomerEntity option) => option.name,
      fieldViewBuilder: (context, fieldController, fieldFocusNode, onFieldSubmitted) {
        return TextField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            hintStyle: TextStyle(
              color: AppColors.blackLight.withOpacity(0.5),
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: icon != null ? Icon(icon, color: AppColors.blackLight) : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(suffixIcon, color: AppColors.primaryColor),
                    onPressed: onSuffixIconPressed,
                  )
                : null,
            filled: true,
            fillColor: AppColors.stitchSurfaceHigh.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            color: AppColors.surface,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = FocusScope.of(context).focusedChild?.size.width ?? 300;
                
                return SizedBox(
                  width: fieldWidth,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: AppColors.blackLight.withOpacity(0.1),
                    ),
                    itemBuilder: (context, index) {
                      final CustomerEntity option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option.name,
                          style: TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          onSelected(option);
                        },
                      );
                    },
                  ),
                );
              }
            ),
          ),
        );
      },
    );
  }
}
