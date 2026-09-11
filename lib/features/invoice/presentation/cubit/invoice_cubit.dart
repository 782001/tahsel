import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/error/failures.dart';

import '../../../debt/domain/entities/debt_entity.dart';
import '../../../debt/domain/usecases/add_debt_usecase.dart';
import '../../../debt/domain/usecases/get_debt_by_id_usecase.dart';
import '../../../debt/domain/usecases/get_debt_transactions_future_use_case.dart';
import '../../../debt/domain/usecases/pay_item_debt_usecase.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/usecases/invoice_history_usecases.dart';
import '../../domain/usecases/invoice_usecases.dart';
import '../../utils/invoice_history_diff.dart';
import '../cubit/invoice_state.dart';
import '../../data/datasources/offline_invoice_local_data_source.dart';
import '../../../standard_features/no-internet/logic/connectivity_cubit.dart';
import '../../../standard_features/no-internet/logic/connectivity_state.dart';
import '../../data/models/invoice_model.dart';
import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/inventory/domain/entities/stock_movement_entity.dart';
import 'package:tahsel/features/inventory/domain/repositories/inventory_repository.dart';

class InvoiceCubit extends Cubit<InvoiceState> {
  final CreateInvoiceUseCase createInvoiceUseCase;
  final GetInvoicesUseCase getInvoicesUseCase;
  final GetInvoicesPaginatedUseCase getInvoicesPaginatedUseCase;
  final GetPendingInvoicesUseCase getPendingInvoicesUseCase;
  final GetInvoiceByIdUseCase getInvoiceByIdUseCase;
  final RecordPaymentUseCase recordPaymentUseCase;
  final LinkDebtToInvoiceUseCase linkDebtToInvoiceUseCase;
  final AddDebtUseCase addDebtUseCase;
  final GetDebtByIdUseCase getDebtByIdUseCase;
  final PayItemDebtUseCase payItemDebtUseCase;
  final UpdateInvoiceUseCase updateInvoiceUseCase;
  final VoidInvoiceUseCase voidInvoiceUseCase;
  final AddInvoiceHistoryUseCase addInvoiceHistoryUseCase;
  final GetDebtTransactionsFutureUseCase getDebtTransactionsUseCase;
  final OfflineInvoiceLocalDataSource offlineInvoiceLocalDataSource;
  final ConnectivityCubit connectivityCubit;

  // ── Search debounce ──────────────────────────────────────────────────────
  Timer? _debounce;
  List<InvoiceEntity> _allInvoices = [];
  bool _lastHasMore = false;
  List<InvoiceEntity>? _serverAllInvoices;

  InvoiceCubit({
    required this.createInvoiceUseCase,
    required this.getInvoicesUseCase,
    required this.getInvoicesPaginatedUseCase,
    required this.getPendingInvoicesUseCase,
    required this.getInvoiceByIdUseCase,
    required this.recordPaymentUseCase,
    required this.linkDebtToInvoiceUseCase,
    required this.addDebtUseCase,
    required this.getDebtByIdUseCase,
    required this.payItemDebtUseCase,
    required this.updateInvoiceUseCase,
    required this.voidInvoiceUseCase,
    required this.addInvoiceHistoryUseCase,
    required this.getDebtTransactionsUseCase,
    required this.offlineInvoiceLocalDataSource,
    required this.connectivityCubit,
  }) : super(InvoiceInitial());

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  // ── Offline Sync ──────────────────────────────────────────────────────────

