import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../offline_sync/data/models/offline_record.dart';
import '../../../offline_sync/domain/repositories/offline_sync_repository.dart';
import '../../domain/entities/ps_session_entity.dart';
import '../../domain/repositories/ps_session_repository.dart';
import '../datasources/ps_session_remote_data_source.dart';
import '../models/ps_session_model.dart';

class PsSessionRepositoryImpl implements PsSessionRepository {
  final PsSessionRemoteDataSource remoteDataSource;
  final OfflineSyncRepository offlineSyncRepository;
  final InternetConnectionChecker connectionChecker;

  PsSessionRepositoryImpl({
    required this.remoteDataSource,
    required this.offlineSyncRepository,
    required this.connectionChecker,
  });

  Future<Box<String>> get _activeSessionsBox async =>
      await Hive.openBox<String>('ps_active_sessions_box');

  Map<String, dynamic> _sessionToSafeMap(PsSessionEntity session) {
    return {
      'uid': session.uid,
      'customerName': session.customerName,
      'phoneNumber': session.phoneNumber,
      'deviceId': session.deviceId,
      'roomId': session.roomId,
      'operatorName': session.operatorName,
      'subType': session.subType,
      'rate': session.rate,
      'startTime': session.startTime.toIso8601String(),
      if (session.endTime != null)
        'endTime': session.endTime!.toIso8601String(),
      'status': session.status == PsSessionStatus.completed
          ? 'completed'
          : 'active',
      'totalAmount': session.totalAmount,
      'paidAmount': session.paidAmount,
      'remainingDebt': session.remainingDebt,
      'turnCount': session.turnCount,
      if (session.ledgerNumber != null) 'ledgerNumber': session.ledgerNumber,
      'createdAt': session.createdAt.toIso8601String(),
    };
  }

