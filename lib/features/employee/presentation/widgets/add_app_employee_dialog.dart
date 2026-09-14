import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/permission_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

import '../cubit/team_management_cubit.dart';
import '../screens/add_app_employee_screen.dart';

class AddAppEmployeeDialog extends StatefulWidget {
  final TeamManagementCubit cubit;

  const AddAppEmployeeDialog({super.key, required this.cubit});

  static Future<void> show(BuildContext context, TeamManagementCubit cubit) {
    return AddAppEmployeeScreen.push(context, cubit);
  }

  @override
  State<AddAppEmployeeDialog> createState() => _AddAppEmployeeDialogState();
}

class _AddAppEmployeeDialogState extends State<AddAppEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedPreset = AppPermissions.roleCashier;
  final Set<String> _selectedPermissions = {};

  @override
  void initState() {
    super.initState();
    _applyPreset(AppPermissions.roleCashier);
  }

  void _applyPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset != AppPermissions.roleCustom) {
        _selectedPermissions.clear();
        final presetPerms = AppPermissions.permissionsForPreset(preset);
        if (PermissionService.instance.isOwner) {
          _selectedPermissions.addAll(presetPerms);
        } else {
          _selectedPermissions.addAll(
            presetPerms.where(
              (p) =>
                  p != AppPermissions.employeesManageAppUsers &&
                  PermissionService.instance.hasPermission(p),
            ),
          );
        }
      }
    });
  }

  void _togglePermission(String key) {
    if (!PermissionService.instance.isOwner) {
      if (key == AppPermissions.employeesManageAppUsers ||
          !PermissionService.instance.hasPermission(key)) {
        return;
      }
    }
    setState(() {
      if (_selectedPermissions.contains(key)) {
        _selectedPermissions.remove(key);
      } else {
        _selectedPermissions.add(key);
      }
      _selectedPreset = AppPermissions.roleCustom;
    });
  }

  void _selectAll() {
    setState(() {
      final isOwner = PermissionService.instance.isOwner;
      final myPerms = PermissionService.instance.permissions;
      for (final group in AppPermissions.allGroups) {
        for (final item in group.items) {
          if (!isOwner) {
            if (item.key == AppPermissions.employeesManageAppUsers) continue;
            if (!myPerms.contains(item.key)) continue;
          }
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
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPermissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.selectAtLeastOnePermission.tr(),
            style: TextStyles.customStyle(color: AppColors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await widget.cubit.addEmployee(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      password: _passwordController.text.trim(),
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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Dialog(
      backgroundColor: AppColors.scafoldBackGround,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 16.w,
        vertical: isDesktop ? 24 : 24.h,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: isDesktop ? 1000 : 750.h,
        ),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 20 : 20.r),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_add_alt_1_rounded,
                                color: AppColors.primaryColor,
                                size: isDesktop ? 24 : 14,
                              ),
                            ),
                            SizedBox(width: isDesktop ? 10 : 10.w),
                            Expanded(
                              child: Text(
                                AppStrings.addAppEmployee.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: isDesktop ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(
                    height: isDesktop ? 20 : 20.h,
                    color: AppColors.lightGreyColor,
                  ),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText:
                                  '${AppStrings.employeeNameField.tr()} *',
                              hintText: AppStrings.employeeNameHint.tr(),
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return AppStrings.employeeNameRequired.tr();
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isDesktop ? 12 : 12.h),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: '${AppStrings.employeeEmail.tr()} *',
                              hintText: 'employee@example.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return AppStrings.employeeEmailRequired.tr();
                              }
                              if (!val.trim().isValidEmail()) {
                                return AppStrings.emailFormatInvalid.tr();
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isDesktop ? 12 : 12.h),

                          // Temporary Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText:
                                  '${AppStrings.temporaryPassword.tr()} *',
                              hintText: AppStrings.passwordMinLengthHint.tr(),
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return AppStrings.passwordRequired.tr();
                              }
                              if (val.trim().length < 6) {
                                return AppStrings.passwordMin6Chars.tr();
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isDesktop ? 16 : 16.h),

                          // Role Presets Header & Chips
                          Text(
                            AppStrings.rolePreset.tr(),
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 14 : 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          SizedBox(height: isDesktop ? 8 : 8.h),
                          Wrap(
                            spacing: isDesktop ? 12 : 8.w,
                            runSpacing: isDesktop ? 12 : 8.h,
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
                          SizedBox(height: isDesktop ? 16 : 16.h),

                          // Granular Permissions Selection
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 6.h,
                            children: [
                              Text(
                                '${AppStrings.grantedPermissions.tr()} (${_selectedPermissions.length})',
                                style: TextStyles.customStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: _selectAll,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isDesktop ? 12 : 8.w,
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
                                        horizontal: isDesktop ? 12 : 8.w,
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
                          SizedBox(height: isDesktop ? 8 : 8.h),

                          // Permission Groups Accordion
                          ...AppPermissions.allGroups
                              .where((group) {
                                if (PermissionService.instance.isOwner) {
                                  return true;
                                }
                                return group.items.any(
                                  (item) =>
                                      item.key !=
                                          AppPermissions
                                              .employeesManageAppUsers &&
                                      PermissionService.instance.hasPermission(
                                        item.key,
                                      ),
                                );
                              })
                              .map((group) {
                                final visibleItems = group.items.where((item) {
                                  if (PermissionService.instance.isOwner) {
                                    return true;
                                  }
                                  return item.key !=
                                          AppPermissions
                                              .employeesManageAppUsers &&
                                      PermissionService.instance.hasPermission(
                                        item.key,
                                      );
                                }).toList();
                                final groupItemsCount = visibleItems.length;
                                final activeInGroup = visibleItems
                                    .where(
                                      (item) => _selectedPermissions.contains(
                                        item.key,
                                      ),
                                    )
                                    .length;

                                return Container(
                                  margin: EdgeInsets.only(
                                    bottom: isDesktop ? 8 : 8.h,
                                  ),
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
                                    data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent,
                                    ),
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
                                        group.titleKey.tr(),
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
                                      children: visibleItems.map((item) {
                                        final isChecked = _selectedPermissions
                                            .contains(item.key);
                                        return CheckboxListTile(
                                          value: isChecked,
                                          onChanged: (_) =>
                                              _togglePermission(item.key),
                                          title: Text(
                                            item.labelKey.tr(),
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
                                          activeColor: AppColors.primaryColor,
                                          dense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: isDesktop ? 16 : 16.w,
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

                  SizedBox(height: isDesktop ? 16 : 16.h),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: isDesktop ? 12 : 12.h,
                            ),
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
                      SizedBox(width: isDesktop ? 12 : 12.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: EdgeInsets.symmetric(
                              vertical: isDesktop ? 12 : 12.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: isDesktop ? 20.h : 20.h,
                                  width: isDesktop ? 20.h : 20.h,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  AppStrings.saveAndActivateAccount.tr(),
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
