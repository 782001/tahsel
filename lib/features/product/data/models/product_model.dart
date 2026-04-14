import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    super.id,
    required super.name,
    required super.lastUsedAt,
    super.totalTransactions = 1,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return ProductModel(
      id: id,
      name: json['name'] as String,
      lastUsedAt: (json['lastUsedAt'] as Timestamp).toDate(),
      totalTransactions: json['totalTransactions'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lastUsedAt': Timestamp.fromDate(lastUsedAt),
      'totalTransactions': totalTransactions,
    };
  }

  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      lastUsedAt: entity.lastUsedAt,
      totalTransactions: entity.totalTransactions,
    );
  }
}
