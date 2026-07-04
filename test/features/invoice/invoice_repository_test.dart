import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/core/usecases/pagination_params.dart';
import 'package:tahsel/features/invoice/data/models/invoice_model.dart';
import 'package:tahsel/features/invoice/data/repositories/invoice_repository_impl.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_entity.dart';
import 'package:tahsel/features/offline_sync/data/models/offline_record.dart';
import 'package:tahsel/features/offline_sync/domain/repositories/offline_sync_repository.dart';
import 'package:tahsel/features/invoice/data/datasources/invoice_remote_data_source.dart';

class FakeInvoiceRemoteDataSource implements InvoiceRemoteDataSource {
  final List<InvoiceEntity> invoices = [];

  @override
  Future<void> createInvoice(InvoiceModel invoice) async {
    invoices.add(invoice);
  }

  @override
  Future<List<InvoiceEntity>> getInvoices(String uid) async {
    return invoices.where((inv) => inv.uid == uid).toList();
  }

  @override
  Future<PaginatedResult<InvoiceEntity>> getInvoicesPaginated(
    String uid, {
    required int limit,
    DocumentSnapshot? lastDocument,
    bool forceRefresh = false,
  }) async {
    final userInvoices = invoices.where((inv) => inv.uid == uid).toList();
    // Sort by date descending
    userInvoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    int startIndex = 0;
    if (lastDocument != null) {
      // Find the index of the document
      final lastId = lastDocument.id;
      final idx = userInvoices.indexWhere((inv) => inv.id == lastId);
      if (idx != -1) {
        startIndex = idx + 1;
      }
    }

    final sublist = userInvoices.skip(startIndex).toList();
    final hasMore = sublist.length > limit;
    final items = hasMore ? sublist.sublist(0, limit) : sublist;

    return PaginatedResult(
      items: items,
      lastDocument: null, // Since we don't mock real DocumentSnapshots, return null or a mock
      hasMore: hasMore,
    );
  }

  @override
  Future<InvoiceEntity?> getInvoiceById(String uid, String invoiceId) async {
    final list = invoices.where((inv) => inv.uid == uid && inv.id == invoiceId).toList();
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Future<void> recordPayment(
      String uid, String invoiceId, InvoicePaymentModel payment) async {
    final idx = invoices.indexWhere((inv) => inv.uid == uid && inv.id == invoiceId);
    if (idx != -1) {
      final existing = invoices[idx];
      final updatedPayments = [...existing.payments, payment];
      invoices[idx] = existing.copyWith(payments: updatedPayments);
    }
  }

  @override
  Future<void> linkDebtToInvoice(
      String uid, String invoiceId, String debtId) async {
    final idx = invoices.indexWhere((inv) => inv.uid == uid && inv.id == invoiceId);
    if (idx != -1) {
      final existing = invoices[idx];
      invoices[idx] = existing.copyWith(linkedDebtId: debtId);
    }
  }

  @override
  Future<void> updateInvoice(InvoiceModel invoice) async {
    final idx = invoices.indexWhere((inv) => inv.id == invoice.id);
    if (idx != -1) {
      invoices[idx] = invoice;
    }
  }

  @override
  Future<void> voidInvoice(String uid, String invoiceId) async {
    final idx = invoices.indexWhere((inv) => inv.uid == uid && inv.id == invoiceId);
    if (idx != -1) {
      final existing = invoices[idx];
      invoices[idx] = existing.copyWith(status: InvoiceStatus.voided);
    }
  }

  @override
  Future<void> syncInvoiceFromDebt({
    required String uid,
    required String debtId,
  }) async {
    // No-op in tests — synchronization is tested at the integration level
  }
}

class FakeOfflineSyncRepository implements OfflineSyncRepository {
  final List<OfflineRecord> savedRecords = [];

