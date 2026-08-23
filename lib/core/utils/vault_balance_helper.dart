import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/cashbox/presentation/cubit/vault_cubit.dart';
import 'package:tahsel/features/cashbox/presentation/widgets/manual_deposit_dialog.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';

class VaultBalanceHelper {
  /// Centralized check for Vault eligibility
  static bool isEnabled([bool? isShopUser]) {
    return AppStrings.isVaultEnabled(isShopUser);
  }

  /// Retrieves the current Vault balance (returns double.infinity when offline to allow offline purchases)
  static Future<double> getCurrentBalance([BuildContext? context]) async {
    if (!isEnabled()) return double.infinity;
    try {
      if (sl.isRegistered<ConnectivityCubit>() &&
          sl<ConnectivityCubit>().state is ConnectivityDisconnected) {
        return double.infinity;
      }
      final vaultSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(AppStrings.userToken)
          .collection('vault')
          .doc('summary')
          .get()
          .timeout(const Duration(seconds: 3));
      if (vaultSnap.exists && vaultSnap.data() != null) {
        return (vaultSnap.data()!['currentBalance'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (_) {
      // In offline / network failure mode, allow offline operations
      return double.infinity;
    }
  }

  /// Displays the Insufficient Balance Dialog with "Deposit Cash" action
  static void showInsufficientBalanceDialog(
    BuildContext context, {
    VoidCallback? onDepositSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppColors.scafoldBackGround,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha:  0.12),
                    shape: BoxShape.circle,
                  ),
                  child:  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.error,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.insufficientBalance.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyles.customStyle(
                    color: AppColors.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.depositCashToContinue.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyles.customStyle(
                    color: AppColors.disabledColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          AppStrings.cancel.tr(),
                          style: TextStyles.customStyle(
                            color: AppColors.disabledColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          openDepositDialog(context, onDepositSuccess: onDepositSuccess);
                        },
                        child: Text(
                          AppStrings.depositToVault.tr(),
                          style: TextStyles.customStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
    );
  }

  /// Opens the existing ManualDepositDialog and performs manual deposit
  static void openDepositDialog(
    BuildContext context, {
    VoidCallback? onDepositSuccess,
  }) {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      showfailureToast(AppStrings.noInternetConnection.tr());
      return;
    }
    showDialog(
      context: context,
      builder: (_) => ManualDepositDialog(
        onSubmit: (amount, note) async {
          try {
            final vaultCubit = sl<VaultCubit>();
            await vaultCubit.depositManual(amount: amount, note: note);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.cashboxSourceManualAdd.tr()),
                  backgroundColor: AppColors.success,
                ),
              );
              onDepositSuccess?.call();
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      ),
    );
  }
}