  List<PsSessionEntity> _getLocalSessions(Box<String> box) {
    final list = <PsSessionEntity>[];
    for (final key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
          jsonMap['startTime'] = Timestamp.fromDate(
            DateTime.parse(jsonMap['startTime']),
          );
          if (jsonMap['endTime'] != null) {
            jsonMap['endTime'] = Timestamp.fromDate(
              DateTime.parse(jsonMap['endTime']),
            );
          }
          if (jsonMap['createdAt'] != null) {
            jsonMap['createdAt'] = Timestamp.fromDate(
              DateTime.parse(jsonMap['createdAt']),
            );
          }
          final session = PsSessionModel.fromJson(jsonMap, key as String);
          list.add(session);
        } catch (e) {
          AppLogger.printMessage(
            "[PsSessionRepo] Error decoding local session $key: $e",
          );
        }
      }
    }
    return list;
  }

  @override
  Future<Either<Failure, String>> startSession(PsSessionEntity session) async {
    try {
      // 1. Generate localId
      final transactionDate = session.createdAt;
      final fingerprint =
          '${session.uid}_${session.deviceId}_${session.roomId}_${transactionDate.millisecondsSinceEpoch}';
      final localId = 'sess_${fingerprint.hashCode.toString()}';

      final sessionWithId = session.copyWith(id: localId);
      final model = PsSessionModel.fromEntity(sessionWithId);

      // 2. Save to local active sessions cache first
      final localBox = await _activeSessionsBox;
      final safeMap = _sessionToSafeMap(model);
      await localBox.put(localId, jsonEncode(safeMap));

      // 3. Prepare offline record
      final payloadJson = jsonEncode(safeMap);
      final offlineRecord = OfflineRecord(
        id: localId,
        amount: 0.0,
        date: transactionDate,
        customerName: session.customerName ?? '',
        type: 'ps_session_start',
        isSynced: false,
        payloadJson: payloadJson,
        collectionName: 'users/${session.uid}/ps_sessions',
      );

      final saveResult = await offlineSyncRepository.saveOfflineRecord(
        offlineRecord,
      );

      return saveResult.fold((failure) => Left(failure), (_) async {
        final hasConnection = await connectionChecker.hasConnection;
        if (hasConnection) {
          await offlineSyncRepository.syncSingleRecord(offlineRecord);
        }
        return Right(localId);
      });
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> endSession({
    required String uid,
    required String sessionId,
    required DateTime endTime,
    required double totalAmount,
    required double paidAmount,
    int? turnCount,
  }) async {
    try {
      // 1. Read session from local cache BEFORE deleting (we need the data for the end payload)
      final localBox = await _activeSessionsBox;
      final sessionJsonStr = localBox.get(sessionId);
      Map<String, dynamic>? cachedSession;
      if (sessionJsonStr != null) {
        try {
          cachedSession = jsonDecode(sessionJsonStr) as Map<String, dynamic>;
        } catch (_) {}
      }

      // 2. Remove from local active sessions box
      await localBox.delete(sessionId);

      // 3. Build the end payload — embed the full session snapshot so the sync
      //    handler can reconstruct the operation even if startSession hasn't
      //    been synced to Firestore yet (avoids the "Session not found" error).
      final Map<String, dynamic> endPayload = {
        'uid': uid,
        'sessionId': sessionId,
        'endTime': endTime.toIso8601String(),
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'turnCount': turnCount,
        // Embed full session snapshot for self-contained sync
        if (cachedSession != null) 'sessionSnapshot': cachedSession,
      };

      // Use a DISTINCT key so this record doesn't overwrite the ps_session_start
      // record in Hive (both use sessionId-based keys).
      final endRecordId = '${sessionId}_end';

      final offlineRecord = OfflineRecord(
        id: endRecordId,
        amount: totalAmount,
        date: endTime,
        customerName: '',
        type: 'ps_session_end',
        isSynced: false,
        payloadJson: jsonEncode(endPayload),
        collectionName: 'users/$uid/ps_sessions',
      );

      final saveResult = await offlineSyncRepository.saveOfflineRecord(
        offlineRecord,
      );

      return saveResult.fold((failure) => Left(failure), (_) async {
        final hasConnection = await connectionChecker.hasConnection;
        if (hasConnection) {
          await offlineSyncRepository.syncSingleRecord(offlineRecord);
        }
        return const Right(unit);
      });
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PsSessionEntity>>> getActiveSessions(
    String uid,
  ) async {
    try {
      final localBox = await _activeSessionsBox;

      // Fetch pending ended session IDs from offline records to filter them out
      final pendingRecordsResult = await offlineSyncRepository
          .getPendingRecords();
      final pendingEndIds = <String>{};
      pendingRecordsResult.fold((_) {}, (records) {
        for (final record in records) {
          if (record.type == 'ps_session_end') {
            // End records use key format "${sessionId}_end" — extract base sessionId
            final baseId = record.id.endsWith('_end')
                ? record.id.substring(0, record.id.length - 4)
                : record.id;
            pendingEndIds.add(baseId);
          }
        }
      });

      final hasConnection = await connectionChecker.hasConnection;
      if (hasConnection) {
        try {
          final remoteSessions = await remoteDataSource.getActiveSessions(uid);

          // Update local cache: clear and overwrite with current remote sessions (excluding pending ended ones)
          await localBox.clear();
          for (final session in remoteSessions) {
            if (!pendingEndIds.contains(session.id)) {
              final Map<String, dynamic> safeMap = _sessionToSafeMap(session);
              await localBox.put(session.id!, jsonEncode(safeMap));
            }
          }

          // But also add any locally started sessions that are not yet on remote (i.e. pending start)
          final localSessions = _getLocalSessions(localBox);
          final merged = <String, PsSessionEntity>{};
          for (final s in remoteSessions) {
            merged[s.id!] = s;
          }
          for (final s in localSessions) {
            merged[s.id!] = s;
          }

          // Filter out any that are pending end
          final finalSessions = merged.values
              .where((s) => !pendingEndIds.contains(s.id))
              .toList();

          return Right(finalSessions);
        } catch (e) {
          AppLogger.printMessage(
            "[PsSessionRepo] Remote fetch failed, falling back to local cache: $e",
          );
          final localSessions = _getLocalSessions(localBox);
          final finalSessions = localSessions
              .where((s) => !pendingEndIds.contains(s.id))
              .toList();
          return Right(finalSessions);
        }
      } else {
        // Offline: load from local cache
        final localSessions = _getLocalSessions(localBox);
        final finalSessions = localSessions
            .where((s) => !pendingEndIds.contains(s.id))
            .toList();
        return Right(finalSessions);
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PsSessionEntity?>> getSessionById(
    String uid,
    String sessionId,
  ) async {
    try {
      final hasConnection = await connectionChecker.hasConnection;
      if (hasConnection) {
        try {
          final remoteSession = await remoteDataSource.getSessionById(
            uid,
            sessionId,
          );
          if (remoteSession != null) {
            return Right(remoteSession);
          }
        } catch (_) {}
      }

      // Fallback/offline
      final localBox = await _activeSessionsBox;
      final jsonStr = localBox.get(sessionId);
      if (jsonStr != null) {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        jsonMap['startTime'] = Timestamp.fromDate(
          DateTime.parse(jsonMap['startTime']),
        );
        if (jsonMap['endTime'] != null) {
          jsonMap['endTime'] = Timestamp.fromDate(
            DateTime.parse(jsonMap['endTime']),
          );
        }
        if (jsonMap['createdAt'] != null) {
          jsonMap['createdAt'] = Timestamp.fromDate(
            DateTime.parse(jsonMap['createdAt']),
          );
        }
        final session = PsSessionModel.fromJson(jsonMap, sessionId);
        return Right(session);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
