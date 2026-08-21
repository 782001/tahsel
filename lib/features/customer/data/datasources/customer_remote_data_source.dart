import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/firebase_error_handler.dart';
import '../models/customer_model.dart';
import '../../domain/entities/customer_operation.dart';

abstract class CustomerRemoteDataSource {
  Future<Map<String, dynamic>> getCustomers(
    String uid, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  });
  Future<void> saveCustomer(String uid, CustomerModel customer);
  Future<void> updateCustomerPhone(String uid, String name, String phoneNumber);
  Future<void> updateCustomerPreference(
    String uid,
    String name,
    String preference,
  );
  Future<Map<String, dynamic>> getCustomerOperations(
    String uid,
    String customerName, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  });
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final FirebaseFirestore firestore;

  CustomerRemoteDataSourceImpl({required this.firestore});

  @override
  Future<Map<String, dynamic>> getCustomers(
    String uid, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      var query = firestore
          .collection('users')
          .doc(uid)
          .collection('customers')
          .orderBy('lastUsedAt', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();

      final customers = snapshot.docs
          .map((doc) => CustomerModel.fromJson(doc.data(), id: doc.id))
          .toList();

      return {
        'customers': customers,
        'lastDoc': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      };
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
        // Customer document exists — just update the preference
        await existing.docs.first.reference.update({
          'notificationPreference': preference,
        });
      } else {
        // Customer has no document yet (added via an older/direct debt flow).
        // Upsert a minimal document so the preference is persisted.
        await collection.add({
          'name': normalizedName,
          'notificationPreference': preference,
          'lastUsedAt': Timestamp.now(),
          'totalTransactions': 0,
          'phoneNumber': null,
        });
      }
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getCustomerOperations(
    String uid,
    String customerName, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      final userRef = firestore.collection('users').doc(uid);

      // 1. Fetch operations with pagination
      var opsQuery = userRef
          .collection('operations')
          .where('customerName', isEqualTo: customerName)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        opsQuery = opsQuery.startAfterDocument(lastDoc);
      }

      final opsSnapshot = await opsQuery.get();
      List<CustomerOperation> operations = [];

      DateTime parseDate(dynamic val) {
        if (val == null) return DateTime.now();
        if (val is Timestamp) return val.toDate();
        if (val is DateTime) return val;
        if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
        if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
        return DateTime.now();
      }

      for (var doc in opsSnapshot.docs) {
        final data = doc.data();
        final type = ((data['remainingDebt'] as num?)?.toDouble() ?? 0.0) > 0
            ? CustomerOperationType.debt
            : CustomerOperationType.purchase;

        operations.add(
          CustomerOperation(
            id: doc.id,
            activityName: data['type']?.toString() ?? '',
            amount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
            type: type,
            date: parseDate(data['timestamp']),
            details: data['productName']?.toString(),
          ),
        );
      }

      // 2. Fetch payments and calculate aggregate statistics only if we are on the first page
      double totalSpent = 0.0;
      double totalPaid = 0.0;

      if (lastDoc == null) {
        final debtsSnapshot = await userRef
            .collection('debts')
            .where('customerName', isEqualTo: customerName)
            .get();

        for (var debtDoc in debtsSnapshot.docs) {
          final debtData = debtDoc.data();
          totalSpent += (debtData['totalAmount'] as num? ?? 0.0).toDouble();
          totalPaid += (debtData['paidAmount'] as num? ?? 0.0).toDouble();

          final activityName = debtData['operationType']?.toString() ?? '';

          final paymentsSnapshot = await debtDoc.reference
              .collection('payments')
              .get();

          for (var paymentDoc in paymentsSnapshot.docs) {
            final pData = paymentDoc.data();
            if (pData['type'] == 'debtAdded') continue;

            operations.add(
              CustomerOperation(
                id: paymentDoc.id,
                activityName: activityName,
                amount: (pData['amountPaid'] as num?)?.toDouble() ?? 0.0,
                type: CustomerOperationType.payment,
                date: parseDate(pData['createdAt']),
                details: null,
              ),
            );
          }
        }
      }

      // Sort combined list latest first
      operations.sort((a, b) => b.date.compareTo(a.date));

      return {
        'operations': operations,
        'lastDoc': opsSnapshot.docs.isNotEmpty ? opsSnapshot.docs.last : null,
        'totalSpent': totalSpent,
        'totalPaid': totalPaid,
      };
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }
}
