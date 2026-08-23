import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import '../../domain/entities/vault_summary_entity.dart';
import '../../domain/entities/vault_transaction_entity.dart';
import '../../domain/usecases/delete_manual_vault_usecase.dart';
import '../../domain/usecases/deposit_manual_vault_usecase.dart';
import '../../domain/usecases/edit_manual_vault_usecase.dart';
import '../../domain/usecases/get_vault_summary_usecase.dart';
import '../../domain/usecases/get_vault_transactions_paginated_usecase.dart';
import '../../domain/usecases/withdraw_manual_vault_usecase.dart';
import 'vault_state.dart';

class VaultCubit extends Cubit<VaultState> {
  final GetVaultSummaryUseCase getVaultSummaryUseCase;
  final GetVaultTransactionsPaginatedUseCase getVaultTransactionsPaginatedUseCase;
  final DepositManualVaultUseCase depositManualVaultUseCase;
  final WithdrawManualVaultUseCase withdrawManualVaultUseCase;
  final EditManualVaultUseCase editManualVaultUseCase;
  final DeleteManualVaultUseCase deleteManualVaultUseCase;

  StreamSubscription<VaultSummaryEntity>? _summarySubscription;
  String? _uid;

  VaultCubit({
    required this.getVaultSummaryUseCase,
    required this.getVaultTransactionsPaginatedUseCase,
    required this.depositManualVaultUseCase,
    required this.withdrawManualVaultUseCase,
    required this.editManualVaultUseCase,
    required this.deleteManualVaultUseCase,
  }) : super(VaultInitial());

  Future<void> loadVaultData(String uid, {VaultTransactionSource? sourceFilter}) async {
    _uid = uid;
    if (state is! VaultLoaded) {
      emit(VaultLoading());
    }

    _summarySubscription?.cancel();
    _summarySubscription = getVaultSummaryUseCase.watch(uid).listen((summary) {
      if (state is VaultLoaded) {
        emit((state as VaultLoaded).copyWith(summary: summary));
      }
    });

    final summaryResult = await getVaultSummaryUseCase(uid);
    final summary = summaryResult.fold(
      (_) => const VaultSummaryEntity(currentBalance: 0.0),
      (s) => s,
    );

    final selectedSource = sourceFilter ?? VaultTransactionSource.all;
    final txResult = await getVaultTransactionsPaginatedUseCase(
      GetVaultTransactionsPaginatedParams(
        uid: uid,
        sourceFilter: selectedSource,
        limit: 15,
      ),
    );

    txResult.fold(
      (failure) => emit(VaultError(failure.message)),
      (data) {
        emit(
          VaultLoaded(
            summary: summary,
            transactions: data.transactions,
            selectedSource: selectedSource,
            hasMore: data.hasMore,
            lastDoc: data.lastDoc,
            isFiltering: false,
          ),
        );
      },
    );
  }

  Future<void> filterBySource(VaultTransactionSource source) async {
    if (_uid == null) return;
    final currentState = state;
    if (currentState is VaultLoaded) {
      if (currentState.selectedSource == source && !currentState.isFiltering) {
        return;
      }
      emit(currentState.copyWith(
        selectedSource: source,
        isFiltering: true,
      ));

      final txResult = await getVaultTransactionsPaginatedUseCase(
        GetVaultTransactionsPaginatedParams(
          uid: _uid!,
          sourceFilter: source,
          limit: 15,
        ),
      );

      final latestState = state;
      if (latestState is VaultLoaded) {
        txResult.fold(
          (failure) => emit(latestState.copyWith(isFiltering: false)),
          (data) {
            emit(
              latestState.copyWith(
                transactions: data.transactions,
                selectedSource: source,
                hasMore: data.hasMore,
                lastDoc: data.lastDoc,
                isFiltering: false,
              ),
            );
          },
        );
      }
    } else {
      await loadVaultData(_uid!, sourceFilter: source);
    }
  }

