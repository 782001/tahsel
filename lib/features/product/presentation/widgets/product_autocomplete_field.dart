import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';

import '../../domain/entities/product_entity.dart';
import '../cubit/product_cubit.dart';

class ProductAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final String? errorText;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<ProductEntity>? onSelected;

  const ProductAutocompleteField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.errorText,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.onSelected,
  });

  @override
  State<ProductAutocompleteField> createState() =>
      _ProductAutocompleteFieldState();
}

class _ProductAutocompleteFieldState extends State<ProductAutocompleteField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  FocusNode? _ownedFocusNode;
  List<ProductEntity> _suggestions = [];

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChanged);
    _hideOverlay();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_effectiveFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_effectiveFocusNode.hasFocus) {
          _hideOverlay();
        }
      });
    } else if (widget.controller.text.isNotEmpty) {
      _updateSuggestions(widget.controller.text);
    }
  }

  void _onTextChanged() {
    if (_effectiveFocusNode.hasFocus) {
      _updateSuggestions(widget.controller.text);
    }
  }

  void _updateSuggestions(String text) {
    if (!mounted) return;
    final suggestions = context.read<ProductCubit>().getSuggestions(text);
    _suggestions = suggestions;

    if (suggestions.isNotEmpty && _effectiveFocusNode.hasFocus) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _selectOption(ProductEntity option) {
    widget.controller.text = option.name;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: option.name.length),
    );
    if (widget.onSelected != null) {
      widget.onSelected!(option);
    }
    _hideOverlay();
    _effectiveFocusNode.unfocus();
  }

  void _showOverlay() {
    if (!mounted) return;
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? const Size(300, 50);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0.0, size.height + 4.0),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              color: AppColors.surface,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  color: AppColors.surface,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: AppColors.blackLight.withValues(alpha: 0.1),
                    ),
                    itemBuilder: (context, index) {
                      final option = _suggestions[index];
                      return InkWell(
                        onTapDown: (_) => _selectOption(option),
                        onTap: () => _selectOption(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            option.name,
                            style: TextStyles.customStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        cursorColor: AppColors.primaryColor,
        controller: widget.controller,
        focusNode: _effectiveFocusNode,
        textInputAction: widget.textInputAction,
        onSubmitted: (val) {
          _hideOverlay();
          widget.onSubmitted?.call(val);
        },
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
      ),
    );
  }
}
