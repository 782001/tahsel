import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts(String uid);
  Future<void> saveProduct(String uid, ProductModel product);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final FirebaseFirestore firestore;

  ProductRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<ProductModel>> getProducts(String uid) async {
    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('products')
        .orderBy('lastUsedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ProductModel.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  @override
  Future<void> saveProduct(String uid, ProductModel product) async {
    final collection = firestore
        .collection('users')
        .doc(uid)
        .collection('products');

    // Use a normalized name for finding (trim and lowercase)
    final normalizedName = product.name.trim();

    // Check if product exists (by name)
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
      await collection.add(product.toJson());
    }
  }
}
