import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';
import 'barcode_scanner_dialog.dart';

/// A reusable searchable dropdown field that shows a label, a tap-to-expand
/// search area, and a filtered list of items.
class SearchableDropdownField<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final String? selectedId;
  final String Function(T) getName;
  final String Function(T) getId;
  final void Function(T) onSelected;
  final VoidCallback onCleared;
  final bool enableBarcodeScan;
  final String? Function(T)? getBarcode;
  final String? Function(T)? getSku;

  const SearchableDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.selectedId,
    required this.getName,
    required this.getId,
    required this.onSelected,
    required this.onCleared,
    this.enableBarcodeScan = false,
    this.getBarcode,
    this.getSku,
  });

  @override
  State<SearchableDropdownField<T>> createState() =>
      _SearchableDropdownFieldState<T>();
}

class _SearchableDropdownFieldState<T>
    extends State<SearchableDropdownField<T>> {
  final TextEditingController _searchController = TextEditingController();
  bool _isExpanded = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filteredItems {
    if (_query.isEmpty) return widget.items;
    final lower = _query.toLowerCase().trim();
    return widget.items.where((item) {
      final nameMatches = widget.getName(item).toLowerCase().contains(lower);
      final idMatches = widget.getId(item).toLowerCase().contains(lower);
      final barcodeMatches = widget.getBarcode != null &&
          (widget.getBarcode!(item)?.toLowerCase().contains(lower) ?? false);
      final skuMatches = widget.getSku != null &&
          (widget.getSku!(item)?.toLowerCase().contains(lower) ?? false);
      return nameMatches || idMatches || barcodeMatches || skuMatches;
    }).toList();
  }

  void _handleBarcodeScanned(String rawCode, {bool isFromCamera = false}) {
    final target = rawCode.trim().toLowerCase();
    if (target.isEmpty) return;

    T? matchedItem;
    for (final item in widget.items) {
      final barcode = widget.getBarcode?.call(item)?.trim().toLowerCase();
      final sku = widget.getSku?.call(item)?.trim().toLowerCase();
      final id = widget.getId(item).trim().toLowerCase();
      final name = widget.getName(item).trim().toLowerCase();
      if ((barcode != null && barcode == target) ||
          (sku != null && sku == target) ||
          id == target ||
          name == target) {
        matchedItem = item;
        break;
      }
    }

    if (matchedItem != null) {
      widget.onSelected(matchedItem);
      setState(() {
        _isExpanded = false;
        _searchController.clear();
        _query = '';
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.getName(matchedItem),
                  style: TextStyles.customStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _query = rawCode;
        _searchController.text = rawCode;
        _isExpanded = true;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noProductsFound.tr()),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String? get _selectedName {
    if (widget.selectedId == null) return null;
    try {
      final item = widget.items.firstWhere(
        (i) => widget.getId(i) == widget.selectedId,
      );
      return widget.getName(item);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: TextStyles.customStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.blackReal,
          ),
        ),
        SizedBox(height: isDesktop ? 6 : 6.h),

        // Selected value display / tap to expand
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 20 : 20.w,
              vertical: isDesktop ? 14 : 14.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.stitchSurfaceHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
              border: _isExpanded
                  ? Border.all(color: AppColors.primaryColor, width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedName ?? widget.label,
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      color: _selectedName != null
                          ? AppColors.blackReal
                          : AppColors.disabledColor,
                    ),
                  ),
                ),
                if (_selectedName != null)
                  GestureDetector(
                    onTap: () {
                      widget.onCleared();
                      setState(() {
                        _searchController.clear();
                        _query = '';
                      });
                    },
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.sandText,
                    ),
                  ),
                if (widget.enableBarcodeScan &&
                    (!kIsWeb && !Platform.isWindows)) ...[
                  SizedBox(width: isDesktop ? 6 : 6.w),
                  GestureDetector(
                    onTap: () async {
                      final scannedCode =
                          await BarcodeScannerDialog.scan(context);
                      if (scannedCode != null && scannedCode.isNotEmpty) {
                        _handleBarcodeScanned(scannedCode, isFromCamera: true);
                      }
                    },
                    child: Tooltip(
                      message: AppStrings.barcode.tr(),
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 20,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
                SizedBox(width: isDesktop ? 6 : 6.w),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.sandText,
                ),
              ],
            ),
          ),
        ),

        // Expandable search + list
        if (_isExpanded) ...[
          SizedBox(height: isDesktop ? 8 : 8.h),
          // Search field
          QuickAddTextField(
            controller: _searchController,
            hint: '${AppStrings.search.tr()} ${widget.label}...',
            icon: Icons.search,
            suffixIcon:
                (!widget.enableBarcodeScan || (!kIsWeb && Platform.isWindows))
                    ? null
                    : Icons.qr_code_scanner_rounded,
            onSuffixIconPressed:
                (!widget.enableBarcodeScan || (!kIsWeb && Platform.isWindows))
                    ? null
                    : () async {
                        final scannedCode =
                            await BarcodeScannerDialog.scan(context);
                        if (scannedCode != null && scannedCode.isNotEmpty) {
                          _handleBarcodeScanned(
                            scannedCode,
                            isFromCamera: true,
                          );
                        }
                      },
            autofocus: true,
            onChanged: (val) => setState(() => _query = val),
            onSubmitted: (scannedCode) {
              if (widget.enableBarcodeScan && scannedCode.isNotEmpty) {
                _handleBarcodeScanned(scannedCode, isFromCamera: false);
              }
            },
          ),
          SizedBox(height: isDesktop ? 6 : 6.h),

          // Filtered results list
          Container(
            constraints: BoxConstraints(maxHeight: isDesktop ? 150 : 150.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
              border: Border.all(color: AppColors.dividerColor),
            ),
            child: _filteredItems.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(isDesktop ? 12 : 12.w),
                    child: Center(
                      child: Text(
                        AppStrings.noResults.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 13,
                          color: AppColors.disabledColor,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final id = widget.getId(item);
                      final name = widget.getName(item);
                      final isSelected = id == widget.selectedId;

                      return InkWell(
                        borderRadius: BorderRadius.circular(
                          isDesktop ? 12 : 12.r,
                        ),
                        onTap: () {
                          widget.onSelected(item);
                          setState(() {
                            _isExpanded = false;
                            _searchController.clear();
                            _query = '';
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 16 : 16.w,
                            vertical: isDesktop ? 10 : 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor.withValues(alpha: 0.08)
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: index < _filteredItems.length - 1
                                    ? AppColors.dividerColor
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isSelected)
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: isDesktop ? 8 : 8.w,
                                  ),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyles.customStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppColors.primaryColor
                                        : AppColors.blackReal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
}
