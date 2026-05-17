import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tahsel/core/error/firebase_error_handler.dart';
import 'package:tahsel/core/usecases/pagination_params.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_person_model.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_operation_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_summary_entity.dart';

abstract class MyDebtPersonRemoteDataSource {
  Future<List<MyDebtPersonModel>> getPersons(
    String uid, {
    bool forceRefresh = false,
  });
  Future<PaginatedResult<MyDebtPersonModel>> getPersonsPaginated(
    String uid, {
    required int limit,
    DocumentSnapshot? lastDocument,
    bool forceRefresh = false,
  });
  Future<MyDebtSummaryEntity> getMyDebtSummary(String uid);
  Future<void> savePerson(String uid, MyDebtPersonModel person);
  Future<void> updatePersonPhone(String uid, String name, String phoneNumber);
  Future<void> updatePersonPreference(
    String uid,
    String name,
    String preference,
  );
  Future<List<MyDebtOperationEntity>> getPersonOperations(
    String uid,
    String personName, {
    bool forceRefresh = false,
  });
}

class MyDebtPersonRemoteDataSourceImpl implements MyDebtPersonRemoteDataSource {
  final FirebaseFirestore firestore;

  MyDebtPersonRemoteDataSourceImpl({required this.firestore});

  @override
  Future<MyDebtSummaryEntity> getMyDebtSummary(String uid) async {
    try {
      final collection = firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_persons');

      double remaining = 0.0;
      double total = 0.0;
      int cnt = 0;

      if (defaultTargetPlatform == TargetPlatform.windows) {
        final querySnapshot = await collection.get();
        cnt = querySnapshot.docs.length;
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          remaining += (data['totalRemainingDebt'] as num?)?.toDouble() ?? 0.0;
          total += (data['totalDebtAmount'] as num?)?.toDouble() ?? 0.0;
        }
      } else {
        final snapshot = await collection.aggregate(
          count(),
          sum('totalRemainingDebt'),
          sum('totalDebtAmount'),
        ).get();

        remaining = snapshot.getSum('totalRemainingDebt') ?? 0.0;
        total = snapshot.getSum('totalDebtAmount') ?? 0.0;
        cnt = snapshot.count ?? 0;
      }

      return MyDebtSummaryEntity(
        totalRemainingDebt: remaining,
        totalDebtAmount: total,
        peopleCount: cnt,
      );
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<PaginatedResult<MyDebtPersonModel>> getPersonsPaginated(
    String uid, {
    required int limit,
    DocumentSnapshot? lastDocument,
    bool forceRefresh = false,
  }) async {
    try {
      var query = firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_persons')
          .orderBy('lastUsedAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Fetch one extra to determine hasMore
      final snapshot = await query.limit(limit + 1).get(
            GetOptions(
              source: forceRefresh ? Source.server : Source.serverAndCache,
            ),
          );

      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.sublist(0, limit) : snapshot.docs;

      final items = docs
          .map((doc) => MyDebtPersonModel.fromJson(doc.data(), id: doc.id))
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
  Future<List<MyDebtPersonModel>> getPersons(
    String uid, {
    bool forceRefresh = false,
  }) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_persons')
          .orderBy('lastUsedAt', descending: true)
          .get(
            GetOptions(
              source: forceRefresh ? Source.server : Source.serverAndCache,
            ),
          );

      return snapshot.docs
          .map((doc) => MyDebtPersonModel.fromJson(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<void> savePerson(String uid, MyDebtPersonModel person) async {
    try {
      final collection = firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_persons');

      final normalizedName = person.name.trim();
      final docRef = collection.doc(normalizedName);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        final currentTotal = docSnap.data()?['totalTransactions'] as int? ?? 0;
        await docRef.update({
          'lastUsedAt': Timestamp.fromDate(DateTime.now()),
          'totalTransactions': currentTotal + 1,
        });
      } else {
        await docRef.set(person.toJson());
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updatePersonPhone(
    String uid,
    String name,
    String phoneNumber,
  ) async {
    try {
      final collection = firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_persons');
      final normalizedName = name.trim();
      final docRef = collection.doc(normalizedName);
      await docRef.update({'phoneNumber': phoneNumber});
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<void> updatePersonPreference(
    String uid,
    String name,
    String preference,
  ) async {
    try {
      final collection = firestore
          .collection('users')
          .doc(uid)
          .collection('my_debt_persons');
      final normalizedName = name.trim();
      final docRef = collection.doc(normalizedName);
      await docRef.update({'notificationPreference': preference});
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<List<MyDebtOperationEntity>> getPersonOperations(
    String uid,
    String personName, {
    bool forceRefresh = false,
  }) async {
    try {
      final userRef = firestore.collection('users').doc(uid);
      final getOptions = GetOptions(
        source: forceRefresh ? Source.server : Source.serverAndCache,
      );

      // 1. Fetch from operations collection
      final opsSnapshot = await userRef
          .collection('my_debt_operations')
          .where('personName', isEqualTo: personName)
          .get(getOptions);

      List<MyDebtOperationEntity> operations = [];

      for (var doc in opsSnapshot.docs) {
        final data = doc.data();
        final type = (data['remainingDebt'] ?? 0) > 0
            ? MyDebtOperationType.debt
            : MyDebtOperationType.purchase;

        operations.add(
          MyDebtOperationEntity(
            id: doc.id,
            activityName: data['type'] ?? '',
            amount: (data['totalAmount'] as num).toDouble(),
            type: type,
            date: (data['timestamp'] as Timestamp).toDate(),
            details: data['details'],
          ),
        );
      }

      // 2. Fetch payments from debt sub-collections
      final debtsSnapshot = await userRef
          .collection('my_debt_items')
          .where('personName', isEqualTo: personName)
          .get(getOptions);

      for (var debtDoc in debtsSnapshot.docs) {
        final debtData = debtDoc.data();
        final activityName = debtData['operationType'] as String;

        final paymentsSnapshot = await debtDoc.reference
            .collection('payments')
            .get(getOptions);

        for (var paymentDoc in paymentsSnapshot.docs) {
          final pData = paymentDoc.data();
          if (pData['type'] == 'debtAdded') continue;

          operations.add(
            MyDebtOperationEntity(
              id: paymentDoc.id,
              activityName: activityName,
              amount: (pData['amountPaid'] as num).toDouble(),
              type: MyDebtOperationType.payment,
              date: (pData['createdAt'] as Timestamp).toDate(),
              details: null,
            ),
          );
        }
      }

      return operations;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }
}
