import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_person_entity.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/add_my_debt_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/get_pending_my_debts_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/payment/distribute_my_debt_payment_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/person/get_my_debt_persons_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/person/get_my_debt_persons_paginated_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/person/update_my_debt_person_preference_usecase.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_state.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_summary_cubit.dart';
import 'package:tahsel/features/offline_sync/data/models/offline_record.dart';
import 'package:tahsel/features/offline_sync/presentation/cubit/offline_sync_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/core/services/injection_container.dart';

class MyDebtsCubit extends Cubit<MyDebtsState> {
  final GetMyDebtPersonsUseCase getPersonsUseCase;
  final GetMyDebtPersonsPaginatedUseCase getPersonsPaginatedUseCase;
  final AddMyDebtUseCase addDebtUseCase;
  final DistributeMyDebtPaymentUseCase distributePaymentUseCase;
  final UpdateMyDebtPersonPreferenceUseCase updatePreferenceUseCase;
  final GetPendingMyDebtsUseCase getPendingMyDebtsUseCase;
  final ConnectivityCubit connectivityCubit;
  final OfflineSyncCubit offlineSyncCubit;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _syncSubscription;

  MyDebtsCubit({
    required this.getPersonsUseCase,
    required this.getPersonsPaginatedUseCase,
    required this.addDebtUseCase,
    required this.distributePaymentUseCase,
    required this.updatePreferenceUseCase,
    required this.getPendingMyDebtsUseCase,
    required this.connectivityCubit,
    required this.offlineSyncCubit,
  }) : super(const MyDebtsState()) {
    _listenToConnectivity();
    _listenToSync();
  }

  void _listenToSync() {
    _syncSubscription = offlineSyncCubit.stream.listen((syncState) {
      if (syncState is OfflineSyncSuccess) {
        final uid = AppStrings.userToken;
        if (uid.isNotEmpty) {
          loadPersons(uid, forceRefresh: true);
        }
      }
    });
  }

  void _listenToConnectivity() {
    _connectivitySubscription = connectivityCubit.stream.listen((
      connectivityState,
    ) {
      if (connectivityState is ConnectivityConnected ||
          connectivityState is ConnectivityDisconnected) {
        final uid = AppStrings.userToken;
        if (uid.isNotEmpty) {
          loadPersons(uid);
        }
      }
    });
  }

  List<MyDebtPersonEntity> _allPersons = [];
  List<MyDebtPersonEntity> _remotePersons = [];
  Timer? _searchDebounce;

