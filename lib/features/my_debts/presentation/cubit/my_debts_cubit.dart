import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_entity.dart';
import 'package:tahsel/features/my_debts/domain/usecases/my_debt_usecases.dart';
import 'package:tahsel/features/my_debts/data/models/my_debt_item_model.dart';

part 'my_debts_state.dart';

class MyDebtsCubit extends Cubit<MyDebtsState> {
  final GetMyDebtsUseCase getMyDebtsUseCase;
  final AddMyDebtUseCase addMyDebtUseCase;
  final AddMyDebtTransactionUseCase addMyDebtTransactionUseCase;
  final GetMyDebtTransactionsUseCase getMyDebtTransactionsUseCase;
  final DeleteMyDebtUseCase deleteMyDebtUseCase;
  final UpdateMyDebtUseCase updateMyDebtUseCase;
  final GetTotalPeopleCountUseCase getTotalPeopleCountUseCase;

  MyDebtsCubit({
    required this.getMyDebtsUseCase,
    required this.addMyDebtUseCase,
    required this.addMyDebtTransactionUseCase,
    required this.getMyDebtTransactionsUseCase,
    required this.deleteMyDebtUseCase,
    required this.updateMyDebtUseCase,
    required this.getTotalPeopleCountUseCase,
  }) : super(const MyDebtsState());

  Future<void> updateNotificationPreference(
    String personName,
    String preference,
  ) async {
    if (isClosed) return;

    // Optimistically update local cache immediately
    _allDebts = _allDebts.map((d) {
      if (d.personName == personName &&
          d.notificationPreference != preference) {
        return MyDebtEntity(
          id: d.id,
          personName: d.personName,
          totalAmount: d.totalAmount,
          paidAmount: d.paidAmount,
          remainingDebt: d.remainingDebt,
          phoneNumber: d.phoneNumber,
          notes: d.notes,
          createdAt: d.createdAt,
          lastTransactionDate: d.lastTransactionDate,
          notificationPreference: preference,
        );
      }
      return d;
    }).toList();

    // Emit the new state immediately so UI updates
    emit(state.copyWith(debts: _allDebts));

    // Update in background
    final personDebts = _allDebts
        .where((d) => d.personName == personName)
        .toList();
    for (var debt in personDebts) {
      if (debt.notificationPreference == preference) {
        // It's already set to preference in the local cache
        await updateMyDebtUseCase(debt);
      }
    }
  }

  Timer? _searchDebounce;
  List<MyDebtEntity> _allDebts = [];

