import 'package:flutter_test/flutter_test.dart';
import 'package:tahsel/features/shipping_reconciliation/data/services/column_detector_service.dart';
import 'package:tahsel/features/shipping_reconciliation/data/services/reconciliation_engine.dart';
import 'package:tahsel/features/shipping_reconciliation/data/services/text_normalization_service.dart';
import 'package:tahsel/features/shipping_reconciliation/domain/entities/column_concept.dart';
import 'package:tahsel/features/shipping_reconciliation/domain/entities/order_reconciliation_item.dart';
import 'package:tahsel/features/shipping_reconciliation/domain/repositories/shipping_reconciliation_repository.dart';

void main() {
  group('TextNormalizationService Tests', () {
    test('Arabic Text Normalization', () {
      expect(TextNormalizationService.normalizeArabicText('أحمد محمدْ'), 'احمد محمد');
      expect(TextNormalizationService.normalizeArabicText('إبراهيم ة ى'), 'ابراهيم ه ي');
    });

    test('Egyptian Phone Normalization', () {
      expect(TextNormalizationService.normalizePhone('+201012345678'), '01012345678');
      expect(TextNormalizationService.normalizePhone('201012345678'), '01012345678');
      expect(TextNormalizationService.normalizePhone('1012345678'), '01012345678');
      expect(TextNormalizationService.normalizePhone('010-1234-5678'), '01012345678');
    });

    test('Currency Parsing', () {
      expect(TextNormalizationService.parseAmount('1,250.50 EGP'), 1250.5);
      expect(TextNormalizationService.parseAmount('ج.م 500'), 500.0);
    });

    test('Shipping Status Classification', () {
      expect(
        TextNormalizationService.classifyShippingStatus('تم التسليم بنجاح'),
        ShippingStatusCategory.delivered,
      );
      expect(
        TextNormalizationService.classifyShippingStatus('Delivered'),
        ShippingStatusCategory.delivered,
      );
      expect(
        TextNormalizationService.classifyShippingStatus('تم الارجاع للمتجر'),
        ShippingStatusCategory.returned,
      );
    });
  });

  group('ColumnDetectorService Tests', () {
    test('Detects Arabic Headers', () {
      final headers = ['كود الطلب', 'اسم العميل', 'رقم الهاتف', 'المبلغ المطلوب'];
      final mapping = ColumnDetectorService.detectMapping(
        fileName: 'test.xlsx',
        rawHeaders: headers,
        sampleRows: [],
        isInternalFile: true,
      );

      expect(mapping.conceptToColumnIndexMap[ColumnConcept.orderNumber], 0);
      expect(mapping.conceptToColumnIndexMap[ColumnConcept.customerName], 1);
      expect(mapping.conceptToColumnIndexMap[ColumnConcept.phone], 2);
      expect(mapping.conceptToColumnIndexMap[ColumnConcept.requiredAmount], 3);
      expect(mapping.isConfident, isTrue);
    });

    test('Detects English Headers', () {
      final headers = ['Order ID', 'Customer Name', 'Mobile', 'Collected Amount', 'Status'];
      final mapping = ColumnDetectorService.detectMapping(
        fileName: 'shipping.csv',
        rawHeaders: headers,
        sampleRows: [],
        isInternalFile: false,
      );

      expect(mapping.conceptToColumnIndexMap[ColumnConcept.orderNumber], 0);
      expect(mapping.conceptToColumnIndexMap[ColumnConcept.customerName], 1);
      expect(mapping.conceptToColumnIndexMap[ColumnConcept.phone], 2);
      expect(mapping.conceptToColumnIndexMap[ColumnConcept.collectedAmount], 3);
      expect(mapping.conceptToColumnIndexMap[ColumnConcept.shippingStatus], 4);
      expect(mapping.isConfident, isTrue);
    });

    test('Detects NMR Express Shipping Headers', () {
      final headers = [
        '#',
        'Code',
        'date',
        'Customer due',
        'Delivered amount',
        'Fees',
        'consignee zone',
        'consignee region',
        'NUM',
        'Recipient name',
        'Status'
      ];
      final mapping = ColumnDetectorService.detectMapping(
        fileName: 'nmr_express.xlsx',
        rawHeaders: headers,
        sampleRows: [],
        isInternalFile: false,
      );

      expect(mapping.conceptToColumnIndexMap[ColumnConcept.orderNumber], 1); // Code
      expect(mapping.conceptToColumnIndexMap[ColumnConcept.expectedAmount], 3); // Customer due
      expect(mapping.conceptToColumnIndexMap[ColumnConcept.collectedAmount], 4); // Delivered amount
      expect(mapping.conceptToColumnIndexMap[ColumnConcept.governorate], 6); // consignee zone
      expect(mapping.conceptToColumnIndexMap[ColumnConcept.address], 7); // consignee region
      expect(mapping.conceptToColumnIndexMap[ColumnConcept.phone], 8); // NUM
      expect(mapping.conceptToColumnIndexMap[ColumnConcept.customerName], 9); // Recipient name
      expect(mapping.conceptToColumnIndexMap[ColumnConcept.shippingStatus], 10); // Status
      expect(mapping.isConfident, isTrue);
    });
  });

  group('ReconciliationEngine Matching Tests', () {
    test('Reconciles Matched, Missing, and Discrepancies', () async {
      final internalFile = RawFileData(
        fileName: 'internal.xlsx',
        headers: ['رقم الطلب', 'اسم العميل', 'الهاتف', 'المبلغ'],
        rows: [
          ['ORD-101', 'أحمد علي', '01012345678', 1000],
          ['ORD-102', 'محمود حسن', '01122334455', 500],
        ],
      );

      final internalMapping = ColumnDetectorService.detectMapping(
        fileName: 'internal.xlsx',
        rawHeaders: internalFile.headers,
        sampleRows: internalFile.rows,
        isInternalFile: true,
      );

      final shippingFile = RawFileData(
        fileName: 'shipping.xlsx',
        headers: ['Order No', 'Customer', 'Phone', 'Collected', 'Status'],
        rows: [
          ['ORD-101', 'احمد علي', '01012345678', 1000, 'تم التسليم'],
          ['ORD-103', 'عميل خارجي', '01200000000', 300, 'تم التسليم'],
        ],
      );

      final shippingMapping = ColumnDetectorService.detectMapping(
        fileName: 'shipping.xlsx',
        rawHeaders: shippingFile.headers,
        sampleRows: shippingFile.rows,
        isInternalFile: false,
      );

      final params = ReconciliationInputParams(
        internalFile: internalFile,
        internalMapping: internalMapping,
        shippingFile: shippingFile,
        shippingMapping: shippingMapping,
      );

      final result = await ReconciliationEngine.reconcileInIsolate(params);

      expect(result.dashboard.totalInternalOrders, 2);
      expect(result.dashboard.totalShippingOrders, 2);
      expect(result.dashboard.matchedOrdersCount, 1);
      expect(result.dashboard.missingFromShippingCount, 1);
      expect(result.dashboard.shippingReportOnlyCount, 1);
      expect(result.dashboard.deliveredCount, 2);
      expect(result.dashboard.fullyCollectedCount, 2);
    });

    test('Reconciles Out-of-Order Rows & Fallback Matching', () async {
      final internalFile = RawFileData(
        fileName: 'internal.xlsx',
        headers: ['رقم الطلب', 'اسم العميل', 'الهاتف', 'المبلغ'],
        rows: [
          ['ORD-1001', 'أحمد محمد علي', '01012345678', 1500],
          ['INT-1005', 'سارة حسن', '01099887766', 300],
          ['ORD-1007', 'خالد عبد الرحمن السعيد', '01011112222', 650],
        ],
      );

      final internalMapping = ColumnDetectorService.detectMapping(
        fileName: 'internal.xlsx',
        rawHeaders: internalFile.headers,
        sampleRows: internalFile.rows,
        isInternalFile: true,
      );

      final shippingFile = RawFileData(
        fileName: 'shipping.xlsx',
        headers: ['Order No', 'Customer', 'Phone', 'Collected', 'Status'],
        rows: [
          // Row 1 corresponds to Row 2 in internal DB (phone match fallback with different order code)
          ['SHP-1005', 'ساره حسن', '01099887766', 300, 'تم التوصيل'],
          // Row 2 corresponds to Row 3 in internal DB (Customer name fallback with phone typo)
          ['ORD-1007', 'خالد عبد الرحمن السعيد', '01011119999', 650, 'تم التوصيل'],
          // Row 3 corresponds to Row 1 in internal DB (Out of order, Arabic normalization & +20 phone format)
          ['ORD-1001', 'احمد محمد على', '+20 10 1234 5678', 1500, 'تم التسليم'],
        ],
      );

      final shippingMapping = ColumnDetectorService.detectMapping(
        fileName: 'shipping.xlsx',
        rawHeaders: shippingFile.headers,
        sampleRows: shippingFile.rows,
        isInternalFile: false,
      );

      final params = ReconciliationInputParams(
        internalFile: internalFile,
        internalMapping: internalMapping,
        shippingFile: shippingFile,
        shippingMapping: shippingMapping,
      );

      final result = await ReconciliationEngine.reconcileInIsolate(params);

      expect(result.dashboard.totalInternalOrders, 3);
      expect(result.dashboard.totalShippingOrders, 3);
      // All 3 matched!
      expect(result.dashboard.matchedOrdersCount + result.dashboard.dataConflictsCount, 3);
      expect(result.dashboard.missingFromShippingCount, 0);
      expect(result.dashboard.shippingReportOnlyCount, 0);
    });
  });
}
