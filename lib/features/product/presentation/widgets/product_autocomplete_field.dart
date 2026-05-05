import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';

import '../../domain/entities/product_entity.dart';
import '../cubit/product_cubit.dart';

class ProductAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final String? errorText;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const ProductAutocompleteField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.errorText,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<ProductEntity>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        return context.read<ProductCubit>().getSuggestions(
          textEditingValue.text,
        );
      },
      displayStringForOption: (ProductEntity option) => option.name,
      fieldViewBuilder:
          (context, fieldController, fieldFocusNode, onFieldSubmitted) {
            return TextField(
              cursorColor: AppColors.primaryColor,
              controller: fieldController,
              focusNode: fieldFocusNode,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              style: TextStyles.customStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
              decoration: InputDecoration(
                hintText: hint,
                errorText: errorText,
                hintStyle: TextStyles.customStyle(
                  color: AppColors.blackLight.withValues(alpha: 0.5),
                  fontWeight: FontWeight.normal,
                ),
                prefixIcon: icon != null
                    ? Icon(icon, color: AppColors.blackLight)
                    : null,
                filled: true,
                fillColor: AppColors.stitchSurfaceHigh.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            color: AppColors.surface,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Determine the width of the field to match it
                final fieldWidth =
                    FocusScope.of(context).focusedChild?.size.width ?? 300;

                return SizedBox(
                  width: fieldWidth,
                  child: Stack(
                    children: [
                      ListView.separated(
                        padding: const EdgeInsets.only(top: 16),
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: AppColors.blackLight.withValues(alpha: 0.1),
                        ),
                        itemBuilder: (context, index) {
                          final ProductEntity option = options.elementAt(index);
                          return ListTile(
                            title: Text(
                              option.name,
                              style: TextStyles.customStyle(
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
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () {
                            Future.delayed(
                              const Duration(milliseconds: 50),
                              () {
                                if (context.mounted) {
                                  FocusScope.of(context).unfocus();
                                }
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.blackLight.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 22,
                              color: AppColors.blackLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
