import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/employee/domain/entities/advance_entity.dart';
import 'package:tahsel/features/employee/domain/entities/employee_entity.dart';
import 'package:tahsel/features/employee/domain/entities/payroll_entity.dart';
import 'package:tahsel/features/employee/domain/utils/monthly_payroll_calculator.dart';

class PaySalaryDialog extends StatefulWidget {
  final EmployeeEntity employee;
  final Function(PayrollEntity, List<String>) onPay;
  final double? initialBaseSalary;
  final double? initialOvertimeHours;
  final double? initialOvertimeRate;
  final double? initialDeductions;
  final double? initialAllowances;
  final List<AdvanceEntity> paidAdvances;
  final List<String> paidMonthKeys;

  const PaySalaryDialog({
    super.key,
    required this.employee,
    required this.onPay,
    this.initialBaseSalary,
    this.initialOvertimeHours,
    this.initialOvertimeRate,
    this.initialDeductions,
    this.initialAllowances,
    this.paidAdvances = const [],
    this.paidMonthKeys = const [],
  });

  @override
  State<PaySalaryDialog> createState() => _PaySalaryDialogState();
}

class _PaySalaryDialogState extends State<PaySalaryDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _baseSalaryController;
  late TextEditingController _overtimeHoursController;
  late TextEditingController _overtimeRateController;
  late TextEditingController _allowancesController;
  late TextEditingController _deductionsController;
  late TextEditingController _notesController;

  late DateTime _paymentDate;
  double _netSalary = 0.0;
  late Set<String> _selectedAdvanceIds;

  bool get _isMonthAlreadyPaid {
    final String currentMonthKey = DateFormat('yyyy-MM').format(_paymentDate);
    return widget.paidMonthKeys.contains(currentMonthKey);
  }

  @override
  void initState() {
    super.initState();
    _baseSalaryController = TextEditingController(
      text: (widget.initialBaseSalary ?? widget.employee.salaryAmount)
          .toStringAsFixed(2),
    );
    _overtimeHoursController = TextEditingController(
      text: (widget.initialOvertimeHours ?? 0.0).toStringAsFixed(2),
    );

    // Estimate overtime hourly rate based on type.
    // Monthly employees use a FIXED 30-day salary contract.
    double defaultOvertimeRate = 10.0;
    if (widget.employee.customOvertimeRate != null) {
      defaultOvertimeRate = widget.employee.customOvertimeRate!;
    } else {
      final double baseAmount = widget.employee.salaryAmount;
      const int fixedMonthDays = 30;
      final double dailyHours = widget.employee.expectedDailyHours;
      final double otMultiplier = widget.employee.overtimeMultiplier;

      if (widget.employee.salaryType == 'monthly') {
        defaultOvertimeRate =
            baseAmount / (fixedMonthDays * dailyHours) * otMultiplier;
      } else if (widget.employee.salaryType == 'daily') {
        defaultOvertimeRate = baseAmount / dailyHours * otMultiplier;
      } else {
        defaultOvertimeRate = baseAmount * otMultiplier;
      }
    }
    _overtimeRateController = TextEditingController(
      text: (widget.initialOvertimeRate ?? defaultOvertimeRate).toStringAsFixed(
        2,
      ),
    );

    _allowancesController = TextEditingController(
      text: (widget.initialAllowances ?? 0.0).toStringAsFixed(2),
    );
    _deductionsController = TextEditingController(
      text: (widget.initialDeductions ?? 0.0).toStringAsFixed(2),
    );
    _notesController = TextEditingController();
    _paymentDate = DateTime.now();

    _selectedAdvanceIds = widget.paidAdvances
        .map((adv) => adv.id)
        .whereType<String>()
        .toSet();

    _calculateNetSalary();

    // Listeners for real-time recalculations
    _baseSalaryController.addListener(_calculateNetSalary);
    _overtimeHoursController.addListener(_calculateNetSalary);
    _overtimeRateController.addListener(_calculateNetSalary);
    _allowancesController.addListener(_calculateNetSalary);
    _deductionsController.addListener(_calculateNetSalary);
  }

  @override
  void dispose() {
    _baseSalaryController.dispose();
    _overtimeHoursController.dispose();
    _overtimeRateController.dispose();
    _allowancesController.dispose();
    _deductionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateNetSalary() {
    final double base = double.tryParse(_baseSalaryController.text) ?? 0.0;
    final double otHours = widget.employee.salaryType == 'hourly'
        ? 0.0
        : (double.tryParse(_overtimeHoursController.text) ?? 0.0);
    final double otRate = widget.employee.salaryType == 'hourly'
        ? 0.0
        : (double.tryParse(_overtimeRateController.text) ?? 0.0);
    final double allow = double.tryParse(_allowancesController.text) ?? 0.0;
    final double deduct = double.tryParse(_deductionsController.text) ?? 0.0;

    double advancesDeduction = 0.0;
    for (final adv in widget.paidAdvances) {
      if (adv.id != null && _selectedAdvanceIds.contains(adv.id)) {
        advancesDeduction += adv.amount;
      }
    }

    setState(() {
      final gross = base + (otHours * otRate) + allow;
      final totalDeductions =
          deduct + advancesDeduction + widget.employee.outstandingBalance;
      _netSalary = gross - totalDeductions;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final dateFormatter = DateFormat('yyyy-MM-dd');

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
                        AppStrings.paySalary.tr(),
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

                  // Employee Summary
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.veryLightGrey,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.employee.name,
                              style: TextStyles.customStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blackReal,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              "${widget.employee.role} • ${_getSalaryTypeTranslation(widget.employee.salaryType)}",
                              style: TextStyles.customStyle(
                                fontSize: 13,
                                color: AppColors.sandText,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "${widget.employee.salaryAmount.toStringAsFixed(2)} / ${_getSalaryTypeTranslation(widget.employee.salaryType)}",
                          style: TextStyles.customStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.employee.salaryType == 'monthly') ...[
                    SizedBox(height: 8.h),
                    Builder(
                      builder: (context) {
                        final period =
                            MonthlyPayrollCalculator.getPayrollPeriod(
                              closingDay: widget.employee.payrollClosingDay,
                            );
                        final fmt = DateFormat('yyyy-MM-dd');
                        return Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.date_range_rounded,
                                size: 14,
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  AppStrings.payrollPeriodRange.tr(
                                    namedArgs: {
                                      'start': fmt.format(period.start),
                                      'end': fmt.format(period.end),
                                    },
                                  ),
                                  style: TextStyles.customStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  SizedBox(height: isDesktop ? 20 : 16.h),

                  // Base Salary (Editable)
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
                    controller: _baseSalaryController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _buildInputDecoration(icon: Icons.money_sharp),
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
                  SizedBox(height: isDesktop ? 16 : 12.h),

                  if (widget.employee.salaryType != 'hourly') ...[
                    // Overtime Hours & Rate Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.overtimeHours.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              TextFormField(
                                cursorColor: AppColors.primaryColor,
                                controller: _overtimeHoursController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: _buildInputDecoration(),
                                style: TextStyles.customStyle(
                                  fontSize: 14,
                                  color: AppColors.blackReal,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return null;
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.overtimeRate.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              TextFormField(
                                cursorColor: AppColors.primaryColor,
                                controller: _overtimeRateController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: _buildInputDecoration(),
                                style: TextStyles.customStyle(
                                  fontSize: 14,
                                  color: AppColors.blackReal,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return null;
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
                      ],
                    ),
                    SizedBox(height: isDesktop ? 16 : 12.h),
                  ],

                  // Allowances & Deductions Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.allowances.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            TextFormField(
                              cursorColor: AppColors.primaryColor,
                              controller: _allowancesController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _buildInputDecoration(),
                              style: TextStyles.customStyle(
                                fontSize: 14,
                                color: AppColors.blackReal,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return null;
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.deduction.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            TextFormField(
                              cursorColor: AppColors.primaryColor,
                              controller: _deductionsController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _buildInputDecoration(),
                              style: TextStyles.customStyle(
                                fontSize: 14,
                                color: AppColors.blackReal,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return null;
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
                    ],
                  ),
                  SizedBox(height: isDesktop ? 16 : 12.h),

                  // Date Picker
                  Text(
                    AppStrings.paymentDate.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  InkWell(
                    borderRadius: BorderRadius.circular(10.r),
                    onTap: _pickDate,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.veryLightGrey),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateFormatter.format(_paymentDate),
                            style: TextStyles.customStyle(
                              fontSize: 14,
                              color: AppColors.blackReal,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.primaryColor,
                            size: 20,
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
                    decoration: _buildInputDecoration(
                      hintText: AppStrings.addTransactionNotesPlaceholder.tr(),
                    ),
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      color: AppColors.blackReal,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 16 : 12.h),

                  if (widget.paidAdvances.isNotEmpty) ...[
                    Text(
                      AppStrings.unpaidAdvancesDeduction.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh.withValues(
                          alpha: 0.5,
                        ),
                        border: Border.all(
                          color: AppColors.surfaceContainerHigh,
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Column(
                        children: widget.paidAdvances.map((advance) {
                          final isSelected = _selectedAdvanceIds.contains(
                            advance.id,
                          );
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                            ),
                            title: Text(
                              "${advance.amount.toStringAsFixed(2)} • ${DateFormat('yyyy-MM-dd').format(advance.date)}",
                              style: TextStyles.customStyle(
                                fontSize: 13,
                                color: AppColors.blackReal,
                              ),
                            ),
                            subtitle: advance.notes.isNotEmpty
                                ? Text(
                                    advance.notes,
                                    style: TextStyles.customStyle(
                                      fontSize: 11,
                                      color: AppColors.blackLight,
                                    ),
                                  )
                                : null,
                            value: isSelected,
                            activeColor: AppColors.primaryColor,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  if (advance.id != null) {
                                    _selectedAdvanceIds.add(advance.id!);
                                  }
                                } else {
                                  _selectedAdvanceIds.remove(advance.id);
                                }
                                _calculateNetSalary();
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: isDesktop ? 20 : 16.h),
                  ],

                  // Net Salary Display Card (Stunning design)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryColor, AppColors.sandText],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.netSalary.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _netSalary < 0
                                  ? "0.00"
                                  : _netSalary.toSmartAmount(),
                              style: TextStyles.customStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (_netSalary < 0) ...[
                          SizedBox(height: 12.h),
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: AppColors.errorText,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        AppStrings.deductionsExceedPayable.tr(),
                                        style: TextStyles.customStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.errorText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  '${AppStrings.outstandingBalance.tr()}: ${_netSalary.abs().toSmartAmount()}\n${AppStrings.carriedForwardAutomatically.tr()}',
                                  style: TextStyles.customStyle(
                                    fontSize: 11,
                                    color: AppColors.errorText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_isMonthAlreadyPaid) ...[
                    SizedBox(height: isDesktop ? 12 : 12.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isDesktop ? 12 : 12.w),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.errorText,
                            size: 24,
                          ),
                          SizedBox(width: isDesktop ? 12 : 12.w),
                          Expanded(
                            child: Text(
                              AppStrings.payrollAlreadyPaidForMonth.tr(
                                namedArgs: {
                                  'month': DateFormat(
                                    'yyyy-MM',
                                  ).format(_paymentDate),
                                },
                              ),
                              style: TextStyles.customStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.errorText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: isDesktop ? 24 : 20.h),

                  // Submit Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: Text(
                            AppStrings.cancel.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blackLight,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isMonthAlreadyPaid ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            AppStrings.confirm.tr(),
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

  InputDecoration _buildInputDecoration({String? hintText, IconData? icon}) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyles.customStyle(
        fontSize: isDesktop ? 13 : 13.sp,
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

  Future<void> _pickDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: AppColors.isDark
                ? ColorScheme.dark(primary: AppColors.primaryColor)
                : ColorScheme.light(
                    primary: AppColors.primaryColor,
                    onPrimary: AppColors.white,
                    onSurface: AppColors.black,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _paymentDate = date;
      });
    }
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final double base = double.parse(_baseSalaryController.text);
      final double otHours = widget.employee.salaryType == 'hourly'
          ? 0.0
          : (double.tryParse(_overtimeHoursController.text) ?? 0.0);
      final double otRate = widget.employee.salaryType == 'hourly'
          ? 0.0
          : (double.tryParse(_overtimeRateController.text) ?? 0.0);
      final double allow = double.tryParse(_allowancesController.text) ?? 0.0;
      final double deduct = double.tryParse(_deductionsController.text) ?? 0.0;

      double advancesDeduction = 0.0;
      for (final adv in widget.paidAdvances) {
        if (adv.id != null && _selectedAdvanceIds.contains(adv.id)) {
          advancesDeduction += adv.amount;
        }
      }

      double actualPaid = _netSalary;
      double carriedForward = 0.0;
      if (_netSalary < 0) {
        actualPaid = 0.0;
        carriedForward = _netSalary.abs();
      }

      final payroll = PayrollEntity(
        uid: widget.employee.uid,
        employeeId: widget.employee.id!,
        employeeName: widget.employee.name,
        paymentDate: _paymentDate,
        amount: base,
        bonus: allow,
        deduction:
            deduct + advancesDeduction + widget.employee.outstandingBalance,
        overtimeCompensation: otHours * otRate,
        netSalary: actualPaid, // only actual paid
        carriedForwardBalance: carriedForward,
        monthKey: DateFormat('yyyy-MM').format(_paymentDate),
        notes: _notesController.text.trim(),
        salaryType: widget.employee.salaryType,
      );

      widget.onPay(payroll, _selectedAdvanceIds.toList());
      Navigator.pop(context);
    }
  }
}
