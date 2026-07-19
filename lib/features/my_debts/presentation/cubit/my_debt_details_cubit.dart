import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_operation_entity.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/add_my_debt_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/delete_my_debt_item_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/get_my_debt_items_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/debt/get_pending_my_debts_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/payment/distribute_my_debt_payment_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/payment/pay_my_debt_item_usecase.dart';
import 'package:tahsel/features/my_debts/domain/usecases/person/get_my_debt_person_operations_usecase.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_state.dart';
import 'package:tahsel/features/offline_sync/data/models/offline_record.dart';
import 'package:tahsel/features/offline_sync/presentation/cubit/offline_sync_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';

class MyDebtDetailsCubit extends Cubit<MyDebtDetailsState> {
  final GetMyDebtItemsUseCase getItemsUseCase;
  final GetMyDebtPersonOperationsUseCase getOperationsUseCase;
  final PayMyDebtItemUseCase payItemUseCase;
  final DeleteMyDebtItemUseCase deleteItemUseCase;
  final AddMyDebtUseCase addDebtUseCase;
  final DistributeMyDebtPaymentUseCase distributePaymentUseCase;
  final GetPendingMyDebtsUseCase getPendingMyDebtsUseCase;
  final ConnectivityCubit connectivityCubit;
  final OfflineSyncCubit offlineSyncCubit;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _syncSubscription;
  String? _currentPersonName;

  MyDebtDetailsCubit({
    required this.getItemsUseCase,
    required this.getOperationsUseCase,
    required this.payItemUseCase,
    required this.deleteItemUseCase,
    required this.addDebtUseCase,
    required this.distributePaymentUseCase,
    required this.getPendingMyDebtsUseCase,
    required this.connectivityCubit,
    required this.offlineSyncCubit,
  }) : super(const MyDebtDetailsState()) {
    _listenToConnectivity();
    _listenToSync();
  }

