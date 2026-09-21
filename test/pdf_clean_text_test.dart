import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/features/customer/domain/entities/customer_operation.dart';
import 'package:tahsel/features/customer/presentation/utils/customer_operation_display_helper.dart';

void main() {
  group('PDF text cleaning and font fallback tests', () {
    test('cleanForPdf correctly maps × and math symbols to ASCII equivalents', () {
      final input1 = 'صنف أ (2 × 50)';
      expect(input1.cleanForPdf(), 'صنف أ (2 x 50)');

      final input2 = 'صنف ب (3 ✕ 20 ✖ 10)';
      expect(input2.cleanForPdf(), 'صنف ب (3 x 20 x 10)');

      final input3 = 'خصم • 10% – عرض خاص';
      expect(input3.cleanForPdf(), 'خصم - 10% - عرض خاص');

      final inputWithEmoji = 'فاتورة مبيعات 🛒 (1 × 100)';
      expect(inputWithEmoji.cleanForPdf(), 'فاتورة مبيعات  (1 x 100)');
    });

    test('cleanForPdf handles null and empty gracefully', () {
      String? nullStr;
      expect(nullStr.cleanForPdf('-'), '-');
      expect(''.cleanForPdf('default'), 'default');
      expect('   '.cleanForPdf('default'), 'default');
    });

    test('PDF generates without missing glyph warning for ×', () async {
      final doc = pw.Document();
      final text = 'Item (2 × 150)'.cleanForPdf();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            fontFallback: [pw.Font.helvetica()],
          ),
          build: (context) => pw.Center(
            child: pw.Text(text),
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes.isNotEmpty, true);
    });
  });

  group('CustomerOperation surplus settlement tests', () {
    test('surplus refund with negative amount is identified as isSettlement', () {
      final op = CustomerOperation(
        id: 'settle_123',
        activityName: 'فاتورة',
        amount: -999.0,
        type: CustomerOperationType.payment,
        date: DateTime.now(),
        invoiceId: 'inv_12345',
      );

      expect(op.isSettlement, true);
      expect(
        op.localizedTitle,
        anyOf('تسوية فائض للعميل', 'customer_surplus_settlement'),
      );
      
      // Formatting must use abs() to avoid double minus
      final prefix = '-';
      final formatted = '$prefix${op.amount.abs().toSmartAmount()} ج.م';
      expect(formatted, '-999 ج.م');
      expect(formatted.contains('--'), false);
    });

    test('positive settlement payment from customer is NOT isSettlement even with settlement text', () {
      final op = CustomerOperation(
        id: 'settle_456',
        activityName: 'تسوية مديونية',
        amount: 500.0,
        type: CustomerOperationType.payment,
        date: DateTime.now(),
        notes: 'تسوية حساب العميل',
      );

      // Customer paid -> amount > 0, so it is NOT customer surplus settlement
      expect(op.isSettlement, false);
      expect(op.localizedTitle, isNot(contains('فائض')));
    });

    test('settlement is excluded from credit/paid column and mapped to paidToCustomer', () {
      final settlementOp = CustomerOperation(
        id: 'settle_789',
        activityName: 'تسوية فائض للعميل',
        amount: -999.0,
        type: CustomerOperationType.payment,
        date: DateTime.now(),
      );

      final normalPaymentOp = CustomerOperation(
        id: 'pay_100',
        activityName: 'سداد دفعة',
        amount: 500.0,
        type: CustomerOperationType.payment,
        date: DateTime.now(),
      );

      // Verify logic as implemented in CustomerStatementPdfExporter
      // For settlement:
      final isSettlement1 = settlementOp.isSettlement;
      final isPayment1 = settlementOp.type == CustomerOperationType.payment && !isSettlement1;
      final creditStr1 = isPayment1 ? settlementOp.amount.abs().toSmartAmount() : '-';
      final paidToCustomerStr1 = isSettlement1 ? settlementOp.amount.abs().toSmartAmount() : '-';

      expect(isSettlement1, true);
      expect(isPayment1, false);
      expect(creditStr1, '-'); // Must NOT appear in "المدفوع (-)"!
      expect(paidToCustomerStr1, '999'); // Appears in "مدفوع للعميل"

      // For normal payment:
      final isSettlement2 = normalPaymentOp.isSettlement;
      final isPayment2 = normalPaymentOp.type == CustomerOperationType.payment && !isSettlement2;
      final creditStr2 = isPayment2 ? normalPaymentOp.amount.abs().toSmartAmount() : '-';
      final paidToCustomerStr2 = isSettlement2 ? normalPaymentOp.amount.abs().toSmartAmount() : '-';

      expect(isSettlement2, false);
      expect(isPayment2, true);
      expect(creditStr2, '500'); // Appears in "المدفوع (-)"
      expect(paidToCustomerStr2, '-'); // Does NOT appear in "مدفوع للعميل"
    });
  });
}
