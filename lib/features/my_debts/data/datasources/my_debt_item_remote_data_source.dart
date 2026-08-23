import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:tahsel/core/error/firebase_error_handler.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/usecases/pagination_params.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/date_formatter.dart';
import 'package:tahsel/features/expenses/data/datasources/expense_remote_data_source.dart';
import 'package:tahsel/features/expenses/data/models/expense_model.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_item_model.dart';
import 'package:tahsel/features/inventory/data/datasources/inventory_local_data_source.dart';
import 'package:tahsel/features/inventory/data/models/inventory_purchase_model.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_payment_model.dart';
import 'package:tahsel/features/cashbox/data/datasources/vault_remote_data_source.dart';
import 'package:tahsel/features/cashbox/domain/entities/vault_transaction_entity.dart';

abstract class MyDebtItemRemoteDataSource {
  Future<String> addDebtItem(MyDebtItemModel debt);
  Future<List<MyDebtItemModel>> getDebtItems(
    String uid,
    String personName, {
    bool forceRefresh = false,
  });
  Future<void> payDebtItem(MyDebtItemModel debt, MyDebtPaymentModel payment);
  Future<void> distributePayment(
    String uid,
    String personName,
    double amount, {
    String? note,
    DateTime? paymentDate,
  });
  Future<void> markPersonAsPaid(String uid, String personName);
  Future<void> payItem({
    required String uid,
    required String debtId,
    required double amount,
    String? note,
    DateTime? paymentDate,
  });
  Future<void> deleteDebtItem(String uid, String debtId);
  Stream<List<MyDebtItemModel>> getDebtsStream(String uid);
  Future<List<MyDebtPaymentModel>> getDebtItemPayments(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  });
  Future<PaginatedResult<MyDebtPaymentModel>> getDebtItemPaymentsPaginated(
    String uid,
    String debtId, {
    required int limit,
    DocumentSnapshot? lastDocument,
    bool forceRefresh = false,
  });
  Future<void> updateMyDebtPayment({
    required String uid,
    required String debtId,
    required String paymentId,
    required double newAmount,
    String? note,
  });
  Future<void> deleteMyDebtPayment({
    required String uid,
    required String debtId,
    required String paymentId,
  });
  Future<void> settleSupplierCredit({
    required String uid,
    required String debtId,
    required double creditAmount,
    String? note,
  });
  Future<MyDebtItemModel?> getMyDebtItemById(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  });
}

class MyDebtItemRemoteDataSourceImpl implements MyDebtItemRemoteDataSource {
  final FirebaseFirestore firestore;
  final ExpenseRemoteDataSource? expenseRemoteDataSource;

  MyDebtItemRemoteDataSourceImpl({
    required this.firestore,
    this.expenseRemoteDataSource,
  });

