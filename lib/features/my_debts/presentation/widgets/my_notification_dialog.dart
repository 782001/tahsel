import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/sms_service.dart';
import 'package:tahsel/core/services/whatsapp_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';

class MyDebtsNotificationDialog extends StatefulWidget {
  final String personName;
  final double amountPaid;
  final double remainingBalance;
  final String? note;
  final String mode; // 'whatsapp' or 'sms'

  const MyDebtsNotificationDialog({
    super.key,
    required this.personName,
    required this.amountPaid,
    required this.remainingBalance,
    required this.mode,
    this.note,
  });

  static bool _isShowing = false;

  static void show({
    required BuildContext context,
    required String personName,
    required double amountPaid,
    required double remainingBalance,
    String? note,
  }) {
    if (_isShowing) return;

    final myDebtsState = context.read<MyDebtsCubit>().state;
    String preference = 'none';
    if (myDebtsState.status == MyDebtsStatus.loaded) {
      final debt = myDebtsState.debts
          .where((d) => d.personName.trim() == personName.trim())
          .firstOrNull;
      preference = debt?.notificationPreference ?? 'none';
    }

    if (preference == 'none') return;

    _isShowing = true;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!context.mounted) {
        _isShowing = false;
        return;
      }

      showModalBottomSheet<Map<String, String>>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: MyDebtsNotificationDialog(
            mode: preference,
            personName: personName,
            amountPaid: amountPaid,
            remainingBalance: remainingBalance,
            note: note,
          ),
        ),
      ).then((result) {
        _isShowing = false;
        if (result != null && context.mounted) {
          handleNotification(
            context: context,
            mode: preference,
            personName: personName,
            amountPaid: amountPaid,
            remainingBalance: remainingBalance,
            phone: result['phone'] ?? '',
            note: result['note'],
          );
        }
      });
    });
  }

  static Future<void> handleNotification({
    required BuildContext context,
    required String mode,
    required String personName,
    required double amountPaid,
    required double remainingBalance,
    required String phone,
    String? note,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final message = await (mode == 'whatsapp'
          ? WhatsAppService.prepareMessage(
              name: personName,
              amount: amountPaid,
              remaining: remainingBalance,
              date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
              note: note ?? '',
            )
          : SmsService.prepareMessage(
              name: personName,
              amount: amountPaid,
              remaining: remainingBalance,
              date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
              note: note ?? '',
            ));

      if (mode == 'whatsapp') {
        final success = await WhatsAppService.sendMessage(
          phoneNumber: phone,
          message: message,
        );
        if (!success) {
          messenger.showSnackBar(
            SnackBar(content: Text(AppStrings.whatsappNotInstalled.tr())),
          );
        }
      } else {
        final success = await SmsService.sendSms(
          phoneNumber: phone,
          message: message,
        );
        if (!success) {
          messenger.showSnackBar(
            SnackBar(content: Text(AppStrings.smsNotSupported.tr())),
          );
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  State<MyDebtsNotificationDialog> createState() => _MyDebtsNotificationDialogState();
}

class _MyDebtsNotificationDialogState extends State<MyDebtsNotificationDialog> {
  final TextEditingController _phoneController = TextEditingController();
  String? _errorText;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPersonPhone();
  }

  void _loadPersonPhone() {
    final state = context.read<MyDebtsCubit>().state;
    if (state.status == MyDebtsStatus.loaded) {
      final debt = state.debts
          .where((d) => d.personName.trim() == widget.personName.trim())
          .firstOrNull;
      if (debt != null &&
          debt.phoneNumber != null &&
          debt.phoneNumber!.isNotEmpty) {
        _phoneController.text = debt.phoneNumber!;
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickFromContacts() async {
    try {
      if (await FlutterContacts.requestPermission(readonly: true)) {
        final contact = await FlutterContacts.openExternalPick();
        if (contact != null) {
          final fullContact = await FlutterContacts.getContact(contact.id);
          if (fullContact != null && fullContact.phones.isNotEmpty) {
            setState(() {
              _phoneController.text = fullContact.phones.first.number;
              _errorText = null;
            });
          }
        }
      } else {
        setState(() => _errorText = AppStrings.permissionDenied.tr());
      }
    } catch (e) {
      setState(() => _errorText = e.toString());
    }
  }

  Future<void> _sendNotification() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorText = AppStrings.requiredField.tr());
      return;
    }

    setState(() => _isSaving = true);
    Navigator.pop(context, {
      'phone': phone,
      'note': widget.note ?? '',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.scafoldBackGround,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          Row(
            children: [
              widget.mode == 'whatsapp'
                  ? Image.asset(
                      Assets.imagesWhatsapp,
                      width: 32.w,
                      height: 32.w,
                    )
                  : Icon(
                      Icons.sms_rounded,
                      color: AppColors.primaryColor,
                      size: 32.w,
                    ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  widget.mode == 'whatsapp'
                      ? AppStrings.sendWhatsapp.tr()
                      : AppStrings.sms.tr(),
                  style: TextStyles.customStyle(
                    color: AppColors.textColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            AppStrings.customerPhone.tr(),
            style: TextStyles.customStyle(
              color: AppColors.disabledColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12.r),
                    border: _errorText != null
                        ? Border.all(color: AppColors.error)
                        : null,
                  ),
                  child: TextField(
                    cursorColor: AppColors.primaryColor,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyles.customStyle(
                      color: AppColors.textColor,
                      fontWeight: FontWeight.w400,
                      fontSize: 16.sp,
                    ),
                    decoration: InputDecoration(
                      hintText: '01xxxxxxxxx',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    onChanged: (_) => setState(() => _errorText = null),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: _pickFromContacts,
                icon: Icon(
                  Icons.contact_phone_rounded,
                  color: AppColors.primaryColor,
                ),
                tooltip: AppStrings.selectFromContacts.tr(),
              ),
            ],
          ),
          if (_errorText != null) ...[
            SizedBox(height: 8.h),
            Text(
              _errorText!,
              style: TextStyle(color: AppColors.error, fontSize: 12.sp),
            ),
          ],
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppStrings.skipNotification.tr(),
                    style: TextStyles.customStyle(
                      color: AppColors.disabledColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _sendNotification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          AppStrings.sendNow.tr(),
                          style: TextStyles.customStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
