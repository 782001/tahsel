import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/expenses/presentation/widgets/add_expense_field.dart';
import 'package:tahsel/shared/widgets/buttons/quick_action_button.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy/MM/dd').format(_selectedDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy/MM/dd').format(_selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      appBar: AppBar(
        backgroundColor: AppColors.scafoldBackGround,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: AppColors.black, size: 22.r),
        ),
        title: Text(
          AppStrings.addNewExpense.tr(),
          style: TextStyles.customStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 24.h),
              AddExpenseField(
                label: AppStrings.amountLabel.tr(),
                hint: "0.00",
                controller: _amountController,
                prefixText: AppStrings.currencyEgp.tr(),
                suffixIcon: Icons.account_balance_wallet_outlined,
                isNumber: true,
              ),
              SizedBox(height: 16.h),
              AddExpenseField(
                label: AppStrings.expenseNameLabel.tr(),
                hint: AppStrings.expenseNamePlaceholder.tr(),
                controller: _nameController,
                suffixIcon: Icons.folder_outlined,
              ),
              SizedBox(height: 16.h),
              AddExpenseField(
                label: AppStrings.descriptionLabel.tr(),
                hint: AppStrings.descriptionPlaceholder.tr(),
                controller: _descController,
                suffixIcon: Icons.description_outlined,
                isMultiline: true,
              ),
              SizedBox(height: 16.h),
              AddExpenseField(
                label: AppStrings.dateLabel.tr(),
                hint: "",
                controller: _dateController,
                suffixIcon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              SizedBox(height: 40.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: QuickActionButton(
                  label: AppStrings.addExpense.tr(),
                  icon: Icons.check_circle_outline,
                  onPressed: () {
                    // TODO: Implement actual save logic
                    Navigator.pop(context);
                  },
                ),
              ),
              SizedBox(height: 48.h),
            ],
          ),
        ),
      ),
    );
  }
}
