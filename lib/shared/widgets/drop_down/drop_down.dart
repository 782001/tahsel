import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';

class DropDownCustomTextfailed extends StatefulWidget {
  const DropDownCustomTextfailed({
    super.key,
    this.hintText,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.dropdownItems,
    this.onDropdownChanged,
    this.dropdownValue,
    this.onTap,
  });

  final String? hintText;
  final TextInputType? keyboardType;
  final Icon? prefixIcon;
  final Icon? suffixIcon;
  final List<String>? dropdownItems;
  final ValueChanged<String?>? onDropdownChanged;
  final String? dropdownValue;
  final VoidCallback? onTap;

  @override
  State<DropDownCustomTextfailed> createState() =>
      _DropDownCustomTextfailedState();
}

class _DropDownCustomTextfailedState extends State<DropDownCustomTextfailed> {
  String? _selectedDropdownItem;
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedDropdownItem = widget.dropdownValue;
  }

  void _toggleDropdown() {
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              _toggleDropdown();
              if (widget.onTap != null) {
                widget.onTap!();
              }
            },
            child: AbsorbPointer(
              child: TextField(
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: _selectedDropdownItem ?? widget.hintText,
                  hintStyle: TextStyles.font14Weight400RightAligned().copyWith(
                    color: AppColors.grey,
                  ),
                  prefixIcon: Icon(
                    _isDropdownOpen
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(
                      color: _isDropdownOpen ? AppColors.green : AppColors.grey,
                      width: 1.w,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(width: 2.w),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 15.h,
                    horizontal: 20.w,
                  ),
                ),
              ),
            ),
          ),
          if (_isDropdownOpen && widget.dropdownItems != null)
            Container(
              width: 1.sw,
              margin: EdgeInsets.only(top: 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: _isDropdownOpen ? AppColors.grey : AppColors.green,
                ),
              ),
              child: SizedBox(
                height: 200.h,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  itemCount: widget.dropdownItems!.length,
                  itemBuilder: (context, index) {
                    String item = widget.dropdownItems![index];
                    bool isSelected = item == _selectedDropdownItem;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDropdownItem = item;
                          _isDropdownOpen = false;
                          if (widget.onDropdownChanged != null) {
                            widget.onDropdownChanged!(_selectedDropdownItem);
                          }
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 15.h,
                          horizontal: 20.w,
                        ),
                        color: isSelected
                            ? const Color(0XFFDDE4DE)
                            : Colors.transparent,
                        child: Text(
                          item,
                          textAlign: TextAlign.right,
                          style: TextStyles.font16Weight400Text().copyWith(
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