  @override
  Future<MyDebtItemModel?> getMyDebtItemById(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  }) async {
    try {
      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_items')
          .doc(debtId)
          .get(
            GetOptions(
              source: forceRefresh ? Source.server : Source.serverAndCache,
            ),
          );

      if (doc.exists) {
        return MyDebtItemModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<void> settleSupplierCredit({
    required String uid,
    required String debtId,
    required double creditAmount,
    String? note,
  }) async {
    try {
      final userRef = firestore.collection('users').doc(uid);
      final debtRef = userRef.collection('my_debt_items').doc(debtId);

      final debtSnap = await debtRef.get();
      if (!debtSnap.exists) return;

      final debtData = debtSnap.data() as Map<String, dynamic>;
      final double totalAmount =
          (debtData['totalAmount'] as num? ?? 0.0).toDouble();
      final String personName = debtData['personName'] as String? ?? '';
      final String operationId = debtData['operationId'] as String? ?? '';

      final double newPaid = totalAmount;
      final double newRemaining = 0.0;
      final bool isPaid = true;

      final batch = firestore.batch();

      batch.update(debtRef, {
        'paidAmount': newPaid,
        'remainingAmount': newRemaining,
        'isPaid': isPaid,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });

      final paymentRef = debtRef.collection('payments').doc();
      batch.set(paymentRef, {
        'debtId': debtId,
        'amountPaid': -creditAmount,
        'remainingAmount': newRemaining,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'settlement',
        'note': note ?? 'استلام الرصيد الدائن من المورد',
      });

      if (operationId.isNotEmpty) {
        final opRef = userRef.collection('my_debt_operations').doc(operationId);
        batch.set(
          opRef,
          {
            'paidAmount': newPaid,
            'remainingDebt': newRemaining,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      if (personName.isNotEmpty) {
        final personRef = userRef.collection('my_debt_persons').doc(personName);
        batch.set(
          personRef,
          {
            'totalRemainingDebt': FieldValue.increment(creditAmount),
            'lastUsedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      final String? purchaseId = (operationId.startsWith('pur_'))
          ? operationId
          : (debtId.startsWith('debt_pur_')
              ? debtId.replaceAll('debt_', '')
              : null);
      if (purchaseId != null) {
        final purchaseRef =
            userRef.collection('inventory_purchases').doc(purchaseId);
        batch.set(
          purchaseRef,
          {
            'paidAmount': newPaid,
            'isPaid': isPaid,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      // Vault Inflow (Adding refunded credit from supplier to the vault)
      if (AppStrings.isVaultEnabled() && creditAmount > 0) {
        final vaultTxId = 'vault_tx_mydebt_${paymentRef.id}';
        final vaultTxRef =
            userRef.collection('vault_transactions').doc(vaultTxId);
        final vaultSummaryRef = userRef.collection('vault').doc('summary');

        final bool isPurchase = (debtId.startsWith('debt_pur_') ||
            operationId.startsWith('pur_'));

        batch.set(vaultTxRef, {
          'id': vaultTxId,
          'uid': uid,
          'amount': creditAmount,
          'direction': 'in',
          'source': isPurchase
              ? VaultTransactionSource.inventory.name
              : VaultTransactionSource.myDebt.name,
          'type': 'supplier_credit_settlement',
          'description': 'استلام الرصيد الدائن من المورد: $personName',
          'relatedEntityId': paymentRef.id,
          'relatedOperationId': debtId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        batch.set(
          vaultSummaryRef,
          {
            'currentBalance': FieldValue.increment(creditAmount),
            'totalIn': FieldValue.increment(creditAmount),
            'transactionCount': FieldValue.increment(1),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      await _recalculatePersonTotals(uid, personName);

      await _syncPurchasePaidAmount(
        uid: uid,
        debtId: debtId,
        operationId: operationId,
      );
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  ExpenseRemoteDataSource get _expenseDataSource =>
      expenseRemoteDataSource ?? GetIt.I<ExpenseRemoteDataSource>();

  Future<void> _syncPaymentToExpense({
    required String uid,
    required String paymentId,
    required double amountPaid,
    required DateTime paymentDate,
    required String personName,
    required String? operationId,
    required String debtId,
    String? note,
    double? previousAmount,
  }) async {
    try {
      if (amountPaid <= 0 && (previousAmount == null || previousAmount <= 0)) return;

      final expenseId = 'exp_pay_$paymentId';
      final String? purchaseId = (operationId != null && operationId.startsWith('pur_'))
          ? operationId
          : (debtId.startsWith('debt_pur_')
              ? debtId.replaceAll('debt_', '')
              : null);

      final String categoryName = (purchaseId != null && purchaseId.isNotEmpty)
          ? (AppStrings.inventoryPurchases.tr().isNotEmpty
              ? AppStrings.inventoryPurchases.tr()
              : 'مشتريات مخزون')
          : (AppStrings.myDebts.tr().isNotEmpty
              ? AppStrings.myDebts.tr()
              : 'سداد ديون');

      final String cleanId =
          purchaseId != null ? purchaseId.replaceAll('pur_', '') : '';
      final String description = purchaseId != null
          ? '${AppStrings.purchaseInvoiceNum.tr()} #$cleanId - $personName${note != null && note.isNotEmpty ? " ($note)" : ""}'
          : 'سداد دين - $personName${note != null && note.isNotEmpty ? " ($note)" : ""}';

      final expense = ExpenseModel(
        id: expenseId,
        uid: uid,
        amount: amountPaid,
        category: categoryName,
        description: description,
        createdAt: paymentDate,
        monthKey: DateFormatter.formatNumericMonth(paymentDate),
      );

      await _expenseDataSource.addExpense(expense, previousAmount: previousAmount);
    } catch (_) {}
  }

  Future<void> _deletePaymentExpense({
    required String uid,
    required String paymentId,
  }) async {
    try {
      final expenseId = 'exp_pay_$paymentId';
      await _expenseDataSource.deleteExpense(uid, expenseId);
    } catch (_) {}
  }

  Future<void> _syncPurchasePaidAmount({
    required String uid,
    required String debtId,
    required String? operationId,
  }) async {
    try {
      final String? purchaseId = (operationId != null && operationId.startsWith('pur_'))
          ? operationId
          : (debtId.startsWith('debt_pur_')
              ? debtId.replaceAll('debt_', '')
              : null);

      if (purchaseId == null) return;

      final debtRef = firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_items')
          .doc(debtId);

      final debtSnap = await debtRef.get();
      if (!debtSnap.exists) return;

      final data = debtSnap.data() as Map<String, dynamic>;
      final double paidAmount = (data['paidAmount'] as num? ?? 0.0).toDouble();
      final double totalAmount = (data['totalAmount'] as num? ?? 0.0).toDouble();
      final bool isPaid = paidAmount >= totalAmount;

      final purchaseRef = firestore
          .collection('users')
          .doc(uid)
          .collection('inventory_purchases')
          .doc(purchaseId);

      await purchaseRef.set({
        'paidAmount': paidAmount,
        'isPaid': isPaid,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also update local cache if InventoryLocalDataSource is available
      if (GetIt.I.isRegistered<InventoryLocalDataSource>()) {
        final localDS = GetIt.I<InventoryLocalDataSource>();
        final purchases = await localDS.getPurchases();
        final idx = purchases.indexWhere((p) => p.id == purchaseId);
        if (idx != -1) {
          final updated = InventoryPurchaseModel.fromEntity(
            purchases[idx].copyWith(
              paidAmount: paidAmount,
              isSynced: true,
            ),
          );
          await localDS.savePurchase(updated);
        }
      }
    } catch (_) {}
  }

  Future<void> _recalculatePersonTotals(String uid, String personName) async {
    if (personName.isEmpty) return;
    try {
      final itemsSnap = await firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_items')
          .where('personName', isEqualTo: personName)
          .get();

      double sumTotal = 0.0;
      double sumRemaining = 0.0;
      int count = itemsSnap.docs.length;

      for (var doc in itemsSnap.docs) {
        final data = doc.data();
        sumTotal += (data['totalAmount'] as num? ?? 0.0).toDouble();
        sumRemaining += (data['remainingAmount'] as num? ?? 0.0).toDouble();
      }

      final personRef = firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_persons')
          .doc(personName);

      await personRef.set(
        {
          'name': personName,
          'totalDebtAmount': sumTotal,
          'totalRemainingDebt': sumRemaining,
          'totalTransactions': count,
          'lastUsedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  @override
  Future<String> addDebtItem(MyDebtItemModel debt) async {
    try {
      final userRef = firestore.collection('users').doc(debt.uid);

      final debtRef = (debt.id != null && debt.id!.isNotEmpty)
          ? userRef.collection('my_debt_items').doc(debt.id)
          : userRef.collection('my_debt_items').doc();
      final opRef = userRef
          .collection('my_debt_operations')
          .doc(debt.operationId);

      final personRef = userRef
          .collection('my_debt_persons')
          .doc(debt.personName);

      // Check if debt item already exists (e.g., editing an existing purchase invoice)
      final existingDebtSnap = await debtRef.get();
      if (existingDebtSnap.exists) {
        final existingData = existingDebtSnap.data() as Map<String, dynamic>;
        final double oldTotal =
            (existingData['totalAmount'] as num? ?? 0.0).toDouble();
        final double existingPaid =
            (existingData['paidAmount'] as num? ?? 0.0).toDouble();
        final double oldRemaining =
            (existingData['remainingAmount'] as num? ?? 0.0).toDouble();

        final double newTotal = debt.totalAmount;
        // Preserve existing payment history!
        final double actualPaid = existingPaid;
        final double newRemaining = newTotal - actualPaid;
        final bool isPaid = newRemaining <= 0;

        final updatedModel = MyDebtItemModel.fromEntity(
          debt.copyWith(
            id: debtRef.id,
            totalAmount: newTotal,
            paidAmount: actualPaid,
            remainingAmount: newRemaining,
            isPaid: isPaid,
          ),
        );

        final double deltaTotal = newTotal - oldTotal;
        final double deltaRemaining = newRemaining - oldRemaining;

        final batch = firestore.batch();
        batch.set(debtRef, updatedModel.toJson(), SetOptions(merge: true));

        batch.set(
          opRef,
          {
            'uid': debt.uid,
            'type': debt.operationType,
            'personName': debt.personName,
            'details': debt.details,
            'totalAmount': newTotal,
            'paidAmount': actualPaid,
            'remainingDebt': newRemaining,
            'timestamp': debt.timestamp != null
                ? Timestamp.fromDate(debt.timestamp!)
                : FieldValue.serverTimestamp(),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        batch.set(
          personRef,
          {
            'name': debt.personName,
            'lastUsedAt': debt.timestamp != null
                ? Timestamp.fromDate(debt.timestamp!)
                : FieldValue.serverTimestamp(),
            'totalDebtAmount': FieldValue.increment(deltaTotal),
            'totalRemainingDebt': FieldValue.increment(deltaRemaining),
          },
          SetOptions(merge: true),
        );

        final debtAddedQuery = await debtRef
            .collection('payments')
            .where('type', isEqualTo: 'debtAdded')
            .limit(1)
            .get();
        if (debtAddedQuery.docs.isNotEmpty) {
          final debtAddedDocRef = debtAddedQuery.docs.first.reference;
          batch.set(
            debtAddedDocRef,
            {
              'amountPaid': newTotal,
              'remainingAmount': newTotal,
            },
            SetOptions(merge: true),
          );
        }

        await batch.commit();
        await _recalculatePersonTotals(debt.uid, debt.personName ?? '');
        return debtRef.id;
      }

      final modelToSave = (debt.id != null && debt.id!.isNotEmpty)
          ? debt
          : MyDebtItemModel.fromEntity(debt.copyWith(id: debtRef.id));

      // Get person first to check if firstDate needs to be set/updated
      final personDoc = await personRef.get();
      final bool firstDateIsNull = !personDoc.exists || personDoc.data()?['firstDate'] == null;

      // Update firstDate if it's null OR if the new debt's date is earlier
      bool shouldUpdateFirstDate = firstDateIsNull;
      if (!firstDateIsNull && debt.timestamp != null) {
        final existingFirstDate = (personDoc.data()?['firstDate'] as Timestamp?)?.toDate();
        if (existingFirstDate != null && debt.timestamp!.isBefore(existingFirstDate)) {
          shouldUpdateFirstDate = true;
        }
      }

      final bool isPurchase = (debt.id?.startsWith('debt_pur_') == true ||
          debt.operationId.startsWith('pur_') ||
          debt.operationType.contains('مشتريات') ||
          debt.operationType.contains('Purchase'));

      // Balance Check before batch commit for initial paid amount (Only for non-purchase debts because purchases already perform balance check)
      if (AppStrings.isVaultEnabled() && debt.paidAmount > 0 && !isPurchase) {
        final summaryDoc = await userRef.collection('vault').doc('summary').get();
        final double currentBalance = (summaryDoc.exists && summaryDoc.data() != null)
            ? ((summaryDoc.data()!['currentBalance'] as num?)?.toDouble() ?? 0.0)
            : 0.0;
        if (currentBalance <= 0 || currentBalance < debt.paidAmount) {
          throw Exception(AppStrings.insufficientBalance);
        }
      }

      final batch = firestore.batch();

      // 1. Add/Update debt item doc
      batch.set(debtRef, modelToSave.toJson(), SetOptions(merge: true));

      // 2. Add/Update operation record
      batch.set(opRef, {
        'uid': debt.uid,
        'type': debt.operationType,
        'personName': debt.personName,
        'details': debt.details,
        'totalAmount': debt.totalAmount,
        'paidAmount': debt.paidAmount,
        'remainingDebt': debt.remainingAmount,
        'timestamp': debt.timestamp != null
            ? Timestamp.fromDate(debt.timestamp!)
            : FieldValue.serverTimestamp(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Add initial transaction record
      final initialPaymentRef = debtRef.collection('payments').doc();
      batch.set(initialPaymentRef, {
        'debtId': debtRef.id,
        'amountPaid': debt.totalAmount,
        'remainingAmount': debt.totalAmount,
        'createdAt': debt.timestamp != null
            ? Timestamp.fromDate(debt.timestamp!)
            : FieldValue.serverTimestamp(),
        'type': 'debtAdded',
      });

      DocumentReference? actualPaymentRef;
      if (debt.paidAmount > 0) {
        actualPaymentRef = debtRef.collection('payments').doc();
        batch.set(actualPaymentRef, {
          'debtId': debtRef.id,
          'amountPaid': debt.paidAmount,
          'remainingAmount': debt.remainingAmount,
          'createdAt': debt.timestamp != null
              ? Timestamp.fromDate(
                  debt.timestamp!.add(const Duration(milliseconds: 1)),
                )
              : FieldValue.serverTimestamp(),
          'type': debt.remainingAmount <= 0 ? 'full' : 'partial',
        });

        // Only sync to Vault if NOT a purchase (since InventoryRepository already handles the purchase vault transaction)
        if (AppStrings.isVaultEnabled() && !isPurchase) {
          final vaultTxRef = userRef.collection('vault_transactions').doc('vault_tx_mydebt_${actualPaymentRef.id}');
          final vaultSummaryRef = userRef.collection('vault').doc('summary');

          batch.set(vaultTxRef, {
            'id': 'vault_tx_mydebt_${actualPaymentRef.id}',
            'uid': debt.uid,
            'amount': debt.paidAmount,
            'direction': 'out',
            'source': VaultTransactionSource.myDebt.name,
            'type': 'debt_payment',
            'description': 'سداد دين للمورد/الشخص: ${debt.personName ?? ''}',
            'relatedEntityId': actualPaymentRef.id,
            'relatedOperationId': debt.id,
            'createdAt': debt.timestamp != null
                ? Timestamp.fromDate(debt.timestamp!.add(const Duration(milliseconds: 1)))
                : FieldValue.serverTimestamp(),
          });

          batch.set(
            vaultSummaryRef,
            {
              'currentBalance': FieldValue.increment(-debt.paidAmount),
              'totalOut': FieldValue.increment(debt.paidAmount),
              'transactionCount': FieldValue.increment(1),
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      }

      // 5. Update person doc with totals
      final Map<String, dynamic> personUpdate = {
        'name': debt.personName,
        'lastUsedAt': debt.timestamp != null
            ? Timestamp.fromDate(debt.timestamp!)
            : FieldValue.serverTimestamp(),
        'totalDebtAmount': FieldValue.increment(debt.totalAmount),
        'totalRemainingDebt': FieldValue.increment(debt.remainingAmount),
        'totalTransactions': FieldValue.increment(1),
      };

      if (debt.phoneNumber != null && debt.phoneNumber!.isNotEmpty) {
        personUpdate['phoneNumber'] = debt.phoneNumber;
      }

      if (shouldUpdateFirstDate) {
        personUpdate['firstDate'] = debt.timestamp != null
            ? Timestamp.fromDate(debt.timestamp!)
            : FieldValue.serverTimestamp();
      }

      batch.set(personRef, personUpdate, SetOptions(merge: true));

      await batch.commit();
      await _recalculatePersonTotals(debt.uid, debt.personName ?? '');

      if (actualPaymentRef != null &&
          !debt.operationId.startsWith('pur_')) {
        await _syncPaymentToExpense(
          uid: debt.uid,
          paymentId: actualPaymentRef.id,
          amountPaid: debt.paidAmount,
          paymentDate: debt.timestamp ?? DateTime.now(),
          personName: debt.personName ?? '',
          operationId: debt.operationId,
          debtId: debtRef.id,
          note: debt.details,
        );
      }
      return debtRef.id;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<List<MyDebtItemModel>> getDebtItems(
    String uid,
    String personName, {
    bool forceRefresh = false,
  }) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_items')
          .where('personName', isEqualTo: personName)
          .orderBy('timestamp', descending: true)
          .get(
            GetOptions(
              source: forceRefresh ? Source.server : Source.serverAndCache,
            ),
          );

      return snapshot.docs
          .map((doc) => MyDebtItemModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<void> payDebtItem(
    MyDebtItemModel debt,
    MyDebtPaymentModel payment,
  ) async {
    try {
      final uid = debt.uid;
      final debtRef = firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_items')
          .doc(debt.id);

      final paymentRef = debtRef.collection('payments').doc();
      final batch = firestore.batch();

      batch.update(debtRef, debt.toJson());
      batch.set(paymentRef, payment.toJson());

      if (debt.operationId.isNotEmpty) {
        final opRef = firestore
            .collection('users')
            .doc(uid)
            .collection('my_debt_operations')
            .doc(debt.operationId);
        batch.update(opRef, {
          'paidAmount': debt.paidAmount,
          'remainingDebt': debt.remainingAmount,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Update person doc
      final personRef = firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_persons')
          .doc(debt.personName);
      batch.update(personRef, {
        'totalRemainingDebt': FieldValue.increment(-payment.amountPaid),
        'lastUsedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      final bool isPurchase = (debt.id?.startsWith('debt_pur_') == true ||
          debt.operationId.startsWith('pur_') ||
          debt.operationType.contains('مشتريات') ||
          debt.operationType.contains('Purchase'));

      await VaultRemoteDataSourceImpl.syncVaultTransaction(
        firestore: firestore,
        uid: uid,
        transactionId: 'vault_tx_mydebt_${paymentRef.id}',
        amount: payment.amountPaid,
        direction: VaultTransactionDirection.outFlow,
        source: isPurchase
            ? VaultTransactionSource.inventory
            : VaultTransactionSource.myDebt,
        type: isPurchase ? 'purchase_payment' : 'debt_payment',
        description: isPurchase
            ? 'سداد دفعة شراء للمورد: ${debt.personName ?? ''}'
            : 'سداد دين للمورد/الشخص: ${debt.personName ?? ''}',
        relatedEntityId: paymentRef.id,
        relatedOperationId: debt.id,
        createdAt: payment.createdAt,
      );

      await _recalculatePersonTotals(uid, debt.personName ?? '');
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<void> distributePayment(
    String uid,
    String personName,
    double amount, {
    String? note,
    DateTime? paymentDate,
  }) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_items')
          .where('personName', isEqualTo: personName)
          .where('isPaid', isEqualTo: false)
          .orderBy('timestamp', descending: false)
          .get();

      if (AppStrings.isVaultEnabled() && amount > 0) {
        final summaryDoc = await firestore
            .collection('users')
            .doc(uid)
            .collection('vault')
            .doc('summary')
            .get();
        final double currentBalance = (summaryDoc.exists && summaryDoc.data() != null)
            ? ((summaryDoc.data()!['currentBalance'] as num?)?.toDouble() ?? 0.0)
            : 0.0;
        if (currentBalance <= 0 || currentBalance < amount) {
          throw Exception(AppStrings.insufficientBalance);
        }
      }

      final batch = firestore.batch();
      double remainingToPay = amount;

      final List<Map<String, dynamic>> createdPayments = [];

      for (var doc in snapshot.docs) {
        if (remainingToPay <= 0) break;

        final debtData = doc.data();
        final debtId = doc.id;
        final operationId = debtData['operationId'] as String?;
        final currentTotal = (debtData['totalAmount'] as num).toDouble();
        final currentPaid = (debtData['paidAmount'] as num).toDouble();
        final currentRemaining = (debtData['remainingAmount'] as num)
            .toDouble();

        double paymentForThisItem = 0;
        if (remainingToPay >= currentRemaining) {
          paymentForThisItem = currentRemaining;
          remainingToPay -= currentRemaining;
        } else {
          paymentForThisItem = remainingToPay;
          remainingToPay = 0;
        }

        final newPaidAmount = currentPaid + paymentForThisItem;
        final newRemainingAmount = currentTotal - newPaidAmount;
        final isPaid = newRemainingAmount <= 0;

        final debtRef = firestore
            .collection('users')
            .doc(uid)
            .collection('my_debt_items')
            .doc(debtId);

        batch.update(debtRef, {
          'paidAmount': newPaidAmount,
          'remainingAmount': newRemainingAmount,
          'isPaid': isPaid,
          'lastUpdatedAt': paymentDate != null ? Timestamp.fromDate(paymentDate) : FieldValue.serverTimestamp(),
        });

        if (operationId != null && operationId.isNotEmpty) {
          batch.update(
            firestore
                .collection('users')
                .doc(uid)
                .collection('my_debt_operations')
                .doc(operationId),
            {
              'paidAmount': newPaidAmount,
              'remainingDebt': newRemainingAmount,
              'lastUpdatedAt': paymentDate != null ? Timestamp.fromDate(paymentDate) : FieldValue.serverTimestamp(),
            },
          );
        }

        final paymentRef = debtRef.collection('payments').doc();
        batch.set(paymentRef, {
          'debtId': debtId,
          'amountPaid': paymentForThisItem,
          'remainingAmount': newRemainingAmount,
          'createdAt': paymentDate != null ? Timestamp.fromDate(paymentDate) : FieldValue.serverTimestamp(),
          'type': isPaid ? 'full' : 'partial',
          'note': note,
        });

        createdPayments.add({
          'paymentId': paymentRef.id,
          'amountPaid': paymentForThisItem,
          'debtId': debtId,
          'operationId': operationId,
        });
      }

      // Update person doc once with total amount distributed
      final personRef = firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_persons')
          .doc(personName);
      batch.update(personRef, {
        'totalRemainingDebt': FieldValue.increment(-amount),
        'lastUsedAt': paymentDate != null ? Timestamp.fromDate(paymentDate) : FieldValue.serverTimestamp(),
      });

      await batch.commit();
      await _recalculatePersonTotals(uid, personName);

      for (final p in createdPayments) {
        final paymentId = p['paymentId'] as String;
        final amountPaid = p['amountPaid'] as double;
        final debtId = p['debtId'] as String;
        final operationId = p['operationId'] as String?;

        final bool isPurchase = (debtId.startsWith('debt_pur_') ||
            (operationId != null && operationId.startsWith('pur_')));

        if (amountPaid > 0) {
          await VaultRemoteDataSourceImpl.syncVaultTransaction(
            firestore: firestore,
            uid: uid,
            transactionId: 'vault_tx_mydebt_$paymentId',
            amount: amountPaid,
            direction: VaultTransactionDirection.outFlow,
            source: isPurchase
                ? VaultTransactionSource.inventory
                : VaultTransactionSource.myDebt,
            type: isPurchase ? 'purchase_payment' : 'debt_payment',
            description: isPurchase
                ? 'سداد دفعة شراء للمورد: $personName'
                : 'سداد دين للمورد/الشخص: $personName',
            relatedEntityId: paymentId,
            relatedOperationId: debtId,
            createdAt: paymentDate ?? DateTime.now(),
          );
        }

        await _syncPaymentToExpense(
          uid: uid,
          paymentId: paymentId,
          amountPaid: amountPaid,
          paymentDate: paymentDate ?? DateTime.now(),
          personName: personName,
          operationId: operationId,
          debtId: debtId,
          note: note,
        );
        await _syncPurchasePaidAmount(
          uid: uid,
          debtId: debtId,
          operationId: operationId,
        );
      }
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<void> markPersonAsPaid(String uid, String personName) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_items')
          .where('personName', isEqualTo: personName)
          .where('isPaid', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      double totalRequired = 0.0;
      for (var doc in snapshot.docs) {
        final debtData = doc.data();
        final currentTotal = (debtData['totalAmount'] as num).toDouble();
        final amountPaid = currentTotal - (debtData['paidAmount'] as num).toDouble();
        if (amountPaid > 0) {
          totalRequired += amountPaid;
        }
      }

      if (AppStrings.isVaultEnabled() && totalRequired > 0) {
        final summaryDoc = await firestore
            .collection('users')
            .doc(uid)
            .collection('vault')
            .doc('summary')
            .get();
        final double currentBalance = (summaryDoc.exists && summaryDoc.data() != null)
            ? ((summaryDoc.data()!['currentBalance'] as num?)?.toDouble() ?? 0.0)
            : 0.0;
        if (currentBalance <= 0 || currentBalance < totalRequired) {
          throw Exception(AppStrings.insufficientBalance);
        }
      }

      final batch = firestore.batch();
      final List<Map<String, dynamic>> createdPayments = [];

      for (var doc in snapshot.docs) {
        final debtData = doc.data();
        final debtId = doc.id;
        final operationId = debtData['operationId'] as String?;
        final currentTotal = (debtData['totalAmount'] as num).toDouble();
        final amountPaid =
            currentTotal - (debtData['paidAmount'] as num).toDouble();

        final debtRef = firestore
            .collection('users')
            .doc(uid)
            .collection('my_debt_items')
            .doc(debtId);

        batch.update(debtRef, {
          'paidAmount': currentTotal,
          'remainingAmount': 0.0,
          'isPaid': true,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });

        if (operationId != null && operationId.isNotEmpty) {
          batch.update(
            firestore
                .collection('users')
                .doc(uid)
                .collection('my_debt_operations')
                .doc(operationId),
            {
              'paidAmount': currentTotal,
              'remainingDebt': 0.0,
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            },
          );
        }

        final paymentRef = debtRef.collection('payments').doc();
        batch.set(paymentRef, {
          'debtId': debtId,
          'amountPaid': amountPaid,
          'remainingAmount': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'type': 'settlement',
        });

        createdPayments.add({
          'paymentId': paymentRef.id,
          'amountPaid': amountPaid,
          'debtId': debtId,
          'operationId': operationId,
        });
      }

      // Update person doc - set remaining debt to 0
      final personRef = firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_persons')
          .doc(personName);
      batch.update(personRef, {
        'totalRemainingDebt': 0.0,
        'lastUsedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      for (final p in createdPayments) {
        final paymentId = p['paymentId'] as String;
        final amountPaid = p['amountPaid'] as double;
        final debtId = p['debtId'] as String;
        final operationId = p['operationId'] as String?;

        final bool isPurchase = (debtId.startsWith('debt_pur_') ||
            (operationId != null && operationId.startsWith('pur_')));

        if (amountPaid > 0) {
          await VaultRemoteDataSourceImpl.syncVaultTransaction(
            firestore: firestore,
            uid: uid,
            transactionId: 'vault_tx_mydebt_$paymentId',
            amount: amountPaid,
            direction: VaultTransactionDirection.outFlow,
            source: isPurchase
                ? VaultTransactionSource.inventory
                : VaultTransactionSource.myDebt,
            type: isPurchase ? 'full_purchase_settlement' : 'full_debt_settlement',
            description: isPurchase
                ? 'تسوية مديونية شراء للمورد بالكامل: $personName'
                : 'تسوية مديونية للمورد/الشخص بالكامل: $personName',
            relatedEntityId: paymentId,
            relatedOperationId: debtId,
            createdAt: DateTime.now(),
          );
        }

        await _syncPaymentToExpense(
          uid: uid,
          paymentId: paymentId,
          amountPaid: amountPaid,
          paymentDate: DateTime.now(),
          personName: personName,
          operationId: operationId,
          debtId: debtId,
          note: 'تسوية المديونية بالكامل',
        );
        await _syncPurchasePaidAmount(
          uid: uid,
          debtId: debtId,
          operationId: operationId,
        );
      }
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<void> payItem({
    required String uid,
    required String debtId,
    required double amount,
    String? note,
    DateTime? paymentDate,
  }) async {
    try {
      final debtRef = firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_items')
          .doc(debtId);

      String personName = '';
      String? operationId;
      String paymentId = '';

      // Balance check before starting transaction (prevents Windows C++ plugin crash inside runTransaction)
      if (AppStrings.isVaultEnabled() && amount > 0) {
        final vaultSummaryRef = firestore
            .collection('users')
            .doc(uid)
            .collection('vault')
            .doc('summary');
        final vaultSnap = await vaultSummaryRef.get();
        final double currentVaultBalance = (vaultSnap.exists && vaultSnap.data() != null)
            ? ((vaultSnap.data()!['currentBalance'] as num?)?.toDouble() ?? 0.0)
            : 0.0;
        if (currentVaultBalance <= 0 || currentVaultBalance < amount) {
          throw Exception(AppStrings.insufficientBalance);
        }
      }

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(debtRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final currentPaid = (data['paidAmount'] as num).toDouble();
        final totalAmount = (data['totalAmount'] as num).toDouble();
        operationId = data['operationId'] as String?;
        personName = data['personName'] as String? ?? '';

        final newPaidAmount = currentPaid + amount;
        final newRemainingAmount = totalAmount - newPaidAmount;
        final isPaid = newRemainingAmount <= 0;

        // 1. Update debt item
        transaction.update(debtRef, {
          'paidAmount': newPaidAmount,
          'remainingAmount': newRemainingAmount,
          'isPaid': isPaid,
          'lastUpdatedAt': paymentDate != null ? Timestamp.fromDate(paymentDate) : FieldValue.serverTimestamp(),
        });

        // 2. Update operation if exists
        if (operationId != null && operationId!.isNotEmpty) {
          final opRef = firestore
              .collection('users')
              .doc(uid)
              .collection('my_debt_operations')
              .doc(operationId!);
          transaction.update(opRef, {
            'paidAmount': newPaidAmount,
            'remainingDebt': newRemainingAmount,
            'lastUpdatedAt': paymentDate != null ? Timestamp.fromDate(paymentDate) : FieldValue.serverTimestamp(),
          });
        }

        // 3. Add payment record
        final paymentRef = debtRef.collection('payments').doc();
        paymentId = paymentRef.id;
        transaction.set(paymentRef, {
          'debtId': debtId,
          'amountPaid': amount,
          'remainingAmount': newRemainingAmount,
          'createdAt': paymentDate != null ? Timestamp.fromDate(paymentDate) : FieldValue.serverTimestamp(),
          'type': isPaid ? 'full' : 'partial',
          'note': note,
        });

        // 4. Update person doc
        final personRef = firestore
            .collection('users')
            .doc(uid)
            .collection('my_debt_persons')
            .doc(personName);
        transaction.update(personRef, {
          'totalRemainingDebt': FieldValue.increment(-amount),
          'lastUsedAt': paymentDate != null ? Timestamp.fromDate(paymentDate) : FieldValue.serverTimestamp(),
        });
      });

      if (paymentId.isNotEmpty) {
        final bool isPurchase = (debtId.startsWith('debt_pur_') ||
            (operationId != null && operationId!.startsWith('pur_')));

        if (amount > 0) {
          await VaultRemoteDataSourceImpl.syncVaultTransaction(
            firestore: firestore,
            uid: uid,
            transactionId: 'vault_tx_mydebt_$paymentId',
            amount: amount,
            direction: VaultTransactionDirection.outFlow,
            source: isPurchase
                ? VaultTransactionSource.inventory
                : VaultTransactionSource.myDebt,
            type: isPurchase ? 'purchase_payment' : 'debt_payment',
            description: isPurchase
                ? 'سداد دفعة شراء للمورد: $personName'
                : 'سداد دين للمورد/الشخص: $personName',
            relatedEntityId: paymentId,
            relatedOperationId: debtId,
            createdAt: paymentDate ?? DateTime.now(),
          );
        }

        await _syncPaymentToExpense(
          uid: uid,
          paymentId: paymentId,
          amountPaid: amount,
          paymentDate: paymentDate ?? DateTime.now(),
          personName: personName,
          operationId: operationId,
          debtId: debtId,
          note: note,
        );
        await _syncPurchasePaidAmount(
          uid: uid,
          debtId: debtId,
          operationId: operationId,
        );
      }
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<void> deleteDebtItem(String uid, String debtId) async {
    try {
      final debtRef = firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_items')
          .doc(debtId);

      // 0. Fetch debt to get amounts for updating person doc
      final debtSnap = await debtRef.get();
      if (!debtSnap.exists) return;
      final debtData = debtSnap.data() as Map<String, dynamic>;
      final personName = debtData['personName'] as String;
      final totalAmount = (debtData['totalAmount'] as num).toDouble();
      final remainingAmount = (debtData['remainingAmount'] as num).toDouble();
      final operationId = debtData['operationId'] as String?;

      // 1. Get payments to delete and remove their expense records
      final paymentsSnapshot = await debtRef.collection('payments').get();

      final List<DocumentReference> allRefs = [];
      for (var paymentDoc in paymentsSnapshot.docs) {
        allRefs.add(paymentDoc.reference);
        try {
          await _expenseDataSource.deleteExpense(uid, 'exp_pay_${paymentDoc.id}');
        } catch (_) {}
      }

      // 2. Add the debt doc itself
      allRefs.add(debtRef);

      // 3. Add the operation doc if exists
      if (operationId != null && operationId.isNotEmpty) {
        allRefs.add(
          firestore
              .collection('users')
              .doc(uid)
              .collection('my_debt_operations')
              .doc(operationId),
        );
      }

      // 3. Perform batch deletion (Firestore limit is 500)
      for (var i = 0; i < allRefs.length; i += 500) {
        final chunk = allRefs.sublist(
          i,
          i + 500 > allRefs.length ? allRefs.length : i + 500,
        );
        final batch = firestore.batch();
        for (var ref in chunk) {
          batch.delete(ref);
        }

        // On the last batch (or only batch), update the person doc
        if (i + 500 >= allRefs.length) {
          final personRef = firestore
              .collection('users')
              .doc(uid)
              .collection('my_debt_persons')
              .doc(personName);
          batch.update(personRef, {
            'totalDebtAmount': FieldValue.increment(-totalAmount),
            'totalRemainingDebt': FieldValue.increment(-remainingAmount),
            'totalTransactions': FieldValue.increment(-1),
            'lastUsedAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
      }
      await _recalculatePersonTotals(uid, personName);
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Stream<List<MyDebtItemModel>> getDebtsStream(String uid) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('my_debt_items')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MyDebtItemModel.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Future<List<MyDebtPaymentModel>> getDebtItemPayments(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  }) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_items')
          .doc(debtId)
          .collection('payments')
          .where(
            'type',
            whereIn: ['debtAdded', 'partial', 'full', 'adjustment', 'reversal'],
          )
          .orderBy('createdAt', descending: true)
          .get(
            GetOptions(
              source: forceRefresh ? Source.server : Source.serverAndCache,
            ),
          );

      return snapshot.docs
          .map((doc) => MyDebtPaymentModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<PaginatedResult<MyDebtPaymentModel>> getDebtItemPaymentsPaginated(
    String uid,
    String debtId, {
    required int limit,
    DocumentSnapshot? lastDocument,
    bool forceRefresh = false,
  }) async {
    try {
      var query = firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_items')
          .doc(debtId)
          .collection('payments')
          .where(
            'type',
            whereIn: ['debtAdded', 'partial', 'full', 'adjustment', 'reversal'],
          )
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Fetch limit + 1 to determine hasMore
      final snapshot = await query
          .limit(limit + 1)
          .get(
            GetOptions(
              source: forceRefresh ? Source.server : Source.serverAndCache,
            ),
          );

      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.sublist(0, limit) : snapshot.docs;

      final items = docs
          .map((doc) => MyDebtPaymentModel.fromJson(doc.data(), doc.id))
          .toList();

      final newLastDoc = docs.isNotEmpty ? docs.last : null;

      return PaginatedResult(
        items: items,
        lastDocument: newLastDoc,
        hasMore: hasMore,
      );
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<void> updateMyDebtPayment({
    required String uid,
    required String debtId,
    required String paymentId,
    required double newAmount,
    String? note,
  }) async {
    try {
      final debtRef = firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_items')
          .doc(debtId);

      MyDebtPaymentModel? targetPayment;
      String personName = '';
      String? operationId;

      await firestore.runTransaction((transaction) async {
        final debtSnap = await transaction.get(debtRef);
        if (!debtSnap.exists) throw Exception('Debt not found');

        personName = debtSnap.data()?['personName'] as String? ?? '';
        operationId = debtSnap.data()?['operationId'] as String?;

        final paymentsSnapshot = await debtRef
            .collection('payments')
            .orderBy('createdAt', descending: true)
            .get();
        final allPayments = paymentsSnapshot.docs
            .map((doc) => MyDebtPaymentModel.fromJson(doc.data(), doc.id))
            .toList();

        targetPayment = allPayments.firstWhere((p) => p.id == paymentId);
        final String relatedTo = targetPayment!.type == 'debtAdded'
            ? 'debt'
            : 'payment';

        // RULE 3 validation for debtAdded
        if (targetPayment!.type == 'debtAdded') {
          final paymentsAfter = allPayments
              .where(
                (p) =>
                    (p.type == 'partial' || p.type == 'full') &&
                    p.createdAt.isAfter(targetPayment!.createdAt),
              )
              .toList();

          if (paymentsAfter.isNotEmpty) {
            final nearestPayment = paymentsAfter.last;
            if (newAmount < nearestPayment.amountPaid) {
              throw Exception('invalid_amount');
            }
          }
        }

        final delta = newAmount - targetPayment!.amountPaid;
        if (delta == 0) return;

        // Direct Mutation: Update the same item
        final paymentRef = debtRef.collection('payments').doc(paymentId);
        transaction.update(paymentRef, {
          'amountPaid': newAmount,
          'note': note ?? targetPayment!.note,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });

        if (relatedTo == 'payment') {
          final userRef = firestore.collection('users').doc(uid);
          final vaultTxId = 'vault_tx_mydebt_${paymentId}_adj_${DateTime.now().millisecondsSinceEpoch}';
          final vaultTxRef = userRef.collection('vault_transactions').doc(vaultTxId);
          final vaultSummaryRef = userRef.collection('vault').doc('summary');

          final bool isPurchase = (debtId.startsWith('debt_pur_') ||
              (operationId != null && operationId!.startsWith('pur_')));

          transaction.set(vaultTxRef, {
            'id': vaultTxId,
            'uid': uid,
            'amount': delta.abs(),
            'direction': delta > 0 ? 'out' : 'in',
            'source': isPurchase
                ? VaultTransactionSource.inventory.name
                : VaultTransactionSource.myDebt.name,
            'type': 'adjustment',
            'description': isPurchase
                ? 'تعديل دفعة شراء: $personName'
                : 'تعديل دفعة دين: $personName',
            'relatedEntityId': paymentId,
            'relatedOperationId': debtId,
            'createdAt': FieldValue.serverTimestamp(),
          });

          transaction.set(
            vaultSummaryRef,
            {
              'currentBalance': FieldValue.increment(-delta),
              'totalOut': FieldValue.increment(delta > 0 ? delta : 0.0),
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }

        // Calculate new values
        final currentTotal = (debtSnap.data()?['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final currentPaid = (debtSnap.data()?['paidAmount'] as num?)?.toDouble() ?? 0.0;
        final currentRemaining = (debtSnap.data()?['remainingAmount'] as num?)?.toDouble() ?? 0.0;

        double newTotalAmount = currentTotal;
        double newPaidAmount = currentPaid;
        double newRemainingAmount = currentRemaining;

        if (relatedTo == 'debt') {
          newTotalAmount = currentTotal + delta;
          newRemainingAmount = currentRemaining + delta;
        } else {
          newPaidAmount = currentPaid + delta;
          newRemainingAmount = currentRemaining - delta;
        }

        final bool newIsPaid = newRemainingAmount <= 1e-9;

        // Update stored totals
        if (relatedTo == 'debt') {
          transaction.update(debtRef, {
            'totalAmount': newTotalAmount,
            'remainingAmount': newRemainingAmount,
            'isPaid': newIsPaid,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(debtRef, {
            'paidAmount': newPaidAmount,
            'remainingAmount': newRemainingAmount,
            'isPaid': newIsPaid,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Update operation if it exists
        if (operationId != null && operationId!.isNotEmpty) {
          final opRef = firestore
              .collection('users')
              .doc(uid)
              .collection('my_debt_operations')
              .doc(operationId);
          if (relatedTo == 'debt') {
            transaction.update(opRef, {
              'totalAmount': newTotalAmount,
              'remainingDebt': newRemainingAmount,
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            transaction.update(opRef, {
              'paidAmount': newPaidAmount,
              'remainingDebt': newRemainingAmount,
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        // Update person doc
        final personRef = firestore
            .collection('users')
            .doc(uid)
            .collection('my_debt_persons')
            .doc(personName);
        if (relatedTo == 'debt') {
          transaction.update(personRef, {
            'totalDebtAmount': FieldValue.increment(delta),
            'totalRemainingDebt': FieldValue.increment(delta),
          });
        } else {
          transaction.update(personRef, {
            'totalRemainingDebt': FieldValue.increment(-delta),
          });
        }
      });

      if (personName.isNotEmpty) {
        await _recalculatePersonTotals(uid, personName);
      }

      if (targetPayment != null && targetPayment!.type != 'debtAdded') {
        await _syncPaymentToExpense(
          uid: uid,
          paymentId: paymentId,
          amountPaid: newAmount,
          paymentDate: targetPayment!.createdAt,
          personName: personName,
          operationId: operationId,
          debtId: debtId,
          note: note ?? targetPayment!.note,
          previousAmount: targetPayment!.amountPaid,
        );
        await _syncPurchasePaidAmount(
          uid: uid,
          debtId: debtId,
          operationId: operationId,
        );
      }
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<void> deleteMyDebtPayment({
    required String uid,
    required String debtId,
    required String paymentId,
  }) async {
    try {
      final debtRef = firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_items')
          .doc(debtId);
      final paymentRef = debtRef.collection('payments').doc(paymentId);

      String personNameForRecalc = '';
      MyDebtPaymentModel? targetPayment;
      String? operationId;

      await firestore.runTransaction((transaction) async {
        final debtSnap = await transaction.get(debtRef);
        if (!debtSnap.exists) throw Exception('Debt not found');

        personNameForRecalc = debtSnap.data()?['personName'] as String? ?? '';
        operationId = debtSnap.data()?['operationId'] as String?;

        final paymentsSnapshot = await debtRef
            .collection('payments')
            .orderBy('createdAt', descending: true)
            .get();
        final allPayments = paymentsSnapshot.docs
            .map((doc) => MyDebtPaymentModel.fromJson(doc.data(), doc.id))
            .toList();

        targetPayment = allPayments.firstWhere((p) => p.id == paymentId);
        final String relatedTo = targetPayment!.type == 'debtAdded'
            ? 'debt'
            : 'payment';

        if (targetPayment!.type == 'debtAdded') {
          // RULE 2: Check for newer payments
          final hasNewerPayments = allPayments.any(
            (p) =>
                (p.type == 'partial' || p.type == 'full') &&
                p.createdAt.isAfter(targetPayment!.createdAt),
          );
          if (hasNewerPayments) {
            throw Exception('delete_not_allowed');
          }
        }

        // Direct Mutation: Delete the same item
        transaction.delete(paymentRef);

        final amountToDelete = targetPayment!.amountPaid;

        if (relatedTo == 'payment' && amountToDelete > 0) {
          final userRef = firestore.collection('users').doc(uid);
          final vaultTxId = 'vault_tx_mydebt_${paymentId}_rev_${DateTime.now().millisecondsSinceEpoch}';
          final vaultTxRef = userRef.collection('vault_transactions').doc(vaultTxId);
          final vaultSummaryRef = userRef.collection('vault').doc('summary');

          final bool isPurchase = (debtId.startsWith('debt_pur_') ||
              (operationId != null && operationId!.startsWith('pur_')));

          transaction.set(vaultTxRef, {
            'id': vaultTxId,
            'uid': uid,
            'amount': amountToDelete,
            'direction': 'in',
            'source': isPurchase
                ? VaultTransactionSource.inventory.name
                : VaultTransactionSource.myDebt.name,
            'type': 'reversal',
            'description': isPurchase
                ? 'إلغاء دفعة شراء: $personNameForRecalc'
                : 'إلغاء دفعة دين: $personNameForRecalc',
            'relatedEntityId': paymentId,
            'relatedOperationId': debtId,
            'createdAt': FieldValue.serverTimestamp(),
          });

          transaction.set(
            vaultSummaryRef,
            {
              'currentBalance': FieldValue.increment(amountToDelete),
              'totalOut': FieldValue.increment(-amountToDelete),
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }

        // Calculate new values
        final currentTotal = (debtSnap.data()?['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final currentPaid = (debtSnap.data()?['paidAmount'] as num?)?.toDouble() ?? 0.0;
        final currentRemaining = (debtSnap.data()?['remainingAmount'] as num?)?.toDouble() ?? 0.0;

        double newTotalAmount = currentTotal;
        double newPaidAmount = currentPaid;
        double newRemainingAmount = currentRemaining;

        if (relatedTo == 'debt') {
          newTotalAmount = currentTotal - amountToDelete;
          newRemainingAmount = currentRemaining - amountToDelete;
        } else {
          newPaidAmount = currentPaid - amountToDelete;
          newRemainingAmount = currentRemaining + amountToDelete;
        }

        final bool newIsPaid = newRemainingAmount <= 1e-9;

        // Update stored totals
        if (relatedTo == 'debt') {
          transaction.update(debtRef, {
            'totalAmount': newTotalAmount,
            'remainingAmount': newRemainingAmount,
            'isPaid': newIsPaid,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(debtRef, {
            'paidAmount': newPaidAmount,
            'remainingAmount': newRemainingAmount,
            'isPaid': newIsPaid,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Update operation if it exists
        if (operationId != null && operationId!.isNotEmpty) {
          final opRef = firestore
              .collection('users')
              .doc(uid)
              .collection('my_debt_operations')
              .doc(operationId);
          if (relatedTo == 'debt') {
            transaction.update(opRef, {
              'totalAmount': newTotalAmount,
              'remainingDebt': newRemainingAmount,
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            transaction.update(opRef, {
              'paidAmount': newPaidAmount,
              'remainingDebt': newRemainingAmount,
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        // Update person doc
        final personName = debtSnap.data()?['personName'] as String;
        final personRef = firestore
            .collection('users')
            .doc(uid)
            .collection('my_debt_persons')
            .doc(personName);
        if (relatedTo == 'debt') {
          transaction.update(personRef, {
            'totalDebtAmount': FieldValue.increment(-amountToDelete),
            'totalRemainingDebt': FieldValue.increment(-amountToDelete),
          });
        } else {
          transaction.update(personRef, {
            'totalRemainingDebt': FieldValue.increment(amountToDelete),
            'lastUsedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      await _recalculatePersonTotals(uid, personNameForRecalc);

      if (targetPayment != null && targetPayment!.type != 'debtAdded') {
        await _deletePaymentExpense(
          uid: uid,
          paymentId: paymentId,
        );
        await _syncPurchasePaidAmount(
          uid: uid,
          debtId: debtId,
          operationId: operationId,
        );
      }
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to delete payment: $e');
    }
  }
}
