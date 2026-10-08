import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/permission_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/currency_helper.dart';
import 'package:tahsel/core/utils/date_formatter.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/utils/vault_balance_helper.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/custody/domain/entities/custody_entity.dart';
import 'package:tahsel/features/custody/presentation/cubit/custody_cubit.dart';
import 'package:tahsel/features/employee/data/models/app_employee_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';
import 'package:tahsel/shared/widgets/text_fields/custom_text_form_field.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';

class NewCustodyDialog extends StatefulWidget {
  final CustodyCubit cubit;

  const NewCustodyDialog({super.key, required this.cubit});

  static Future<void> show(BuildContext context, CustodyCubit cubit) {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      showfailureToast(AppStrings.noInternetConnection.tr());
      return Future.value();
    }
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => NewCustodyDialog(cubit: cubit),
    );
  }

  @override
  State<NewCustodyDialog> createState() => _NewCustodyDialogState();
}

class _NewCustodyDialogState extends State<NewCustodyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _customNameController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isCustomRecipient = false;
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;
  bool _isLoadingEmployees = true;
  List<AppEmployeeModel> _teamEmployees = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _customNameController.addListener(_onCustomNameChanged);
    _loadTeamEmployees();
  }

  void _onCustomNameChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _customNameController.removeListener(_onCustomNameChanged);
    _amountController.dispose();
    _customNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamEmployees() async {
    final ownerUid = AppStrings.userToken;
    if (ownerUid.isEmpty) {
      if (mounted) setState(() => _isLoadingEmployees = false);
      return;
    }

    try {
      final snapshot = await sl<FirebaseFirestore>()
          .collection('users')
          .doc(ownerUid)
          .collection('app_employees')
          .where('accountStatus', isEqualTo: 'active')
          .get();

      if (mounted) {
        setState(() {
          _teamEmployees = snapshot.docs
              .map((doc) => AppEmployeeModel.fromMap(doc.data(), doc.id))
              .toList();
          _isLoadingEmployees = false;
          if (_teamEmployees.isNotEmpty) {
            _selectedEmployeeId = _teamEmployees.first.authUid;
            _selectedEmployeeName = _teamEmployees.first.name;
          } else {
            _isCustomRecipient = true;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingEmployees = false;
          _isCustomRecipient = true;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      showfailureToast(AppStrings.noInternetConnection.tr());
      return;
    }
    // ── Permission Guard ──
    final canCreate = PermissionService.instance.isOwner ||
        PermissionService.instance.hasPermission(AppPermissions.vaultAccess) ||
        PermissionService.instance.hasPermission(AppPermissions.vaultWithdraw);
    if (!canCreate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noPermissionForAction.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.custodyAmountPositive.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final String recipientName;
    final String? recipientEmployeeId;
    final String recipientType;

    if (_isCustomRecipient) {
      recipientName = _customNameController.text.trim();
      recipientEmployeeId = null;
      recipientType = recipientName.contains('مالك') ||
              recipientName.toLowerCase().contains('owner')
          ? 'owner'
          : 'other';
    } else {
      if (_selectedEmployeeName == null || _selectedEmployeeName!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.custodyRecipientRequired.tr()),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      recipientName = _selectedEmployeeName!;
      recipientEmployeeId = _selectedEmployeeId;
      recipientType = 'employee';
    }

    final bool alreadyHasActive = widget.cubit.activeCustodies.any((c) {
      if (_isCustomRecipient) {
        return c.recipientName.trim().toLowerCase() ==
            recipientName.trim().toLowerCase();
      } else {
        return c.recipientEmployeeId == recipientEmployeeId;
      }
    });

    if (alreadyHasActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.recipientAlreadyHasActiveCustodyNotice.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (VaultBalanceHelper.isEnabled()) {
      final currentBalance = await VaultBalanceHelper.getCurrentBalance(context);
      if (currentBalance < amount) {
        if (mounted) {
          VaultBalanceHelper.showInsufficientBalanceDialog(context);
        }
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final success = await widget.cubit.createCustody(
      recipientName: recipientName,
      recipientEmployeeId: recipientEmployeeId,
      recipientType: recipientType,
      initialAmount: amount,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 16.w,
        vertical: isDesktop ? 24 : 24.h,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 20.r),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 520 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 24 : 18.r),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isDesktop ? 10 : 10.r),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppColors.primaryColor,
                          size: isDesktop ? 24 : 24.r,
                        ),
                      ),
                      SizedBox(width: isDesktop ? 12 : 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.newCustody.tr(),
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 18 : 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            Text(
                              DateFormatter.formatDate(DateTime.now()),
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 12 : 11.5,
                                color: AppColors.sandText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.sandText,
                          size: isDesktop ? 22 : 22.r,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 18 : 18.h),

                  // Recipient Type Segmented Toggle
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 4 : 4.r),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreyColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isCustomRecipient = false),
                            borderRadius: BorderRadius.circular(isDesktop ? 10 : 10.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: isDesktop ? 8 : 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: !_isCustomRecipient
                                    ? AppColors.surface
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  isDesktop ? 10 : 10.r,
                                ),
                                boxShadow: !_isCustomRecipient
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  AppStrings.selectFromTeam.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyles.customStyle(
                                    fontSize: isDesktop ? 12.5 : 12,
                                    fontWeight: !_isCustomRecipient
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: !_isCustomRecipient
                                        ? AppColors.primaryColor
                                        : AppColors.blackLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isCustomRecipient = true),
                            borderRadius: BorderRadius.circular(isDesktop ? 10 : 10.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: isDesktop ? 8 : 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: _isCustomRecipient
                                    ? AppColors.surface
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  isDesktop ? 10 : 10.r,
                                ),
                                boxShadow: _isCustomRecipient
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  AppStrings.customRecipient.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyles.customStyle(
                                    fontSize: isDesktop ? 12.5 : 12,
                                    fontWeight: _isCustomRecipient
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _isCustomRecipient
                                        ? AppColors.primaryColor
                                        : AppColors.blackLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isDesktop ? 16 : 16.h),

                  // Recipient Selector or Custom Input
                  if (!_isCustomRecipient) ...[
                    if (_isLoadingEmployees)
                      ShimmerLoading(
                        child: ShimmerPlaceholder(
                          width: double.infinity,
                          height: isDesktop ? 52 : 48.h,
                          borderRadius: isDesktop ? 12 : 12.r,
                        ),
                      )
                    else if (_teamEmployees.isEmpty)
                      Container(
                        padding: EdgeInsets.all(isDesktop ? 12 : 12.r),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            isDesktop ? 10 : 10.r,
                          ),
                          border: Border.all(
                            color: AppColors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          AppStrings.noAppEmployeesYet.tr(),
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 12 : 11.5,
                            color: AppColors.orange,
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.stitchSurfaceHigh.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(
                            isDesktop ? 12 : 12.r,
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedEmployeeId,
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 15 : 14.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textColor,
                          ),
                          dropdownColor: AppColors.surface,
                          decoration: InputDecoration(
                            labelText: AppStrings.custodyRecipient.tr(),
                            labelStyle: TextStyles.customStyle(
                              fontSize: isDesktop ? 14 : 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textColor,
                            ),
                            prefixIcon:  Icon(
                              Icons.person_rounded,
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                isDesktop ? 12 : 12.r,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 16 : 16.w,
                              vertical: isDesktop ? 14 : 14.h,
                            ),
                          ),
                          items: _teamEmployees.map((emp) {
                            return DropdownMenuItem<String>(
                              value: emp.authUid,
                              child: Text(
                                '${emp.name} (${emp.rolePreset})',
                                style: TextStyles.customStyle(
                                  fontSize: isDesktop ? 14 : 13.5,
                                  color: AppColors.textColor,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedEmployeeId = val;
                              final emp = _teamEmployees.firstWhere(
                                (e) => e.authUid == val,
                              );
                              _selectedEmployeeName = emp.name;
                            });
                          },
                        ),
                      ),
                  ] else ...[
                    CustomTextFormField(
                      controller: _customNameController,
                      labelText:
                          '${AppStrings.custodyRecipient.tr()} ${AppStrings.custodyRecipientOwnerOrOther.tr()}',
                      hintText: AppStrings.custodyCustomRecipientHint.tr(),
                      prefixIcon: Icons.badge_outlined,
                      validator: (val) {
                        if (_isCustomRecipient &&
                            (val == null || val.trim().isEmpty)) {
                          return AppStrings.custodyRecipientRequired.tr();
                        }
                        return null;
                      },
                    ),
                  ],
                  Builder(
                    builder: (context) {
                      CustodyEntity? activeCustody;
                      for (final c in widget.cubit.activeCustodies) {
                        if (_isCustomRecipient) {
                          if (_customNameController.text.trim().isNotEmpty &&
                              c.recipientName.trim().toLowerCase() ==
                                  _customNameController.text
                                      .trim()
                                      .toLowerCase()) {
                            activeCustody = c;
                            break;
                          }
                        } else {
                          if (c.recipientEmployeeId == _selectedEmployeeId) {
                            activeCustody = c;
                            break;
                          }
                        }
                      }

                      // If recipient already has an active custody:
                      // Hide amount/notes fields and submit button, and display informative warning card with Close button.
                      if (activeCustody != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: isDesktop ? 16 : 14.h),
                            Container(
                              padding: EdgeInsets.all(isDesktop ? 16 : 14.r),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(
                                  isDesktop ? 14 : 14.r,
                                ),
                                border: Border.all(
                                  color: AppColors.orange.withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(isDesktop ? 7 : 6.r),
                                        decoration: BoxDecoration(
                                          color: AppColors.orange
                                              .withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.lock_clock_rounded,
                                          color: AppColors.orange,
                                          size: isDesktop ? 20 : 20.r,
                                        ),
                                      ),
                                      SizedBox(width: isDesktop ? 10 : 8.w),
                                      Expanded(
                                        child: Text(
                                          AppStrings
                                              .cannotCreateMultipleActiveCustodies
                                              .tr(),
                                          style: TextStyles.customStyle(
                                            fontSize: isDesktop ? 14 : 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isDesktop ? 10 : 8.h),
                                  Text(
                                    AppStrings
                                        .recipientAlreadyHasActiveCustodyNotice
                                        .tr(),
                                    style: TextStyles.customStyle(
                                      fontSize: isDesktop ? 12.5 : 12,
                                      color: AppColors.blackLight,
                                      height: 1.4,
                                    ),
                                  ),
                                  SizedBox(height: isDesktop ? 14 : 12.h),
                                  Container(
                                    padding: EdgeInsets.all(isDesktop ? 12 : 10.r),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(
                                        isDesktop ? 10 : 10.r,
                                      ),
                                      border: Border.all(
                                        color: AppColors.lightGreyColor
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        _buildCustodyDetailRow(
                                          label: AppStrings
                                              .activeCustodyInitialAmount
                                              .tr(),
                                          value: CurrencyHelper.formatCurrency(
                                            activeCustody.initialAmount,
                                          ),
                                          isDesktop: isDesktop,
                                        ),
                                        SizedBox(height: isDesktop ? 8 : 6.h),
                                        _buildCustodyDetailRow(
                                          label: AppStrings
                                              .activeCustodySpentAmount
                                              .tr(),
                                          value: CurrencyHelper.formatCurrency(
                                            activeCustody.spentAmount,
                                          ),
                                          isDesktop: isDesktop,
                                        ),
                                        SizedBox(height: isDesktop ? 8 : 6.h),
                                        Divider(
                                          color: AppColors.lightGreyColor
                                              .withValues(alpha: 0.4),
                                          height: 1,
                                        ),
                                        SizedBox(height: isDesktop ? 8 : 6.h),
                                        _buildCustodyDetailRow(
                                          label: AppStrings
                                              .activeCustodyCurrentBalance
                                              .tr(),
                                          value: CurrencyHelper.formatCurrency(
                                            activeCustody.remainingAmount,
                                          ),
                                          isDesktop: isDesktop,
                                          isHighlight: true,
                                          highlightColor: activeCustody.isDeficit
                                              ? AppColors.orange
                                              : AppColors.primaryColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isDesktop ? 20 : 18.h),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.close_rounded,
                                size: isDesktop ? 18 : 18.r,
                              ),
                              label: Text(
                                AppStrings.close.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: isDesktop ? 14 : 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.blackLight,
                                side: BorderSide(
                                  color: AppColors.lightGreyColor
                                      .withValues(alpha: 0.6),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: isDesktop ? 13 : 12.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    isDesktop ? 12 : 12.r,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      // If NO active custody exists: show input fields and submit button normally
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: isDesktop ? 16 : 16.h),

                          // Custody Amount Field
                          CustomTextFormField(
                            controller: _amountController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            labelText: AppStrings.originalCustodyAmount.tr(),
                            hintText: AppStrings.custodyAmountHint.tr(),
                            prefixText: AppStrings.currencyEgp.tr(),
                            prefixIcon: Icons.payments_outlined,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return AppStrings.custodyAmountPositive.tr();
                              }
                              final num = double.tryParse(val.trim());
                              if (num == null || num <= 0) {
                                return AppStrings.custodyAmountPositive.tr();
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isDesktop ? 16 : 16.h),

                          // Notes / Purpose Field
                          CustomTextFormField(
                            controller: _notesController,
                            maxLines: 2,
                            labelText: AppStrings.custodyNotes.tr(),
                            hintText: AppStrings.custodyNotesHint.tr(),
                            prefixIcon: Icons.notes_rounded,
                          ),
                          SizedBox(height: isDesktop ? 14 : 14.h),

                          // Simple Notice (Vault withdrawal + Custody self-containment)
                          Container(
                            padding: EdgeInsets.all(isDesktop ? 12 : 10.r),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                isDesktop ? 10 : 10.r,
                              ),
                              border: Border.all(
                                color: AppColors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.orange,
                                  size: isDesktop ? 18 : 18.r,
                                ),
                                SizedBox(width: isDesktop ? 8 : 8.w),
                                Expanded(
                                  child: Text(
                                    AppStrings.custodyCreationNoticeSimple.tr(),
                                    style: TextStyles.customStyle(
                                      fontSize: isDesktop ? 12 : 11.5,
                                      color: AppColors.blackLight,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isDesktop ? 20 : 18.h),

                          // Submit Button
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: EdgeInsets.symmetric(
                                vertical: isDesktop ? 14 : 14.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isDesktop ? 12 : 12.r,
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? ShimmerLoading(
                                    child: Container(
                                      height: 16,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    ),
                                  )
                                : Text(
                                    AppStrings.newCustody.tr(),
                                    style: TextStyles.customStyle(
                                      fontSize: isDesktop ? 15.5 : 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustodyDetailRow({
    required String label,
    required String value,
    required bool isDesktop,
    bool isHighlight = false,
    Color? highlightColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyles.customStyle(
            fontSize: isDesktop ? 12 : 11.5,
            color: AppColors.sandText,
          ),
        ),
        Text(
          value,
          style: TextStyles.customStyle(
            fontSize: isDesktop ? 12.5 : 12,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: highlightColor ?? AppColors.blackReal,
          ),
        ),
      ],
    );
  }
}
