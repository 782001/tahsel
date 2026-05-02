import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/firebase_error_handler.dart';
import '../models/customer_model.dart';
import '../../domain/entities/customer_operation.dart';

abstract class CustomerRemoteDataSource {
  Future<List<CustomerModel>> getCustomers(String uid);
  Future<void> saveCustomer(String uid, CustomerModel customer);
  Future<void> updateCustomerPhone(String uid, String name, String phoneNumber);
  Future<void> updateCustomerPreference(
    String uid,
    String name,
    String preference,
  );
  Future<List<CustomerOperation>> getCustomerOperations(
    String uid,
    String customerName,
  );
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final FirebaseFirestore firestore;

  CustomerRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<CustomerModel>> getCustomers(String uid) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('customers')
          .orderBy('lastUsedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CustomerModel.fromJson(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<void> saveCustomer(String uid, CustomerModel customer) async {
    try {
      final collection = firestore
          .collection('users')
          .doc(uid)
          .collection('customers');

      // Use a normalized name for finding (trim and lowercase)
      final normalizedName = customer.name.trim();

      // Check if customer exists (by name)
      final existing = await collection
          .where('name', isEqualTo: normalizedName)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        final currentTotal = doc.data()['totalTransactions'] as int? ?? 0;
        await doc.reference.update({
          'lastUsedAt': Timestamp.fromDate(DateTime.now()),
          'totalTransactions': currentTotal + 1,
        });
      } else {
        await collection.add(customer.toJson());
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateCustomerPhone(
    String uid,
    String name,
    String phoneNumber,
  ) async {
    try {
      final collection = firestore
          .collection('users')
          .doc(uid)
          .collection('customers');
      final normalizedName = name.trim();
      final existing = await collection
          .where('name', isEqualTo: normalizedName)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference.update({
          'phoneNumber': phoneNumber,
        });
      }
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<void> updateCustomerPreference(
    String uid,
    String name,
    String preference,
  ) async {
    try {
      final collection = firestore
          .collection('users')
          .doc(uid)
          .collection('customers');
      final normalizedName = name.trim();
      final existing = await collection
          .where('name', isEqualTo: normalizedName)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference.update({
          'notificationPreference': preference,
        });
      }
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<List<CustomerOperation>> getCustomerOperations(
    String uid,
    String customerName,
  ) async {
    try {
      final userRef = firestore.collection('users').doc(uid);

      // 1. Fetch from operations collection
      final opsSnapshot = await userRef
          .collection('operations')
          .where('customerName', isEqualTo: customerName)
          .get();

      List<CustomerOperation> operations = [];

      for (var doc in opsSnapshot.docs) {
        final data = doc.data();
        final type = data['remainingDebt'] > 0
            ? CustomerOperationType.debt
            : CustomerOperationType.purchase;

        operations.add(
          CustomerOperation(
            id: doc.id,
            activityName: data['type'] ?? '',
            amount: (data['totalAmount'] as num).toDouble(),
            type: type,
            date: (data['timestamp'] as Timestamp).toDate(),
            details: data['productName'],
          ),
        );
      }

      // 2. Fetch payments from debt sub-collections
      final debtsSnapshot = await userRef
          .collection('debts')
          .where('customerName', isEqualTo: customerName)
          .get();

      for (var debtDoc in debtsSnapshot.docs) {
        final debtData = debtDoc.data();
        final activityName = debtData['operationType'] as String;

        final paymentsSnapshot = await debtDoc.reference
            .collection('payments')
            .get();

        for (var paymentDoc in paymentsSnapshot.docs) {
          final pData = paymentDoc.data();
          // Skip the 'debtAdded' type as it's already covered by the operation record
          if (pData['type'] == 'debtAdded') continue;

          operations.add(
            CustomerOperation(
              id: paymentDoc.id,
              activityName: activityName,
              amount: (pData['amountPaid'] as num).toDouble(),
              type: CustomerOperationType.payment,
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