  Future<void> syncOfflineInvoices() async {
    final pending = await offlineInvoiceLocalDataSource.getPendingInvoices();
    if (pending.isEmpty) return;

    if (connectivityCubit.state is ConnectivityDisconnected) return;

    for (final p in pending) {
      final invoiceId = p['invoiceId'] as String;
      final map = jsonDecode(p['invoiceJson']) as Map<String, dynamic>;
      final invoice = InvoiceModel.fromMap(map);
      final paymentAmount = (p['paymentAmount'] as num).toDouble();
      final note = p['paymentNote'] as String?;

      // 1. Create invoice online (with isAlreadyDeductedLocally flag)
      final createResult = await createInvoiceUseCase(
        invoice,
        isAlreadyDeductedLocally: true,
      );
      final failed = createResult.fold((f) => f, (_) => null);
      if (failed != null) continue; // Try again next sync

      // 2. Apply payment logic directly (without emitting state)
      // Even if paymentAmount == 0, we need to create the baseline debt if totalAmount > 0 (never for quotations)
      if (!invoice.isQuotation &&
          (paymentAmount > 0 || invoice.totalAmount > 0)) {
        await _processPaymentInternally(
          uid: invoice.uid,
          invoiceId: invoiceId,
          invoice: invoice,
          paidNow: paymentAmount,
          note: note,
          skipInvoicePayment: paymentAmount > 0, // If > 0, it's already in the invoice JSON
        );
      }

      // 3. Clean up local storage
      await offlineInvoiceLocalDataSource.deleteOfflineInvoice(invoiceId);
    }
    
    // Refresh UI if needed
    final uid = AppStrings.userToken;
    if (uid.isNotEmpty) {
      fetchInvoices(uid, forceRefresh: true);
    }
  }

  // ── Create ────────────────────────────────────────────────────────────────

  /// Creates a new invoice. Handles offline-first flow internally.
  Future<void> createInvoice(InvoiceEntity invoice) async {
    emit(InvoiceLoading());

    if (connectivityCubit.state is ConnectivityDisconnected) {
      // Deterministic ID for offline consistency
      final timeKey = invoice.createdAt.millisecondsSinceEpoch ~/ 1000;
      final fingerprint = '${invoice.uid}_${invoice.totalAmount}_${invoice.customerName ?? "anon"}_$timeKey';
      final invoiceId = 'inv_${fingerprint.hashCode.abs()}';

      final invoiceWithId = invoice.copyWith(id: invoiceId);
      await offlineInvoiceLocalDataSource.saveOfflineInvoice(invoiceWithId);

      // Deduct inventory stock locally immediately if VIP subscription is active (never for quotation)
      if (AppStrings.isVip && !invoice.isQuotation && GetIt.I.isRegistered<InventoryRepository>()) {
        try {
          final itemsMap = invoiceWithId.items.map((item) {
            String name = item.description.trim();
            final match = RegExp(r'^(.*?)(?:\s*\(\s*(\d+(?:\.\d+)?)\s*×.*?\))?$')
                .firstMatch(name);
            if (match != null && match.group(1)?.trim().isNotEmpty == true) {
              name = match.group(1)!.trim();
            }
            return {
              'id': item.id,
              'name': name,
              'quantity': item.quantity,
            };
          }).toList();

          await GetIt.I<InventoryRepository>().processInvoiceStockChange(
            invoiceId: invoiceId,
            items: itemsMap,
            type: StockMovementType.invoiceSale,
          );
        } catch (_) {}
      }

      emit(InvoiceCreateSuccess(invoiceId));
      return;
    }

    final result = await createInvoiceUseCase(invoice);
    final failure = result.fold((f) => f, (_) => null);
    final invoiceId = result.fold((_) => null, (id) => id);

    if (failure != null) {
      emit(InvoiceFailure(failure.message));
    } else if (invoiceId != null) {
      // Automatically create baseline debt if amount > 0 (only for actual invoices, never for quotations)
      if (!invoice.isQuotation && invoice.totalAmount > 0) {
         await _processPaymentInternally(
           uid: invoice.uid,
           invoiceId: invoiceId,
           invoice: invoice.copyWith(id: invoiceId),
           paidNow: 0, // Just create the debt baseline
         );
      }
       _serverAllInvoices = null;
       emit(InvoiceCreateSuccess(invoiceId));
    }
  }

  // ── List ──────────────────────────────────────────────────────────────────

