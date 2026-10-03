import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/firebase_error_handler.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/services/activity_logger_service.dart';
import '../../../../core/services/injection_container.dart';
import '../../../../core/utils/app_strings.dart';
import '../models/customer_model.dart';
import '../../domain/entities/customer_operation.dart';

abstract class CustomerRemoteDataSource {
  Future<Map<String, dynamic>> getCustomers(
    String uid, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  });
  Future<void> saveCustomer(String uid, CustomerModel customer);
  Future<void> updateCustomerPhone(String uid, String name, String phoneNumber);
  Future<void> updateCustomerPreference(
    String uid,
    String name,
    String preference,
  );
  Future<void> updateCustomerDetails(
    String uid, {
    String? customerId,
    required String name,
    String? phoneNumber,
    String? ledgerNumber,
    String? taxNumber,
    String? commercialRegistration,
  });
  Future<Map<String, dynamic>> getCustomerOperations(
    String uid,
    String customerName, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  });
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final FirebaseFirestore firestore;

  CustomerRemoteDataSourceImpl({required this.firestore});

  @override
  Future<Map<String, dynamic>> getCustomers(
    String uid, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      var query = firestore
          .collection('users')
          .doc(uid)
          .collection('customers')
          .orderBy('lastUsedAt', descending: true);

      if (limit > 0) {
        query = query.limit(limit);
      }

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();

      final customers = snapshot.docs
          .map((doc) => CustomerModel.fromJson(doc.data(), id: doc.id))
          .toList();

      return {
        'customers': customers,
        'lastDoc': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      };
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<void> saveCustomer(String uid, CustomerModel customer) async {
    try {
      final collection = firestore
          .collection('users')
          .doc(uid)
          .collection('customers');

      // Use a normalized name for finding (trim and lowercase)
      final normalizedName = customer.name.trim();

      // Check if customer exists (by name)
      final existing = await collection
          .where('name', isEqualTo: normalizedName)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        final currentTotal = doc.data()['totalTransactions'] as int? ?? 0;
        final updateData = <String, dynamic>{
          'lastUsedAt': Timestamp.fromDate(DateTime.now()),
        };
        if (customer.totalTransactions > 0) {
          updateData['totalTransactions'] = currentTotal + customer.totalTransactions;
        }
        if (customer.phoneNumber != null && customer.phoneNumber!.trim().isNotEmpty) {
          updateData['phoneNumber'] = customer.phoneNumber!.trim();
        }
        if (customer.taxNumber != null && customer.taxNumber!.trim().isNotEmpty) {
          updateData['taxNumber'] = customer.taxNumber!.trim();
        }
        if (customer.commercialRegistration != null &&
            customer.commercialRegistration!.trim().isNotEmpty) {
          updateData['commercialRegistration'] =
              customer.commercialRegistration!.trim();
        }
        if (customer.ledgerNumber != null && customer.ledgerNumber!.trim().isNotEmpty) {
          updateData['ledgerNumber'] = customer.ledgerNumber!.trim();
        }
        await doc.reference.update(updateData);
      } else {
        final newDoc = await collection.add(customer.toJson());
        if (sl.isRegistered<ActivityLoggerService>()) {
          final phoneInfo = (customer.phoneNumber != null &&
                  customer.phoneNumber!.isNotEmpty)
              ? ' (هاتف: ${customer.phoneNumber})'
              : '';
          sl<ActivityLoggerService>().logStandalone(
            ownerUid: uid,
            actionCategory: 'debts',
            actionType: 'add_customer_profile',
            actionTitle: 'إضافة عميل جديد: ${customer.name}',
            details: 'تسجيل ملف عميل جديد: ${customer.name}$phoneInfo',
            extraData: {
              'customerId': newDoc.id,
              'customerName': customer.name,
              'phoneNumber': customer.phoneNumber,
              'taxNumber': customer.taxNumber,
            },
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateCustomerPhone(
    String uid,
    String name,
    String phoneNumber,
  ) async {
    try {
      final collection = firestore
          .collection('users')
          .doc(uid)
          .collection('customers');
      final normalizedName = name.trim();
      final existing = await collection
          .where('name', isEqualTo: normalizedName)
          .limit(1)
          .get();

      String oldPhone = 'بدون';
      final cleanNewPhone = phoneNumber.trim();

      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        oldPhone = (doc.data()['phoneNumber'] as String?)?.trim() ?? 'بدون';
        if (oldPhone.isEmpty) oldPhone = 'بدون';
        await doc.reference.update({
          'phoneNumber': cleanNewPhone,
        });
      } else {
        await collection.add({
          'name': normalizedName,
          'phoneNumber': cleanNewPhone,
          'notificationPreference': 'none',
          'lastUsedAt': Timestamp.now(),
          'totalTransactions': 0,
        });
      }

      if (sl.isRegistered<ActivityLoggerService>() && oldPhone != cleanNewPhone) {
        sl<ActivityLoggerService>().logStandalone(
          ownerUid: uid,
          actionCategory: 'debts',
          actionType: 'update_customer_phone',
          actionTitle: 'تعديل هاتف العميل: $normalizedName',
          details:
              'تعديل رقم هاتف العميل ($normalizedName): تم تغيير الهاتف من "$oldPhone" إلى "$cleanNewPhone"',
          extraData: {
            'customerName': normalizedName,
            'oldPhoneNumber': oldPhone,
            'newPhoneNumber': cleanNewPhone,
          },
        );
      }
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<void> updateCustomerPreference(
    String uid,
    String name,
    String preference,
  ) async {
    try {
      final collection = firestore
          .collection('users')
          .doc(uid)
          .collection('customers');
      final normalizedName = name.trim();
      final existing = await collection
          .where('name', isEqualTo: normalizedName)
          .limit(1)
          .get();

      String oldPref = 'none';

      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        oldPref = (doc.data()['notificationPreference'] as String?) ?? 'none';
        await doc.reference.update({
          'notificationPreference': preference,
        });
      } else {
        // Customer has no document yet (added via an older/direct debt flow).
        // Upsert a minimal document so the preference is persisted.
        await collection.add({
          'name': normalizedName,
          'notificationPreference': preference,
          'lastUsedAt': Timestamp.now(),
          'totalTransactions': 0,
          'phoneNumber': null,
        });
      }

      if (sl.isRegistered<ActivityLoggerService>() && oldPref != preference) {
        String prefLabel(String p) {
          switch (p) {
            case 'whatsapp':
              return 'واتساب';
            case 'sms':
              return 'رسائل SMS';
            case 'both':
              return 'واتساب وSMS';
            default:
              return 'بدون إشعارات';
          }
        }

        sl<ActivityLoggerService>().logStandalone(
          ownerUid: uid,
          actionCategory: 'debts',
          actionType: 'update_customer_preference',
          actionTitle: 'تعديل وسيلة إشعار العميل: $normalizedName',
          details:
              'تعديل تفضيل إشعار العميل ($normalizedName): تم التغيير من "${prefLabel(oldPref)}" إلى "${prefLabel(preference)}"',
          extraData: {
            'customerName': normalizedName,
            'oldPreference': oldPref,
            'newPreference': preference,
          },
        );
      }
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<void> updateCustomerDetails(
    String uid, {
    String? customerId,
    required String name,
    String? phoneNumber,
    String? ledgerNumber,
    String? taxNumber,
    String? commercialRegistration,
  }) async {
    try {
      final collection = firestore
          .collection('users')
          .doc(uid)
          .collection('customers');

      DocumentReference? docRef;
      Map<String, dynamic>? oldData;
      if (customerId != null && customerId.isNotEmpty) {
        final candidateRef = collection.doc(customerId);
        try {
          final docSnap = await candidateRef.get();
          if (docSnap.exists) {
            docRef = candidateRef;
            oldData = docSnap.data();
          }
        } catch (_) {}
      }

      if (docRef == null) {
        final normalizedName = name.trim();
        final existing = await collection
            .where('name', isEqualTo: normalizedName)
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) {
          docRef = existing.docs.first.reference;
          oldData = existing.docs.first.data();
        }
      }

      final updateData = <String, dynamic>{
        'phoneNumber': (phoneNumber != null && phoneNumber.trim().isNotEmpty)
            ? phoneNumber.trim()
            : null,
        'ledgerNumber': (ledgerNumber != null && ledgerNumber.trim().isNotEmpty)
            ? ledgerNumber.trim()
            : null,
        'taxNumber': (taxNumber != null && taxNumber.trim().isNotEmpty)
            ? taxNumber.trim()
            : null,
        'commercialRegistration': (commercialRegistration != null &&
                commercialRegistration.trim().isNotEmpty)
            ? commercialRegistration.trim()
            : null,
      };

      if (docRef != null) {
        await docRef.update(updateData);
      } else {
        await collection.add({
          'name': name.trim(),
          'lastUsedAt': Timestamp.now(),
          'totalTransactions': 0,
          'notificationPreference': 'none',
          ...updateData,
        });
      }

      if (sl.isRegistered<ActivityLoggerService>()) {
        final updatedFields = <String>[];
        final oldPhone = (oldData?['phoneNumber'] as String?)?.trim() ?? '';
        final newPhone = (phoneNumber ?? '').trim();
        if (oldPhone != newPhone) {
          final oldVal = oldPhone.isNotEmpty ? oldPhone : 'بدون';
          final newVal = newPhone.isNotEmpty ? newPhone : 'بدون';
          updatedFields.add('الهاتف: من "$oldVal" إلى "$newVal"');
        }

        final oldLedger = (oldData?['ledgerNumber'] as String?)?.trim() ?? '';
        final newLedger = (ledgerNumber ?? '').trim();
        if (oldLedger != newLedger) {
          final oldVal = oldLedger.isNotEmpty ? oldLedger : 'بدون';
          final newVal = newLedger.isNotEmpty ? newLedger : 'بدون';
          updatedFields.add('رقم الدفتر: من "$oldVal" إلى "$newVal"');
        }

        final oldTax = (oldData?['taxNumber'] as String?)?.trim() ?? '';
        final newTax = (taxNumber ?? '').trim();
        if (oldTax != newTax) {
          final oldVal = oldTax.isNotEmpty ? oldTax : 'بدون';
          final newVal = newTax.isNotEmpty ? newTax : 'بدون';
          updatedFields.add('الرقم الضريبي: من "$oldVal" إلى "$newVal"');
        }

        final oldCrn = (oldData?['commercialRegistration'] as String?)?.trim() ?? '';
        final newCrn = (commercialRegistration ?? '').trim();
        if (oldCrn != newCrn) {
          final oldVal = oldCrn.isNotEmpty ? oldCrn : 'بدون';
          final newVal = newCrn.isNotEmpty ? newCrn : 'بدون';
          updatedFields.add('السجل التجاري: من "$oldVal" إلى "$newVal"');
        }

        final detailsText = updatedFields.isNotEmpty
            ? 'تحديث بيانات العميل (${name.trim()}): تم تعديل ${updatedFields.join("، ")}'
            : 'تحديث وتأكيد بيانات العميل: ${name.trim()}';

        sl<ActivityLoggerService>().logStandalone(
          ownerUid: uid,
          actionCategory: 'debts',
          actionType: 'update_customer_details',
          actionTitle: 'تعديل بيانات عميل: ${name.trim()}',
          details: detailsText,
          extraData: {
            'customerName': name.trim(),
            if (phoneNumber != null) 'phoneNumber': phoneNumber.trim(),
            if (ledgerNumber != null) 'ledgerNumber': ledgerNumber.trim(),
            if (taxNumber != null) 'taxNumber': taxNumber.trim(),
            if (commercialRegistration != null)
              'commercialRegistration': commercialRegistration.trim(),
          },
        );
      }
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getCustomerOperations(
    String uid,
    String customerName, {
    int limit = 0,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      final userRef = firestore.collection('users').doc(uid);
      final trimmedCustomerName = customerName.trim();

      // Fetch customer profile details if on first page
      CustomerModel? customerModel;
      if (lastDoc == null) {
        try {
          final custSnapshot = await userRef
              .collection('customers')
              .where('name', isEqualTo: trimmedCustomerName)
              .limit(1)
              .get(const GetOptions(source: Source.serverAndCache));
          if (custSnapshot.docs.isNotEmpty) {
            final doc = custSnapshot.docs.first;
            customerModel = CustomerModel.fromJson(doc.data(), id: doc.id);
          }
        } catch (_) {}
      }

      // 1. Fetch debts first to know which operations are credit debts vs cash sales
      double totalSpent = 0.0;
      double totalPaid = 0.0;
      final Set<String> debtOperationIds = {};
      final List<CustomerOperation> rawOperations = [];

      DateTime parseDate(dynamic val) {
        if (val == null) return DateTime.now();
        if (val is Timestamp) return val.toDate();
        if (val is DateTime) return val;
        if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
        if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
        return DateTime.now();
      }

      // Helper function to extract genuine invoice ID (starting with inv_)
      String? extractRealInvoiceId(dynamic candidate) {
        if (candidate == null) return null;
        final str = candidate.toString().trim();
        if (str.isEmpty) return null;
        if (str.startsWith('debt_inv_')) {
          final extracted = str.replaceFirst('debt_inv_', '');
          return extractRealInvoiceId(extracted);
        }
        if (str.startsWith('debt_')) {
          final extracted = str.replaceFirst('debt_', '');
          return extractRealInvoiceId(extracted);
        }
        final match = RegExp(r'inv_[a-zA-Z0-9_-]+').firstMatch(str);
        if (match != null) {
          var id = match.group(0)!;
          if (id.endsWith('_cash_pay')) id = id.replaceFirst('_cash_pay', '');
          if (id.endsWith('_pay')) id = id.replaceFirst('_pay', '');
          return id;
        }
        return null;
      }

      // Pre-load customer invoices to build an authoritative link map (docId / debtId -> real inv_ ID)
      final Map<String, String> idToRealInvoiceMap = {};
      QuerySnapshot<Map<String, dynamic>>? invoicesSnapshot;
      if (lastDoc == null) {
        try {
          invoicesSnapshot = await userRef
              .collection('invoices')
              .where('customerName', isEqualTo: trimmedCustomerName)
              .get(const GetOptions(source: Source.serverAndCache));

          for (var invDoc in invoicesSnapshot.docs) {
            final invData = invDoc.data();
            final rawInvId = invData['id']?.toString() ?? invDoc.id;
            final invId = rawInvId.startsWith('inv_') ? rawInvId : 'inv_$rawInvId';

            idToRealInvoiceMap[invId] = invId;
            idToRealInvoiceMap[invDoc.id] = invId;
            idToRealInvoiceMap['debt_$invId'] = invId;
            idToRealInvoiceMap['debt_inv_$invId'] = invId;

            final linkedDebt = invData['linkedDebtId']?.toString();
            if (linkedDebt != null && linkedDebt.isNotEmpty) {
              idToRealInvoiceMap[linkedDebt] = invId;
              if (linkedDebt.startsWith('debt_inv_')) {
                idToRealInvoiceMap[linkedDebt.replaceFirst('debt_inv_', '')] = invId;
              }
            }
          }
        } catch (_) {}
      }

      String? resolveDebtInvoiceId(String debtId, String? opId, Map<String, dynamic> data) {
        if (idToRealInvoiceMap.containsKey(debtId)) return idToRealInvoiceMap[debtId];
        if (opId != null && idToRealInvoiceMap.containsKey(opId)) return idToRealInvoiceMap[opId];

        final fromDebtId = extractRealInvoiceId(debtId);
        if (fromDebtId != null) return fromDebtId;

        if (opId != null) {
          final fromOpId = extractRealInvoiceId(opId);
          if (fromOpId != null) return fromOpId;
        }

        final fromInvField = extractRealInvoiceId(data['invoiceId']);
        if (fromInvField != null) return fromInvField;

        final fromLedger = extractRealInvoiceId(data['ledgerNumber']);
        if (fromLedger != null) return fromLedger;

        final fromDetails = extractRealInvoiceId(data['productOrSessionDetails']);
        if (fromDetails != null) return fromDetails;

        final fromNotes = extractRealInvoiceId(data['notes']);
        if (fromNotes != null) return fromNotes;

        return null;
      }

      String? resolveOpInvoiceId(String docId, Map<String, dynamic> data) {
        if (idToRealInvoiceMap.containsKey(docId)) return idToRealInvoiceMap[docId];

        final fromDocId = extractRealInvoiceId(docId);
        if (fromDocId != null) return fromDocId;

        final fromInvField = extractRealInvoiceId(data['invoiceId']);
        if (fromInvField != null) return fromInvField;

        final fromLedger = extractRealInvoiceId(data['ledgerNumber']);
        if (fromLedger != null) return fromLedger;

        final fromProduct = extractRealInvoiceId(data['productName']);
        if (fromProduct != null) return fromProduct;

        final fromNotes = extractRealInvoiceId(data['notes']);
        if (fromNotes != null) return fromNotes;

        return null;
      }

      QuerySnapshot<Map<String, dynamic>>? debtsSnapshot;
      final Set<String> seenOpIds = {};

      if (lastDoc == null) {
        debtsSnapshot = await userRef
            .collection('debts')
            .where('customerName', isEqualTo: trimmedCustomerName)
            .get(const GetOptions(source: Source.serverAndCache));

        for (var debtDoc in debtsSnapshot.docs) {
          debtOperationIds.add(debtDoc.id);
          final debtData = debtDoc.data();
          final debtOpId = debtData['operationId']?.toString();
          if (debtOpId != null && debtOpId.isNotEmpty) {
            debtOperationIds.add(debtOpId);
          }

          final debtTotal = (debtData['totalAmount'] as num? ?? 0.0).toDouble();
          final debtPaid = (debtData['paidAmount'] as num? ?? 0.0).toDouble();
          totalSpent += debtTotal;
          totalPaid += debtPaid;

          final activityName = debtData['operationType']?.toString() ?? '';
          final debtInvId = resolveDebtInvoiceId(debtDoc.id, debtOpId, debtData);

          // Optimization: ONLY query payments if paidAmount > 0
          if (debtPaid > 0) {
            final paymentsSnapshot = await debtDoc.reference
                .collection('payments')
                .get(const GetOptions(source: Source.serverAndCache));

            for (var paymentDoc in paymentsSnapshot.docs) {
              final pData = paymentDoc.data();
              if (pData['type'] == 'debtAdded') continue;

              final paidAmount = (pData['amountPaid'] as num?)?.toDouble() ?? 0.0;
              if (paidAmount == 0.0) continue;

              final pType = pData['type']?.toString();
              final pActName = pData['activityName']?.toString();
              final pNotes = pData['notes']?.toString();
              final isSurplusRefund = paidAmount < 0;

              final resolvedActName = isSurplusRefund
                  ? (pActName ?? AppStrings.customerSurplusSettlement.tr())
                  : (pActName ?? (pType == 'settlement' ? AppStrings.directPayment.tr() : activityName));

              rawOperations.add(
                CustomerOperation(
                  id: paymentDoc.id,
                  activityName: resolvedActName,
                  amount: paidAmount,
                  type: CustomerOperationType.payment,
                  date: parseDate(pData['createdAt']),
                  details: pNotes ??
                      pData['paymentMethod']?.toString() ??
                      (isSurplusRefund ? AppStrings.customerSurplusSettlement.tr() : null),
                  referenceNumber: isSurplusRefund ? null : debtInvId,
                  invoiceId: isSurplusRefund ? null : debtInvId,
                  notes: pNotes,
                ),
              );
            }
          }
        }
      }

      // 2. Fetch operations with serverAndCache
      var opsQuery = userRef
          .collection('operations')
          .where('customerName', isEqualTo: trimmedCustomerName)
          .orderBy('timestamp', descending: true);

      if (limit > 0) {
        opsQuery = opsQuery.limit(limit);
      }

      if (lastDoc != null) {
        opsQuery = opsQuery.startAfterDocument(lastDoc);
      }

      final opsSnapshot = await opsQuery.get(
        const GetOptions(source: Source.serverAndCache),
      );

      for (var doc in opsSnapshot.docs) {
        seenOpIds.add(doc.id);
        final data = doc.data();
        final opInvId = resolveOpInvoiceId(doc.id, data);

        if (opInvId != null) {
          seenOpIds.add(opInvId);
          seenOpIds.add('debt_inv_$opInvId');
          seenOpIds.add('debt_$opInvId');
        }

        final remainingDebt = (data['remainingDebt'] as num?)?.toDouble() ?? 0.0;
        final opTotal = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final opPaid = (data['paidAmount'] as num?)?.toDouble() ?? (remainingDebt <= 0 ? opTotal : 0.0);
        final opDate = parseDate(data['timestamp']);
        final isDebt = remainingDebt > 0;
        final type = isDebt ? CustomerOperationType.debt : CustomerOperationType.purchase;

        // Record the purchase / debt operation
        rawOperations.add(
          CustomerOperation(
            id: doc.id,
            activityName: data['type']?.toString() ?? '',
            amount: opTotal,
            type: type,
            date: opDate,
            details: data['productName']?.toString(),
            referenceNumber: opInvId,
            invoiceId: opInvId,
            notes: data['notes']?.toString(),
          ),
        );

        // If this is a cash sale (not linked to debts collection) and paidAmount > 0:
        // Record the corresponding cash payment so the sale doesn't leave phantom debt!
        final isLinkedDebt = debtOperationIds.contains(doc.id) ||
            (opInvId != null && debtOperationIds.contains('debt_inv_$opInvId')) ||
            (opInvId != null && debtOperationIds.contains('debt_$opInvId'));

        if (!isLinkedDebt) {
          totalSpent += opTotal;
          if (opPaid > 0) {
            totalPaid += opPaid;
            rawOperations.add(
              CustomerOperation(
                id: '${doc.id}_cash_pay',
                activityName: data['type']?.toString() ?? '',
                amount: opPaid,
                type: CustomerOperationType.payment,
                date: opDate.add(const Duration(milliseconds: 1)),
                details: AppStrings.instantCashPayment.tr(),
                referenceNumber: opInvId,
                invoiceId: opInvId,
                notes: AppStrings.directCashPayment.tr(),
              ),
            );
          }
        }
      }

      // 3. Reconcile any debts from debtsSnapshot that had no corresponding operations doc
      if (lastDoc == null && debtsSnapshot != null) {
        for (var debtDoc in debtsSnapshot.docs) {
          final debtData = debtDoc.data();
          final debtOpId = debtData['operationId']?.toString();
          final wasFoundInOps = seenOpIds.contains(debtDoc.id) ||
              (debtOpId != null && seenOpIds.contains(debtOpId));
          if (!wasFoundInOps) {
            final debtTotal = (debtData['totalAmount'] as num? ?? 0.0).toDouble();
            final debtDate = parseDate(debtData['timestamp'] ?? debtData['createdAt']);
            final debtInvId = resolveDebtInvoiceId(debtDoc.id, debtOpId, debtData);

            rawOperations.add(
              CustomerOperation(
                id: debtDoc.id,
                activityName: debtData['operationType']?.toString() ?? AppStrings.debt.tr(),
                amount: debtTotal,
                type: CustomerOperationType.debt,
                date: debtDate,
                details: debtData['productOrSessionDetails']?.toString(),
                referenceNumber: debtInvId,
                invoiceId: debtInvId,
                notes: debtData['notes']?.toString(),
              ),
            );
          }
        }

        // 4. Reconcile direct cash invoices that were not linked to debts or operations
        if (invoicesSnapshot != null) {
          for (var invDoc in invoicesSnapshot.docs) {
            final invData = invDoc.data();
            final invStatus = invData['status']?.toString();
            if (invStatus == 'cancelled' || invStatus == 'voided') continue;

            final rawInvId = invData['id']?.toString() ?? invDoc.id;
            final invId = rawInvId.startsWith('inv_') ? rawInvId : 'inv_$rawInvId';

            final linkedDebt = invData['linkedDebtId']?.toString();
            if (debtOperationIds.contains('debt_inv_$invId') ||
                debtOperationIds.contains('debt_$invId') ||
                debtOperationIds.contains(invId) ||
                (linkedDebt != null && debtOperationIds.contains(linkedDebt)) ||
                seenOpIds.contains(invId) ||
                seenOpIds.contains(rawInvId) ||
                (linkedDebt != null && seenOpIds.contains(linkedDebt))) {
              continue;
            }

            final bool isQuotation = invStatus == 'quotation' ||
                invData['isQuotation'] == true ||
                invData['type'] == 'quotation';

            final invTotal = (invData['totalAmount'] as num? ?? 0.0).toDouble();
            final invPaid = (invData['totalPaid'] as num? ?? 0.0).toDouble();
            final invDate = parseDate(invData['createdAt']);

            final opTitle = isQuotation
                ? AppStrings.invoiceStatusQuotation.tr()
                : AppStrings.salesInvoice.tr();

            rawOperations.add(
              CustomerOperation(
                id: invId,
                activityName: opTitle,
                amount: invTotal,
                type: isQuotation
                    ? CustomerOperationType.quotation
                    : CustomerOperationType.purchase,
                date: invDate,
                details: '$opTitle #$invId',
                referenceNumber: invId,
                invoiceId: invId,
                notes: invData['notes']?.toString(),
              ),
            );

            if (!isQuotation) {
              totalSpent += invTotal;
              if (invPaid > 0) {
                totalPaid += invPaid;
                rawOperations.add(
                  CustomerOperation(
                    id: '${invId}_pay',
                    activityName: AppStrings.salesInvoice.tr(),
                    amount: invPaid,
                    type: CustomerOperationType.payment,
                    date: invDate.add(const Duration(milliseconds: 1)),
                    details: AppStrings.instantCashPayment.tr(),
                    referenceNumber: invId,
                    invoiceId: invId,
                    notes: AppStrings.directCashPayment.tr(),
                  ),
                );
              }
            }
          }
        }
      }

      // 5. Calculate running balance chronologically (oldest to newest) with tie-breaker
      rawOperations.sort((a, b) {
        final cmp = a.date.compareTo(b.date);
        if (cmp != 0) return cmp;
        if (a.type != b.type) {
          if (a.type == CustomerOperationType.payment) return 1;
          if (b.type == CustomerOperationType.payment) return -1;
        }
        return 0;
      });

      double currentRunning = 0.0;
      final List<CustomerOperation> balancedOperations = [];

      for (var op in rawOperations) {
        if (op.type == CustomerOperationType.quotation) {
          // Quotations are price offers and do not alter customer debt balance
        } else if (op.type == CustomerOperationType.payment) {
          currentRunning -= op.amount;
        } else {
          currentRunning += op.amount;
        }
        balancedOperations.add(op.copyWith(runningBalance: currentRunning));
      }

      // Sort latest first for UI display
      final displayOperations = balancedOperations.reversed.toList();

      return {
        'operations': displayOperations,
        'lastDoc': opsSnapshot.docs.isNotEmpty ? opsSnapshot.docs.last : null,
        'totalSpent': totalSpent,
        'totalPaid': totalPaid,
        'customer': customerModel,
      };
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      rethrow;
    }
  }
}