  Future<void> loadPersons(String uid, {bool forceRefresh = false}) async {
    if (isClosed) return;

    emit(
      state.copyWith(
        status: MyDebtsStatus.loading,
        clearMessage: true,
        clearLastDocument: true,
        hasMore: false,
        isPaginationLoading: false,
      ),
    );

    final result = await getPersonsPaginatedUseCase(
      GetMyDebtPersonsPaginatedParams(
        uid: uid,
        limit: 15,
        forceRefresh: forceRefresh,
      ),
    );
    final pendingResult = await getPendingMyDebtsUseCase(const NoParams());
    final List<OfflineRecord> pendingRecords = pendingResult.fold(
      (_) => [],
      (records) => records,
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        _remotePersons = [];
        final merged = _mergePendingRecords([], pendingRecords);
        _allPersons = merged;
        _emitLoaded(
          merged,
          status: MyDebtsStatus.offlineLoaded,
          lastDocument: null,
          hasMore: false,
        );
      },
      (paginated) {
        _remotePersons = List.from(paginated.items);
        final merged = _mergePendingRecords(_remotePersons, pendingRecords);
        _allPersons = merged;
        _emitLoaded(
          merged,
          status: MyDebtsStatus.loaded,
          lastDocument: paginated.lastDocument,
          hasMore: paginated.hasMore,
        );
      },
    );
  }

  Future<void> loadMorePersons(String uid) async {
    if (isClosed) return;
    if (state.isPaginationLoading ||
        !state.hasMore ||
        state.status == MyDebtsStatus.loading) {
      return;
    }

    emit(state.copyWith(isPaginationLoading: true));

    final result = await getPersonsPaginatedUseCase(
      GetMyDebtPersonsPaginatedParams(
        uid: uid,
        limit: 15,
        lastDocument: state.lastDocument,
      ),
    );

    final pendingResult = await getPendingMyDebtsUseCase(const NoParams());
    final List<OfflineRecord> pendingRecords = pendingResult.fold(
      (_) => [],
      (records) => records,
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        emit(state.copyWith(isPaginationLoading: false));
      },
      (paginated) {
        _remotePersons.addAll(paginated.items);
        final merged = _mergePendingRecords(_remotePersons, pendingRecords);
        _allPersons = merged;
        _emitLoaded(
          merged,
          status: MyDebtsStatus.loaded,
          lastDocument: paginated.lastDocument,
          hasMore: paginated.hasMore,
          isPaginationLoading: false,
        );
      },
    );
  }

  List<MyDebtPersonEntity> _mergePendingRecords(
    List<MyDebtPersonEntity> persons,
    List<OfflineRecord> pendingRecords,
  ) {
    final List<MyDebtPersonEntity> merged = List.from(persons);

    for (final record in pendingRecords) {
      final String name = record.customerName.trim(); // Trim for robustness
      final double amount = record.amount;

      // Use case-insensitive and trimmed comparison to avoid duplication
      final existingIndex = merged.indexWhere(
        (p) => p.name.trim().toLowerCase() == name.toLowerCase(),
      );

      if (existingIndex != -1) {
        final existing = merged[existingIndex];
        merged[existingIndex] = existing.copyWith(
          totalDebtAmount: existing.totalDebtAmount + amount,
          totalRemainingDebt: existing.totalRemainingDebt + amount,
          totalTransactions: existing.totalTransactions + 1,
          lastUsedAt: record.date.isAfter(existing.lastUsedAt)
              ? record.date
              : existing.lastUsedAt,
        );
      } else {
        merged.add(
          MyDebtPersonEntity(
            name: name,
            totalDebtAmount: amount,
            totalRemainingDebt: amount,
            lastUsedAt: record.date,
            totalTransactions: 1,
          ),
        );
      }
    }

    // Sort by lastUsedAt descending
    merged.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    return merged;
  }

  void _emitLoaded(
    List<MyDebtPersonEntity> persons, {
    MyDebtsStatus status = MyDebtsStatus.loaded,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    bool? isPaginationLoading,
  }) {
    double totalOwed = 0;
    double totalPaid = 0;
    for (var p in persons) {
      totalOwed += p.totalRemainingDebt;
      totalPaid += (p.totalDebtAmount - p.totalRemainingDebt);
    }

    emit(
      state.copyWith(
        status: status,
        persons: persons,
        filteredPersons: persons,
        totalOwed: totalOwed,
        totalPaid: totalPaid,
        totalPeople: persons.length,
        lastDocument: lastDocument,
        hasMore: hasMore,
        isPaginationLoading: isPaginationLoading,
      ),
    );
  }

  Future<void> addDebt({
    required String uid,
    required String personName,
    required double totalAmount,
    required double paidAmount,
    String? details,
    String? phone,
  }) async {
    if (state.status == MyDebtsStatus.loading ||
        state.status == MyDebtsStatus.addingDebt ||
        state.status == MyDebtsStatus.addingPayment ||
        state.status == MyDebtsStatus.markingAsPaid ||
        state.status == MyDebtsStatus.deletingDebt) {
      return;
    }
    // Sanitize personName: replace '/' with ' ' to avoid Firestore path segment errors
    final sanitizedName = personName.replaceAll('/', ' ').trim();

    // if (isClosed) return;
    emit(
      state.copyWith(
        status: MyDebtsStatus.addingDebt,
        processingId: sanitizedName,
      ),
    );

    final now = DateTime.now();
    final debt = MyDebtItemEntity(
      id: '', // Generated by server
      uid: uid,
      operationId: 'manual_my_debt_${now.millisecondsSinceEpoch}',
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      remainingAmount: totalAmount - paidAmount,
      personName: sanitizedName,
      details: details ?? 'ديون جديدة',
      operationType: 'debt',
      timestamp: now,
      isPaid: (totalAmount - paidAmount) <= 0,
      phoneNumber: phone,
    );

    final result = await addDebtUseCase(debt);
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.printMessage(failure.message);
        emit(
          state.copyWith(status: MyDebtsStatus.error, message: failure.message),
        );
      },
      (_) {
        loadPersons(uid, forceRefresh: true);
        sl<MyDebtsSummaryCubit>().refreshSummary(uid);
      },
    );
  }

  Future<void> payTotalDebt({
    required String uid,
    required String personName,
    required double amount,
    required double totalRemainingBefore,
  }) async {
    if (state.status == MyDebtsStatus.loading ||
        state.status == MyDebtsStatus.addingDebt ||
        state.status == MyDebtsStatus.addingPayment ||
        state.status == MyDebtsStatus.markingAsPaid ||
        state.status == MyDebtsStatus.deletingDebt) {
      return;
    }
    final sanitizedName = personName.replaceAll('/', ' ').trim();
    if (isClosed) return;
    emit(
      state.copyWith(
        status: MyDebtsStatus.addingPayment,
        processingId: sanitizedName,
      ),
    );

    final result = await distributePaymentUseCase(
      uid: uid,
      personName: sanitizedName,
      amount: amount,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: MyDebtsStatus.error, message: failure.message),
      ),
      (_) {
        emit(
          state.copyWith(
            status: MyDebtsStatus.loaded,
            lastPaymentPerson: sanitizedName,
            lastPaymentAmount: amount,
            lastPaymentRemaining: totalRemainingBefore - amount,
          ),
        );
        loadPersons(uid, forceRefresh: true);
        sl<MyDebtsSummaryCubit>().refreshSummary(uid);
      },
    );
  }

  Future<void> updatePreference(
    String uid,
    String name,
    String preference,
  ) async {
    final sanitizedName = name.replaceAll('/', ' ').trim();
    // Optimistic Update
    final updated = _allPersons.map((p) {
      if (p.name == sanitizedName) {
        return p.copyWith(notificationPreference: preference);
      }
      return p;
    }).toList();
    _emitLoaded(updated);

    final result = await updatePreferenceUseCase(
      uid,
      sanitizedName,
      preference,
    );
    result.fold(
      (failure) => loadPersons(uid, forceRefresh: true), // Rollback
      (_) => null,
    );
  }

  void search(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (isClosed) return;
      final filtered = query.isEmpty
          ? _allPersons
          : _allPersons
                .where(
                  (p) =>
                      p.name.toLowerCase().contains(query.toLowerCase()) ||
                      (p.phoneNumber?.contains(query) ?? false),
                )
                .toList();
      _emitLoaded(filtered);
    });
  }

  void clearFlags() {
    if (isClosed) return;
    emit(
      state.copyWith(
        clearMessage: true,
        clearLastPayment: true,
        clearProcessingId: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    _connectivitySubscription?.cancel();
    _syncSubscription?.cancel();
    return super.close();
  }

  void clearData() {
    _allPersons.clear();
    emit(const MyDebtsState());
  }
}
