import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../debt/domain/entities/debt_entity.dart';
import '../../../debt/domain/usecases/add_debt_usecase.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/usecases/invoice_history_usecases.dart';
import '../../domain/usecases/invoice_usecases.dart';
import '../../utils/invoice_history_diff.dart';
import 'invoice_state.dart';

class InvoiceCubit extends Cubit<InvoiceState> {
  final CreateInvoiceUseCase createInvoiceUseCase;
  final GetInvoicesUseCase getInvoicesUseCase;
  final GetInvoicesPaginatedUseCase getInvoicesPaginatedUseCase;
  final GetPendingInvoicesUseCase getPendingInvoicesUseCase;
  final GetInvoiceByIdUseCase getInvoiceByIdUseCase;
  final RecordPaymentUseCase recordPaymentUseCase;
  final LinkDebtToInvoiceUseCase linkDebtToInvoiceUseCase;
  final AddDebtUseCase addDebtUseCase;
  final UpdateInvoiceUseCase updateInvoiceUseCase;
  final VoidInvoiceUseCase voidInvoiceUseCase;
  final AddInvoiceHistoryUseCase addInvoiceHistoryUseCase;

  // ── Search debounce ──────────────────────────────────────────────────────
  Timer? _debounce;
  List<InvoiceEntity> _allInvoices = [];

  InvoiceCubit({
    required this.createInvoiceUseCase,
    required this.getInvoicesUseCase,
    required this.getInvoicesPaginatedUseCase,
    required this.getPendingInvoicesUseCase,
    required this.getInvoiceByIdUseCase,
    required this.recordPaymentUseCase,
    required this.linkDebtToInvoiceUseCase,
    required this.addDebtUseCase,
    required this.updateInvoiceUseCase,
    required this.voidInvoiceUseCase,
    required this.addInvoiceHistoryUseCase,
  }) : super(InvoiceInitial());

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  // ── Create ────────────────────────────────────────────────────────────────

  /// Creates a new invoice. Handles offline-first flow internally.
  Future<void> createInvoice(InvoiceEntity invoice) async {
    emit(InvoiceLoading());
    final result = await createInvoiceUseCase(invoice);
    result.fold(
      (failure) => emit(InvoiceFailure(failure.message)),
      (invoiceId) => emit(InvoiceCreateSuccess(invoiceId)),
    );
  }

  // ── List ──────────────────────────────────────────────────────────────────

  /// Loads paginated invoices for the given user from Firestore.
  Future<void> fetchInvoices(String uid, {bool forceRefresh = false}) async {
    emit(InvoiceLoading());
    final result = await getInvoicesPaginatedUseCase(
      GetInvoicesPaginatedParams(
        uid: uid,
        limit: 15,
        forceRefresh: forceRefresh,
      ),
    );
    result.fold((failure) => emit(InvoiceFailure(failure.message)), (
      paginated,
    ) {
      _allInvoices = List.from(paginated.items);
      emit(
        InvoiceListLoaded(
          invoices: _allInvoices,
          lastDocument: paginated.lastDocument,
          hasMore: paginated.hasMore,
          isPaginationLoading: false,
        ),
      );
    });
  }

