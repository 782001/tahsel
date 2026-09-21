import 'package:equatable/equatable.dart';

enum CustomerOperationType { purchase, payment, debt, quotation }

class CustomerOperation extends Equatable {
  final String id;
  final String activityName; // e.g., 'Tea', 'Mango', 'Session'
  final double amount;
  final CustomerOperationType type;
  final DateTime date;
  final String? details;
  final double runningBalance;
  final String? referenceNumber;
  final String? invoiceId;
  final String? notes;

  const CustomerOperation({
    required this.id,
    required this.activityName,
    required this.amount,
    required this.type,
    required this.date,
    this.details,
    this.runningBalance = 0.0,
    this.referenceNumber,
    this.invoiceId,
    this.notes,
  });

  CustomerOperation copyWith({
    String? id,
    String? activityName,
    double? amount,
    CustomerOperationType? type,
    DateTime? date,
    String? details,
    double? runningBalance,
    String? referenceNumber,
    String? invoiceId,
    String? notes,
  }) {
    return CustomerOperation(
      id: id ?? this.id,
      activityName: activityName ?? this.activityName,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      details: details ?? this.details,
      runningBalance: runningBalance ?? this.runningBalance,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      invoiceId: invoiceId ?? this.invoiceId,
      notes: notes ?? this.notes,
    );
  }

  /// Returns the real invoice ID starting with 'inv_' if this operation is linked to an invoice.
  String? get resolvedInvoiceId {
    String? extractInvId(String? raw) {
      if (raw == null) return null;
      final text = raw.trim();
      if (text.isEmpty) return null;

      // Strip known prefixes recursively
      if (text.startsWith('debt_inv_')) {
        return extractInvId(text.replaceFirst('debt_inv_', ''));
      }
      if (text.startsWith('debt_')) {
        return extractInvId(text.replaceFirst('debt_', ''));
      }
      if (text.startsWith('inv_pay_')) {
        return extractInvId(text.replaceFirst('inv_pay_', ''));
      }
      if (text.startsWith('inv_quote_settle_')) {
        return extractInvId(text.replaceFirst('inv_quote_settle_', ''));
      }
      if (text.startsWith('inv_inv_')) {
        return extractInvId(text.replaceFirst('inv_', ''));
      }

      // Regex search for inv_ pattern
      final match = RegExp(r'inv_[a-zA-Z0-9_-]+').firstMatch(text);
      if (match != null) {
        var res = match.group(0)!;
        if (res.endsWith('_cash_pay')) {
          res = res.replaceFirst('_cash_pay', '');
        }
        if (res.endsWith('_pay')) {
          res = res.replaceFirst('_pay', '');
        }
        return res;
      }
      return null;
    }

    final fromInvoiceId = extractInvId(invoiceId);
    if (fromInvoiceId != null) return fromInvoiceId;

    final fromId = extractInvId(id);
    if (fromId != null) return fromId;

    final fromRef = extractInvId(referenceNumber);
    if (fromRef != null) return fromRef;

    final fromDetails = extractInvId(details);
    if (fromDetails != null) return fromDetails;

    final fromNotes = extractInvId(notes);
    if (fromNotes != null) return fromNotes;

    return null;
  }


  @override
  List<Object?> get props => [
    id,
    activityName,
    amount,
    type,
    date,
    details,
    runningBalance,
    referenceNumber,
    invoiceId,
    notes,
  ];
}
