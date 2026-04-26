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
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/shared/widgets/buttons/custom_button.dart';
import 'package:tahsel/shared/widgets/text_fields/custom_text_form_field.dart';

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
    return BlocProvider(
      create: (context) => sl<MyDebtsCubit>(),
      child: BlocListener<MyDebtsCubit, MyDebtsState>(
        listener: (context, state) {
          if (state.status == MyDebtsStatus.loaded) {
            sl<NavigatorService>().pop();
          } else if (state.status == MyDebtsStatus.error) {
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
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textColor),
              onPressed: () => sl<NavigatorService>().pop(),
            ),
          ),
          body: SingleChildScrollView(
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
                      color: Colors.black.withOpacity(0.02),
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
                        fontSize: 16.sp,
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
                        fontSize: 16.sp,
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
                                  fontSize: 14.sp,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              CustomTextFormField(
                                controller: _totalController,
                                hintText: AppStrings.totalAmountHint.tr(),
                                prefixIcon: Icons.payments_outlined,
                                keyboardType: TextInputType.number,
                                hintFontSize: 10.sp,
                                validator: (val) {
                                  if (val!.isEmpty) {
                                    return AppStrings.validationFieldRequired
                                        .tr();
                                  }
                                  if (double.tryParse(val) == null) {
                                    return AppStrings.validationInvalidAmount
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
                                  fontSize: 14.sp,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              CustomTextFormField(
                                controller: _paidController,
                                hintText: "0.00",
                                prefixText: AppStrings.currencyEgp.tr(),
                                keyboardType: TextInputType.number,
                                validator: (val) {
                                  if (val!.isEmpty) return null;
                                  final paid = double.tryParse(val);
                                  final total = double.tryParse(
                                    _totalController.text,
                                  );
                                  if (paid == null) {
                                    return AppStrings.validationInvalidAmount
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
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    CustomTextFormField(
                      controller: _notesController,
                      hintText: AppStrings.notes.tr(),
                      prefixIcon: Icons.note_alt_outlined,
                      maxLines: 3,
                    ),
                    SizedBox(height: 32.h),
                    BlocBuilder<MyDebtsCubit, MyDebtsState>(
                      builder: (context, state) {
                        return CustomButton(
                          text: AppStrings.confirm.tr(),
                          isLoading: state.status == MyDebtsStatus.addingDebt,
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              context.read<MyDebtsCubit>().addDebt(
                                name: _nameController.text,
                                total: double.parse(_totalController.text),
                                paid:
                                    double.tryParse(_paidController.text) ?? 0,
                                phone: _phoneController.text.isEmpty
                                    ? null
                                    : _phoneController.text,
                                notes: _notesController.text.isEmpty
                                    ? null
                                    : _notesController.text,
                              );
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
    );
  }

  Widget _buildRemainingDisplay() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              AppStrings.remainingDebt.tr(),
              style: TextStyles.customStyle(
                color: AppColors.subTitleColor,
                fontSize: 14.sp,
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
                  fontSize: 18.sp,
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