  /// Loads more paginated invoices.
  Future<void> fetchMoreInvoices(String uid) async {
    final currentState = state;
    if (currentState is! InvoiceListLoaded) return;
    if (currentState.isPaginationLoading || !currentState.hasMore) return;

    emit(currentState.copyWith(isPaginationLoading: true));

    final result = await getInvoicesPaginatedUseCase(
      GetInvoicesPaginatedParams(
        uid: uid,
        limit: 15,
        lastDocument: currentState.lastDocument,
      ),
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(isPaginationLoading: false));
      },
      (paginated) {
        _allInvoices.addAll(paginated.items);
        emit(
          currentState.copyWith(
            invoices: _allInvoices,
            filtered: currentState.searchQuery.isEmpty ? _allInvoices : null,
            lastDocument: paginated.lastDocument,
            hasMore: paginated.hasMore,
            isPaginationLoading: false,
          ),
        );
        // If a search query is active, re-run search on the updated _allInvoices list.
        if (currentState.searchQuery.isNotEmpty) {
          search(currentState.searchQuery);
        }
      },
    );
  }

  // ── Search (debounced) ─────────────────────────────────────────────────────

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (isClosed) return;
      final q = query.trim().toLowerCase();
      final currentState = state;
      if (currentState is! InvoiceListLoaded) return;

      if (q.isEmpty) {
        emit(currentState.copyWith(filtered: _allInvoices, searchQuery: ''));
        return;
      }
      final filtered = _allInvoices.where((inv) {
        final name = inv.customerName?.toLowerCase() ?? '';
        final phone = inv.customerPhone?.toLowerCase() ?? '';
        final ledger = inv.ledgerNumber?.toLowerCase() ?? '';
        final id = inv.id.toLowerCase();
        final itemDescs = inv.items
            .map((i) => i.description.toLowerCase())
            .join(' ');
        return name.contains(q) ||
            phone.contains(q) ||
            ledger.contains(q) ||
            id.contains(q) ||
            itemDescs.contains(q);
      }).toList();
      emit(currentState.copyWith(filtered: filtered, searchQuery: query));
    });
  }

  // ── Detail ─────────────────────────────────────────────────────────────────

  Future<void> loadInvoice(String uid, String invoiceId) async {
    emit(InvoiceLoading());
    final result = await getInvoiceByIdUseCase(uid, invoiceId);
    result.fold(
      (failure) => emit(InvoiceFailure(failure.message)),
      (invoice) => emit(InvoiceDetailLoaded(invoice)),
    );
  }

  // ── Record Payment ─────────────────────────────────────────────────────────
  //
  // CANONICAL FLOW — mirrors the existing Quick Add / Debt module exactly:
  //
  //   Step 1: Persist the payment in the invoice's own payment sub-collection
  //           (invoices/{id}/payments). This is the invoice ledger.
  //
  //   Step 2: Create the linked Debt record using the FULL invoice total.
  //           • totalAmount  = invoice.totalAmount  (the full bill)
  //           • paidAmount   = paidNow              (what the customer paid)
  //           • remainingAmount = totalAmount - paidNow
  //
  //           DebtRemoteDataSource.addDebt() already writes TWO Firestore
  //           documents atomically in one batch:
  //             Transaction A – type: debtAdded   → amountPaid = totalAmount
  //             Transaction B – type: partial/full → amountPaid = paidNow
  //
  //           This is IDENTICAL to the Quick Add workflow. Nothing is skipped.
  //
  //   Step 3: Link the debt ID back to the invoice document (idempotent).
  //
  // IMPORTANT: Do NOT pre-subtract paidNow from totalAmount before calling
  // addDebt. The data source already does the arithmetic — passing a
  // pre-subtracted value skips Transaction A and breaks the ledger history.

  Future<void> recordPayment({
    required String uid,
    required String invoiceId,
    required InvoiceEntity invoice,
    required double paidNow,
    String? note,
  }) async {
    emit(InvoiceLoading());

    // ── Step 1: append to the invoice's own payment ledger ───────────────────
    // (This is the invoice sub-collection; separate from debt/payments.)
    if (paidNow > 0) {
      final payment = InvoicePayment(
        id: 'pmt_${DateTime.now().millisecondsSinceEpoch}',
        amount: paidNow,
        paidAt: DateTime.now(),
        note: note,
      );
      final payResult = await recordPaymentUseCase(uid, invoiceId, payment);
      final failed = payResult.fold((f) => f, (_) => null);
      if (failed != null) {
        emit(InvoiceFailure(failed.message));
        return;
      }
    }

    // ── Step 2: compute remaining to decide whether a debt is needed ──────────
    final newTotalPaid = invoice.totalPaid + paidNow;
    final remaining =
        (invoice.totalAmount - newTotalPaid).clamp(0.0, double.infinity);

    if (remaining > 0) {
      // Deterministic debt ID — idempotent (set() overwrites safely).
      final debtId = 'debt_inv_$invoiceId';

      // Pass the FULL invoice amount and paidNow to addDebt.
      // addDebt's Firestore batch will produce:
      //   • debtAdded  transaction: { amountPaid: invoice.totalAmount }
      //   • payment    transaction: { amountPaid: paidNow, type: partial/full }
      final debt = DebtEntity(
        uid: uid,
        operationId: debtId,
        totalAmount: invoice.totalAmount, // ← FULL amount, NOT pre-subtracted
        paidAmount: paidNow,             // ← what was paid right now
        remainingAmount: remaining,      // ← totalAmount - paidNow
        customerName:
            (invoice.customerName ?? '').replaceAll('/', ' ').trim(),
        productOrSessionDetails: 'فاتورة #$invoiceId',
        operationType: 'invoice_debt',
        timestamp: DateTime.now(),
        isPaid: false,
        phoneNumber: invoice.customerPhone,
        ledgerNumber: invoiceId,
      );

      final debtResult = await addDebtUseCase(AddDebtParams(debt: debt));
      final debtFailure = await debtResult.fold(
        (f) async => f,
        (createdDebtId) async {
          // Link only once (idempotent — calling twice is harmless).
          if (invoice.linkedDebtId == null) {
            await linkDebtToInvoiceUseCase(uid, invoiceId, createdDebtId);
          }
          return null;
        },
      );

      if (debtFailure != null) {
        emit(InvoiceFailure(debtFailure.message));
        return;
      }
    }

    // ── Step 3: notify UI ─────────────────────────────────────────────────────
    emit(InvoicePaymentSuccess());
  }

  /// Legacy helper kept for backward-compat references; delegates to recordPayment.
  /// Prefer calling recordPayment() directly.
  Future<void> convertRemainingToDebt({
    required String uid,
    required InvoiceEntity invoice,
  }) => recordPayment(
        uid: uid,
        invoiceId: invoice.id,
        invoice: invoice,
        paidNow: 0,
      );

  // ── Update Invoice ───────────────────────────────────────────────────────────

  /// Updates mutable fields on an existing invoice (items, notes, customer info).
  /// Payment history and status are untouched.
  ///
  /// [previous] is the *unmodified* snapshot used to compute the diff.
  /// When [previous] is null no history entries are generated.
  Future<void> updateInvoice(
    InvoiceEntity invoice, {
    InvoiceEntity? previous,
  }) async {
    emit(InvoiceLoading());
    final result = await updateInvoiceUseCase(invoice);
    result.fold(
      (failure) => emit(InvoiceFailure(failure.message)),
      (_) async {
        // Generate and persist audit entries in the background.
        // We do NOT await so the UI transitions immediately.
        if (previous != null) {
          final entries = InvoiceHistoryDiff.diff(
            before: previous,
            after: invoice,
            uid: invoice.uid,
          );
          if (entries.isNotEmpty) {
            unawaited(
              addInvoiceHistoryUseCase(
                uid: invoice.uid,
                invoiceId: invoice.id,
                entries: entries,
              ),
            );
          }
        }
        emit(InvoiceUpdateSuccess());
      },
    );
  }

  // ── Void Invoice ────────────────────────────────────────────────────────────

  /// Irreversibly voids an invoice.
  Future<void> voidInvoice(String uid, String invoiceId) async {
    emit(InvoiceLoading());
    final result = await voidInvoiceUseCase(uid, invoiceId);
    result.fold(
      (failure) => emit(InvoiceFailure(failure.message)),
      (_) => emit(InvoiceVoidSuccess()),
    );
  }
}
