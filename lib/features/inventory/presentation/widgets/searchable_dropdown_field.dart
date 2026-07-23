import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';

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

  const SearchableDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.selectedId,
    required this.getName,
    required this.getId,
    required this.onSelected,
    required this.onCleared,
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
    final lower = _query.toLowerCase();
    return widget.items
        .where((item) => widget.getName(item).toLowerCase().contains(lower))
        .toList();
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
                SizedBox(width: isDesktop ? 4 : 4.w),
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
            onChanged: (val) => setState(() => _query = val),
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
