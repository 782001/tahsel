import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/error/exceptions.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/services/activity_logger_service.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/summary_helper.dart';
import 'package:tahsel/features/cashbox/data/datasources/vault_remote_data_source.dart';
import 'package:tahsel/features/cashbox/domain/entities/vault_transaction_entity.dart';
import '../models/custody_model.dart';

abstract class CustodyRemoteDataSource {
  Future<CustodyModel> createCustody({
    required String ownerUid,
    required String recipientName,
    String? recipientEmployeeId,
    required String recipientType,
    required double initialAmount,
    String? notes,
  });

  Future<List<CustodyModel>> getCustodies(String ownerUid);

  Future<CustodyModel?> getActiveCustodyForRecipient(
    String ownerUid, {
    String? employeeUid,
    String? recipientName,
  });

  Future<void> addCustodyExpense({
    required String ownerUid,
    required String custodyId,
    required CustodyExpenseItemModel expense,
  });

  Future<void> settleCustody({
    required String ownerUid,
    required String custodyId,
    required double actualReturnedAmount,
    required double varianceAmount,
    required String settledBy,
    String? settlementNotes,
    String? deficitReason,
  });

  Future<void> updateCustodyNotes({
    required String ownerUid,
    required String custodyId,
    required String notes,
  });

  Future<void> deleteCustody(String ownerUid, String custodyId);
  Future<void> deleteCustodyExpenseItem({
    required String ownerUid,
    required String custodyId,
    required CustodyExpenseItemModel expenseItem,
  });
}

class CustodyRemoteDataSourceImpl implements CustodyRemoteDataSource {
  final FirebaseFirestore firestore;

  CustodyRemoteDataSourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> _custodiesRef(String ownerUid) {
    return firestore.collection('users').doc(ownerUid).collection('custodies');
  }

  @override
  Future<CustodyModel> createCustody({
    required String ownerUid,
    required String recipientName,
    String? recipientEmployeeId,
    required String recipientType,
    required double initialAmount,
    String? notes,
  }) async {
    try {
      // Validate that recipient does not already have an active custody
      final existingActive = await getActiveCustodyForRecipient(
        ownerUid,
        employeeUid: recipientEmployeeId,
        recipientName:
            recipientEmployeeId == null || recipientEmployeeId.isEmpty
            ? recipientName
            : null,
      );
      if (existingActive != null) {
        throw ServerException(
          AppStrings.recipientAlreadyHasActiveCustodyNotice.tr(),
        );
      }

      final docRef = _custodiesRef(ownerUid).doc();
      final now = DateTime.now();

      final custody = CustodyModel(
        id: docRef.id,
        ownerUid: ownerUid,
        recipientName: recipientName,
        recipientEmployeeId: recipientEmployeeId,
        recipientType: recipientType,
        initialAmount: initialAmount,
        spentAmount: 0.0,
        remainingAmount: initialAmount,
        status: 'active',
        notes: notes,
        createdAt: now,
        expenses: const [],
      );

      await docRef.set(custody.toMap());
      AppLogger.printMessage(
        '[CustodyRemote] Created custody ${docRef.id} for $recipientName',
      );

      // Deduct disbursed custody amount from Vault
      if (initialAmount > 0 && AppStrings.isVaultEnabled()) {
        try {
          await VaultRemoteDataSourceImpl.syncVaultTransaction(
            firestore: firestore,
            uid: ownerUid,
            transactionId: 'vault_tx_custody_${docRef.id}',
            amount: initialAmount,
            direction: VaultTransactionDirection.outFlow,
            source: VaultTransactionSource.custody,
            type: 'custody_disbursement',
            description: 'صرف عهدة نقدية: $recipientName',
            relatedEntityId: docRef.id,
            relatedOperationId: docRef.id,
            createdAt: now,
          );
        } catch (vaultError) {
          AppLogger.printMessage(
            '[CustodyRemote] Error syncing vault on custody creation: $vaultError',
          );
          await docRef.delete();
          if (vaultError.toString().contains(AppStrings.insufficientBalance) ||
              vaultError.toString().contains('insufficient_balance')) {
            throw ServerException(AppStrings.insufficientBalance);
          }
          throw ServerException(vaultError.toString());
        }
      }

      return custody;
    } catch (e) {
      AppLogger.printMessage('[CustodyRemote] Error creating custody: $e');
      throw ServerException(e.toString());
    }
  }