  @override
  Future<Either<Failure, void>> saveOfflineRecord(OfflineRecord record) async {
    savedRecords.add(record);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<OfflineRecord>>> getPendingRecords() async {
    return Right(savedRecords.where((r) => !r.isSynced).toList());
  }

  @override
  Future<Either<Failure, void>> syncAllPendingRecords() async {
    for (final r in savedRecords) {
      r.isSynced = true;
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> syncSingleRecord(OfflineRecord record) async {
    final index = savedRecords.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      savedRecords[index].isSynced = true;
    }
    return const Right(null);
  }
}

class FakeInternetConnectionChecker implements InternetConnectionChecker {
  bool isConnected = true;

  @override
  Future<bool> get hasConnection async => isConnected;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #hasConnection) {
      return hasConnection;
    }
    return null;
  }
}

void main() {
  late FakeInvoiceRemoteDataSource remoteDataSource;
  late FakeOfflineSyncRepository offlineSyncRepository;
  late FakeInternetConnectionChecker connectionChecker;
  late InvoiceRepositoryImpl repository;

  setUp(() {
    remoteDataSource = FakeInvoiceRemoteDataSource();
    offlineSyncRepository = FakeOfflineSyncRepository();
    connectionChecker = FakeInternetConnectionChecker();

    repository = InvoiceRepositoryImpl(
      remoteDataSource: remoteDataSource,
      offlineSyncRepository: offlineSyncRepository,
      connectionChecker: connectionChecker,
    );
  });

  final testInvoice = InvoiceEntity(
    id: '',
    uid: 'user_123',
    customerName: 'Test Customer',
    customerPhone: '123456789',
    ledgerNumber: 'L-101',
    items: const [
      InvoiceItem(
        id: 'item_1',
        description: 'Consulting Service',
        unitPrice: 150.0,
        quantity: 2.0,
      ),
    ],
    payments: const [],
    status: InvoiceStatus.pending,
    createdAt: DateTime(2026, 7, 4, 10, 0, 0),
  );

  group('InvoiceRepositoryImpl Tests', () {
    test(
      'createInvoice should generate a deterministic ID, save locally first, and sync immediately if online',
      () async {
        connectionChecker.isConnected = true;

        final result = await repository.createInvoice(testInvoice);

        expect(result.isRight(), isTrue);
        final invoiceId = result.getOrElse(() => '');
        expect(invoiceId, startsWith('inv_'));

        // Check local record exists and is synced
        expect(offlineSyncRepository.savedRecords.length, 1);
        final record = offlineSyncRepository.savedRecords.first;
        expect(record.id, invoiceId);
        expect(record.isSynced, isTrue);

        // Verify payload JSON data
        final payload = jsonDecode(record.payloadJson) as Map<String, dynamic>;
        expect(payload['id'], invoiceId);
        expect(payload['customerName'], 'Test Customer');
        expect(payload['items'].length, 1);
        expect(payload['items'][0]['description'], 'Consulting Service');
      },
    );

    test(
      'createInvoice should generate a deterministic ID, save locally first, but NOT sync if offline',
      () async {
        connectionChecker.isConnected = false;

        final result = await repository.createInvoice(testInvoice);

        expect(result.isRight(), isTrue);
        final invoiceId = result.getOrElse(() => '');
        expect(invoiceId, startsWith('inv_'));

        // Check local record exists and is NOT synced
        expect(offlineSyncRepository.savedRecords.length, 1);
        final record = offlineSyncRepository.savedRecords.first;
        expect(record.id, invoiceId);
        expect(record.isSynced, isFalse);
      },
    );

    test(
      'getPendingInvoices should filter and retrieve only unsynced invoice records as entities',
      () async {
        final syncedRecord = OfflineRecord(
          id: 'inv_synced',
          amount: 100,
          date: DateTime.now(),
          customerName: 'Customer A',
          type: 'invoice',
          isSynced: true,
          payloadJson: jsonEncode(
            InvoiceModel.fromEntity(
              testInvoice.copyWith(id: 'inv_synced', customerName: 'Customer A'),
            ).toMap(),
          ),
          collectionName: 'users/user_123/invoices',
        );

        final pendingRecord = OfflineRecord(
          id: 'inv_pending',
          amount: 200,
          date: DateTime.now(),
          customerName: 'Customer B',
          type: 'invoice',
          isSynced: false,
          payloadJson: jsonEncode(
            InvoiceModel.fromEntity(
              testInvoice.copyWith(id: 'inv_pending', customerName: 'Customer B'),
            ).toMap(),
          ),
          collectionName: 'users/user_123/invoices',
        );

        final otherRecord = OfflineRecord(
          id: 'expense_1',
          amount: 50,
          date: DateTime.now(),
          customerName: '',
          type: 'expense',
          isSynced: false,
          payloadJson: '{}',
          collectionName: 'users/user_123/expenses',
        );

        offlineSyncRepository.savedRecords.addAll([syncedRecord, pendingRecord, otherRecord]);

        final result = await repository.getPendingInvoices();

        expect(result.isRight(), isTrue);
        final pendingInvoices = result.getOrElse(() => []);
        expect(pendingInvoices.length, 1);
        expect(pendingInvoices.first.id, 'inv_pending');
        expect(pendingInvoices.first.customerName, 'Customer B');
      },
    );

    test(
      'getInvoicesPaginated should return a paginated list of invoices when online',
      () async {
        // Arrange
        final invoice1 = InvoiceModel.fromEntity(testInvoice.copyWith(id: 'inv_1', createdAt: DateTime.now().subtract(const Duration(minutes: 5))));
        final invoice2 = InvoiceModel.fromEntity(testInvoice.copyWith(id: 'inv_2', createdAt: DateTime.now()));
        remoteDataSource.invoices.addAll([invoice1, invoice2]);

        // Act
        final result = await repository.getInvoicesPaginated('user_123', limit: 1);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail(failure.message),
          (paginated) {
            expect(paginated.items.length, 1);
            // The newest invoice should be returned first
            expect(paginated.items.first.id, 'inv_2');
            expect(paginated.hasMore, isTrue);
          },
        );
      },
    );
  });
}
