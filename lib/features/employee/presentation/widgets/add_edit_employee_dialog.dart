import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/employee/domain/entities/employee_entity.dart';

class AddEditEmployeeDialog extends StatefulWidget {
  final EmployeeEntity? employee;
  final Function(EmployeeEntity) onSave;

  const AddEditEmployeeDialog({super.key, this.employee, required this.onSave});

  @override
  State<AddEditEmployeeDialog> createState() => _AddEditEmployeeDialogState();
}

class _AddEditEmployeeDialogState extends State<AddEditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _roleController;
  late TextEditingController _salaryAmountController;
  late TextEditingController _notesController;
  late TextEditingController _allowedPaidWeekendsController;
  late TextEditingController _dailyDeductionMultiplierController;
  late TextEditingController _expectedHoursController;
  late TextEditingController _overtimeMultiplierController;
  late TextEditingController _customOvertimeRateController;
  late TextEditingController _customDeductionRateController;
  late TextEditingController _paymentWindowStartController;
  late TextEditingController _paymentWindowEndController;
  late TextEditingController _payrollClosingDayController;

  String _salaryType = 'monthly';
  String _status = 'active';

  final List<String> _salaryTypes = ['monthly', 'daily', 'hourly'];
  final List<String> _statuses = ['active', 'inactive', 'suspended'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.employee?.phone ?? '',
    );
    _roleController = TextEditingController(text: widget.employee?.role ?? '');
    _salaryAmountController = TextEditingController(
      text: widget.employee != null
          ? widget.employee!.salaryAmount.toStringAsFixed(2)
          : '',
    );
    _notesController = TextEditingController(
      text: widget.employee?.notes ?? '',
    );
    _salaryType = widget.employee?.salaryType ?? 'monthly';
    _status = widget.employee?.status ?? 'active';

    _allowedPaidWeekendsController = TextEditingController(
      text: widget.employee != null
          ? widget.employee!.allowedPaidWeekendsPerMonth.toString()
          : '4',
    );
    _dailyDeductionMultiplierController = TextEditingController(
      text: widget.employee != null
          ? widget.employee!.dailyDeductionMultiplier.toString()
          : '1.0',
    );
    _expectedHoursController = TextEditingController(
      text: widget.employee != null
          ? widget.employee!.expectedDailyHours.toString()
          : '8.0',
    );
    _overtimeMultiplierController = TextEditingController(
      text: widget.employee != null
          ? widget.employee!.overtimeMultiplier.toString()
          : '1.5',
    );
    _customOvertimeRateController = TextEditingController(
      text: widget.employee?.customOvertimeRate?.toString() ?? '',
    );
    _customDeductionRateController = TextEditingController(
      text: widget.employee?.customDeductionRate?.toString() ?? '',
    );
    _paymentWindowStartController = TextEditingController(
      text: widget.employee != null
          ? widget.employee!.paymentWindowStart.toString()
          : '1',
    );
    _paymentWindowEndController = TextEditingController(
      text: widget.employee != null
          ? widget.employee!.paymentWindowEnd.toString()
          : '28',
    );
    _payrollClosingDayController = TextEditingController(
      text: widget.employee != null
          ? widget.employee!.payrollClosingDay.toString()
          : '25',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _salaryAmountController.dispose();
    _notesController.dispose();
    _allowedPaidWeekendsController.dispose();
    _dailyDeductionMultiplierController.dispose();
    _expectedHoursController.dispose();
    _overtimeMultiplierController.dispose();
    _customOvertimeRateController.dispose();
    _customDeductionRateController.dispose();
    _paymentWindowStartController.dispose();
    _paymentWindowEndController.dispose();
    _payrollClosingDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 20.r),
      ),
      backgroundColor: AppColors.scafoldBackGround,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 500 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 20.w,
              vertical: isDesktop ? 24 : 20.h,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (widget.employee == null
                                ? AppStrings.addEmployee
                                : AppStrings.editEmployee)
                            .tr(),
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: AppColors.blackLight,
                      ),
                    ],
                  ),
                  const Divider(),
                  SizedBox(height: isDesktop ? 16 : 12.h),

                  // Name
                  Text(
                    AppStrings.employeeName.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  TextFormField(
                    cursorColor: AppColors.primaryColor,
                    controller: _nameController,
                    decoration: _buildInputDecoration(
                      hintText: AppStrings.employeeNamePlaceholder.tr(),
                      icon: Icons.person_rounded,
                    ),
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      color: AppColors.blackReal,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return AppStrings.requiredField.tr();
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isDesktop ? 16 : 12.h),

                  // Phone
                  Text(
                    AppStrings.phone.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  TextFormField(
                    cursorColor: AppColors.primaryColor,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _buildInputDecoration(
                      hintText: AppStrings.employeePhonePlaceholder.tr(),
                      icon: Icons.phone_android_rounded,
                    ),
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      color: AppColors.blackReal,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return AppStrings.requiredField.tr();
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isDesktop ? 16 : 12.h),

                  // Role
                  Text(
                    AppStrings.employeeRole.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  TextFormField(
                    cursorColor: AppColors.primaryColor,
                    controller: _roleController,
                    decoration: _buildInputDecoration(
                      hintText: AppStrings.employeeRolePlaceholder.tr(),
                      icon: Icons.work_rounded,
                    ),
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      color: AppColors.blackReal,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return AppStrings.requiredField.tr();
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isDesktop ? 16 : 12.h),

                  Row(
                    children: [
                      // Salary Amount
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.baseSalary.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            TextFormField(
                              cursorColor: AppColors.primaryColor,
                              controller: _salaryAmountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _buildInputDecoration(
                                hintText: "0.00",
                                icon: Icons.money_sharp,
                              ),
                              style: TextStyles.customStyle(
                                fontSize: 14,
                                color: AppColors.blackReal,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return AppStrings.requiredField.tr();
                                }
                                if (double.tryParse(val) == null ||
                                    double.parse(val) < 0) {
                                  return AppStrings.invalidValue.tr();
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // Salary Type
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.debtType.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _salaryType,
                              decoration: _buildInputDecoration(),
                              dropdownColor: AppColors.whiteColor,
                              style: TextStyles.customStyle(
                                fontSize: 14,
                                color: AppColors.blackReal,
                              ),
                              items: _salaryTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    _getSalaryTypeTranslation(type),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _salaryType = val;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 16 : 12.h),

                  // Status
                  Text(
                    AppStrings.employeeStatus.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _status,
                    decoration: _buildInputDecoration(
                      icon: Icons.info_outline_rounded,
                    ),
                    dropdownColor: AppColors.whiteColor,
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      color: AppColors.blackReal,
                    ),
                    items: _statuses.map((st) {
                      return DropdownMenuItem(
                        value: st,
                        child: Text(
                          _getStatusTranslation(st),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _status = val;
                        });
                      }
                    },
                  ),
                  SizedBox(height: isDesktop ? 16 : 12.h),

                  // Calculation settings section
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      side: BorderSide(color: AppColors.surfaceContainerHigh),
                    ),
                    color: AppColors.surfaceContainerHigh.withValues(
                      alpha: 0.1,
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        collapsedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          side: BorderSide(
                            color: AppColors.surfaceContainerHigh,
                          ),
                        ),
                        iconColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          side: BorderSide(
                            color: AppColors.surfaceContainerHigh,
                          ),
                        ),
                        title: Text(
                          AppStrings.calculateNetSalary.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        leading: Icon(
                          Icons.settings_applications,
                          color: AppColors.primaryColor,
                        ),
                        childrenPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        children: [
                          if (_salaryType != 'hourly') ...[
                            if (_salaryType == 'monthly') ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppStrings.allowedPaidWeekendsPerMonth
                                              .tr(),
                                          style: TextStyles.customStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        TextFormField(
                                          cursorColor: AppColors.primaryColor,
                                          controller:
                                              _allowedPaidWeekendsController,
                                          keyboardType: TextInputType.number,
                                          decoration: _buildInputDecoration(
                                            hintText: '4',
                                          ),
                                          style: TextStyles.customStyle(
                                            fontSize: 13,
                                          ),
                                          validator: (val) {
                                            if (_salaryType != 'monthly') {
                                              return null;
                                            }
                                            if (val == null ||
                                                val.trim().isEmpty) {
                                              return AppStrings.requiredField
                                                  .tr();
                                            }
                                            final numVal = int.tryParse(val);
                                            if (numVal == null ||
                                                numVal < 0 ||
                                                numVal > 28) {
                                              return "${AppStrings.invalidValue.tr()} (1 - 28)";
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppStrings.dailyDeductionMultiplier
                                              .tr(),
                                          style: TextStyles.customStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        TextFormField(
                                          cursorColor: AppColors.primaryColor,
                                          controller:
                                              _dailyDeductionMultiplierController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: _buildInputDecoration(
                                            hintText: '1.0',
                                          ),
                                          style: TextStyles.customStyle(
                                            fontSize: 13,
                                          ),
                                          validator: (val) {
                                            if (_salaryType != 'monthly') {
                                              return null;
                                            }
                                            if (val == null ||
                                                val.trim().isEmpty) {
                                              return AppStrings.requiredField
                                                  .tr();
                                            }
                                            final numVal = double.tryParse(val);
                                            if (numVal == null || numVal < 0) {
                                              return AppStrings.invalidValue
                                                  .tr();
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppStrings.payrollClosingDay.tr(),
                                          style: TextStyles.customStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        TextFormField(
                                          cursorColor: AppColors.primaryColor,
                                          controller:
                                              _payrollClosingDayController,
                                          keyboardType: TextInputType.number,
                                          decoration: _buildInputDecoration(
                                            hintText: '25',
                                          ),
                                          style: TextStyles.customStyle(
                                            fontSize: 13,
                                          ),
                                          validator: (val) {
                                            if (_salaryType != 'monthly') {
                                              return null;
                                            }
                                            if (val == null ||
                                                val.trim().isEmpty) {
                                              return AppStrings.requiredField
                                                  .tr();
                                            }
                                            final numVal = int.tryParse(val);
                                            if (numVal == null ||
                                                numVal < 1 ||
                                                numVal > 28) {
                                              return AppStrings
                                                  .invalidPayrollClosingDay
                                                  .tr();
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  const Expanded(child: SizedBox()),
                                ],
                              ),
                              SizedBox(height: 12.h),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.expectedDailyHours.tr(),
                                        style: TextStyles.customStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      TextFormField(
                                        cursorColor: AppColors.primaryColor,
                                        controller: _expectedHoursController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: _buildInputDecoration(
                                          hintText: '8.0',
                                        ),
                                        style: TextStyles.customStyle(
                                          fontSize: 13,
                                        ),
                                        validator: (val) {
                                          if (_salaryType == 'hourly') {
                                            return null;
                                          }
                                          if (val == null ||
                                              val.trim().isEmpty) {
                                            return AppStrings.requiredField
                                                .tr();
                                          }
                                          final numVal = double.tryParse(val);
                                          if (numVal == null || numVal <= 0) {
                                            return AppStrings.invalidValue.tr();
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.overtimeMultiplier.tr(),
                                        style: TextStyles.customStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      TextFormField(
                                        cursorColor: AppColors.primaryColor,
                                        controller:
                                            _overtimeMultiplierController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: _buildInputDecoration(
                                          hintText: '1.5',
                                        ),
                                        style: TextStyles.customStyle(
                                          fontSize: 13,
                                        ),
                                        validator: (val) {
                                          if (_salaryType == 'hourly') {
                                            return null;
                                          }
                                          if (val == null ||
                                              val.trim().isEmpty) {
                                            return AppStrings.requiredField
                                                .tr();
                                          }
                                          final numVal = double.tryParse(val);
                                          if (numVal == null || numVal < 0) {
                                            return AppStrings.invalidValue.tr();
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.customOvertimeRate.tr(),
                                        style: TextStyles.customStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      TextFormField(
                                        cursorColor: AppColors.primaryColor,
                                        controller:
                                            _customOvertimeRateController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: _buildInputDecoration(
                                          hintText:
                                              '${AppStrings.optional.tr()} (e.g. 50)',
                                        ),
                                        style: TextStyles.customStyle(
                                          fontSize: 13,
                                        ),
                                        validator: (val) {
                                          if (_salaryType == 'hourly') {
                                            return null;
                                          }
                                          if (val != null &&
                                              val.trim().isNotEmpty) {
                                            final numVal = double.tryParse(val);
                                            if (numVal == null || numVal < 0) {
                                              return AppStrings.invalidValue
                                                  .tr();
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.customDeductionRate.tr(),
                                        style: TextStyles.customStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      TextFormField(
                                        cursorColor: AppColors.primaryColor,
                                        controller:
                                            _customDeductionRateController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: _buildInputDecoration(
                                          hintText:
                                              '${AppStrings.optional.tr()} (e.g. 40)',
                                        ),
                                        style: TextStyles.customStyle(
                                          fontSize: 13,
                                        ),
                                        validator: (val) {
                                          if (_salaryType == 'hourly') {
                                            return null;
                                          }
                                          if (val != null &&
                                              val.trim().isNotEmpty) {
                                            final numVal = double.tryParse(val);
                                            if (numVal == null || numVal < 0) {
                                              return AppStrings.invalidValue
                                                  .tr();
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 12.h),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.paymentWindowStart.tr(),
                                      style: TextStyles.customStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    TextFormField(
                                      cursorColor: AppColors.primaryColor,
                                      controller: _paymentWindowStartController,
                                      keyboardType: TextInputType.number,
                                      decoration: _buildInputDecoration(
                                        hintText: '1',
                                      ),
                                      style: TextStyles.customStyle(
                                        fontSize: 13,
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return AppStrings.requiredField.tr();
                                        }
                                        final numVal = int.tryParse(val);
                                        if (numVal == null ||
                                            numVal < 1 ||
                                            numVal > 28) {
                                          return AppStrings
                                              .invalidPaymentWindowDay
                                              .tr();
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.paymentWindowEnd.tr(),
                                      style: TextStyles.customStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    TextFormField(
                                      cursorColor: AppColors.primaryColor,
                                      controller: _paymentWindowEndController,
                                      keyboardType: TextInputType.number,
                                      decoration: _buildInputDecoration(
                                        hintText: '28',
                                      ),
                                      style: TextStyles.customStyle(
                                        fontSize: 13,
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return AppStrings.requiredField.tr();
                                        }
                                        final numVal = int.tryParse(val);
                                        if (numVal == null ||
                                            numVal < 1 ||
                                            numVal > 28) {
                                          return AppStrings
                                              .invalidPaymentWindowDay
                                              .tr();
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isDesktop ? 16 : 12.h),

                  // Notes
                  Text(
                    AppStrings.notes.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  TextFormField(
                    cursorColor: AppColors.primaryColor,
                    controller: _notesController,
                    maxLines: 3,
                    decoration: _buildInputDecoration(
                      hintText: AppStrings.employeeNotesPlaceholder.tr(),
                    ),
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      color: AppColors.blackReal,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 24 : 20.h),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: isDesktop ? 50 : 44.h,
                    child: ElevatedButton(
                      onPressed: _saveForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        AppStrings.confirm.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({String? hintText, IconData? icon}) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyles.customStyle(
        fontSize: 13,
        color: AppColors.blackLight.withValues(alpha: 0.6),
      ),
      prefixIcon: icon != null
          ? Icon(icon, color: AppColors.primaryColor, size: 20)
          : null,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 16.w,
        vertical: isDesktop ? 12 : 12.h,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: AppColors.surfaceContainerHigh),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: AppColors.surfaceContainerHigh),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  String _getSalaryTypeTranslation(String type) {
    switch (type) {
      case 'monthly':
        return AppStrings.monthly.tr();
      case 'daily':
        return AppStrings.daily.tr();
      case 'hourly':
        return AppStrings.hourly.tr();
      default:
        return type.tr();
    }
  }

  String _getStatusTranslation(String status) {
    switch (status) {
      case 'active':
        return AppStrings.active.tr();
      case 'inactive':
        return AppStrings.inactive.tr();
      case 'suspended':
        return AppStrings.suspended.tr();
      default:
        return status.tr();
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final employee = EmployeeEntity(
        id: widget.employee?.id,
        uid: widget.employee?.uid ?? AppStrings.userToken,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _roleController.text.trim(),
        salaryType: _salaryType,
        salaryAmount: double.parse(_salaryAmountController.text),
        status: _status,
        createdAt: widget.employee?.createdAt ?? DateTime.now(),
        notes: _notesController.text.trim(),
        expectedDailyHours:
            double.tryParse(_expectedHoursController.text) ?? 8.0,
        overtimeMultiplier:
            double.tryParse(_overtimeMultiplierController.text) ?? 1.5,
        customOvertimeRate: _customOvertimeRateController.text.trim().isNotEmpty
            ? double.tryParse(_customOvertimeRateController.text)
            : null,
        customDeductionRate:
            _customDeductionRateController.text.trim().isNotEmpty
            ? double.tryParse(_customDeductionRateController.text)
            : null,
        paymentWindowStart:
            int.tryParse(_paymentWindowStartController.text) ?? 1,
        paymentWindowEnd: int.tryParse(_paymentWindowEndController.text) ?? 28,
        outstandingBalance: widget.employee?.outstandingBalance ?? 0.0,
        allowedPaidWeekendsPerMonth:
            int.tryParse(_allowedPaidWeekendsController.text) ?? 4,
        dailyDeductionMultiplier:
            double.tryParse(_dailyDeductionMultiplierController.text) ?? 1.0,
        payrollClosingDay: _salaryType == 'monthly'
            ? (int.tryParse(_payrollClosingDayController.text) ?? 25)
            : 25,
      );
      widget.onSave(employee);
      Navigator.pop(context);
    }
  }
}
