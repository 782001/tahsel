import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

import '../../data/models/app_employee_model.dart';
import '../cubit/team_management_cubit.dart';
import '../screens/edit_app_employee_screen.dart';

class EditAppEmployeeDialog extends StatefulWidget {
  final AppEmployeeModel employee;
  final TeamManagementCubit cubit;

  const EditAppEmployeeDialog({
    super.key,
    required this.employee,
    required this.cubit,
  });

  static Future<void> show(
    BuildContext context, {
    required AppEmployeeModel employee,
    required TeamManagementCubit cubit,
  }) {
    return EditAppEmployeeScreen.push(
      context,
      employee: employee,
      cubit: cubit,
    );
  }

  @override
  State<EditAppEmployeeDialog> createState() => _EditAppEmployeeDialogState();
}

class _EditAppEmployeeDialogState extends State<EditAppEmployeeDialog> {
  late String _selectedPreset;
  late final Set<String> _selectedPermissions;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.employee.rolePreset;
    _selectedPermissions = Set.from(widget.employee.permissions);
  }

  void _applyPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset != AppPermissions.roleCustom) {
        _selectedPermissions.clear();
        _selectedPermissions.addAll(
          AppPermissions.permissionsForPreset(preset),
        );
      }
    });
  }

  void _togglePermission(String key) {
    setState(() {
      if (_selectedPermissions.contains(key)) {
        _selectedPermissions.remove(key);
        final dependents = AppPermissions.getDependents(key);
        final removedDependents = dependents
            .where((d) => _selectedPermissions.contains(d))
            .toList();
        if (removedDependents.isNotEmpty) {
          _selectedPermissions.removeAll(dependents);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showDependencyToast(
              '${AppStrings.permAutoDisabledDependents.tr()}: ${removedDependents.map((k) => AppPermissions.getPermissionLabel(k)).join('، ')}',
              isWarning: true,
            );
          });
        }
      } else {
        _selectedPermissions.add(key);
        final prerequisites = AppPermissions.getPrerequisites(key);
        final addedPrerequisites = prerequisites
            .where((p) => !_selectedPermissions.contains(p))
            .toList();
        if (addedPrerequisites.isNotEmpty) {
          _selectedPermissions.addAll(prerequisites);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showDependencyToast(
              '${AppStrings.permAutoEnabledPrerequisites.tr()}: ${addedPrerequisites.map((k) => AppPermissions.getPermissionLabel(k)).join('، ')}',
            );
          });
        }
      }
      _selectedPreset = AppPermissions.roleCustom;
    });
  }

  void _showDependencyToast(String message, {bool isWarning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isWarning ? Icons.info_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyles.customStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isWarning
            ? Colors.orange.shade800
            : AppColors.primaryColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  void _selectAll() {
    setState(() {
      for (final group in AppPermissions.allGroups) {
        for (final item in group.items) {
          _selectedPermissions.add(item.key);
        }
      }
      _selectedPreset = AppPermissions.roleCustom;
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedPermissions.clear();
      _selectedPreset = AppPermissions.roleCustom;
    });
  }

  Future<void> _submit() async {
    if (_selectedPermissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.appEmployeeSelectAtLeastOnePermission.tr(),
            style: TextStyles.customStyle(color: AppColors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await widget.cubit.updatePermissions(
      employeeAuthUid: widget.employee.authUid,
      rolePreset: _selectedPreset,
      permissions: _selectedPermissions.toList(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = AppStrings.currentLang == AppStrings.arabicCode;

    return Dialog(
      backgroundColor: AppColors.scafoldBackGround,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600, maxHeight: 750.h),
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.editAppEmployee.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${widget.employee.name} (${widget.employee.email})',
                          style: TextStyles.customStyle(
                            fontSize: 12,
                            color: AppColors.sandText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(height: 20.h, color: AppColors.lightGreyColor),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Role Presets Header & Chips
                      Text(
                        AppStrings.rolePreset.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          _buildPresetChip(
                            AppPermissions.roleCashier,
                            AppStrings.roleCashierLabel.tr(),
                            Icons.point_of_sale_rounded,
                          ),
                          _buildPresetChip(
                            AppPermissions.roleStorekeeper,
                            AppStrings.roleStorekeeperLabel.tr(),
                            Icons.inventory_2_outlined,
                          ),
                          _buildPresetChip(
                            AppPermissions.roleAccountant,
                            AppStrings.roleAccountantLabel.tr(),
                            Icons.calculate_outlined,
                          ),
                          _buildPresetChip(
                            AppPermissions.roleSupervisor,
                            AppStrings.roleSupervisorLabel.tr(),
                            Icons.admin_panel_settings_outlined,
                          ),
                          _buildPresetChip(
                            AppPermissions.roleCustom,
                            AppStrings.roleCustomLabel.tr(),
                            Icons.tune_rounded,
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Granular Permissions Selection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppStrings.appEmployeeGrantedPermissions.tr()} (${_selectedPermissions.length})',
                            style: TextStyles.customStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: _selectAll,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                  ),
                                ),
                                child: Text(
                                  AppStrings.selectAll.tr(),
                                  style: TextStyles.customStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _deselectAll,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                  ),
                                ),
                                child: Text(
                                  AppStrings.deselectAll.tr(),
                                  style: TextStyles.customStyle(
                                    fontSize: 12,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),

                      // Permission Groups Accordion
                      ...AppPermissions.allGroups.map((group) {
                        final groupItemsCount = group.items.length;
                        final activeInGroup = group.items
                            .where(
                              (item) => _selectedPermissions.contains(item.key),
                            )
                            .length;

                        return Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: activeInGroup > 0
                                  ? AppColors.primaryColor.withValues(
                                      alpha: 0.3,
                                    )
                                  : AppColors.lightGreyColor,
                            ),
                          ),
                          child: Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              leading: Icon(
                                activeInGroup > 0
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: activeInGroup > 0
                                    ? AppColors.primaryColor
                                    : AppColors.disabledColor,
                                size: 20,
                              ),
                              title: Text(
                                isArabic ? group.titleAr : group.titleEn,
                                style: TextStyles.customStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                              subtitle: Text(
                                '$activeInGroup / $groupItemsCount ${AppStrings.permissionsCount.tr()}',
                                style: TextStyles.customStyle(
                                  fontSize: 11,
                                  color: activeInGroup > 0
                                      ? AppColors.primaryColor
                                      : AppColors.sandText,
                                ),
                              ),
                              children: group.items.map((item) {
                                final isChecked = _selectedPermissions.contains(
                                  item.key,
                                );
                                return CheckboxListTile(
                                  value: isChecked,
                                  onChanged: (_) => _togglePermission(item.key),
                                  title: Text(
                                    isArabic ? item.labelAr : item.labelEn,
                                    style: TextStyles.customStyle(
                                      fontSize: 13,
                                      fontWeight: isChecked
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isChecked
                                          ? AppColors.black
                                          : AppColors.blackLight,
                                    ),
                                  ),
                                  subtitle:
                                      AppPermissions.hasPrerequisites(item.key)
                                      ? Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.link_rounded,
                                                size: 13,
                                                color: AppColors.primaryColor
                                                    .withValues(alpha: 0.75),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  '${AppStrings.permRequiresPrefix.tr()}: ${AppPermissions.getPrerequisiteLabels(item.key)}',
                                                  style: TextStyles.customStyle(
                                                    fontSize: 10.5,
                                                    color: AppColors.sandText,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : null,
                                  activeColor: AppColors.primaryColor,
                                  dense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        AppStrings.cancel.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 14,
                          color: AppColors.sandText,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20.h,
                              width: 20.h,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              AppStrings.saveChanges.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String presetKey, String label, IconData icon) {
    final isSelected = _selectedPreset == presetKey;
    return ChoiceChip(
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : AppColors.primaryColor,
      ),
      label: Text(
        label,
        style: TextStyles.customStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.black,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primaryColor,
      backgroundColor: AppColors.surface,
      onSelected: (_) => _applyPreset(presetKey),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: BorderSide(
          color: isSelected ? AppColors.primaryColor : AppColors.lightGreyColor,
        ),
      ),
    );
  }
}
