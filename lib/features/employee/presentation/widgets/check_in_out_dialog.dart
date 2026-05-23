import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/config/locale/app_localizations.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/employee/domain/entities/attendance_entity.dart';
import 'package:tahsel/features/employee/domain/entities/employee_entity.dart';

class CheckInOutDialog extends StatefulWidget {
  final EmployeeEntity employee;
  final AttendanceEntity?
  activeAttendance; // If present, this is a CHECK-OUT action. Otherwise CHECK-IN.
  final double previousWorkedHoursToday;
  final double previousOvertimeToday;
  final double previousDeductionToday;
  final Function(AttendanceEntity) onCheckIn;
  final Function({
    required String attendanceId,
    required DateTime checkOutTime,
    required double overtimeHours,
    required double deductionHours,
    required int lateMinutes,
    required String status,
    required String notes,
  })
  onCheckOut;

  const CheckInOutDialog({
    super.key,
    required this.employee,
    this.activeAttendance,
    this.previousWorkedHoursToday = 0.0,
    this.previousOvertimeToday = 0.0,
    this.previousDeductionToday = 0.0,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  @override
  State<CheckInOutDialog> createState() => _CheckInOutDialogState();
}

class _CheckInOutDialogState extends State<CheckInOutDialog> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedTime;
  late TextEditingController _overtimeController;
  late TextEditingController _lateMinutesController;
  late TextEditingController _notesController;
  late TextEditingController _expectedHoursController;
  late TextEditingController _deductionsController;

  String _status = 'present';
  final List<String> _checkInStatuses = [
    'present',
    'late',
    'absent',
    'excused',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTime = DateTime.now();
    _overtimeController = TextEditingController(text: '0');
    _lateMinutesController = TextEditingController(text: '0');
    _notesController = TextEditingController();
    _expectedHoursController = TextEditingController(
      text: widget.employee.expectedDailyHours.toString(),
    );
    _deductionsController = TextEditingController(text: '0.0');

    if (widget.activeAttendance != null) {
      _status = 'present';
      _expectedHoursController.text = widget
          .activeAttendance!
          .expectedWorkingHours
          .toString();
      _calculateOvertimeAndDeductions();
    } else {
      _status = 'present';
    }
  }

  void _calculateOvertimeAndDeductions() {
    if (!_isCheckOut || widget.activeAttendance == null) return;
    final checkInTime = widget.activeAttendance!.checkIn;
    final checkOutTime = _selectedTime;
    final duration = checkOutTime.difference(checkInTime);
    final actualWorkedHours = duration.inMinutes / 60.0;

    if (widget.employee.salaryType == 'hourly') {
      _overtimeController.text = '0.0';
      _deductionsController.text = '0.0';
      return;
    }

    final expectedHours =
        double.tryParse(_expectedHoursController.text) ??
        widget.employee.expectedDailyHours;

    final totalWorkedToday = widget.previousWorkedHoursToday + actualWorkedHours;

    if (totalWorkedToday > expectedHours) {
      double totalOvertime = totalWorkedToday - expectedHours;
      double netOvertime = totalOvertime - widget.previousOvertimeToday;
      double netDeduction = 0.0 - widget.previousDeductionToday;
      
      _overtimeController.text = netOvertime.toStringAsFixed(2);
      _deductionsController.text = netDeduction.toStringAsFixed(2);
    } else if (totalWorkedToday < expectedHours) {
      double totalDeduction = expectedHours - totalWorkedToday;
      double netDeduction = totalDeduction - widget.previousDeductionToday;
      double netOvertime = 0.0 - widget.previousOvertimeToday;

      _overtimeController.text = netOvertime.toStringAsFixed(2);
      _deductionsController.text = netDeduction.toStringAsFixed(2);
    } else {
      double netOvertime = 0.0 - widget.previousOvertimeToday;
      double netDeduction = 0.0 - widget.previousDeductionToday;
      _overtimeController.text = netOvertime.toStringAsFixed(2);
      _deductionsController.text = netDeduction.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _overtimeController.dispose();
    _lateMinutesController.dispose();
    _notesController.dispose();
    _expectedHoursController.dispose();
    _deductionsController.dispose();
    super.dispose();
  }

  bool get _isCheckOut => widget.activeAttendance != null;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final localeCode = AppLocalizations.current?.locale.languageCode ?? 'ar';
    final timeFormatter = DateFormat('yyyy-MM-dd hh:mm a', localeCode);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 20.r),
      ),
      backgroundColor: AppColors.scafoldBackGround,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 450 : double.infinity,
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
                        (_isCheckOut
                                ? AppStrings.confirmCheckout
                                : AppStrings.checkIn)
                            .tr(),
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: _isCheckOut
                              ? AppColors.warning
                              : AppColors.success,
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

                  // Employee Info Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Column(
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
                          widget.employee.role,
                          style: TextStyles.customStyle(
                            fontSize: 13,
                            color: AppColors.sandText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isDesktop ? 20 : 16.h),

