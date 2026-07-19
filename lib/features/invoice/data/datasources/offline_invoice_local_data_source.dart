import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/invoice_model.dart';
import '../../domain/entities/invoice_entity.dart';

abstract class OfflineInvoiceLocalDataSource {
  Future<void> saveOfflineInvoice(InvoiceEntity invoice);
  Future<void> updateOfflinePayment(String invoiceId, double paymentAmount, String? paymentNote);
  Future<List<Map<String, dynamic>>> getPendingInvoices();
  Future<void> deleteOfflineInvoice(String invoiceId);
}

class OfflineInvoiceLocalDataSourceImpl implements OfflineInvoiceLocalDataSource {
  static const String _boxName = 'offline_invoices_box';

  Future<Box<String>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<String>(_boxName);
    }
    return Hive.box<String>(_boxName);
  }

  @override
  Future<void> saveOfflineInvoice(InvoiceEntity invoice) async {
    final box = await _getBox();
    final model = InvoiceModel.fromEntity(invoice);
    
    final data = {
      'invoiceId': invoice.id,
      'invoiceJson': model.toJson(),
      'paymentAmount': 0.0,
      'paymentNote': null,
    };
    
    await box.put(invoice.id, jsonEncode(data));
  }

  @override
  Future<void> updateOfflinePayment(String invoiceId, double paymentAmount, String? paymentNote) async {
    final box = await _getBox();
    final jsonStr = box.get(invoiceId);
    if (jsonStr != null) {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      // We must accumulate the new payment amount with whatever is already there.
      final oldPaymentAmount = (data['paymentAmount'] as num?)?.toDouble() ?? 0.0;
      final newPaymentAmount = oldPaymentAmount + paymentAmount;
      
      data['paymentAmount'] = newPaymentAmount;
      data['paymentNote'] = paymentNote;
      
      // Update the embedded invoiceJson so UI reflects the payment immediately
      final invoiceMap = jsonDecode(data['invoiceJson']) as Map<String, dynamic>;
      
      // Append the payment to the invoice's internal payments list
      final payments = List<dynamic>.from(invoiceMap['payments'] ?? []);
      payments.add({
        'id': 'pmt_offline_${DateTime.now().millisecondsSinceEpoch}',
        'amount': paymentAmount,
        'paidAt': DateTime.now().toIso8601String(),
        'note': paymentNote,
      });
      invoiceMap['payments'] = payments;
      
      // Calculate dynamic totals to update the status field correctly
      final model = InvoiceModel.fromMap(invoiceMap);
      final totalAmount = model.totalAmount;
          
      final newPaid = payments.fold(0.0, (sum, p) => sum + (p['amount'] as num));
      final newRemaining = totalAmount - newPaid;
      
      if (newRemaining <= 1e-9) {
        invoiceMap['status'] = 'paid';
      } else if (newPaid > 0) {
        invoiceMap['status'] = 'partial';
      } else {
        invoiceMap['status'] = 'pending';
      }
      
      data['invoiceJson'] = jsonEncode(invoiceMap);
      
      await box.put(invoiceId, jsonEncode(data));
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingInvoices() async {
    final box = await _getBox();
    final List<Map<String, dynamic>> result = [];
    for (final jsonStr in box.values) {
      result.add(jsonDecode(jsonStr) as Map<String, dynamic>);
    }
    return result;
  }

  @override
  Future<void> deleteOfflineInvoice(String invoiceId) async {
    final box = await _getBox();
    await box.delete(invoiceId);
  }
}
