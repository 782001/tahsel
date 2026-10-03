import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';

import '../../../../core/error/firebase_error_handler.dart';
import '../../../../core/services/activity_logger_service.dart';
import '../../../../core/services/injection_container.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/summary_helper.dart';
import '../../../cashbox/domain/entities/vault_transaction_entity.dart';
import '../models/operation_model.dart';

abstract class OperationRemoteDataSource {
  Future<String> addOperation(OperationModel operation);
}

class OperationRemoteDataSourceImpl implements OperationRemoteDataSource {
  final FirebaseFirestore firestore;

  OperationRemoteDataSourceImpl({required this.firestore});

  @override
  Future<String> addOperation(OperationModel operation) async {
    try {
      final userRef = firestore.collection('users').doc(operation.uid);
      final collectionRef = userRef.collection('operations');

      final docRef = (operation.id != null && operation.id!.isNotEmpty)
          ? collectionRef.doc(operation.id)
          : collectionRef.doc();

      final batch = firestore.batch();

      // 1. Set the operation document
      batch.set(docRef, operation.toJson());

      // 2. Update Summaries (Daily, Weekly, Monthly, All-Time)
      final timestamp = operation.timestamp ?? DateTime.now();
      final summaryKeys = SummaryHelper.getSummaryKeys(timestamp);

      final type = operation.type.toLowerCase();
      final isShop = type == AppStrings.shop.toLowerCase();
      final isPS = type == AppStrings.playStation.toLowerCase();

      for (final key in summaryKeys) {
        final summaryRef = userRef.collection('summaries').doc(key);
        batch.set(summaryRef, {
          'totalIncome': FieldValue.increment(operation.totalAmount),
          if (isShop) 'cafeIncome': FieldValue.increment(operation.totalAmount),
          if (isPS)
            'playstationIncome': FieldValue.increment(operation.totalAmount),
          'transactionCount': FieldValue.increment(1),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 3. Record Vault Inflow for fully paid direct operations
      final double paidCash = operation.remainingDebt <= 0
          ? (operation.paidAmount > 0
                ? operation.paidAmount
                : operation.totalAmount)
          : operation.paidAmount;

      if (AppStrings.isVaultEnabled() && paidCash > 0) {
        final vaultTxRef = userRef
            .collection('vault_transactions')
            .doc('vault_tx_op_${docRef.id}');
        final vaultSummaryRef = userRef.collection('vault').doc('summary');

        final String desc =
            operation.productName != null && operation.productName!.isNotEmpty
            ? '${operation.productName}'
            : (operation.type);

        batch.set(vaultTxRef, {
          'id': 'vault_tx_op_${docRef.id}',
          'uid': operation.uid,
          'amount': paidCash,
          'direction': 'in',
          'source': VaultTransactionSource.customerDebt.name,
          'type': 'cash_sale',
          'description': 'مبيعات مباشرة: $desc',
          'relatedEntityId': docRef.id,
          'createdAt': Timestamp.fromDate(timestamp),
        });

        batch.set(vaultSummaryRef, {
          'currentBalance': FieldValue.increment(paidCash),
          'totalIn': FieldValue.increment(paidCash),
          'transactionCount': FieldValue.increment(1),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 4. Log Employee Activity
      if (sl.isRegistered<ActivityLoggerService>()) {
        final desc =
            operation.productName != null && operation.productName!.isNotEmpty
            ? operation.productName!
            : operation.type;
        final hasDebt = operation.remainingDebt > 0;
        final totalFormatted = operation.totalAmount.toSmartAmount();
        final paidFormatted = operation.paidAmount.toSmartAmount();
        final remFormatted = operation.remainingDebt.toSmartAmount();
        final hasCustomer =
            operation.customerName != null &&
            operation.customerName!.trim().isNotEmpty;
        final customerNameStr = hasCustomer
            ? operation.customerName!.trim()
            : '';

        final actionTitle = hasCustomer
            ? (hasDebt
                  ? 'بيع آجل للعميل: $customerNameStr ($desc)'
                  : 'بيع مباشر للعميل: $customerNameStr ($desc)')
            : (hasDebt
                  ? 'بيع آجل (POS): $desc'
                  : 'بيع مباشر نقدي (POS): $desc');

        final detailsText = hasDebt
            ? 'تسجيل بيع آجل${hasCustomer ? " للعميل $customerNameStr" : ""} ($desc) بمبلغ $totalFormatted ${AppStrings.currencyEgp.tr()} (المدفوع: $paidFormatted ج.م، والمتبقي دين: $remFormatted ج.م)'
            : 'تسجيل عملية بيع مباشر نقدي${hasCustomer ? " للعميل $customerNameStr" : ""} ($desc) بمبلغ $totalFormatted ${AppStrings.currencyEgp.tr()}';

        sl<ActivityLoggerService>().appendToBatch(
          batch,
          ownerUid: operation.uid,
          actionCategory: 'sales',
          actionType: hasDebt ? 'pos_sale_with_debt' : 'pos_quick_sale_cash',
          actionTitle: actionTitle,
          details: detailsText,
          amount: operation.totalAmount,
          extraData: {
            'operationId': docRef.id,
            'type': operation.type,
            'productName': operation.productName,
            'customerName': operation.customerName,
            'totalAmount': operation.totalAmount,
            'paidAmount': operation.paidAmount,
            'remainingDebt': operation.remainingDebt,
            'hasDebt': hasDebt,
          },
          timestamp: timestamp,
        );
      }

      await batch.commit();
      return docRef.id;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to add operation: $e');
    }
  }
}
