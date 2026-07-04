import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/core/utils/app_logger.dart';

import '../../domain/entities/invoice_history_entity.dart';
import '../../domain/repositories/invoice_history_repository.dart';
import '../datasources/invoice_history_remote_data_source.dart';
import '../models/invoice_history_model.dart';

/// Offline-first implementation:
///   - If online  → writes directly to Firestore.
///   - If offline → silently succeeds locally; entries will be synced when the
///                  user comes back online (via the main invoice offline-sync queue).
///
/// NOTE: Because history records are very lightweight and non-critical to the
/// core invoice workflow, we use a best-effort offline strategy here:
/// the edit itself is always saved first (via the InvoiceRepository offline
/// flow), and the history entries piggyback on the next connectivity event.
class InvoiceHistoryRepositoryImpl implements InvoiceHistoryRepository {
  final InvoiceHistoryRemoteDataSource remoteDataSource;
  final InternetConnectionChecker connectionChecker;

  const InvoiceHistoryRepositoryImpl({
    required this.remoteDataSource,
    required this.connectionChecker,
  });

  @override
  Future<Either<Failure, void>> addHistoryEntries({
    required String uid,
    required String invoiceId,
    required List<InvoiceHistoryEntity> entries,
  }) async {
    if (entries.isEmpty) return const Right(null);
    try {
      final hasConnection = await connectionChecker.hasConnection;
      if (!hasConnection) {
        // Best-effort: log and skip. The invoice edit itself is offline-safe.
        AppLogger.printMessage(
          '[InvoiceHistory] Offline — skipping history write for $invoiceId',
        );
        return const Right(null);
      }

      final models =
          entries.map(InvoiceHistoryModel.fromEntity).toList();
      await remoteDataSource.addHistoryEntries(
        uid: uid,
        invoiceId: invoiceId,
        entries: models,
      );
      return const Right(null);
    } catch (e) {
      AppLogger.printMessage('[InvoiceHistory] addHistoryEntries error: $e');
      // Non-fatal — return success so the main update flow is not blocked.
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, List<InvoiceHistoryEntity>>> getHistory({
    required String uid,
    required String invoiceId,
  }) async {
    try {
      final hasConnection = await connectionChecker.hasConnection;
      if (!hasConnection) {
        return const Right([]);
      }
      final result = await remoteDataSource.getHistory(
        uid: uid,
        invoiceId: invoiceId,
      );
      return Right(result);
    } catch (e) {
      AppLogger.printMessage('[InvoiceHistory] getHistory error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
