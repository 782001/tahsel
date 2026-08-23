import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/firebase_error_handler.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/summary_helper.dart';
import '../../../cashbox/domain/entities/vault_transaction_entity.dart';
import '../models/ps_session_model.dart';
import '../models/operation_model.dart';

abstract class PsSessionRemoteDataSource {
  /// Creates a new session document in Firestore. Returns the document ID.
  Future<String> startSession(PsSessionModel session);

  /// Ends an active session: sets endTime, calculates totals, updates status,
  /// and creates a corresponding operation document for billing/reporting.
  Future<void> endSession({
    required String uid,
    required String sessionId,
    required DateTime endTime,
    required double totalAmount,
    required double paidAmount,
    int? turnCount,
  });

  /// Returns all active sessions for a user.
  Future<List<PsSessionModel>> getActiveSessions(String uid);

  /// Returns a single session by ID.
  Future<PsSessionModel?> getSessionById(String uid, String sessionId);
}

class PsSessionRemoteDataSourceImpl implements PsSessionRemoteDataSource {
  final FirebaseFirestore firestore;

  PsSessionRemoteDataSourceImpl({required this.firestore});

  CollectionReference<Map<String, dynamic>> _sessionsRef(String uid) {
    return firestore.collection('users').doc(uid).collection('ps_sessions');
  }

  @override
  Future<String> startSession(PsSessionModel session) async {
    try {
      final docRef = session.id != null && session.id!.isNotEmpty
          ? _sessionsRef(session.uid).doc(session.id)
          : _sessionsRef(session.uid).doc();
      await docRef.set(session.toJson());
      return docRef.id;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to start session: $e');
    }
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
    try {
      final sessionRef = _sessionsRef(uid).doc(sessionId);
      final sessionDoc = await sessionRef.get();

      if (!sessionDoc.exists) {
        throw Exception('Session not found: $sessionId');
      }

      final sessionData = sessionDoc.data()!;
      final session = PsSessionModel.fromJson(sessionData, sessionId);
      final remainingDebt = (totalAmount - paidAmount) > 0
          ? (totalAmount - paidAmount)
          : 0.0;

      final batch = firestore.batch();

      // 1. Update the session document
      batch.update(sessionRef, {
        'endTime': Timestamp.fromDate(endTime),
        'status': 'completed',
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'remainingDebt': remainingDebt,
        if (turnCount != null) 'turnCount': turnCount,
      });

      // 2. Create a corresponding operation for billing & reporting
      final durationMinutes = endTime.difference(session.startTime).inMinutes;
      final operationModel = OperationModel(
        uid: uid,
        type: AppStrings.playStation,
        subType: session.subType,
        customerName: session.customerName,
        phoneNumber: session.phoneNumber,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        remainingDebt: remainingDebt,
        timestamp: session.startTime,
        lastUpdatedAt: endTime,
        durationMinutes: session.subType == 'time' ? durationMinutes : null,
        turnCount: turnCount ?? session.turnCount,
        rate: session.rate,
        ledgerNumber: session.ledgerNumber,
      );

      final userRef = firestore.collection('users').doc(uid);
      final operationRef = userRef.collection('operations').doc();
      batch.set(operationRef, operationModel.toJson());

      // 3. Update summaries (same logic as addOperation)
      final timestamp = session.startTime;
      final summaryKeys = SummaryHelper.getSummaryKeys(timestamp);

      for (final key in summaryKeys) {
        final summaryRef = userRef.collection('summaries').doc(key);
        batch.set(summaryRef, {
          'totalIncome': FieldValue.increment(totalAmount),
          'playstationIncome': FieldValue.increment(totalAmount),
          'transactionCount': FieldValue.increment(1),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 4. Record Vault Inflow for completed PS session payments
      if (AppStrings.isVaultEnabled() && paidAmount > 0) {
        final vaultTxRef = userRef
            .collection('vault_transactions')
            .doc('vault_tx_ps_$sessionId');
        final vaultSummaryRef = userRef.collection('vault').doc('summary');

        final String cust = session.customerName != null &&
                session.customerName!.isNotEmpty
            ? session.customerName!
            : 'عميل';

        batch.set(vaultTxRef, {
          'id': 'vault_tx_ps_$sessionId',
          'uid': uid,
          'amount': paidAmount,
          'direction': 'in',
          'source': VaultTransactionSource.customerDebt.name,
          'type': 'ps_session_payment',
          'description': 'تحصيل جلسة بلايستيشن: $cust',
          'relatedEntityId': sessionId,
          'createdAt': Timestamp.fromDate(endTime),
        });

        batch.set(
          vaultSummaryRef,
          {
            'currentBalance': FieldValue.increment(paidAmount),
            'totalIn': FieldValue.increment(paidAmount),
            'transactionCount': FieldValue.increment(1),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to end session: $e');
    }
  }

  @override
  Future<List<PsSessionModel>> getActiveSessions(String uid) async {
    try {
      final snapshot = await _sessionsRef(uid)
          .where('status', isEqualTo: 'active')
          .orderBy('startTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PsSessionModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch active sessions: $e');
    }
  }

  @override
  Future<PsSessionModel?> getSessionById(String uid, String sessionId) async {
    try {
      final doc = await _sessionsRef(uid).doc(sessionId).get();
      if (doc.exists) {
        return PsSessionModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch session: $e');
    }
  }
}
