import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/contact_service.dart';
import 'package:tahsel/core/services/sms_service.dart';
import 'package:tahsel/core/services/whatsapp_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/customer/presentation/cubit/customer_cubit.dart';
import 'package:tahsel/features/customer/presentation/cubit/customer_state.dart';

class NotificationDialog extends StatefulWidget {
  final String customerName;
  final double amountPaid;
  final double remainingBalance;
  final String? note;
  final String mode; // 'whatsapp' or 'sms'
  final String operationType; // 'payment', 'edit', 'delete'

  const NotificationDialog({
    super.key,
    required this.customerName,
    required this.amountPaid,
    required this.remainingBalance,
    required this.mode,
    this.note,
    this.operationType = 'payment',
  });

  static bool _isShowing = false;

  /// THE CENTRAL WAY to show and handle the notification flow
  static void show({
    required BuildContext context,
    required String customerName,
    required double amountPaid,
    required double remainingBalance,
    String? note,
    String operationType = 'payment',
  }) {
    if (_isShowing) return;

    final customerState = context.read<CustomerCubit>().state;
    String preference = 'none';
    if (customerState is CustomerLoaded) {
      final customer = customerState.customers
          .where((c) => c.name.trim() == customerName.trim())
          .firstOrNull;
      preference = customer?.notificationPreference ?? 'none';
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
        backgroundColor: AppColors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: NotificationDialog(
            mode: preference,
            customerName: customerName,
            amountPaid: amountPaid,
            remainingBalance: remainingBalance,
            note: note,
            operationType: operationType,
          ),
        ),
      ).then((result) {
        _isShowing = false;
        if (result != null && context.mounted) {
          handleNotification(
            context: context,
            mode: preference,
            customerName: customerName,
            amountPaid: amountPaid,
            remainingBalance: remainingBalance,
            phone: result['phone'] ?? '',
            note: result['note'],
            operationType: operationType,
          );
        }
      });
    });
  }

  /// STATIC HELPER to handle the sending logic after the dialog is popped
  /// Returns the correct template key based on operation type and channel.
  static String _getTemplateKey(String operationType, String mode) {
    if (mode == 'whatsapp') {
      switch (operationType) {
        case 'edit':
          return AppStrings.whatsappEditMsgTemplate;
        case 'delete':
          return AppStrings.whatsappDeleteMsgTemplate;
        default:
          return AppStrings.whatsappMsgTemplate;
      }
    } else {
      switch (operationType) {
        case 'edit':
          return AppStrings.smsEditMsgTemplate;
        case 'delete':
          return AppStrings.smsDeleteMsgTemplate;
        default:
          return AppStrings.smsMsgTemplate;
      }
    }
  }

  static Future<void> handleNotification({
    required BuildContext context,
    required String mode,
    required String customerName,
    required double amountPaid,
    required double remainingBalance,
    required String phone,
    String? note,
    String operationType = 'payment',
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<CustomerCubit>();
    final uid = AppStrings.userToken;

    try {
      cubit.updateCustomerPhone(uid, customerName, phone);

      final templateKey = _getTemplateKey(operationType, mode);
      final template = templateKey.tr();

      final message = await (mode == 'whatsapp'
          ? WhatsAppService.prepareMessage(
              name: customerName,
              amount: amountPaid,
              remaining: remainingBalance,
              date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
              note: (note ?? '').tr(),
              template: template,
            )
          : SmsService.prepareMessage(
              name: customerName,
              amount: amountPaid,
              remaining: remainingBalance,
              date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
              note: (note ?? '').tr(),
              template: template,
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
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  final TextEditingController _phoneController = TextEditingController();
  String? _errorText;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCustomerPhone();
  }

  void _loadCustomerPhone() {
    final state = context.read<CustomerCubit>().state;
    if (state is CustomerLoaded) {
      final customer = state.customers
          .where((c) => c.name.trim() == widget.customerName.trim())
          .firstOrNull;
      if (customer != null &&
          customer.phoneNumber != null &&
          customer.phoneNumber!.isNotEmpty) {
        _phoneController.text = customer.phoneNumber!;
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickFromContacts() async {
    final contact = await ContactService.pickContact(context);
    if (contact != null && contact['phone'] != null) {
      setState(() {
        _phoneController.text = contact['phone']!;
        _errorText = null;
      });
    }
  }

  Future<void> _sendNotification() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorText = AppStrings.requiredField.tr());
      return;
    }

    setState(() => _isSaving = true);
    Navigator.pop(context, {'phone': phone, 'note': widget.note ?? ''});
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
                    fontSize: 18,
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
              fontSize: 14,
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
                      fontSize: 16,
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
              style: TextStyles.customStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
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
                      fontSize: 12,
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
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          AppStrings.sendNow.tr(),
                          style: TextStyles.customStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 12,
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
