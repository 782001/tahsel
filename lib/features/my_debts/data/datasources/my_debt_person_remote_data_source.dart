import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/error/firebase_error_handler.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_person_model.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_operation_entity.dart';

abstract class MyDebtPersonRemoteDataSource {
  Future<List<MyDebtPersonModel>> getPersons(
    String uid, {
    bool forceRefresh = false,
  });
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
