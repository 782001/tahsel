import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/contact_service.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_state.dart';
import 'package:tahsel/shared/widgets/buttons/custom_button.dart';
import 'package:tahsel/shared/widgets/text_fields/custom_text_form_field.dart';
import 'package:tahsel/core/utils/date_formatter.dart';


class AddMyDebtScreen extends StatefulWidget {
  const AddMyDebtScreen({super.key});

  @override
  State<AddMyDebtScreen> createState() => _AddMyDebtScreenState();
}

class _AddMyDebtScreenState extends State<AddMyDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _totalController = TextEditingController();
  final _paidController = TextEditingController();
  final _notesController = TextEditingController();

  double _remaining = 0;
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final DateTime minDate = DateTime(2000);
    final DateTime initialDate = _selectedDate ?? DateTime.now();
    final DateTime finalInitialDate = initialDate.isBefore(minDate)
        ? minDate
        : initialDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: finalInitialDate,
      firstDate: minDate,
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
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }


  @override
  void initState() {
    super.initState();
    _totalController.addListener(_calculateRemaining);
    _paidController.addListener(_calculateRemaining);
  }

  void _calculateRemaining() {
    final total = double.tryParse(_totalController.text) ?? 0;
    final paid = double.tryParse(_paidController.text) ?? 0;
    setState(() {
      _remaining = total - paid;
    });
  }

  Future<void> _pickContact() async {
    final contactInfo = await ContactService.pickContact(context);
    if (contactInfo != null) {
      setState(() {
        _nameController.text = contactInfo['name'] ?? '';
        _phoneController.text = contactInfo['phone'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _totalController.dispose();
    _paidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocProvider.value(
      value: context.read<MyDebtsCubit>(),
      child: BlocListener<MyDebtsCubit, MyDebtsState>(
        listener: (context, state) {
          if (state.status == MyDebtsStatus.error) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message ?? 'Error')));
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.scafoldBackGround,
          appBar: AppBar(
            backgroundColor: AppColors.scafoldBackGround,
            elevation: 0,
            centerTitle: true,
            title: Text(
              AppStrings.addNewDebt.tr(),
              style: TextStyles.customStyle(
                color: AppColors.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textColor),
              onPressed: () => sl<NavigatorService>().pop(),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 800 : double.infinity,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.r),
                child: Form(
                  key: _formKey,
                  child: Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: AppColors.debtCardSurface,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.sellerPersonName.tr(),
                          style: TextStyles.customStyle(
                            color: AppColors.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        CustomTextFormField(
                          controller: _nameController,
                          hintText: AppStrings.sellerPersonName.tr(),
                          prefixIcon: Icons.person_outline,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.contact_phone_rounded),
                            onPressed: _pickContact,
                            color: AppColors.primaryColor,
                          ),
                          validator: (val) => val!.isEmpty
                              ? AppStrings.validationFieldRequired.tr()
                              : null,
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          AppStrings.sellerPhone.tr(),
                          style: TextStyles.customStyle(
                            color: AppColors.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        CustomTextFormField(
                          controller: _phoneController,
                          hintText: AppStrings.sellerPhone.tr(),
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 20.h),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.totalDueLabel.tr(),
                                    style: TextStyles.customStyle(
                                      color: AppColors.textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  CustomTextFormField(
                                    controller: _totalController,
                                    hintText: AppStrings.totalAmountHint.tr(),
                                    // prefixIcon: Icons.payments_outlined,
                                    keyboardType: TextInputType.number,
                                    hintFontSize: 12,
                                    validator: (val) {
                                      if (val!.isEmpty) {
                                        return AppStrings
                                            .validationFieldRequired
                                            .tr();
                                      }
                                      if (double.tryParse(val) == null) {
                                        return AppStrings
                                            .validationInvalidAmount
                                            .tr();
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.paidAmount.tr(),
                                    style: TextStyles.customStyle(
                                      color: AppColors.textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  CustomTextFormField(
                                    controller: _paidController,
                                    hintText: "0.00",
                                    // prefixText: AppStrings.currencyEgp.tr(),
                                    keyboardType: TextInputType.number,
                                    validator: (val) {
                                      if (val!.isEmpty) return null;
                                      final paid = double.tryParse(val);
                                      final total = double.tryParse(
                                        _totalController.text,
                                      );
                                      if (paid == null) {
                                        return AppStrings
                                            .validationInvalidAmount
                                            .tr();
                                      }
                                      if (total != null && paid > total) {
                                        return AppStrings.errorPaidGreaterTotal
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
                        _buildRemainingDisplay(),
                        SizedBox(height: 20.h),
                        Text(
                          AppStrings.notes.tr(),
                          style: TextStyles.customStyle(
                            color: AppColors.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        CustomTextFormField(
                          controller: _notesController,
                          hintText: AppStrings.notes.tr(),
                          prefixIcon: Icons.note_alt_outlined,
                          maxLines: 3,
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          AppStrings.paymentDate.tr(),
                          style: TextStyles.customStyle(
                            color: AppColors.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        InkWell(
                          borderRadius: BorderRadius.circular(12.r),
                          onTap: _pickDate,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: AppColors.disabledColor.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      color: _selectedDate != null
                                          ? AppColors.primaryColor
                                          : AppColors.disabledColor,
                                      size: 20.r,
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      _selectedDate != null
                                          ? DateFormatter.formatNumericDate(
                                              _selectedDate!,
                                            )
                                          : AppStrings.notSet.tr(),
                                      style: TextStyles.customStyle(
                                        color: _selectedDate != null
                                            ? AppColors.textColor
                                            : AppColors.disabledColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_selectedDate != null)
                                  IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: AppColors.error,
                                      size: 20.r,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      setState(() {
                                        _selectedDate = null;
                                      });
                                    },
                                  )
                                else
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: AppColors.disabledColor,
                                    size: 14.r,
                                  ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 32.h),
                        BlocBuilder<MyDebtsCubit, MyDebtsState>(
                          builder: (context, state) {
                            return CustomButton(
                              text: AppStrings.confirm.tr(),
                              isLoading:
                                  state.status == MyDebtsStatus.addingDebt,
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  final cubit = context.read<MyDebtsCubit>();
                                  await cubit.addDebt(
                                    uid: AppStrings.userToken,
                                    personName: _nameController.text,
                                    totalAmount: double.parse(
                                      _totalController.text,
                                    ),
                                    paidAmount:
                                        double.tryParse(_paidController.text) ??
                                        0,
                                    phone: _phoneController.text.isEmpty
                                        ? null
                                        : _phoneController.text,
                                    details: _notesController.text.isEmpty
                                        ? null
                                        : _notesController.text,
                                    timestamp: _selectedDate,
                                  );
                                  if (!mounted) return;
                                  sl<NavigatorService>().pop();
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemainingDisplay() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              AppStrings.remainingDebt.tr(),
              style: TextStyles.customStyle(
                color: AppColors.subTitleColor,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${_remaining.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()}',
                style: TextStyles.customStyle(
                  color: AppColors.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