  void _repairCustodyDuplicatesIfNeeded(
    String ownerUid,
    String docId,
    Map<String, dynamic> rawData,
    CustodyModel model,
  ) {
    try {
      final rawExpenses = rawData['expenses'] as List<dynamic>? ?? [];
      if (model.expenses.length < rawExpenses.length) {
        _custodiesRef(ownerUid)
            .doc(docId)
            .update({
              'spentAmount': model.spentAmount,
              'remainingAmount': model.remainingAmount,
              'expenses': model.expenses
                  .map((e) => CustodyExpenseItemModel.fromEntity(e).toMap())
                  .toList(),
            })
            .then((_) {
              AppLogger.printMessage(
                '[CustodyRemote] Auto-repaired duplicate expenses for custody $docId',
              );
            })
            .catchError((e) {
              AppLogger.printMessage(
                '[CustodyRemote] Error auto-repairing custody $docId: $e',
              );
            });
      }
    } catch (_) {}
  }

  @override
  Future<List<CustodyModel>> getCustodies(String ownerUid) async {
    try {
      final snapshot = await _custodiesRef(
        ownerUid,
      ).orderBy('createdAt', descending: true).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final model = CustodyModel.fromMap(data, doc.id);
        _repairCustodyDuplicatesIfNeeded(ownerUid, doc.id, data, model);
        return model;
      }).toList();
    } catch (e) {
      AppLogger.printMessage('[CustodyRemote] Error fetching custodies: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<CustodyModel?> getActiveCustodyForRecipient(
    String ownerUid, {
    String? employeeUid,
    String? recipientName,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _custodiesRef(
        ownerUid,
      ).where('status', isEqualTo: 'active');

      if (employeeUid != null && employeeUid.isNotEmpty) {
        query = query.where('recipientEmployeeId', isEqualTo: employeeUid);
      } else if (recipientName != null && recipientName.isNotEmpty) {
        query = query.where('recipientName', isEqualTo: recipientName);
      }

      final snapshot = await query.limit(1).get();
      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data();
      final model = CustodyModel.fromMap(data, doc.id);
      _repairCustodyDuplicatesIfNeeded(ownerUid, doc.id, data, model);
      return model;
    } catch (e) {
      AppLogger.printMessage(
        '[CustodyRemote] Error fetching active custody: $e',
      );
      return null;
    }
  }

  @override
  Future<void> addCustodyExpense({
    required String ownerUid,
    required String custodyId,
    required CustodyExpenseItemModel expense,
  }) async {
    try {
      final docRef = _custodiesRef(ownerUid).doc(custodyId);
      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw ServerException('Custody not found');
        }

        final data = snapshot.data()!;
        final currentStatus = data['status'] as String? ?? 'active';
        if (currentStatus == 'settled') {
          throw ServerException('Cannot add expense to a settled custody');
        }
        final rawExpenses = data['expenses'] as List<dynamic>? ?? [];

        // Idempotency check: don't add the same expense twice
        final alreadyExists = rawExpenses.any(
          (e) =>
              e is Map &&
              (e['id'] == expense.id ||
                  (expense.id.isNotEmpty &&
                      e['id'] == 'cust_exp_${expense.id}') ||
                  (expense.id.isNotEmpty &&
                      e['id'] is String &&
                      (e['id'] as String).replaceFirst('cust_exp_', '') ==
                          expense.id.replaceFirst('cust_exp_', ''))),
        );
        if (alreadyExists) {
          AppLogger.printMessage(
            '[CustodyRemote] Expense ${expense.id} already exists in custody $custodyId, skipping.',
          );
          return;
        }

        final currentSpent = (data['spentAmount'] as num?)?.toDouble() ?? 0.0;
        final initialAmount =
            (data['initialAmount'] as num?)?.toDouble() ?? 0.0;
        final newSpent = currentSpent + expense.amount;
        final newRemaining = initialAmount - newSpent;

        final updatedExpenses = List<Map<String, dynamic>>.from(rawExpenses)
          ..add(expense.toMap());

        transaction.update(docRef, {
          'spentAmount': newSpent,
          'remainingAmount': newRemaining,
          'expenses': updatedExpenses,
        });
      });
      AppLogger.printMessage(
        '[CustodyRemote] Added expense to custody $custodyId',
      );
    } catch (e) {
      AppLogger.printMessage(
        '[CustodyRemote] Error adding custody expense: $e',
      );
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> settleCustody({
    required String ownerUid,
    required String custodyId,
    required double actualReturnedAmount,
    required double varianceAmount,
    required String settledBy,
    String? settlementNotes,
    String? deficitReason,
  }) async {
    try {
      final docRef = _custodiesRef(ownerUid).doc(custodyId);
      final docSnap = await docRef.get();
      if (!docSnap.exists || docSnap.data() == null) {
        throw ServerException('Custody not found');
      }
      final custodyData = docSnap.data()!;
      final currentStatus = custodyData['status'] as String? ?? 'active';
      if (currentStatus == 'settled') {
        throw ServerException('Custody is already settled');
      }
      final recipientName = custodyData['recipientName'] as String? ?? '';
      final initialAmount =
          (custodyData['initialAmount'] as num?)?.toDouble() ?? 0.0;
      final currentSpent =
          (custodyData['spentAmount'] as num?)?.toDouble() ?? 0.0;
      final remainingAmount =
          (custodyData['remainingAmount'] as num?)?.toDouble() ?? 0.0;
      final rawExpenses = custodyData['expenses'] as List<dynamic>? ?? [];
      final now = DateTime.now();

      // Check if there is a cash deficit upon settlement
      final double deficitAmount = remainingAmount > actualReturnedAmount
          ? (remainingAmount - actualReturnedAmount)
          : 0.0;

      double finalSpent = currentSpent;
      final updatedExpenses = List<Map<String, dynamic>>.from(
        rawExpenses.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
      );

      if (deficitAmount > 0) {
        final reason =
            (deficitReason != null && deficitReason.trim().isNotEmpty)
            ? deficitReason.trim()
            : AppStrings.deficitSettlementDefaultReason.tr();

        final deficitExpenseItem = {
          'id': 'cust_exp_deficit_${now.millisecondsSinceEpoch}',
          'description': '${AppStrings.deficitSettlementExpense.tr()}: $reason',
          'amount': deficitAmount,
          'date': Timestamp.fromDate(now),
          'category': AppStrings.deficitSettlementExpense.tr(),
          'createdAt': Timestamp.fromDate(now),
        };
        updatedExpenses.add(deficitExpenseItem);
        finalSpent = currentSpent + deficitAmount;
      }

      await docRef.update({
        'status': 'settled',
        'spentAmount': finalSpent,
        'remainingAmount': (initialAmount - finalSpent).clamp(
          0.0,
          double.infinity,
        ),
        'expenses': updatedExpenses,
        'actualSettledAmount': actualReturnedAmount,
        'varianceAmount': varianceAmount,
        'settledAt': Timestamp.fromDate(now),
        'settledBy': settledBy,
        if (settlementNotes != null && settlementNotes.isNotEmpty)
          'settlementNotes': settlementNotes,
      });

      // 1. If remaining cash returned to company, deposit back into Vault
      if (actualReturnedAmount > 0) {
        try {
          await VaultRemoteDataSourceImpl.syncVaultTransaction(
            firestore: firestore,
            uid: ownerUid,
            transactionId: 'vault_tx_custody_ref_$custodyId',
            amount: actualReturnedAmount,
            direction: VaultTransactionDirection.inFlow,
            source: VaultTransactionSource.custody,
            type: 'custody_settlement_refund',
            description: 'استرجاع متبقي عهدة نقدية: $recipientName',
            relatedEntityId: custodyId,
            relatedOperationId: custodyId,
            createdAt: now,
          );
        } catch (vaultError) {
          AppLogger.printMessage(
            '[CustodyRemote] Error syncing vault refund: $vaultError',
          );
        }
      }

      // 2. If employee paid out of pocket (deficit / remaining < 0), reimburse from Vault
      if (remainingAmount < 0) {
        final reimbursement = remainingAmount.abs();
        if (reimbursement > 0) {
          try {
            await VaultRemoteDataSourceImpl.syncVaultTransaction(
              firestore: firestore,
              uid: ownerUid,
              transactionId: 'vault_tx_custody_reimb_$custodyId',
              amount: reimbursement,
              direction: VaultTransactionDirection.outFlow,
              source: VaultTransactionSource.custody,
              type: 'custody_settlement_reimbursement',
              description: 'سداد فارق تسوية عهدة (دفع من جيبه): $recipientName',
              relatedEntityId: custodyId,
              relatedOperationId: custodyId,
              createdAt: now,
            );
          } catch (vaultError) {
            AppLogger.printMessage(
              '[CustodyRemote] Error syncing vault reimbursement: $vaultError',
            );
          }
        }
      }

      // 3. Post summary settlement expense to general expenses (without vault deduction)
      // so it appears in monthly P&L and expense reports seamlessly
      if (finalSpent > 0) {
        try {
          final expenseRef = firestore
              .collection('users')
              .doc(ownerUid)
              .collection('expenses')
              .doc('exp_cust_settle_$custodyId');

          final expenseMonthKey =
              "${now.year}-${now.month.toString().padLeft(2, '0')}";

          final expenseData = {
            'uid': ownerUid,
            'amount': finalSpent,
            'category': 'تسوية عهدة',
            'description': 'تسوية عهدة: $recipientName',
            'createdAt': Timestamp.fromDate(now),
            'monthKey': expenseMonthKey,
            'custodyId': custodyId,
            'isCustodySettlement': true,
          };

          final batch = firestore.batch();
          batch.set(expenseRef, expenseData, SetOptions(merge: true));

          // Update summaries for P&L reporting
          final summaryKeys = SummaryHelper.getSummaryKeys(now);
          for (final key in summaryKeys) {
            final summaryRef = firestore
                .collection('users')
                .doc(ownerUid)
                .collection('summaries')
                .doc(key);
            batch.set(summaryRef, {
              'totalExpenses': FieldValue.increment(finalSpent),
              'transactionCount': FieldValue.increment(1),
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
          await batch.commit();
        } catch (expErr) {
          AppLogger.printMessage(
            '[CustodyRemote] Error posting settlement expense: $expErr',
          );
        }
      }

      AppLogger.printMessage('[CustodyRemote] Settled custody $custodyId');
    } catch (e) {
      AppLogger.printMessage('[CustodyRemote] Error settling custody: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateCustodyNotes({
    required String ownerUid,
    required String custodyId,
    required String notes,
  }) async {
    try {
      await _custodiesRef(ownerUid).doc(custodyId).update({'notes': notes});
      AppLogger.printMessage(
        '[CustodyRemote] Updated notes for custody $custodyId',
      );
    } catch (e) {
      AppLogger.printMessage(
        '[CustodyRemote] Error updating custody notes: $e',
      );
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteCustody(String ownerUid, String custodyId) async {
    try {
      final docRef = _custodiesRef(ownerUid).doc(custodyId);
      final docSnap = await docRef.get();
      if (docSnap.exists && docSnap.data() != null) {
        final data = docSnap.data()!;
        final status = data['status'] as String? ?? 'active';
        if (status == 'settled') {
          throw ServerException(
            AppStrings.cannotDeleteSettledCustodyExpense.tr(),
          );
        }

        final spent = (data['spentAmount'] as num?)?.toDouble() ?? 0.0;
        final rawExpenses = data['expenses'] as List<dynamic>? ?? [];

        // 1. Strict guard: custody can only be deleted if NO amount was withdrawn/spent at all
        if (spent > 0 || rawExpenses.isNotEmpty) {
          throw ServerException(AppStrings.cannotDeleteCustodySpentMsg.tr());
        }

        final initial = (data['initialAmount'] as num?)?.toDouble() ?? 0.0;
        final recipientName = data['recipientName'] as String? ?? '';
        final empId = data['recipientEmployeeId'] as String?;

        // 2. Return the full initial custody amount back to the vault
        if (initial > 0 && AppStrings.isVaultEnabled()) {
          try {
            await VaultRemoteDataSourceImpl.syncVaultTransaction(
              firestore: firestore,
              uid: ownerUid,
              transactionId: 'vault_tx_custody_del_$custodyId',
              amount: initial,
              direction: VaultTransactionDirection.inFlow,
              source: VaultTransactionSource.custody,
              type: 'custody_deletion_refund',
              description:
                  'استرجاع كامل مبلغ عهدة ملغاة إلى الخزينة: $recipientName',
              relatedEntityId: custodyId,
              createdAt: DateTime.now(),
            );
          } catch (vaultErr) {
            AppLogger.printMessage(
              '[CustodyRemote] Error returning custody to vault: $vaultErr',
            );
          }
        }

        // 3. Log standalone activity
        if (sl.isRegistered<ActivityLoggerService>()) {
          try {
            sl<ActivityLoggerService>().logStandalone(
              ownerUid: ownerUid,
              actionCategory: 'custody',
              actionType: 'delete_custody',
              actionTitle: 'حذف عهدة نقدية: $recipientName',
              details:
                  'تم حذف العهدة كأن لم تكن واسترجاع كامل مبلغها (${initial.toSmartAmount()} ${AppStrings.currencyEgp.tr()}) إلى الخزينة وحذفها نهائياً من حساب المستلم',
              amount: initial,
              extraData: {
                'custodyId': custodyId,
                'recipientName': recipientName,
                if (empId != null) 'employeeUid': empId,
                'refundedAmount': initial,
              },
            );
          } catch (_) {}
        }
      }

      await docRef.delete();
      AppLogger.printMessage('[CustodyRemote] Deleted custody $custodyId');
    } catch (e) {
      AppLogger.printMessage('[CustodyRemote] Error deleting custody: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteCustodyExpenseItem({
    required String ownerUid,
    required String custodyId,
    required CustodyExpenseItemModel expenseItem,
  }) async {
    try {
      final docRef = _custodiesRef(ownerUid).doc(custodyId);
      String recipientName = '';

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists || snapshot.data() == null) {
          throw ServerException('Custody not found');
        }

        final data = snapshot.data()!;
        final currentStatus = data['status'] as String? ?? 'active';
        if (currentStatus == 'settled') {
          throw ServerException(
            AppStrings.cannotDeleteSettledCustodyExpense.tr(),
          );
        }

        recipientName = data['recipientName'] as String? ?? '';

        final currentSpent = (data['spentAmount'] as num?)?.toDouble() ?? 0.0;
        final initialAmount =
            (data['initialAmount'] as num?)?.toDouble() ?? 0.0;
        final newSpent = (currentSpent - expenseItem.amount).clamp(
          0.0,
          double.infinity,
        );
        final newRemaining = initialAmount - newSpent;

        final rawExpenses = data['expenses'] as List<dynamic>? ?? [];
        final updatedExpenses = rawExpenses.where((e) {
          if (e is Map) {
            final id = e['id']?.toString() ?? '';
            return id != expenseItem.id &&
                id != 'cust_exp_${expenseItem.id}' &&
                !(e['description'] is String &&
                    (e['description'] as String).contains(expenseItem.id));
          }
          return true;
        }).toList();

        transaction.update(docRef, {
          'spentAmount': newSpent,
          'remainingAmount': newRemaining,
          'expenses': updatedExpenses,
        });
      });

      // 1. Also delete from users/{ownerUid}/expenses if exists
      try {
        final expenseRef = firestore
            .collection('users')
            .doc(ownerUid)
            .collection('expenses')
            .doc(expenseItem.id);
        final expenseDoc = await expenseRef.get();
        if (expenseDoc.exists) {
          final batch = firestore.batch();
          batch.delete(expenseRef);
          final summaryKeys = SummaryHelper.getSummaryKeys(expenseItem.date);
          for (final key in summaryKeys) {
            final summaryRef = firestore
                .collection('users')
                .doc(ownerUid)
                .collection('summaries')
                .doc(key);
            batch.set(summaryRef, {
              'totalExpenses': FieldValue.increment(-expenseItem.amount),
              'transactionCount': FieldValue.increment(-1),
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
          await batch.commit();
        }
      } catch (_) {}

      // 2. Log activity
      if (sl.isRegistered<ActivityLoggerService>()) {
        try {
          sl<ActivityLoggerService>().logStandalone(
            ownerUid: ownerUid,
            actionCategory: 'custody',
            actionType: 'delete_custody_expense',
            actionTitle: 'حذف مصروف من عهدة: $recipientName',
            details:
                'تم حذف مصروف بقيمة ${expenseItem.amount.toSmartAmount()} ${AppStrings.currencyEgp.tr()} من عهدة ($recipientName) واسترجاع قيمته لرصيد العهدة',
            amount: expenseItem.amount,
            extraData: {
              'custodyId': custodyId,
              'expenseId': expenseItem.id,
              'recipientName': recipientName,
              'amount': expenseItem.amount,
            },
          );
        } catch (_) {}
      }

      AppLogger.printMessage(
        '[CustodyRemote] Deleted expense item ${expenseItem.id} from custody $custodyId',
      );
    } catch (e) {
      AppLogger.printMessage(
        '[CustodyRemote] Error deleting custody expense item: $e',
      );
      throw ServerException(e.toString());
    }
  }
}