  Future<void> loadMyDebts({bool forceRefresh = false}) async {
    if (isClosed) return;
    
    // Prevent multiple simultaneous loads or redundant loading if already fetching
    if (state.status == MyDebtsStatus.loading) return;

    // Cache logic: skip loading if already loaded and refresh is not forced
    if (!forceRefresh && state.status == MyDebtsStatus.loaded && state.debts.isNotEmpty) {
      return;
    }
    
    emit(state.copyWith(status: MyDebtsStatus.loading, clearProcessingId: true, clearMessage: true, clearLastPayment: true));
    final result = await getMyDebtsUseCase();
    if (isClosed) return;

    // Extract debts from result — avoid async callbacks inside fold
    List<MyDebtEntity>? debts;
    result.fold(
      (failure) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: MyDebtsStatus.error,
              message: 'Failed to load debts',
            ),
          );
        }
      },
      (data) {
        debts = data;
      },
    );

    // If fold hit the failure path, debts is null — return early
    if (debts == null || isClosed) return;

    _allDebts = debts!;

    // Compute totals in background with proper error handling
    try {
      final totals = await compute(_calculateTotals, debts!);
      if (!isClosed) {
        emit(
          state.copyWith(
            status: MyDebtsStatus.loaded,
            debts: debts,
            filteredDebts: debts,
            groupedDebts: totals.groupedDebts,
            totalOwed: totals.totalRemaining,
            totalPeople: totals.totalPeople,
            totalPaid: totals.totalPaid,
          ),
        );
      }
    } catch (e) {
      // If compute fails, still emit loaded with raw data so UI doesn't stay stuck
      if (!isClosed) {
        emit(
          state.copyWith(
            status: MyDebtsStatus.loaded,
            debts: debts,
            filteredDebts: debts,
          ),
        );
      }
    }
  }

  void searchDebts(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (isClosed) return;
      
      final filtered = query.isEmpty
          ? _allDebts
          : _allDebts.where((debt) {
              final nameMatch = debt.personName.toLowerCase().contains(
                    query.toLowerCase(),
                  );
              final phoneMatch = debt.phoneNumber?.contains(query) ?? false;
              return nameMatch || phoneMatch;
            }).toList();

      // Recalculate totals and grouping for the filtered list
      final totals = await compute(_calculateTotals, filtered);
      
      if (!isClosed) {
        emit(state.copyWith(
          filteredDebts: filtered,
          groupedDebts: totals.groupedDebts,
          totalOwed: totals.totalRemaining,
          totalPeople: totals.totalPeople,
          totalPaid: totals.totalPaid,
        ));
      }
    });
  }

  Future<void> addDebt({
    required String name,
    required double total,
    required double paid,
    String? phone,
    String? notes,
  }) async {
    if (isClosed) return;
    emit(state.copyWith(status: MyDebtsStatus.addingDebt, processingId: name));

    final now = DateTime.now();

    // 1. Check if person already exists (identity matching)
    final existingDebt = state.debts.firstWhereOrNull(
      (d) => d.personName.trim().toLowerCase() == name.trim().toLowerCase(),
    );

    if (existingDebt != null) {
      // 2. EXISTING PERSON: Add transaction to their anchor record
      final debtId = existingDebt.id;

      // Add 'debt' transaction
      final debtTransaction = MyDebtTransactionEntity(
        id: '${now.millisecondsSinceEpoch}_d',
        debtId: debtId,
        amount: total,
        type: 'debt',
        note: notes,
        date: now,
      );

      final result = await addMyDebtTransactionUseCase(debtTransaction);

      if (result.isRight() && paid > 0) {
        // Add 'payment' transaction if there was an initial payment
        final paymentTransaction = MyDebtTransactionEntity(
          id: '${now.millisecondsSinceEpoch + 1}_p',
          debtId: debtId,
          amount: paid,
          type: 'payment',
          note: notes,
          date: now,
        );
        await addMyDebtTransactionUseCase(paymentTransaction);
      }

      if (isClosed) return;

      // Update phone if provided and different
      if (phone != null &&
          phone.isNotEmpty &&
          phone != existingDebt.phoneNumber) {
        await updateMyDebtUseCase(existingDebt.copyWith(phoneNumber: phone));
      }

      emit(state.copyWith(status: MyDebtsStatus.loaded, clearProcessingId: true));
      loadMyDebts();
    } else {
      // 3. NEW PERSON: Create anchor document and first transaction
      final id = now.millisecondsSinceEpoch.toString();

      final resultEntities = await compute(
        _createDebtEntities,
        _AddDebtParams(
          id,
          name,
          total,
          paid,
          phone,
          notes,
          now,
          id,
        ), // personId = id for new
      );

      final result = await addMyDebtUseCase(
        resultEntities.debt,
        resultEntities.transaction,
      );

      if (isClosed) return;
      result.fold(
        (failure) => emit(
          state.copyWith(
            status: MyDebtsStatus.error,
            message: 'Failed to add debt',
            clearProcessingId: true,
          ),
        ),
        (_) {
          emit(state.copyWith(status: MyDebtsStatus.loaded, clearProcessingId: true));
          loadMyDebts();
        },
      );
    }
  }

  Future<void> addPayment(
    String debtId,
    double amount,
    String? note, {
    required String personName,
    required double remainingBalanceBefore,
  }) async {
    if (isClosed) return;
    emit(state.copyWith(status: MyDebtsStatus.addingPayment, processingId: debtId));
    final transaction = MyDebtTransactionEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      debtId: debtId,
      amount: amount,
      type: 'payment',
      note: note,
      date: DateTime.now(),
    );
    if (isClosed) return;
    final result = await addMyDebtTransactionUseCase(transaction);
    if (isClosed) return;
    result.fold(
      (failure) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: MyDebtsStatus.error,
              message: 'Failed to add payment',
              clearProcessingId: true,
            ),
          );
        }
      },
      (_) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: MyDebtsStatus.loaded,
              lastPaymentPerson: personName,
              lastPaymentAmount: amount,
              lastPaymentRemaining: remainingBalanceBefore - amount,
              lastPaymentNote: note,
              clearProcessingId: true,
            ),
          );
          loadMyDebts();
        }
      },
    );
  }

  Future<void> markItemAsPaid({
    required MyDebtEntity debt,
    required double totalRemainingBefore,
  }) async {
    if (isClosed) return;
    emit(state.copyWith(status: MyDebtsStatus.markingAsPaid, processingId: debt.id));
    final transaction = MyDebtTransactionEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      debtId: debt.id,
      amount: debt.remainingDebt,
      type: 'payment',
      note: AppStrings.fullSettlement.tr(),
      date: DateTime.now(),
    );
    if (isClosed) return;
    final result = await addMyDebtTransactionUseCase(transaction);
    if (isClosed) return;
    result.fold(
      (failure) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: MyDebtsStatus.error,
              message: 'Failed to settle item',
              clearProcessingId: true,
            ),
          );
        }
      },
      (_) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: MyDebtsStatus.loaded,
              lastPaymentPerson: debt.personName,
              lastPaymentAmount: debt.remainingDebt,
              lastPaymentRemaining: totalRemainingBefore - debt.remainingDebt,
              lastPaymentNote: AppStrings.fullSettlement.tr(),
              clearProcessingId: true,
            ),
          );
          loadMyDebts();
        }
      },
    );
  }

  Future<void> markAsPaid({
    required String personName,
    required double totalAmount,
    String? note,
  }) async {
    if (isClosed) return;
    emit(state.copyWith(status: MyDebtsStatus.markingAsPaid, processingId: personName));

    // Find all active debts for this person
    final personDebts = _allDebts
        .where((d) => d.personName == personName && d.remainingDebt > 0)
        .toList();

    bool hasError = false;
    for (var debt in personDebts) {
      final transaction = MyDebtTransactionEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        debtId: debt.id,
        amount: debt.remainingDebt,
        type: 'payment',
        note: note ?? AppStrings.fullSettlement.tr(),
        date: DateTime.now(),
      );
      final result = await addMyDebtTransactionUseCase(transaction);
      result.fold((failure) => hasError = true, (_) => null);
    }

    if (isClosed) return;

    if (hasError) {
      emit(
        state.copyWith(
          status: MyDebtsStatus.error,
          message: 'Failed to settle some debts',
          clearProcessingId: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: MyDebtsStatus.loaded,
          lastPaymentPerson: personName,
          lastPaymentAmount: totalAmount,
          lastPaymentRemaining: 0,
          lastPaymentNote: note ?? AppStrings.fullSettlement.tr(),
          clearProcessingId: true,
        ),
      );
    }
    loadMyDebts();
  }

  Future<void> deleteMultipleDebts(List<String> debtIds) async {
    if (isClosed || debtIds.isEmpty) return;
    emit(state.copyWith(status: MyDebtsStatus.deletingDebt, processingId: debtIds.first));
    
    bool hasError = false;
    for (var id in debtIds) {
      final result = await deleteMyDebtUseCase(id);
      result.fold((failure) => hasError = true, (_) => null);
    }
    
    if (isClosed) return;
    
    if (hasError) {
      emit(state.copyWith(
        status: MyDebtsStatus.error,
        message: 'Failed to delete some debts',
        clearProcessingId: true,
      ));
    } else {
      emit(state.copyWith(status: MyDebtsStatus.loaded, message: 'delete_success', clearProcessingId: true));
    }
    loadMyDebts();
  }

  Future<void> deleteDebt(String debtId) async {
    if (isClosed) return;

    // Check if debt exists and is fully paid
    final debt = state.debts.firstWhereOrNull((d) => d.id == debtId);
    if (debt == null) return;

    if (debt.remainingDebt > 0) {
      emit(state.copyWith(
        status: MyDebtsStatus.error,
        message: AppStrings.cannotDeleteUnpaidDebt,
      ));
      return;
    }

    emit(state.copyWith(status: MyDebtsStatus.deletingDebt, processingId: debtId));
    final result = await deleteMyDebtUseCase(debtId);
    if (isClosed) return;
    result.fold(
      (failure) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: MyDebtsStatus.error,
              message: 'Failed to delete debt',
              processingId: null,
            ),
          );
        }
      },
      (_) {
        if (!isClosed) {
          // Emit loaded FIRST so UI can react immediately
          emit(state.copyWith(status: MyDebtsStatus.loaded, message: 'delete_success', processingId: null));
          // Then refresh data in background
          loadMyDebts();
        }
      },
    );
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}

