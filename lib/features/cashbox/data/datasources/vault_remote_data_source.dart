import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/error/firebase_error_handler.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import '../../../../core/utils/summary_helper.dart';
import '../../domain/entities/vault_transaction_entity.dart';
import '../models/vault_summary_model.dart';
import '../models/vault_transaction_model.dart';

abstract class VaultRemoteDataSource {
  Future<VaultSummaryModel> getSummary(String uid);
  Stream<VaultSummaryModel> watchSummary(String uid);

  Future<
      ({
        List<VaultTransactionModel> transactions,
        DocumentSnapshot? lastDoc,
        bool hasMore
      })> getTransactionsPaginated({
    required String uid,
    VaultTransactionSource sourceFilter = VaultTransactionSource.all,
    int limit = 15,
    DocumentSnapshot? lastDoc,
  });

  Future<void> depositManual({
    required String uid,
    required double amount,
    String? note,
  });

  Future<void> withdrawManual({
    required String uid,
    required double amount,
    String? note,
  });

  Future<void> recordTransaction(VaultTransactionModel transaction);
  Future<void> recordTransactionDelta({
    required String uid,
    required String transactionId,
    required double deltaAmount,
    required VaultTransactionDirection direction,
    required VaultTransactionSource source,
    required String type,
    required String description,
    String? relatedEntityId,
    String? relatedOperationId,
    DateTime? createdAt,
  });

  Future<void> editManualTransaction({
    required String uid,
    required VaultTransactionModel oldTransaction,
    required double newAmount,
    required String newDescription,
  });

  Future<void> deleteManualTransaction({
    required String uid,
    required VaultTransactionModel transaction,
  });
}

class VaultRemoteDataSourceImpl implements VaultRemoteDataSource {
  final FirebaseFirestore firestore;

  VaultRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference _getUserRef(String uid) {
    return firestore.collection('users').doc(uid);
  }

  DocumentReference _getSummaryRef(String uid) {
    return firestore.collection('users').doc(uid).collection('vault').doc('summary');
  }

  CollectionReference _getTransactionsCol(String uid) {
    return firestore.collection('users').doc(uid).collection('vault_transactions');
  }

