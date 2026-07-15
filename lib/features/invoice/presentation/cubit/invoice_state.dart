import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../debt/domain/entities/payment_entity.dart';
import '../../domain/entities/invoice_entity.dart';

abstract class InvoiceState extends Equatable {
  const InvoiceState();

  @override
  List<Object?> get props => [];
}

/// Initial / idle state
class InvoiceInitial extends InvoiceState {}

/// Submitting or loading data
class InvoiceLoading extends InvoiceState {}

/// Invoice was created successfully
class InvoiceCreateSuccess extends InvoiceState {
  final String invoiceId;

  const InvoiceCreateSuccess(this.invoiceId);

  @override
  List<Object?> get props => [invoiceId];
}

/// Invoices list loaded (with optional search filter)
class InvoiceListLoaded extends InvoiceState {
  final List<InvoiceEntity> invoices;
  final List<InvoiceEntity> filtered;
  final String searchQuery;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final bool isPaginationLoading;
  final Set<String> pendingSyncIds;

  const InvoiceListLoaded({
    required this.invoices,
    List<InvoiceEntity>? filtered,
    this.searchQuery = '',
    this.lastDocument,
    this.hasMore = false,
    this.isPaginationLoading = false,
    this.pendingSyncIds = const {},
  }) : filtered = filtered ?? invoices;

  InvoiceListLoaded copyWith({
    List<InvoiceEntity>? invoices,
    List<InvoiceEntity>? filtered,
    String? searchQuery,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    bool? isPaginationLoading,
    Set<String>? pendingSyncIds,
    bool clearLastDocument = false,
  }) {
    return InvoiceListLoaded(
      invoices: invoices ?? this.invoices,
      filtered: filtered ?? this.filtered,
      searchQuery: searchQuery ?? this.searchQuery,
      lastDocument:
          clearLastDocument ? null : (lastDocument ?? this.lastDocument),
      hasMore: hasMore ?? this.hasMore,
      isPaginationLoading: isPaginationLoading ?? this.isPaginationLoading,
      pendingSyncIds: pendingSyncIds ?? this.pendingSyncIds,
    );
  }

  @override
  List<Object?> get props => [
        invoices,
        filtered,
        searchQuery,
        lastDocument,
        hasMore,
        isPaginationLoading,
        pendingSyncIds,
      ];
}

/// A single invoice was loaded (detail view)
class InvoiceDetailLoaded extends InvoiceState {
  final InvoiceEntity invoice;
  /// Payments fetched directly from the linked Debt sub-collection.
  /// Non-null only when the invoice has a [linkedDebtId].
  final List<PaymentEntity>? debtTransactions;

  const InvoiceDetailLoaded(this.invoice, {this.debtTransactions});

  @override
  List<Object?> get props => [invoice, debtTransactions];
}

/// Payment recorded successfully
class InvoicePaymentSuccess extends InvoiceState {}

/// Invoice was updated successfully
class InvoiceUpdateSuccess extends InvoiceState {}

/// Invoice was voided successfully
class InvoiceVoidSuccess extends InvoiceState {}

/// Error state
class InvoiceFailure extends InvoiceState {
  final String message;

  const InvoiceFailure(this.message);

  @override
  List<Object?> get props => [message];
}