                  // Selected Date/Time Picker View
                  Text(
                    AppStrings.dateLabel.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  InkWell(
                    borderRadius: BorderRadius.circular(10.r),
                    onTap: _pickDateTime,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.surfaceContainerHigh,
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            timeFormatter.format(_selectedTime),
                            style: TextStyles.customStyle(
                              fontSize: 14,
                              color: AppColors.blackReal,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isDesktop ? 20 : 16.h),

                  if (!_isCheckOut) ...[
                    // Status for Check In
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
                      initialValue: _status,
                      decoration: _buildInputDecoration(
                        icon: Icons.info_outline_rounded,
                      ),
                      dropdownColor: AppColors.whiteColor,
                      style: TextStyles.customStyle(
                        fontSize: 14,
                        color: AppColors.blackReal,
                      ),
                      items: _checkInStatuses.map((st) {
                        return DropdownMenuItem(
                          value: st,
                          child: Text(_getAttendanceStatusTranslation(st)),
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
                    if (widget.employee.salaryType != 'hourly') ...[
                      SizedBox(height: isDesktop ? 20 : 16.h),
                      Text(
                        AppStrings.dailyWorkingHours.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      TextFormField(
                        cursorColor: AppColors.primaryColor,
                        controller: _expectedHoursController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: '8.0',
                          icon: Icons.access_time_rounded,
                        ),
                        style: TextStyles.customStyle(
                          fontSize: 14,
                          color: AppColors.blackReal,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return AppStrings.invalidValue.tr();
                          }
                          if (double.tryParse(val) == null ||
                              double.parse(val) <= 0) {
                            return AppStrings.invalidValue.tr();
                          }
                          return null;
                        },
                      ),
                    ],
                  ] else if (widget.employee.salaryType != 'hourly') ...[
                    // Check Out Inputs
                    Row(
                      children: [
                        // Overtime Hours
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
                                controller: _overtimeController,
                                readOnly: true, // Read Only
                                decoration: _buildInputDecoration(hintText: '0')
                                    .copyWith(
                                      fillColor: AppColors.surfaceContainerHigh,
                                      filled: true,
                                    ),
                                style: TextStyles.customStyle(
                                  fontSize: 14,
                                  color: AppColors.blackLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        // Deduction Hours
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.deductionHours
                                    .tr(), // Let's ensure this is in translation
                                style: TextStyles.customStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              TextFormField(
                                controller: _deductionsController,
                                readOnly: true, // Read Only
                                decoration: _buildInputDecoration(hintText: '0')
                                    .copyWith(
                                      fillColor: AppColors.surfaceContainerHigh,
                                      filled: true,
                                    ),
                                style: TextStyles.customStyle(
                                  fontSize: 14,
                                  color: AppColors.blackLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: isDesktop ? 20 : 16.h),

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
                      hintText: AppStrings.addNotesPlaceholder.tr(),
                    ),
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      color: AppColors.blackReal,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 28 : 24.h),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
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
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCheckOut
                                ? AppColors.warning
                                : AppColors.success,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
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
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyles.customStyle(
        fontSize: 13,
        color: AppColors.blackLight.withValues(alpha: 0.6),
      ),
      prefixIcon: icon != null
          ? Icon(icon, color: AppColors.primaryColor, size: 20)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedTime,
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
    if (date == null) return;

    if (!mounted) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
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
    if (time == null) return;

    setState(() {
      _selectedTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _calculateOvertimeAndDeductions();
    });
  }

  String _getAttendanceStatusTranslation(String status) {
    switch (status) {
      case 'present':
        return AppStrings.present.tr();
      case 'late':
        return AppStrings.late.tr();
      case 'absent':
        return AppStrings.absent.tr();
      case 'excused':
        return AppStrings.excused.tr();
      default:
        return status.tr();
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_isCheckOut) {
        widget.onCheckOut(
          attendanceId: widget.activeAttendance!.id!,
          checkOutTime: _selectedTime,
          overtimeHours: double.tryParse(_overtimeController.text) ?? 0.0,
          deductionHours: double.tryParse(_deductionsController.text) ?? 0.0,
          lateMinutes:
              0, // Late minutes logic deprecated / subsumed by deduction
          status: 'present',
          notes: _notesController.text.trim(),
        );
      } else {
        final checkInAttendance = AttendanceEntity(
          uid: widget.employee.uid,
          employeeId: widget.employee.id!,
          employeeName: widget.employee.name,
          checkIn: _selectedTime,
          checkOut: null,
          date: DateFormat('yyyy-MM-dd').format(_selectedTime),
          status: _status,
          overtimeHours: 0.0,
          deductionHours: 0.0,
          expectedWorkingHours:
              double.tryParse(_expectedHoursController.text) ??
              widget.employee.expectedDailyHours,
          lateMinutes: 0,
          notes: _notesController.text.trim(),
        );
        widget.onCheckIn(checkInAttendance);
      }
      Navigator.pop(context);
    }
  }
}
