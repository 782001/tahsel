import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/offline_sync/data/models/offline_record.dart';
import 'package:tahsel/features/offline_sync/domain/repositories/offline_sync_repository.dart';
import 'package:tahsel/features/operation/data/datasources/ps_session_remote_data_source.dart';
import 'package:tahsel/features/operation/data/repositories/ps_session_repository_impl.dart';
import 'package:tahsel/features/operation/data/models/ps_session_model.dart';
import 'package:tahsel/features/operation/domain/entities/ps_session_entity.dart';

class FakePsSessionRemoteDataSource implements PsSessionRemoteDataSource {
  final List<PsSessionModel> activeSessions = [];
  bool startSessionCalled = false;
  bool endSessionCalled = false;

  @override
  Future<String> startSession(PsSessionModel session) async {
    startSessionCalled = true;
    activeSessions.add(session);
    return session.id ?? 'remote_id';
  }

  @override
  Future<void> endSession({
    required String uid,
    required String sessionId,
    required DateTime endTime,
    required double totalAmount,
    required double paidAmount,
    int? turnCount,
  }) async {
    endSessionCalled = true;
    activeSessions.removeWhere((s) => s.id == sessionId);
  }

  @override
  Future<List<PsSessionModel>> getActiveSessions(String uid) async {
    return activeSessions;
  }

  @override
  Future<PsSessionModel?> getSessionById(String uid, String sessionId) async {
    final matches = activeSessions.where((s) => s.id == sessionId);
    return matches.isNotEmpty ? matches.first : null;
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
  late Directory tempDir;
  late FakePsSessionRemoteDataSource remoteDataSource;
  late FakeOfflineSyncRepository offlineSyncRepository;
  late FakeInternetConnectionChecker connectionChecker;
  late PsSessionRepositoryImpl repository;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(OfflineRecordAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);

    remoteDataSource = FakePsSessionRemoteDataSource();
    offlineSyncRepository = FakeOfflineSyncRepository();
    connectionChecker = FakeInternetConnectionChecker();

    repository = PsSessionRepositoryImpl(
      remoteDataSource: remoteDataSource,
      offlineSyncRepository: offlineSyncRepository,
      connectionChecker: connectionChecker,
    );
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  final testSession = PsSessionEntity(
    uid: 'user123',
    customerName: 'Ahmad',
    phoneNumber: '0123456789',
    deviceId: 'deviceA',
    roomId: 'room1',
    operatorName: 'Operator',
    subType: 'time',
    rate: 10.0,
    startTime: DateTime(2026, 6, 20, 10, 0),
    status: PsSessionStatus.active,
    createdAt: DateTime(2026, 6, 20, 10, 0),
  );

  group('PsSessionRepositoryImpl Offline Tests', () {
    test('startSession when online should save locally, queue record, and call syncSingleRecord', () async {
      connectionChecker.isConnected = true;

      final result = await repository.startSession(testSession);

      expect(result.isRight(), isTrue);
      final sessionId = result.getOrElse(() => '');
      expect(sessionId, startsWith('sess_'));

      // Check saved locally
      final localBox = await Hive.openBox<String>('ps_active_sessions_box');
      expect(localBox.containsKey(sessionId), isTrue);

      // Check queued and sync called
      expect(offlineSyncRepository.savedRecords.length, 1);
      expect(offlineSyncRepository.savedRecords.first.id, sessionId);
      expect(offlineSyncRepository.savedRecords.first.isSynced, isTrue);
    });

    test('startSession when offline should save locally, queue record, but NOT call syncSingleRecord', () async {
      connectionChecker.isConnected = false;

      final result = await repository.startSession(testSession);

      expect(result.isRight(), isTrue);
      final sessionId = result.getOrElse(() => '');
      expect(sessionId, startsWith('sess_'));

      // Check saved locally
      final localBox = await Hive.openBox<String>('ps_active_sessions_box');
      expect(localBox.containsKey(sessionId), isTrue);

      // Check queued but NOT sync (isSynced remains false)
      expect(offlineSyncRepository.savedRecords.length, 1);
      expect(offlineSyncRepository.savedRecords.first.id, sessionId);
      expect(offlineSyncRepository.savedRecords.first.isSynced, isFalse);
    });

    test('endSession should delete session from local cache and queue ending record', () async {
      connectionChecker.isConnected = false;

      // First start it
      final startResult = await repository.startSession(testSession);
      final sessionId = startResult.getOrElse(() => '');

      // Check it is in cache
      final localBox = await Hive.openBox<String>('ps_active_sessions_box');
      expect(localBox.containsKey(sessionId), isTrue);

      // Now end it
      final endResult = await repository.endSession(
        uid: 'user123',
        sessionId: sessionId,
        endTime: DateTime(2026, 6, 20, 12, 0),
        totalAmount: 20.0,
        paidAmount: 20.0,
      );

      expect(endResult.isRight(), isTrue);

      // Verify removed from cache
      expect(localBox.containsKey(sessionId), isFalse);

      // Verify ending record is queued
      final endingRecords = offlineSyncRepository.savedRecords
          .where((r) => r.type == 'ps_session_end')
          .toList();
      expect(endingRecords.length, 1);
      expect(endingRecords.first.id, sessionId);
    });

    test('getActiveSessions when offline should return locally started sessions that are not pending end', () async {
      connectionChecker.isConnected = false;

      // 1. Start a session
      final startResult = await repository.startSession(testSession);
      final sessionId = startResult.getOrElse(() => '');

      // 2. Fetch active sessions offline
      final activeResult = await repository.getActiveSessions('user123');
      expect(activeResult.isRight(), isTrue);
      final list = activeResult.getOrElse(() => []);
      expect(list.length, 1);
      expect(list.first.id, sessionId);

      // 3. End the session (offline)
      await repository.endSession(
        uid: 'user123',
        sessionId: sessionId,
        endTime: DateTime(2026, 6, 20, 12, 0),
        totalAmount: 20.0,
        paidAmount: 20.0,
      );

      // 4. Fetch active sessions again offline - it should filter out the ended one
      final activeResult2 = await repository.getActiveSessions('user123');
      expect(activeResult2.isRight(), isTrue);
      final list2 = activeResult2.getOrElse(() => []);
      expect(list2.isEmpty, isTrue);
    });
  });
}
