import 'package:equatable/equatable.dart';

/// Status of an invoice payment lifecycle.
enum InvoiceStatus {
  pending, // Created, no payment yet
  partial, // Partially paid → debt exists
  paid, // Fully settled
  voided, // Cancelled / reversed
  quotation, // Price offer / quotation - purely for display & pricing, no financial impact
}

/// A single line-item in an invoice.
class InvoiceItem extends Equatable {
  final String id;
  final String description;
  final double unitPrice;
  final double quantity;
  final String? unit;

  // Future-proof: tax, discount per item, and purchase price
  final double taxRate; // e.g. 0.14 for 14%
  final double discountRate; // e.g. 0.10 for 10%
  final double? purchasePrice; // Cost / purchase price for margin warning

  const InvoiceItem({
    required this.id,
    required this.description,
    required this.unitPrice,
    required this.quantity,
    this.unit,
    this.taxRate = 0.0,
    this.discountRate = 0.0,
    this.purchasePrice,
  });

  double get subtotal => unitPrice * quantity;
  double get discountAmount => subtotal * discountRate;
  double get taxAmount => (subtotal - discountAmount) * taxRate;
  double get total => subtotal - discountAmount + taxAmount;

  InvoiceItem copyWith({
    String? id,
    String? description,
    double? unitPrice,
    double? quantity,
    String? unit,
    double? taxRate,
    double? discountRate,
    double? purchasePrice,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      description: description ?? this.description,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      taxRate: taxRate ?? this.taxRate,
      discountRate: discountRate ?? this.discountRate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
    );
  }

  @override
  List<Object?> get props => [
    id,
    description,
    unitPrice,
    quantity,
    unit,
    taxRate,
    discountRate,
    purchasePrice,
  ];
}

/// A payment event applied against an invoice.
class InvoicePayment extends Equatable {
  final String id;
  final double amount;
  final DateTime paidAt;
  final String? note;

  const InvoicePayment({
    required this.id,
    required this.amount,
    required this.paidAt,
    this.note,
  });

  InvoicePayment copyWith({
    String? id,
    double? amount,
    DateTime? paidAt,
    String? note,
  }) {
    return InvoicePayment(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      paidAt: paidAt ?? this.paidAt,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [id, amount, paidAt, note];
}

/// The primary Invoice entity — independent of Debt.
/// Debt is a *side-effect* that may be created if this invoice is only partially paid.
class InvoiceEntity extends Equatable {
  final String id;
  final String uid; // Owner (business user)
  final String? customerName;
  final String? customerPhone;
  final String? ledgerNumber;
  final List<InvoiceItem> items;
  final List<InvoicePayment> payments;
  final InvoiceStatus status;
  final DateTime createdAt;
  final DateTime? lastUpdatedAt;

  // Future-proof extension fields
  final String? notes;
  final String? referenceNumber;
  final String? linkedDebtId;

  /// Persisted in Firestore by the debt-sync transaction.
  /// When present, it takes priority over the computed payments-array total.
  final double? syncedTotalPaid;

  /// Overall cash discount applied to the total invoice amount in currency (EGP).
  final double discountAmount;

  /// Indicates if the paid amount of this voided invoice was refunded to customer and deducted from vault.
  final bool isRefundedToCustomer;

  final DateTime? dueDate;

  const InvoiceEntity({
    required this.id,
    required this.uid,
    this.customerName,
    this.customerPhone,
    this.ledgerNumber,
    required this.items,
    this.payments = const [],
    this.status = InvoiceStatus.pending,
    required this.createdAt,
    this.lastUpdatedAt,
    this.notes,
    this.referenceNumber,
    this.linkedDebtId,
    this.syncedTotalPaid,
    this.discountAmount = 0.0,
    this.isRefundedToCustomer = false,
    this.dueDate,
  });

  /// Raw subtotal of all items before ANY discounts (sum of qty * unitPrice).
  double get rawSubtotalAmount =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Sum of all discounts applied individually to line items.
  double get itemsDiscountAmount =>
      items.fold(0.0, (sum, item) => sum + item.discountAmount);

  /// Total combined discount (item-level discounts + overall invoice discount).
  double get totalDiscountAmount => itemsDiscountAmount + discountAmount;

  double get subtotalAmount => items.fold(0.0, (sum, item) => sum + item.total);

  double get totalAmount {
    final net = subtotalAmount - discountAmount;
    return net > 0 ? net : 0.0;
  }

  /// If the debt-sync has written a `syncedTotalPaid` value, use it as the
  /// authoritative paid amount; otherwise fall back to the payments array.
  double get totalPaid =>
      syncedTotalPaid ?? payments.fold(0.0, (sum, p) => sum + p.amount);

  double get remainingAmount {
    final r = totalAmount - totalPaid;
    return r > 0 ? r : 0.0;
  }

  bool get isFullyPaid => remainingAmount == 0;

  bool get isQuotation => status == InvoiceStatus.quotation;

  InvoiceEntity copyWith({
    String? id,
    String? uid,
    String? customerName,
    String? customerPhone,
    String? ledgerNumber,
    List<InvoiceItem>? items,
    List<InvoicePayment>? payments,
    InvoiceStatus? status,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    String? notes,
    String? referenceNumber,
    String? linkedDebtId,
    double? syncedTotalPaid,
    double? discountAmount,
    bool? isRefundedToCustomer,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return InvoiceEntity(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      ledgerNumber: ledgerNumber ?? this.ledgerNumber,
      items: items ?? this.items,
      payments: payments ?? this.payments,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      notes: notes ?? this.notes,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      linkedDebtId: linkedDebtId ?? this.linkedDebtId,
      syncedTotalPaid: syncedTotalPaid ?? this.syncedTotalPaid,
      discountAmount: discountAmount ?? this.discountAmount,
      isRefundedToCustomer: isRefundedToCustomer ?? this.isRefundedToCustomer,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    );
  }

  @override
  List<Object?> get props => [
    id,
    uid,
    customerName,
    customerPhone,
    ledgerNumber,
    items,
    payments,
    status,
    createdAt,
    lastUpdatedAt,
    notes,
    referenceNumber,
    linkedDebtId,
    syncedTotalPaid,
    discountAmount,
    isRefundedToCustomer,
    dueDate,
  ];
}