  /// Loads paginated invoices for the given user from Firestore or Hive if offline.
  Future<void> fetchInvoices(String uid, {bool forceRefresh = false}) async {
    emit(InvoiceLoading());
    
    // 1. Load offline pending invoices first
    final pendingMap = await offlineInvoiceLocalDataSource.getPendingInvoices();
    final pendingIds = pendingMap.map((p) => p['invoiceId'] as String).toSet();
    final pendingInvoices = pendingMap.map(
      (p) => InvoiceModel.fromMap(jsonDecode(p['invoiceJson']) as Map<String, dynamic>)
    ).toList();

    // 2. If disconnected, ONLY show Hive invoices
    if (connectivityCubit.state is ConnectivityDisconnected) {
      _allInvoices = pendingInvoices;
      emit(
        InvoiceListLoaded(
          invoices: _allInvoices,
          lastDocument: null,
          hasMore: false, // No pagination offline
          isPaginationLoading: false,
          pendingSyncIds: pendingIds,
        ),
      );
      return;
    }

    final result = await getInvoicesPaginatedUseCase(
      GetInvoicesPaginatedParams(
        uid: uid,
        limit: 15,
        forceRefresh: forceRefresh,
      ),
    );
    result.fold((failure) => emit(InvoiceFailure(failure.message)), (
      paginated,
    ) async {
      // Remove duplicates if any
      final filteredRemote = paginated.items.where((i) => !pendingIds.contains(i.id)).toList();

      _allInvoices = [...pendingInvoices, ...filteredRemote];
      _lastHasMore = paginated.hasMore;
      _serverAllInvoices = null;
      
      emit(
        InvoiceListLoaded(
          invoices: _allInvoices,
          lastDocument: paginated.lastDocument,
          hasMore: paginated.hasMore,
          isPaginationLoading: false,
          pendingSyncIds: pendingIds,
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
        final pendingIds = currentState.pendingSyncIds;
        final filteredRemote = paginated.items.where((i) => !pendingIds.contains(i.id)).toList();
        
        _allInvoices = List.from(_allInvoices)..addAll(filteredRemote);
        _lastHasMore = paginated.hasMore;
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

  // ── Search (Server-backed & debounced) ──────────────────────────────────────

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (isClosed) return;
      final q = query.trim().toLowerCase();
      final currentState = state;
      if (currentState is! InvoiceListLoaded) return;

      if (q.isEmpty) {
        emit(
          currentState.copyWith(
            filtered: _allInvoices,
            searchQuery: '',
            hasMore: _lastHasMore,
            isPaginationLoading: false,
          ),
        );
        return;
      }

      // Fetch all user invoices directly from server for exhaustive search across entire collection
      List<InvoiceEntity> sourceInvoices = _serverAllInvoices ?? [];
      if (_serverAllInvoices == null) {
        final uid = AppStrings.userToken;
        if (uid.isNotEmpty) {
          final result = await getInvoicesUseCase(uid);
          result.fold(
            (_) {},
            (invoices) {
              _serverAllInvoices = invoices;
              sourceInvoices = invoices;
            },
          );
        }
      }

      if (sourceInvoices.isEmpty) {
        sourceInvoices = _allInvoices;
      }

      final filtered = sourceInvoices.where((inv) {
        final name = inv.customerName?.toLowerCase() ?? '';
        final ledger = inv.ledgerNumber?.toLowerCase() ?? '';
        final id = inv.id.toLowerCase();
        final phone = inv.customerPhone?.toLowerCase() ?? '';
        final ref = inv.referenceNumber?.toLowerCase() ?? '';
        final hasItem = inv.items.any(
          (item) => item.description.toLowerCase().contains(q),
        );
            
        return name.contains(q) ||
            ledger.contains(q) ||
            id.contains(q) ||
            phone.contains(q) ||
            ref.contains(q) ||
            hasItem;
      }).toList();

      if (isClosed) return;
      emit(
        currentState.copyWith(
          filtered: filtered,
          searchQuery: query,
          hasMore: false, // During search, full server results are loaded; no trailing pagination skeleton!
          isPaginationLoading: false,
        ),
      );
    });
  }

  // ── Detail ─────────────────────────────────────────────────────────────────

  Future<void> loadInvoice(String uid, String invoiceId) async {
    emit(InvoiceLoading());

    // Check offline storage first
    final pendingInvoices = await offlineInvoiceLocalDataSource.getPendingInvoices();
    final localMatch = pendingInvoices.firstWhere(
        (i) => i['invoiceId'] == invoiceId, orElse: () => <String, dynamic>{});
        
    if (localMatch.isNotEmpty) {
        final invJson = localMatch['invoiceJson'] as String;
        final map = jsonDecode(invJson) as Map<String, dynamic>;
        final inv = InvoiceModel.fromMap(map);
        emit(InvoiceDetailLoaded(inv));
        return;
    }

    final result = await getInvoiceByIdUseCase(uid, invoiceId);
    result.fold(
      (failure) => emit(InvoiceFailure(failure.message)),
      (invoice) async {
        // If the invoice is linked to a debt, fetch the debt's payment
        // transactions and use them as the authoritative payment history.
        if (invoice.linkedDebtId != null) {
          final txResult = await getDebtTransactionsUseCase(
            GetDebtTransactionsParams(
              uid: uid,
              debtId: invoice.linkedDebtId!,
              forceRefresh: true,
            ),
          );
          final debtTx = txResult.fold((_) => null, (list) => list);
          emit(InvoiceDetailLoaded(invoice, debtTransactions: debtTx));
        } else {
          emit(InvoiceDetailLoaded(invoice));
        }
      },
    );
  }

  // ── Record Payment ─────────────────────────────────────────────────────────
  //
  // CANONICAL FLOW — two branches based on whether a linked debt already exists:
  //
  //  FIRST PAYMENT (no linked debt yet):
  //   Step 1: Persist the payment in the invoice's own payment sub-collection.
  //   Step 2: Call addDebt with the FULL invoice total + paidNow.
  //           DebtRemoteDataSource.addDebt() atomically writes:
  //             Transaction A – type: debtAdded   → amountPaid = totalAmount
  //             Transaction B – type: partial/full → amountPaid = paidNow
  //   Step 3: Link the debt ID back to the invoice document.
  //
  //  SUBSEQUENT PAYMENTS (linked debt already exists):
  //   Step 1: Persist the payment in the invoice's own payment sub-collection.
  //   Step 2: Call payDebt on the EXISTING debt to accumulate the payment.
  //           This appends a new payment transaction without overwriting the
  //           debt document, preserving the full transaction history.
  //
  // IMPORTANT: Never call addDebt when a linked debt already exists — it does
  // a batch.set() with a fixed ID which would overwrite the existing document
  // and reset the accumulated paidAmount to just the latest paidNow value.

  Future<void> recordPayment({
    required String uid,
    required String invoiceId,
    required InvoiceEntity invoice,
    required double paidNow,
    String? note,
  }) async {
    // Check if it's pending offline
    final pendingInvoices = await offlineInvoiceLocalDataSource.getPendingInvoices();
    final isPendingLocally = pendingInvoices.any((i) => i['invoiceId'] == invoiceId);
    
    if (isPendingLocally) {
       await offlineInvoiceLocalDataSource.updateOfflinePayment(invoiceId, paidNow, note);
       emit(InvoicePaymentSuccess());
       return;
    }

    emit(InvoiceLoading());
    final failure = await _processPaymentInternally(
       uid: uid,
       invoiceId: invoiceId,
       invoice: invoice,
       paidNow: paidNow,
       note: note,
    );
    
    if (failure != null) {
      emit(InvoiceFailure(failure.message));
    } else {
      _serverAllInvoices = null;
      emit(InvoicePaymentSuccess());
    }
  }

  Future<Failure?> _processPaymentInternally({
    required String uid,
    required String invoiceId,
    required InvoiceEntity invoice,
    required double paidNow,
    String? note,
    bool skipInvoicePayment = false,
  }) async {
    // Quotation invoices must never have payments recorded or linked debts created
    if (invoice.isQuotation) return null;

    // ── Compute remaining to decide debt requirements ────────────────────────
    final newTotalPaid =
        skipInvoicePayment ? invoice.totalPaid : invoice.totalPaid + paidNow;
    final remaining =
        (invoice.totalAmount - newTotalPaid).clamp(0.0, double.infinity);

    if (remaining > 0 || paidNow > 0) {
      final debtId = 'debt_inv_$invoiceId';

      // Check if the linked debt already exists in Firestore.
      // Force a fresh server read to avoid stale cache after the first creation.
      final existingDebtResult = await getDebtByIdUseCase(
        uid,
        debtId,
        forceRefresh: true,
      );
      final existingDebt = existingDebtResult.fold((_) => null, (d) => d);

      if (existingDebt == null) {
        // ── FIRST PAYMENT / INITIAL: No linked debt exists yet ────────────────
        if (paidNow > 0 && !skipInvoicePayment) {
          final payment = InvoicePayment(
            id: 'pmt_${DateTime.now().millisecondsSinceEpoch}',
            amount: paidNow,
            paidAt: DateTime.now(),
            note: note,
          );
          final payResult = await recordPaymentUseCase(uid, invoiceId, payment);
          final failed = payResult.fold((f) => f, (_) => null);
          if (failed != null) {
            return failed;
          }
        }

        if (remaining > 0) {
          final debt = DebtEntity(
            uid: uid,
            operationId: debtId,
            totalAmount: invoice.totalAmount, // ← FULL amount, NOT pre-subtracted
            paidAmount: paidNow, // ← what was paid right now
            remainingAmount: remaining, // ← totalAmount - paidNow
            customerName:
                (invoice.customerName ?? '').replaceAll('/', ' ').trim(),
            productOrSessionDetails: 'فاتورة #$invoiceId',
            operationType: 'invoice_debt',
            timestamp: DateTime.now(),
            isPaid: false,
            phoneNumber: invoice.customerPhone,
            ledgerNumber: invoiceId,
            dueDate: invoice.dueDate,
          );

          final debtResult = await addDebtUseCase(AddDebtParams(debt: debt));
          final debtFailure = await debtResult.fold((f) async => f, (
            createdDebtId,
          ) async {
            if (invoice.linkedDebtId == null) {
              await linkDebtToInvoiceUseCase(uid, invoiceId, createdDebtId);
            }
            return null;
          });

          if (debtFailure != null) {
            return debtFailure;
          }
        }
      } else {
        // ── SUBSEQUENT PAYMENT: append to the existing debt record ────────────
        // Only record if there is an actual cash amount being paid.
        // NOTE: payItemDebtUseCase -> payDebt atomically syncs the payment to the
        // linked invoice's payments array via _updateLinkedInvoice. We MUST NOT
        // also call recordPaymentUseCase here, as that would duplicate the payment.
        if (paidNow > 0) {
          final payResult = await payItemDebtUseCase(
            PayItemDebtParams(
              debt: existingDebt,
              amountToPay: paidNow,
              note: note,
            ),
          );
          final payFailure = payResult.fold((f) => f, (_) => null);
          if (payFailure != null) {
            return payFailure;
          }
        }
      }
    }
    return null;
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
  ///
  /// Business rules enforced by [UpdateInvoiceItemsParams]:
  ///  1. Payment history is NEVER deleted or modified.
  ///  2. Remaining balance = New Total − Σ All Existing Payments.
  ///  3. Linked Debt baseline is atomically updated to the new total.
  ///
  /// [previous] is the *unmodified* snapshot used to compute the audit diff.
  /// When [previous] is null no history entries are generated.
  Future<void> updateInvoice(
    InvoiceEntity invoice, {
    InvoiceEntity? previous,
  }) async {
    emit(InvoiceLoading());

    // Build the structured params so the use-case contract is explicit.
    final params = UpdateInvoiceItemsParams(
      updated: invoice,
      previous: previous,
    );

    final result = await updateInvoiceUseCase(
      params.updated,
      previous: params.previous,
    );
    result.fold(
      (failure) => emit(InvoiceFailure(failure.message)),
      (_) async {
        // Generate and persist audit entries in the background.
        // We do NOT await so the UI transitions immediately.
        if (params.previous != null) {
          final entries = InvoiceHistoryDiff.diff(
            before: params.previous!,
            after: params.updated,
            uid: params.updated.uid,
          );
          if (entries.isNotEmpty) {
            unawaited(
              addInvoiceHistoryUseCase(
                uid: params.updated.uid,
                invoiceId: params.updated.id,
                entries: entries,
              ),
            );
          }
        }
        _serverAllInvoices = null;
        emit(InvoiceUpdateSuccess());
      },
    );
  }


  // ── Void Invoice ────────────────────────────────────────────────────────────

  /// Irreversibly voids an invoice.
  Future<void> voidInvoice(
    String uid,
    String invoiceId, {
    InvoiceEntity? invoice,
  }) async {
    emit(InvoiceLoading());
    final result = await voidInvoiceUseCase(uid, invoiceId, invoice: invoice);
    result.fold(
      (failure) => emit(InvoiceFailure(failure.message)),
      (_) {
        _serverAllInvoices = null;
        emit(InvoiceVoidSuccess());
      },
    );
  }
}
