import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/invoice_history_usecases.dart';
import 'invoice_history_state.dart';

/// Lightweight cubit dedicated to loading the edit-history timeline.
///
/// Kept separate from [InvoiceCubit] so that fetching/refreshing history
/// never triggers a rebuild of the entire InvoiceDetailScreen widget tree.
class InvoiceHistoryCubit extends Cubit<InvoiceHistoryState> {
  final GetInvoiceHistoryUseCase getHistoryUseCase;
  final AddInvoiceHistoryUseCase addHistoryUseCase;

  InvoiceHistoryCubit({
    required this.getHistoryUseCase,
    required this.addHistoryUseCase,
  }) : super(InvoiceHistoryInitial());

  /// Fetches the full history timeline for [invoiceId].
  Future<void> loadHistory({
    required String uid,
    required String invoiceId,
  }) async {
    emit(InvoiceHistoryLoading());
    final result = await getHistoryUseCase(uid: uid, invoiceId: invoiceId);
    result.fold(
      (failure) => emit(InvoiceHistoryFailure(failure.message)),
      (entries) {
        if (entries.isEmpty) {
          emit(InvoiceHistoryEmpty());
        } else {
          emit(InvoiceHistoryLoaded(entries));
        }
      },
    );
  }
}
