import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';

import '../../domain/entities/customer_entity.dart';
import '../cubit/customer_cubit.dart';

/// A customer-name autocomplete field backed by [CustomerCubit].
///
/// [RawAutocomplete] requires that [textEditingController] and [focusNode] are
/// either BOTH provided or BOTH null.  Since we always receive a controller
/// from the parent, we own an internal [FocusNode] when none is supplied.
class CustomerAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final String? errorText;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<CustomerEntity>? onSelected;

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
    this.onSelected,
  });

  @override
  State<CustomerAutocompleteField> createState() =>
      _CustomerAutocompleteFieldState();
}

class _CustomerAutocompleteFieldState extends State<CustomerAutocompleteField> {
  // When the caller does not supply a FocusNode we own one ourselves so that
  // RawAutocomplete's assertion "(focusNode == null) == (controller == null)"
  // is always satisfied.
  FocusNode? _ownedFocusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void dispose() {
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<CustomerEntity>(
      textEditingController: widget.controller,
      focusNode: _effectiveFocusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        return context.read<CustomerCubit>().getSuggestions(
          textEditingValue.text,
        );
      },
      displayStringForOption: (CustomerEntity option) => option.name,
      fieldViewBuilder:
          (context, fieldController, fieldFocusNode, onFieldSubmitted) {
            return TextField(
              cursorColor: AppColors.primaryColor,
              controller: fieldController,
              focusNode: fieldFocusNode,
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              style: TextStyles.customStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                errorText: widget.errorText,
                hintStyle: TextStyles.customStyle(
                  color: AppColors.blackLight.withValues(alpha: 0.5),
                  fontWeight: FontWeight.normal,
                ),
                prefixIcon: widget.icon != null
                    ? Icon(widget.icon, color: AppColors.blackLight)
                    : null,
                suffixIcon: widget.suffixIcon != null
                    ? IconButton(
                        icon: Icon(
                          widget.suffixIcon,
                          color: AppColors.primaryColor,
                        ),
                        onPressed: widget.onSuffixIconPressed,
                      )
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
                          final CustomerEntity option = options.elementAt(
                            index,
                          );
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
                              if (widget.onSelected != null) {
                                widget.onSelected!(option);
                              }
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