  /// Static atomic helper for all modules (Debts, Purchases, Expenses, Employees, Offline Sync)
  static Future<void> syncVaultTransaction({
    FirebaseFirestore? firestore,
    required String uid,
    required String transactionId,
    required double amount,
    required VaultTransactionDirection direction,
    required VaultTransactionSource source,
    required String type,
    required String description,
    String? relatedEntityId,
    String? relatedOperationId,
    DateTime? createdAt,
    bool? isShop,
    bool allowNegativeBalance = false,
  }) async {
    // 1. MANDATORY ELIGIBILITY & COST OPTIMIZATION: Zero Firebase interaction if Vault is not enabled
    if (!AppStrings.isVaultEnabled(isShop)) {
      return;
    }

    if (amount <= 0 || uid.isEmpty) return;

    final db = firestore ?? FirebaseFirestore.instance;
    final txRef = db.collection('users').doc(uid).collection('vault_transactions').doc(transactionId);
    final summaryRef = db.collection('users').doc(uid).collection('vault').doc('summary');

    final isIn = direction == VaultTransactionDirection.inFlow;

    // Balance check before starting transaction (prevents Windows C++ plugin crash inside runTransaction)
    if (!isIn && !allowNegativeBalance) {
      final summaryDoc = await summaryRef.get();
      final double currentBalance = (summaryDoc.exists && summaryDoc.data() != null)
          ? ((summaryDoc.data()!['currentBalance'] as num?)?.toDouble() ?? 0.0)
          : 0.0;
      if (currentBalance <= 0 || currentBalance < amount) {
        throw Exception(AppStrings.insufficientBalance);
      }
    }

    await db.runTransaction((tx) async {
      final existingDoc = await tx.get(txRef);
      if (existingDoc.exists) {
        // Skip if already processed for idempotency
        return;
      }

      final txDate = createdAt ?? DateTime.now();
      final model = VaultTransactionModel(
        id: transactionId,
        uid: uid,
        amount: amount,
        direction: direction,
        source: source,
        type: type,
        description: description,
        relatedEntityId: relatedEntityId,
        relatedOperationId: relatedOperationId,
        createdAt: txDate,
      );

      tx.set(txRef, model.toMap());

      final double signedDelta = isIn ? amount : -amount;

      tx.set(
        summaryRef,
        {
          'currentBalance': FieldValue.increment(signedDelta),
          'totalIn': FieldValue.increment(isIn ? amount : 0.0),
          'totalOut': FieldValue.increment(isIn ? 0.0 : amount),
          'transactionCount': FieldValue.increment(1),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<VaultSummaryModel> getSummary(String uid) async {
    if (!AppStrings.isVaultEnabled()) {
      return const VaultSummaryModel(currentBalance: 0.0);
    }
    try {
      final doc = await _getSummaryRef(uid).get();
      if (!doc.exists || doc.data() == null) {
        return const VaultSummaryModel(currentBalance: 0.0);
      }
      return VaultSummaryModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to get vault summary: $e');
    }
  }

  @override
  Stream<VaultSummaryModel> watchSummary(String uid) {
    if (!AppStrings.isVaultEnabled()) {
      return Stream.value(const VaultSummaryModel(currentBalance: 0.0));
    }
    return _getSummaryRef(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return const VaultSummaryModel(currentBalance: 0.0);
      }
      return VaultSummaryModel.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  @override
  Future<
      ({
        List<VaultTransactionModel> transactions,
        DocumentSnapshot? lastDoc,
        bool hasMore
      })> getTransactionsPaginated({
    required String uid,
    VaultTransactionSource sourceFilter = VaultTransactionSource.all,
    int limit = 15,
    DocumentSnapshot? lastDoc,
  }) async {
    if (!AppStrings.isVaultEnabled()) {
      return (transactions: <VaultTransactionModel>[], lastDoc: null, hasMore: false);
    }
    try {
      Query query = _getTransactionsCol(uid).orderBy('createdAt', descending: true);

      if (sourceFilter != VaultTransactionSource.all) {
        query = query.where('source', isEqualTo: sourceFilter.name);
      }

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      final docs = snapshot.docs;
      final transactions = docs
          .map((doc) => VaultTransactionModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      final bool hasMore = docs.length == limit;
      final DocumentSnapshot? newLastDoc = docs.isNotEmpty ? docs.last : null;

      return (
        transactions: transactions,
        lastDoc: newLastDoc,
        hasMore: hasMore,
      );
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch vault transactions: $e');
    }
  }

  @override
  Future<void> recordTransaction(VaultTransactionModel transaction) async {
    if (!AppStrings.isVaultEnabled()) return;
    await syncVaultTransaction(
      firestore: firestore,
      uid: transaction.uid,
      transactionId: transaction.id,
      amount: transaction.amount,
      direction: transaction.direction,
      source: transaction.source,
      type: transaction.type,
      description: transaction.description,
      relatedEntityId: transaction.relatedEntityId,
      relatedOperationId: transaction.relatedOperationId,
      createdAt: transaction.createdAt,
    );
  }

  @override
  Future<void> recordTransactionDelta({
    required String uid,
    required String transactionId,
    required double deltaAmount,
    required VaultTransactionDirection direction,
    required VaultTransactionSource source,
    required String type,
    required String description,
    String? relatedEntityId,
    String? relatedOperationId,
    DateTime? createdAt,
  }) async {
    if (!AppStrings.isVaultEnabled()) return;
    if (deltaAmount == 0) return;

    try {
      final txRef = _getTransactionsCol(uid).doc(transactionId);
      final summaryRef = _getSummaryRef(uid);

      final isIn = direction == VaultTransactionDirection.inFlow;
      final double signedDelta = isIn ? deltaAmount : -deltaAmount;
      final txDate = createdAt ?? DateTime.now();

      final model = VaultTransactionModel(
        id: transactionId,
        uid: uid,
        amount: deltaAmount.abs(),
        direction: direction,
        source: source,
        type: type,
        description: description,
        relatedEntityId: relatedEntityId,
        relatedOperationId: relatedOperationId,
        createdAt: txDate,
      );

      final batch = firestore.batch();
      batch.set(txRef, model.toMap(), SetOptions(merge: true));

      batch.set(
        summaryRef,
        {
          'currentBalance': FieldValue.increment(signedDelta),
          'totalIn': FieldValue.increment(isIn ? deltaAmount.abs() : 0.0),
          'totalOut': FieldValue.increment(isIn ? 0.0 : deltaAmount.abs()),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to record vault delta: $e');
    }
  }

  @override
  Future<void> depositManual({
    required String uid,
    required double amount,
    String? note,
  }) async {
    if (!AppStrings.isVaultEnabled()) return;
    if (amount <= 0) return;

    final String txId = 'vault_manual_dep_${DateTime.now().millisecondsSinceEpoch}';
    final transaction = VaultTransactionModel(
      id: txId,
      uid: uid,
      amount: amount,
      direction: VaultTransactionDirection.inFlow,
      source: VaultTransactionSource.manualDeposit,
      type: 'manual_deposit',
      description: note != null && note.isNotEmpty ? note : 'إيداع نقدي يدوياً',
      createdAt: DateTime.now(),
    );

    await recordTransaction(transaction);
  }

  @override
  Future<void> withdrawManual({
    required String uid,
    required double amount,
    String? note,
  }) async {
    if (!AppStrings.isVaultEnabled()) return;
    if (amount <= 0) return;

    try {
      final String txId = 'vault_manual_with_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();
      final monthKey = DateFormat('yyyy-MM', 'en').format(now);
      final description = note != null && note.isNotEmpty ? note : 'سحب نقدي يدوياً';

      final transaction = VaultTransactionModel(
        id: txId,
        uid: uid,
        amount: amount,
        direction: VaultTransactionDirection.outFlow,
        source: VaultTransactionSource.manualWithdrawal,
        type: 'manual_withdrawal',
        description: description,
        createdAt: now,
      );

      final userRef = _getUserRef(uid);
      final txRef = _getTransactionsCol(uid).doc(txId);
      final summaryRef = _getSummaryRef(uid);
      final expenseRef = userRef.collection('expenses').doc('exp_$txId');

      final batch = firestore.batch();

      // 1. Vault Transaction
      batch.set(txRef, transaction.toMap(), SetOptions(merge: true));

      // 2. Vault Summary Update
      batch.set(
        summaryRef,
        {
          'currentBalance': FieldValue.increment(-amount),
          'totalOut': FieldValue.increment(amount),
          'transactionCount': FieldValue.increment(1),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 3. Expense Document
      batch.set(
        expenseRef,
        {
          'id': 'exp_$txId',
          'uid': uid,
          'amount': amount,
          'category': 'سحب نقدي من الخزنة',
          'description': description,
          'createdAt': Timestamp.fromDate(now),
          'monthKey': monthKey,
          'syncedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 4. Expense Summaries Update
      final summaryKeys = SummaryHelper.getSummaryKeys(now);
      for (final key in summaryKeys) {
        batch.set(
          userRef.collection('summaries').doc(key),
          {
            'totalExpenses': FieldValue.increment(amount),
            'transactionCount': FieldValue.increment(1),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to record manual withdrawal: $e');
    }
  }

  @override
  Future<void> editManualTransaction({
    required String uid,
    required VaultTransactionModel oldTransaction,
    required double newAmount,
    required String newDescription,
  }) async {
    if (!AppStrings.isVaultEnabled()) return;
    if (newAmount <= 0) return;
    try {
      final userRef = _getUserRef(uid);
      final txRef = _getTransactionsCol(uid).doc(oldTransaction.id);
      final summaryRef = _getSummaryRef(uid);

      final double deltaAmount = newAmount - oldTransaction.amount;
      final isIn = oldTransaction.direction == VaultTransactionDirection.inFlow;

      final batch = firestore.batch();
      batch.update(txRef, {
        'amount': newAmount,
        'description': newDescription,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(
        summaryRef,
        {
          'currentBalance': FieldValue.increment(isIn ? deltaAmount : -deltaAmount),
          'totalIn': FieldValue.increment(isIn ? deltaAmount : 0.0),
          'totalOut': FieldValue.increment(isIn ? 0.0 : deltaAmount),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (oldTransaction.source == VaultTransactionSource.manualWithdrawal) {
        final expenseRef = userRef.collection('expenses').doc('exp_${oldTransaction.id}');
        batch.set(
          expenseRef,
          {
            'amount': newAmount,
            'description': newDescription,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        final summaryKeys = SummaryHelper.getSummaryKeys(oldTransaction.createdAt);
        for (final key in summaryKeys) {
          batch.set(
            userRef.collection('summaries').doc(key),
            {
              'totalExpenses': FieldValue.increment(deltaAmount),
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      }

      await batch.commit();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to edit manual transaction: $e');
    }
  }

  @override
  Future<void> deleteManualTransaction({
    required String uid,
    required VaultTransactionModel transaction,
  }) async {
    if (!AppStrings.isVaultEnabled()) return;
    try {
      final userRef = _getUserRef(uid);
      final txRef = _getTransactionsCol(uid).doc(transaction.id);
      final summaryRef = _getSummaryRef(uid);

      final isIn = transaction.direction == VaultTransactionDirection.inFlow;
      final amount = transaction.amount;

      final batch = firestore.batch();
      batch.delete(txRef);

      batch.set(
        summaryRef,
        {
          'currentBalance': FieldValue.increment(isIn ? -amount : amount),
          'totalIn': FieldValue.increment(isIn ? -amount : 0.0),
          'totalOut': FieldValue.increment(isIn ? 0.0 : -amount),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (transaction.source == VaultTransactionSource.manualWithdrawal) {
        final expenseRef = userRef.collection('expenses').doc('exp_${transaction.id}');
        batch.delete(expenseRef);

        final summaryKeys = SummaryHelper.getSummaryKeys(transaction.createdAt);
        for (final key in summaryKeys) {
          batch.set(
            userRef.collection('summaries').doc(key),
            {
              'totalExpenses': FieldValue.increment(-amount),
              'transactionCount': FieldValue.increment(-1),
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      }

      await batch.commit();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to delete manual transaction: $e');
    }
  }
}
