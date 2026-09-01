import 'dart:convert';

import '../../domain/entities/invoice_entity.dart';

class InvoiceItemModel extends InvoiceItem {
  const InvoiceItemModel({
    required super.id,
    required super.description,
    required super.unitPrice,
    required super.quantity,
    super.taxRate,
    super.discountRate,
  });

  factory InvoiceItemModel.fromEntity(InvoiceItem item) => InvoiceItemModel(
    id: item.id,
    description: item.description,
    unitPrice: item.unitPrice,
    quantity: item.quantity,
    taxRate: item.taxRate,
    discountRate: item.discountRate,
  );

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) =>
      InvoiceItemModel(
        id: map['id'] as String,
        description: map['description'] as String,
        unitPrice: (map['unitPrice'] as num).toDouble(),
        quantity: (map['quantity'] as num).toDouble(),
        taxRate: (map['taxRate'] as num? ?? 0).toDouble(),
        discountRate: (map['discountRate'] as num? ?? 0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'description': description,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'taxRate': taxRate,
    'discountRate': discountRate,
  };
}

class InvoicePaymentModel extends InvoicePayment {
  const InvoicePaymentModel({
    required super.id,
    required super.amount,
    required super.paidAt,
    super.note,
  });

  factory InvoicePaymentModel.fromEntity(InvoicePayment p) =>
      InvoicePaymentModel(
        id: p.id,
        amount: p.amount,
        paidAt: p.paidAt,
        note: p.note,
      );

  factory InvoicePaymentModel.fromMap(Map<String, dynamic> map) =>
      InvoicePaymentModel(
        id: map['id'] as String,
        amount: (map['amount'] as num).toDouble(),
        paidAt: DateTime.parse(map['paidAt'] as String),
        note: map['note'] as String?,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'paidAt': paidAt.toIso8601String(),
    'note': note,
  };
}

class InvoiceModel extends InvoiceEntity {
  const InvoiceModel({
    required super.id,
    required super.uid,
    super.customerName,
    super.customerPhone,
    super.ledgerNumber,
    required super.items,
    super.payments,
    super.status,
    required super.createdAt,
    super.lastUpdatedAt,
    super.notes,
    super.referenceNumber,
    super.linkedDebtId,
    super.syncedTotalPaid,
    super.discountAmount,
    super.isRefundedToCustomer,
    super.dueDate,
  });

  factory InvoiceModel.fromEntity(InvoiceEntity e) => InvoiceModel(
    id: e.id,
    uid: e.uid,
    customerName: e.customerName,
    customerPhone: e.customerPhone,
    ledgerNumber: e.ledgerNumber,
    items: e.items.map((i) => InvoiceItemModel.fromEntity(i)).toList(),
    payments: e.payments.map((p) => InvoicePaymentModel.fromEntity(p)).toList(),
    status: e.status,
    createdAt: e.createdAt,
    lastUpdatedAt: e.lastUpdatedAt,
    notes: e.notes,
    referenceNumber: e.referenceNumber,
    linkedDebtId: e.linkedDebtId,
    syncedTotalPaid: e.syncedTotalPaid,
    discountAmount: e.discountAmount,
    isRefundedToCustomer: e.isRefundedToCustomer,
    dueDate: e.dueDate,
  );

  factory InvoiceModel.fromMap(Map<String, dynamic> map) => InvoiceModel(
    id: map['id'] as String,
    uid: map['uid'] as String,
    customerName: map['customerName'] as String?,
    customerPhone: map['customerPhone'] as String?,
    ledgerNumber: map['ledgerNumber'] as String?,
    items: (map['items'] as List<dynamic>? ?? [])
        .map((i) => InvoiceItemModel.fromMap(i as Map<String, dynamic>))
        .toList(),
    payments: (map['payments'] as List<dynamic>? ?? [])
        .map((p) => InvoicePaymentModel.fromMap(p as Map<String, dynamic>))
        .toList(),
    status: InvoiceStatus.values.firstWhere(
      (s) => s.name == (map['status'] as String? ?? 'pending'),
      orElse: () => InvoiceStatus.pending,
    ),
    createdAt: DateTime.parse(map['createdAt'] as String),
    lastUpdatedAt: map['lastUpdatedAt'] != null
        ? DateTime.parse(map['lastUpdatedAt'] as String)
        : null,
    notes: map['notes'] as String?,
    referenceNumber: map['referenceNumber'] as String?,
    linkedDebtId: map['linkedDebtId'] as String?,
    syncedTotalPaid: (map['syncedTotalPaid'] as num?)?.toDouble(),
    discountAmount: (map['discountAmount'] as num? ?? 0.0).toDouble(),
    isRefundedToCustomer: map['isRefundedToCustomer'] as bool? ?? false,
    dueDate: map['dueDate'] == null
        ? null
        : (map['dueDate'] is DateTime
            ? map['dueDate'] as DateTime
            : DateTime.tryParse(map['dueDate'].toString())),
  );

  /// Converts the model to a plain JSON-safe Map (no Firestore Timestamps).
  Map<String, dynamic> toMap() => {
    'id': id,
    'uid': uid,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'ledgerNumber': ledgerNumber,
    'items': items.map((i) => (i as InvoiceItemModel).toMap()).toList(),
    'payments': payments
        .map((p) => (p as InvoicePaymentModel).toMap())
        .toList(),
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
    'notes': notes,
    'referenceNumber': referenceNumber,
    'linkedDebtId': linkedDebtId,
    if (syncedTotalPaid != null) 'syncedTotalPaid': syncedTotalPaid,
    'discountAmount': discountAmount,
    'isRefundedToCustomer': isRefundedToCustomer,
    'dueDate': dueDate?.toIso8601String(),
  };

  String toJson() => jsonEncode(toMap());
}