  Future<void> loadMoreTransactions() async {
    final currentState = state;
    if (currentState is! VaultLoaded || !currentState.hasMore || currentState.isLoadingMore || _uid == null) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    final txResult = await getVaultTransactionsPaginatedUseCase(
      GetVaultTransactionsPaginatedParams(
        uid: _uid!,
        sourceFilter: currentState.selectedSource,
        limit: 15,
        lastDoc: currentState.lastDoc,
      ),
    );

    txResult.fold(
      (failure) => emit(currentState.copyWith(isLoadingMore: false)),
      (data) {
        final updatedList = List<VaultTransactionEntity>.from(currentState.transactions)
          ..addAll(data.transactions);
        emit(
          currentState.copyWith(
            transactions: updatedList,
            hasMore: data.hasMore,
            lastDoc: data.lastDoc,
            isLoadingMore: false,
          ),
        );
      },
    );
  }

  Future<void> depositManual({required double amount, String? note}) async {
    _uid ??= FirebaseAuth.instance.currentUser?.uid;
    if (_uid == null) return;
    if (amount <= 0) {
      emit(const VaultError('Amount must be greater than zero'));
      return;
    }

    final result = await depositManualVaultUseCase(
      uid: _uid!,
      amount: amount,
      note: note,
    );

    result.fold(
      (failure) => emit(VaultError(failure.message)),
      (_) {
        emit(const VaultActionSuccess(AppStrings.depositSuccess));
        loadVaultData(_uid!);
      },
    );
  }

  Future<void> withdrawManual({required double amount, String? note}) async {
    _uid ??= FirebaseAuth.instance.currentUser?.uid;
    if (_uid == null) return;
    if (amount <= 0) {
      emit(const VaultError('Amount must be greater than zero'));
      return;
    }

    if (state is VaultLoaded) {
      final currentBal = (state as VaultLoaded).summary.currentBalance;
      if (amount > currentBal) {
        emit(const VaultError(AppStrings.insufficientBalance));
        return;
      }
    }

    final result = await withdrawManualVaultUseCase(
      uid: _uid!,
      amount: amount,
      note: note,
    );

    result.fold(
      (failure) => emit(VaultError(failure.message)),
      (_) {
        emit(const VaultActionSuccess(AppStrings.withdrawSuccess));
        loadVaultData(_uid!);
      },
    );
  }

  Future<void> editManualTransaction({
    required VaultTransactionEntity transaction,
    required double newAmount,
    required String newDescription,
  }) async {
    _uid ??= FirebaseAuth.instance.currentUser?.uid;
    if (_uid == null) return;
    if (newAmount <= 0) {
      emit(const VaultError(AppStrings.validationAmountGreaterThanZero));
      return;
    }

    final result = await editManualVaultUseCase(
      uid: _uid!,
      oldTransaction: transaction,
      newAmount: newAmount,
      newDescription: newDescription,
    );

    result.fold(
      (failure) => emit(VaultError(failure.message)),
      (_) {
        emit(const VaultActionSuccess(AppStrings.transactionUpdatedSuccess));
        loadVaultData(_uid!);
      },
    );
  }

  Future<void> deleteManualTransaction(VaultTransactionEntity transaction) async {
    _uid ??= FirebaseAuth.instance.currentUser?.uid;
    if (_uid == null) return;

    final result = await deleteManualVaultUseCase(
      uid: _uid!,
      transaction: transaction,
    );

    result.fold(
      (failure) => emit(VaultError(failure.message)),
      (_) {
        emit(const VaultActionSuccess(AppStrings.transactionDeletedSuccess));
        loadVaultData(_uid!);
      },
    );
  }

  Future<List<VaultTransactionEntity>> getAllTransactionsForExport({
    VaultTransactionSource? sourceFilter,
  }) async {
    final uid = _uid ??
        FirebaseAuth.instance.currentUser?.uid ??
        AppStrings.userToken;
    if (uid.isEmpty) return [];

    final selectedSource = sourceFilter ??
        (state is VaultLoaded
            ? (state as VaultLoaded).selectedSource
            : VaultTransactionSource.all);

    final result = await getVaultTransactionsPaginatedUseCase(
      GetVaultTransactionsPaginatedParams(
        uid: uid,
        sourceFilter: selectedSource,
        limit: 1000,
      ),
    );

    return result.fold(
      (_) => state is VaultLoaded ? (state as VaultLoaded).transactions : [],
      (data) => data.transactions,
    );
  }

  @override
  Future<void> close() {
    _summarySubscription?.cancel();
    return super.close();
  }
}
