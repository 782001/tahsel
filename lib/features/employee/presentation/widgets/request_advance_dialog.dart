import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/employee/domain/entities/advance_entity.dart';
import 'package:tahsel/features/employee/domain/entities/employee_entity.dart';
import 'package:tahsel/features/employee/presentation/cubit/employee_cubit.dart';
import 'package:tahsel/features/employee/presentation/cubit/employee_state.dart';
import 'package:tahsel/features/expenses/domain/entities/expense_entity.dart';
import 'package:tahsel/features/expenses/presentation/cubit/expense_cubit.dart';

class RequestAdvanceDialog extends StatefulWidget {
  final EmployeeEntity employee;

  const RequestAdvanceDialog({super.key, required this.employee});

  @override
  State<RequestAdvanceDialog> createState() => _RequestAdvanceDialogState();
}

class _RequestAdvanceDialogState extends State<RequestAdvanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyles.customStyle(
        fontSize: 13,
        color: AppColors.blackLight.withValues(alpha: 0.5),
      ),
      filled: true,
      fillColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      if (amount <= 0) return;

      final advance = AdvanceEntity(
        id: '', // Handled by repository
        uid: AppStrings.userToken,
        employeeId: widget.employee.id!,
        employeeName: widget.employee.name,
        amount: amount,
        date: DateTime.now(),
        notes: _notesController.text.trim(),
        status: 'paid',
      );

      context.read<EmployeeCubit>().requestAdvance(advance);

      final categoryName = AppStrings.advanceExpenseFor.tr(
        namedArgs: {'name': widget.employee.name},
      );

      final expense = ExpenseEntity(
        id: 'exp_emp_adv_${DateTime.now().millisecondsSinceEpoch}',
        uid: AppStrings.userToken,
        amount: amount,
        category: categoryName,
        description: _notesController.text.trim(),
        createdAt: DateTime.now(),
        monthKey: DateFormat('yyyy-MM', 'en').format(DateTime.now()),
      );
      if (mounted) {
        context.read<ExpenseCubit>().addExpense(expense);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      backgroundColor: AppColors.scafoldBackGround,
      insetPadding: EdgeInsets.all(isDesktop ? 24 : 16.w),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 450 : double.infinity,
        ),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 24 : 20.w),
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
                      AppStrings.requestAdvance.tr(),
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackReal,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: AppColors.blackLight,
                        size: isDesktop ? 20 : 20.r,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 16 : 16.h),
                Text(
                  AppStrings.advanceAmount.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                TextFormField(
                  controller: _amountController,
                  cursorColor: AppColors.primaryColor,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _buildInputDecoration(hintText: '0.00'),
                  style: TextStyles.customStyle(fontSize: 14),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.requiredField.tr();
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return AppStrings.invalidAmount.tr();
                    }
                    return null;
                  },
                ),
                SizedBox(height: isDesktop ? 16 : 16.h),
                Text(
                  AppStrings.notes.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                TextFormField(
                  controller: _notesController,
                  cursorColor: AppColors.primaryColor,
                  maxLines: 3,
                  decoration: _buildInputDecoration(
                    hintText: AppStrings.addNotesPlaceholder.tr(),
                  ),
                  style: TextStyles.customStyle(fontSize: 14),
                ),
                SizedBox(height: isDesktop ? 24 : 24.h),
                BlocBuilder<EmployeeCubit, EmployeeState>(
                  builder: (context, state) {
                    if (state is EmployeeLoading) {
                      return  Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                          strokeWidth: 2,
                        ),
                      );
                    }
                    return SizedBox(
                      width: double.infinity,
                      height: isDesktop ? 45 : 45.h,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppStrings.requestAdvance.tr(),
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 15 : 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
