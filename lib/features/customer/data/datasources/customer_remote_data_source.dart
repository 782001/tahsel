import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

abstract class CustomerRemoteDataSource {
  Future<List<CustomerModel>> getCustomers(String uid);
  Future<void> saveCustomer(String uid, CustomerModel customer);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final FirebaseFirestore firestore;

  CustomerRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<CustomerModel>> getCustomers(String uid) async {
    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('customers')
        .orderBy('lastUsedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CustomerModel.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  @override
  Future<void> saveCustomer(String uid, CustomerModel customer) async {
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
  }
}
