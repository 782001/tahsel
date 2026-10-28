import 'package:equatable/equatable.dart';
import '../../domain/entities/vault_summary_entity.dart';
import '../../domain/entities/vault_transaction_entity.dart';

abstract class VaultState extends Equatable {
  const VaultState();

  @override
  List<Object?> get props => [];
}

class VaultInitial extends VaultState {}

class VaultLoading extends VaultState {}

class VaultLoaded extends VaultState {
  final VaultSummaryEntity summary;
  final List<VaultTransactionEntity> transactions;
  final VaultTransactionSource selectedSource;
  final String selectedPaymentMethod; // 'all', 'cash', 'card'
  final bool hasMore;
  final bool isLoadingMore;
  final bool isFiltering;
  final dynamic lastDoc;

  const VaultLoaded({
    required this.summary,
    required this.transactions,
    this.selectedSource = VaultTransactionSource.all,
    this.selectedPaymentMethod = 'all',
    this.hasMore = false,
    this.isLoadingMore = false,
    this.isFiltering = false,
    this.lastDoc,
  });

  List<VaultTransactionEntity> get filteredTransactions {
    if (selectedPaymentMethod == 'all') return transactions;
    return transactions
        .where((t) => t.paymentMethod.toLowerCase() == selectedPaymentMethod.toLowerCase())
        .toList();
  }

  VaultLoaded copyWith({
    VaultSummaryEntity? summary,
    List<VaultTransactionEntity>? transactions,
    VaultTransactionSource? selectedSource,
    String? selectedPaymentMethod,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isFiltering,
    dynamic lastDoc,
  }) {
    return VaultLoaded(
      summary: summary ?? this.summary,
      transactions: transactions ?? this.transactions,
      selectedSource: selectedSource ?? this.selectedSource,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isFiltering: isFiltering ?? this.isFiltering,
      lastDoc: lastDoc ?? this.lastDoc,
    );
  }

  @override
  List<Object?> get props => [
        summary,
        transactions,
        selectedSource,
        selectedPaymentMethod,
        hasMore,
        isLoadingMore,
        isFiltering,
        lastDoc,
      ];
}

class VaultError extends VaultState {
  final String message;

  const VaultError(this.message);

  @override
  List<Object?> get props => [message];
}

class VaultActionSuccess extends VaultState {
  final String message;

  const VaultActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