  void _listenToSync() {
    _syncSubscription = offlineSyncCubit.stream.listen((syncState) {
      if (syncState is OfflineSyncSuccess) {
        final uid = AppStrings.userToken;
        if (uid.isNotEmpty && _currentPersonName != null) {
          loadDetails(uid, _currentPersonName!);
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
        if (uid.isNotEmpty &&
            _currentPersonName != null &&
            state.status != MyDebtDetailsStatus.loading) {
          loadDetails(uid, _currentPersonName!);
        }
      }
    });
  }

  Future<void> loadDetails(String uid, String personName) async {
    _currentPersonName = personName;
    emit(state.copyWith(status: MyDebtDetailsStatus.loading));

    // 1. Fetch pending records first
    final pendingResult = await getPendingMyDebtsUseCase(const NoParams());
    final List<OfflineRecord> pendingRecords = pendingResult.fold(
      (_) => [],
      (records) => records,
    );

    // Filter pending records for this person and map to entities
    final filteredPending = pendingRecords
        .where((r) => r.customerName == personName)
        .map(
          (r) {
            double totalAmount = r.amount;
            double paidAmount = 0;
            double remainingAmount = r.amount;
            String details = AppStrings.syncing.tr();

            if (r.type == 'my_debt_add') {
              try {
                final payload = jsonDecode(r.payloadJson);
                totalAmount = (payload['totalAmount'] ?? 0).toDouble();
                paidAmount = (payload['paidAmount'] ?? 0).toDouble();
                remainingAmount = (payload['remainingAmount'] ?? 0).toDouble();
                details = payload['details'] ?? AppStrings.syncing.tr();
              } catch (e) {
                // Ignore parsing errors, keep defaults
              }
            }
            
            return MyDebtItemEntity(
              id: r.id,
              uid: uid,
              operationId: 'pending_${r.id}',
              totalAmount: totalAmount,
              paidAmount: paidAmount,
              remainingAmount: remainingAmount,
              personName: personName,
              details: details,
              operationType: 'debt',
              timestamp: r.date,
              isPaid: remainingAmount <= 0,
            );
          }
        )
        .toList();

    // 2. Fetch remote items
    final itemsResult = await getItemsUseCase(
      GetMyDebtItemsParams(uid: uid, personName: personName),
    );
    final opsResult = await getOperationsUseCase(
      GetMyDebtPersonOperationsParams(uid: uid, personName: personName),
    );

    itemsResult.fold(
      (f) {
        // OFFLINE or Error: Show ONLY pending items
        _emitLoaded(filteredPending, []);
      },
      (remoteItems) {
        // ONLINE: Show ONLY remote items
        opsResult.fold(
          (f) => _emitLoaded(remoteItems, []),
          (ops) => _emitLoaded(remoteItems, ops),
        );
      },
    );
  }

  void _emitLoaded(
    List<MyDebtItemEntity> items,
    List<MyDebtOperationEntity> ops,
  ) {
    double totalOwed = 0;
    double totalPaid = 0;
    DateTime? earliestDate;

    for (var item in items) {
      totalOwed += item.totalAmount;
      totalPaid += item.paidAmount;
      if (item.timestamp != null) {
        if (earliestDate == null || item.timestamp!.isBefore(earliestDate)) {
          earliestDate = item.timestamp;
        }
      }
    }

    emit(
      state.copyWith(
        status: MyDebtDetailsStatus.loaded,
        items: items,
        operations: ops,
        totalOwed: totalOwed,
        totalPaid: totalPaid,
        remainingAmount: totalOwed - totalPaid,
        firstDate: earliestDate,
      ),
    );
  }

  void clearFlags() {
    emit(state.copyWith(clearPayment: true, message: null));
  }

  double lastPaymentAmount = 0.0;
  double lastPaymentRemaining = 0.0;
  String lastPaymentNote = "";
  Future<void> payItem({
    required String uid,
    required String debtId,
    required double amount,
    required String personName,
    String? note,
    DateTime? paymentDate,
  }) async {
    if (state.status == MyDebtDetailsStatus.loading) return;
    emit(state.copyWith(status: MyDebtDetailsStatus.loading));
    final result = await payItemUseCase(
      uid: uid,
      debtId: debtId,
      amount: amount,
      note: note,
      paymentDate: paymentDate,
    );

    result.fold(
      (f) => emit(
        state.copyWith(status: MyDebtDetailsStatus.error, message: f.message),
      ),
      (_) {
        emit(
          state.copyWith(
            lastPaymentAmount: amount,
            lastPaymentRemaining: state.remainingAmount - amount,
            lastPaymentNote: note,
          ),
        );
        lastPaymentAmount = amount;
        lastPaymentRemaining = state.remainingAmount - amount;
        lastPaymentNote = note ?? "";
        emit(state.copyWith(clearPayment: true));
        loadDetails(uid, personName);
      },
    );
  }

  Future<void> addDebt({
    required String uid,
    required String personName,
    required double totalAmount,
    double? paidAmount,
    String? description,
    String? phone,
    DateTime? timestamp,
  }) async {
    if (state.status == MyDebtDetailsStatus.loading) return;
    emit(state.copyWith(status: MyDebtDetailsStatus.loading));

    final now = DateTime.now();
    final debt = MyDebtItemEntity(
      id: '',
      uid: uid,
      operationId: 'manual_my_debt_${now.millisecondsSinceEpoch}',
      totalAmount: totalAmount,
      paidAmount: paidAmount ?? 0,
      remainingAmount: totalAmount - (paidAmount ?? 0),
      personName: personName,
      details: description ?? AppStrings.newDebt.tr(),
      operationType: 'debt',
      timestamp: timestamp ?? now,
      isPaid: (totalAmount - (paidAmount ?? 0)) <= 0,
      phoneNumber: phone,
    );

    final result = await addDebtUseCase(debt);

    result.fold(
      (f) => emit(
        state.copyWith(status: MyDebtDetailsStatus.error, message: f.message),
      ),
      (_) => loadDetails(uid, personName),
    );
  }

  Future<void> payDebt({
    required String uid,
    required String personName,
    required double amount,
    String? note,
    DateTime? paymentDate,
  }) async {
    if (state.status == MyDebtDetailsStatus.loading) return;
    emit(state.copyWith(status: MyDebtDetailsStatus.loading));
    final result = await distributePaymentUseCase(
      uid: uid,
      personName: personName,
      amount: amount,
      note: note,
      paymentDate: paymentDate,
    );

    result.fold(
      (f) => emit(
        state.copyWith(status: MyDebtDetailsStatus.error, message: f.message),
      ),
      (_) {
        emit(
          state.copyWith(
            lastPaymentAmount: amount,
            lastPaymentRemaining: state.remainingAmount - amount,
            lastPaymentNote: note,
          ),
        );
        lastPaymentAmount = amount;
        lastPaymentRemaining = state.remainingAmount - amount;
        lastPaymentNote = note ?? "";
        emit(state.copyWith(clearPayment: true));
        loadDetails(uid, personName);
      },
    );
  }

  Future<void> deleteItem(String uid, String debtId, String personName) async {
    if (state.status == MyDebtDetailsStatus.loading) return;
    emit(state.copyWith(status: MyDebtDetailsStatus.loading));
    final result = await deleteItemUseCase(uid, debtId);
    result.fold(
      (f) => emit(
        state.copyWith(status: MyDebtDetailsStatus.error, message: f.message),
      ),
      (_) => loadDetails(uid, personName),
    );
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    _syncSubscription?.cancel();
    return super.close();
  }
}