// Top-level function for Isolate
class DebtTotals {
  final double totalRemaining;
  final double totalPaid;
  final int totalPeople;
  final List<MyDebtDetail> groupedDebts;
  DebtTotals(this.totalRemaining, this.totalPaid, this.totalPeople, this.groupedDebts);
}

DebtTotals _calculateTotals(List<MyDebtEntity> debts) {
  double remaining = 0;
  double paid = 0;
  final Set<String> uniquePeople = {};
  final Map<String, List<MyDebtEntity>> grouped = {};

  for (var debt in debts) {
    remaining += debt.remainingDebt;
    paid += debt.paidAmount;

    final personKey = debt.personId ?? debt.personName.trim().toLowerCase();
    uniquePeople.add(personKey);
    
    // Use the actual name from the entity for grouping
    grouped.putIfAbsent(debt.personName, () => []).add(debt);
  }

  final groupedDebts = grouped.entries
      .map((entry) => MyDebtDetail.fromEntities(entry.key, entry.value))
      .toList()
    ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

  return DebtTotals(remaining, paid, uniquePeople.length, groupedDebts);
}

class _AddDebtParams {
  final String id;
  final String name;
  final double total;
  final double paid;
  final String? phone;
  final String? notes;
  final DateTime now;
  final String? personId;
  _AddDebtParams(
    this.id,
    this.name,
    this.total,
    this.paid,
    this.phone,
    this.notes,
    this.now,
    this.personId,
  );
}

class _AddDebtResult {
  final MyDebtEntity debt;
  final MyDebtTransactionEntity transaction;
  _AddDebtResult(this.debt, this.transaction);
}

_AddDebtResult _createDebtEntities(_AddDebtParams params) {
  return _AddDebtResult(
    MyDebtEntity(
      id: params.id,
      personId: params.personId,
      personName: params.name,
      totalAmount: params.total,
      paidAmount: params.paid,
      remainingDebt: params.total - params.paid,
      phoneNumber: params.phone,
      notes: params.notes,
      createdAt: params.now,
      lastTransactionDate: params.now,
    ),
    MyDebtTransactionEntity(
      id: params.now.millisecondsSinceEpoch.toString(),
      debtId: params.id,
      amount: params.total,
      type: 'debt',
      note: params.notes,
      date: params.now,
    ),
  );
}
