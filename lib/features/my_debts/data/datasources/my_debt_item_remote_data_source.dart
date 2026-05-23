import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/error/firebase_error_handler.dart';
import 'package:tahsel/core/usecases/pagination_params.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_item_model.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_payment_model.dart';

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
  });
  Future<void> markPersonAsPaid(String uid, String personName);
  Future<void> payItem({
    required String uid,
    required String debtId,
    required double amount,
    String? note,
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
  Future<MyDebtItemModel?> getMyDebtItemById(
    String uid,
    String debtId, {
    bool forceRefresh = false,
  });
}

class MyDebtItemRemoteDataSourceImpl implements MyDebtItemRemoteDataSource {
  final FirebaseFirestore firestore;

  MyDebtItemRemoteDataSourceImpl({required this.firestore});

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
  Future<String> addDebtItem(MyDebtItemModel debt) async {
    try {
      final userRef = firestore.collection('users').doc(debt.uid);

      final debtRef = userRef.collection('my_debt_items').doc();
      final opRef = userRef
          .collection('my_debt_operations')
          .doc(debt.operationId);

      final batch = firestore.batch();

      // 1. Add to debts collection
      batch.set(debtRef, debt.toJson());

      // 2. Add to operations collection
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

      // 4. Add initial payment if any
      if (debt.paidAmount > 0) {
        final actualPaymentRef = debtRef.collection('payments').doc();
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
      }

      // 5. Update person doc with totals
      final personRef = userRef
          .collection('my_debt_persons')
          .doc(debt.personName);
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

      batch.set(personRef, personUpdate, SetOptions(merge: true));

      await batch.commit();
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

      if (snapshot.docs.isEmpty) return;

      final batch = firestore.batch();
      double remainingToPay = amount;

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
              'paidAmount': newPaidAmount,
              'remainingDebt': newRemainingAmount,
              'lastUpdatedAt': FieldValue.serverTimestamp(),
            },
          );
        }

        final paymentRef = debtRef.collection('payments').doc();
        batch.set(paymentRef, {
          'debtId': debtId,
          'amountPaid': paymentForThisItem,
          'remainingAmount': newRemainingAmount,
          'createdAt': FieldValue.serverTimestamp(),
          'type': isPaid ? 'full' : 'partial',
          'note': note,
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
        'lastUsedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
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

      final batch = firestore.batch();

      for (var doc in snapshot.docs) {
        final debtData = doc.data();
        final debtId = doc.id;
        final operationId = debtData['operationId'] as String?;
        final currentTotal = (debtData['totalAmount'] as num).toDouble();

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
          'amountPaid':
              currentTotal - (debtData['paidAmount'] as num).toDouble(),
          'remainingAmount': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'type': 'settlement',
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
  }) async {
    try {
      final debtRef = firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_items')
          .doc(debtId);

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(debtRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final currentPaid = (data['paidAmount'] as num).toDouble();
        final totalAmount = (data['totalAmount'] as num).toDouble();
        final operationId = data['operationId'] as String?;

        final newPaidAmount = currentPaid + amount;
        final newRemainingAmount = totalAmount - newPaidAmount;
        final isPaid = newRemainingAmount <= 0;

        // 1. Update debt item
        transaction.update(debtRef, {
          'paidAmount': newPaidAmount,
          'remainingAmount': newRemainingAmount,
          'isPaid': isPaid,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });

        // 2. Update operation if exists
        if (operationId != null && operationId.isNotEmpty) {
          final opRef = firestore
              .collection('users')
              .doc(uid)
              .collection('my_debt_operations')
              .doc(operationId);
          transaction.update(opRef, {
            'paidAmount': newPaidAmount,
            'remainingDebt': newRemainingAmount,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
        }

        // 3. Add payment record
        final paymentRef = debtRef.collection('payments').doc();
        transaction.set(paymentRef, {
          'debtId': debtId,
          'amountPaid': amount,
          'remainingAmount': newRemainingAmount,
          'createdAt': FieldValue.serverTimestamp(),
          'type': isPaid ? 'full' : 'partial',
          'note': note,
        });

        // 4. Update person doc
        final personName = data['personName'] as String;
        final personRef = firestore
            .collection('users')
            .doc(uid)
            .collection('my_debt_persons')
            .doc(personName);
        transaction.update(personRef, {
          'totalRemainingDebt': FieldValue.increment(-amount),
          'lastUsedAt': FieldValue.serverTimestamp(),
        });
      });
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

      // 1. Get payments to delete
      final paymentsSnapshot = await debtRef.collection('payments').get();

      final List<DocumentReference> allRefs = [];
      for (var paymentDoc in paymentsSnapshot.docs) {
        allRefs.add(paymentDoc.reference);
      }

      // 2. Add the debt doc itself
      allRefs.add(debtRef);

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

      await firestore.runTransaction((transaction) async {
        final debtSnap = await transaction.get(debtRef);
        if (!debtSnap.exists) throw Exception('Debt not found');

        final paymentsSnapshot = await debtRef
            .collection('payments')
            .orderBy('createdAt', descending: true)
            .get();
        final allPayments = paymentsSnapshot.docs
            .map((doc) => MyDebtPaymentModel.fromJson(doc.data(), doc.id))
            .toList();

        final targetPayment = allPayments.firstWhere((p) => p.id == paymentId);
        final String relatedTo = targetPayment.type == 'debtAdded'
            ? 'debt'
            : 'payment';

        // RULE 3 validation for debtAdded
        if (targetPayment.type == 'debtAdded') {
          final paymentsAfter = allPayments
              .where(
                (p) =>
                    (p.type == 'partial' || p.type == 'full') &&
                    p.createdAt.isAfter(targetPayment.createdAt),
              )
              .toList();

          if (paymentsAfter.isNotEmpty) {
            final nearestPayment = paymentsAfter.last;
            if (newAmount < nearestPayment.amountPaid) {
              throw Exception('invalid_amount');
            }
          }
        }

        final delta = newAmount - targetPayment.amountPaid;
        if (delta == 0) return;

        // Direct Mutation: Update the same item
        final paymentRef = debtRef.collection('payments').doc(paymentId);
        transaction.update(paymentRef, {
          'amountPaid': newAmount,
          'note': note ?? targetPayment.note,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });

        // Update stored totals
        if (relatedTo == 'debt') {
          transaction.update(debtRef, {
            'totalAmount': FieldValue.increment(delta),
            'remainingAmount': FieldValue.increment(delta),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(debtRef, {
            'paidAmount': FieldValue.increment(delta),
            'remainingAmount': FieldValue.increment(-delta),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
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
            'totalDebtAmount': FieldValue.increment(delta),
            'totalRemainingDebt': FieldValue.increment(delta),
          });
        } else {
          transaction.update(personRef, {
            'totalRemainingDebt': FieldValue.increment(-delta),
          });
        }
      });
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

      await firestore.runTransaction((transaction) async {
        final debtSnap = await transaction.get(debtRef);
        if (!debtSnap.exists) throw Exception('Debt not found');

        final paymentsSnapshot = await debtRef
            .collection('payments')
            .orderBy('createdAt', descending: true)
            .get();
        final allPayments = paymentsSnapshot.docs
            .map((doc) => MyDebtPaymentModel.fromJson(doc.data(), doc.id))
            .toList();

        final targetPayment = allPayments.firstWhere((p) => p.id == paymentId);
        final String relatedTo = targetPayment.type == 'debtAdded'
            ? 'debt'
            : 'payment';

        if (targetPayment.type == 'debtAdded') {
          // RULE 2: Check for newer payments
          final hasNewerPayments = allPayments.any(
            (p) =>
                (p.type == 'partial' || p.type == 'full') &&
                p.createdAt.isAfter(targetPayment.createdAt),
          );
          if (hasNewerPayments) {
            throw Exception('delete_not_allowed');
          }
        }

        // Direct Mutation: Delete the same item
        transaction.delete(paymentRef);

        // Update stored totals
        final amountToDelete = targetPayment.amountPaid;
        if (relatedTo == 'debt') {
          transaction.update(debtRef, {
            'totalAmount': FieldValue.increment(-amountToDelete),
            'remainingAmount': FieldValue.increment(-amountToDelete),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(debtRef, {
            'paidAmount': FieldValue.increment(-amountToDelete),
            'remainingAmount': FieldValue.increment(amountToDelete),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
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
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to delete payment: $e');
    }
  }
}
