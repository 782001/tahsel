import 'package:equatable/equatable.dart';

class InventorySupplierEntity extends Equatable {
  final String id;
  final String name;
  final String? companyName;
  final String? taxNumber;
  final String phone;
  final String address;
  final String? email;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const InventorySupplierEntity({
    required this.id,
    required this.name,
    this.companyName,
    this.taxNumber,
    required this.phone,
    required this.address,
    this.email,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  InventorySupplierEntity copyWith({
    String? id,
    String? name,
    String? companyName,
    String? taxNumber,
    String? phone,
    String? address,
    String? email,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return InventorySupplierEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      taxNumber: taxNumber ?? this.taxNumber,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        companyName,
        taxNumber,
        phone,
        address,
        email,
        notes,
        createdAt,
        updatedAt,
        isSynced,
      ];
}
