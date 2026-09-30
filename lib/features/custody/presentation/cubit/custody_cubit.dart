import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import '../../domain/entities/custody_entity.dart';
import '../../domain/entities/custody_expense_item.dart';
import '../../domain/repositories/custody_repository.dart';
import 'custody_state.dart';

class CustodyCubit extends Cubit<CustodyState> {
  final CustodyRepository repository;

  CustodyCubit({required this.repository}) : super(CustodyInitial());

  @override
  void emit(CustodyState state) {
    if (isClosed) return;
    super.emit(state);
  }

  void clearData() {
    _custodies = [];
    if (!isClosed) emit(CustodyInitial());
  }

  List<CustodyEntity> _custodies = [];
  List<CustodyEntity> get custodies => List.unmodifiable(_custodies);
  List<CustodyEntity> get activeCustodies => _custodies.where((c) => c.isActive).toList();

  Future<void> loadCustodies() async {
    final ownerUid = AppStrings.userToken;
    if (ownerUid.isEmpty) {
      emit(const CustodyLoaded([]));
      return;
    }

    emit(CustodyLoading());
    final result = await repository.getCustodies(ownerUid);
    if (isClosed) return;
    result.fold(
      (failure) => emit(CustodyFailure(failure.message)),
      (list) {
        _custodies = List<CustodyEntity>.from(list);
        emit(CustodyLoaded(_custodies));
      },
    );
  }

  Future<bool> createCustody({
    required String recipientName,
    String? recipientEmployeeId,
    required String recipientType,
    required double initialAmount,
    String? notes,
  }) async {
    final ownerUid = AppStrings.userToken;
    if (ownerUid.isEmpty) return false;

    emit(CustodyLoading());
    final result = await repository.createCustody(
      ownerUid: ownerUid,
      recipientName: recipientName,
      recipientEmployeeId: recipientEmployeeId,
      recipientType: recipientType,
      initialAmount: initialAmount,
      notes: notes,
    );
    if (isClosed) return false;

    return result.fold(
      (failure) {
        emit(CustodyFailure(failure.message));
        return false;
      },
      (created) {
        _custodies.insert(0, created);
        emit(CustodyActionSuccess(AppStrings.custodyCreatedSuccess.tr()));
        emit(CustodyLoaded(_custodies));
        return true;
      },
    );
  }

  Future<bool> settleCustody({
    required String custodyId,
    required double actualReturnedAmount,
    required double varianceAmount,
    required String settledBy,
    String? settlementNotes,
    String? deficitReason,
  }) async {
    final ownerUid = AppStrings.userToken;
    if (ownerUid.isEmpty) return false;

    emit(CustodyLoading());
    final result = await repository.settleCustody(
      ownerUid: ownerUid,
      custodyId: custodyId,
      actualReturnedAmount: actualReturnedAmount,
      varianceAmount: varianceAmount,
      settledBy: settledBy,
      settlementNotes: settlementNotes,
      deficitReason: deficitReason,
    );
    if (isClosed) return false;

    return result.fold(
      (failure) {
        emit(CustodyFailure(failure.message));
        return false;
      },
      (_) async {
        await loadCustodies();
        emit(CustodyActionSuccess(AppStrings.custodySettledSuccess.tr()));
        return true;
      },
    );
  }

  Future<bool> addCustodyExpense({
    required String custodyId,
    required double amount,
    required String category,
    required String description,
  }) async {
    final ownerUid = AppStrings.userToken;
    if (ownerUid.isEmpty) return false;

    final expenseItem = CustodyExpenseItem(
      id: 'cust_exp_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      category: category,
      description: description,
      date: DateTime.now(),
      employeeName: AppStrings.loggedInEmployeeName.isNotEmpty
          ? AppStrings.loggedInEmployeeName
          : null,
    );

    emit(CustodyLoading());
    final result = await repository.addCustodyExpense(
      ownerUid: ownerUid,
      custodyId: custodyId,
      expense: expenseItem,
    );
    if (isClosed) return false;

    return result.fold(
      (failure) {
        emit(CustodyFailure(failure.message));
        return false;
      },
      (_) {
        final index = _custodies.indexWhere((c) => c.id == custodyId);
        if (index != -1) {
          final old = _custodies[index];
          final newSpent = old.spentAmount + amount;
          final newRemaining = old.initialAmount - newSpent;
          final updatedExpenses = List<CustodyExpenseItem>.from(old.expenses)
            ..add(expenseItem);

          _custodies[index] = old.copyWith(
            spentAmount: newSpent,
            remainingAmount: newRemaining,
            expenses: updatedExpenses,
          );
        }
        emit(CustodyActionSuccess(AppStrings.custodyExpenseAddedSuccess.tr()));
        emit(CustodyLoaded(_custodies));
        return true;
      },
    );
  }

  Future<bool> updateCustodyNotes({
    required String custodyId,
    required String notes,
  }) async {
    final ownerUid = AppStrings.userToken;
    if (ownerUid.isEmpty) return false;

    emit(CustodyLoading());
    final result = await repository.updateCustodyNotes(
      ownerUid: ownerUid,
      custodyId: custodyId,
      notes: notes,
    );
    if (isClosed) return false;

    return result.fold(
      (failure) {
        emit(CustodyFailure(failure.message));
        return false;
      },
      (_) {
        final index = _custodies.indexWhere((c) => c.id == custodyId);
        if (index != -1) {
          final old = _custodies[index];
          _custodies[index] = old.copyWith(notes: notes);
        }
        emit(CustodyActionSuccess(AppStrings.custodyNotesUpdatedSuccess.tr()));
        emit(CustodyLoaded(_custodies));
        return true;
      },
    );
  }

  Future<bool> deleteCustody(String custodyId) async {
    final ownerUid = AppStrings.userToken;
    if (ownerUid.isEmpty) return false;

    emit(CustodyLoading());
    final result = await repository.deleteCustody(ownerUid, custodyId);
    if (isClosed) return false;

    return result.fold(
      (failure) {
        emit(CustodyFailure(failure.message));
        return false;
      },
      (_) {
        _custodies.removeWhere((c) => c.id == custodyId);
        emit(CustodyActionSuccess(AppStrings.custodyDeletedSuccess.tr()));
        emit(CustodyLoaded(_custodies));
        return true;
      },
    );
  }

  Future<CustodyEntity?> getActiveCustodyForCurrentUser() async {
    final result = await repository.getActiveCustodyForCurrentUser();
    return result.fold((_) => null, (c) => c);
  }

  Future<bool> deleteCustodyExpenseItem({
    required String custodyId,
    required CustodyExpenseItem expenseItem,
  }) async {
    final ownerUid = AppStrings.userToken;
    if (ownerUid.isEmpty) return false;

    emit(CustodyLoading());
    final result = await repository.deleteCustodyExpenseItem(
      ownerUid: ownerUid,
      custodyId: custodyId,
      expenseItem: expenseItem,
    );
    if (isClosed) return false;

    return result.fold(
      (failure) {
        emit(CustodyFailure(failure.message));
        return false;
      },
      (_) async {
        await loadCustodies();
        return true;
      },
    );
  }
}
