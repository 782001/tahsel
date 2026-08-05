// ignore_for_file: avoid_print

import 'dart:io';
import 'package:excel/excel.dart';

void main() {
  print('Creating advanced edge cases test files in F:\\myApps\\tahsel...');

  // 1. Internal DB Data
  final internalHeaders = [
    'كود الطلب',
    'اسم العميل',
    'رقم الهاتف',
    'المبلغ المطلوب',
    'المنتج',
    'المحافظة',
    'التاريخ'
  ];

  final internalRows = [
    // Case 1: Standard Matched Order (out of order in shipping)
    ['ORD-1001', 'أحمد محمد علي', '01012345678', '1500.0', 'ساعة ذكية', 'القاهرة', '2026-08-01'],
    
    // Case 2: Arabic Name variations & phone +20 (out of order in shipping)
    ['ORD-1002', 'إبراهيم مصطفى القاضي', '01122334455', '850.50 LE', 'حذاء رياضي', 'الجيزة', '2026-08-01'],
    
    // Case 3: Partial collection (Required 500, Collected 350)
    ['ORD-1003', 'فاطمة محمود', '01298765432', '500.00 ج.م', 'حقيبة يد', 'الإسكندرية', '2026-08-02'],
    
    // Case 4: Order in Internal DB ONLY (Missing from shipping report)
    ['ORD-1004', 'محمود عبد العزيز', '01511223344', '1200.0', 'شاحن سريع', 'طنطا', '2026-08-02'],
    
    // Case 5: Phone match fallback (Order number formatted differently: INT-1005 vs SHP-1005)
    ['INT-1005', 'سارة حسن', '01099887766', '300.0', 'سماعة بلاستيك', 'المنصورة', '2026-08-03'],
    
    // Case 6: Duplicate handling in Shipping Report
    ['ORD-1006', 'علي حسن', '01144556677', '450.0', 'نظارة شمسية', 'الزقازيق', '2026-08-03'],
    
    // Case 7: Customer Name fallback match (Phone has typo: 01011112222 vs 01011119999)
    ['ORD-1007', 'خالد عبد الرحمن السعيد', '01011112222', '650.0', 'قميص قطني', 'أسيوط', '2026-08-04'],
  ];

  // 2. Shipping Report Data (Intentionally OUT OF ORDER & containing edge cases)
  final shippingHeaders = [
    'رقم الشحنة / الطلب',
    'العميل',
    'موبايل العميل',
    'المبلغ المتوقع',
    'المبلغ المحصل',
    'حالة التوصيل',
    'حالة التحصيل'
  ];

  final shippingRows = [
    // Row 1 (Corresponds to Internal Case 3: Partial collection, phone format 1298765432 without leading 0)
    ['#1003', 'فاطمه محمود', '1298765432', '500.0', '350.0', 'تم التسليم', 'تحصيل جزئي'],
    
    // Row 2 (Shipping Report ONLY - Not in Internal DB)
    ['SHP-9999', 'عميل غير مسجل بالمتجر', '01000009999', '900.0', '900.0', 'تم التوصيل', 'تم التحصيل'],
    
    // Row 3 (Corresponds to Internal Case 2: Out of order, +20 phone format, Arabic name norm: ابراهيم مصطفي القاضي)
    ['1002', 'ابراهيم مصطفي القاضي', '+20 11 2233 4455', '850.5', '850.5', 'تم الاستلام بنجاح', 'مكتمل'],
    
    // Row 4 (Corresponds to Internal Case 6: FIRST entry for duplicate ORD-1006)
    ['ORD-1006', 'علي حسن', '01144556677', '450.0', '450.0', 'تم التسليم', 'مكتمل'],
    
    // Row 5 (Corresponds to Internal Case 6: SECOND entry for duplicate ORD-1006)
    ['ORD-1006', 'علي حسن', '01144556677', '450.0', '0.0', 'مرتجع للراسل', 'لم يحصل'],
    
    // Row 6 (Corresponds to Internal Case 1: Out of order, Arabic name norm: احمد محمد على)
    ['ORD-1001', 'احمد محمد على', '01012345678', '١٥٠٠.٠', '١٥٠٠.٠', 'تم التسليم بنجاح', 'تم التحصيل'],
    
    // Row 7 (Corresponds to Internal Case 5: Phone match fallback with different order code SHP-1005)
    ['SHP-1005', 'ساره حسن', '01099887766', '300.0', '300.0', 'تم التوصيل', 'تم التحصيل'],
    
    // Row 8 (Corresponds to Internal Case 7: Customer Name fallback with typo in phone)
    ['ORD-1007', 'خالد عبد الرحمن السعيد', '01011119999', '650.0', '650.0', 'تم التوصيل', 'تم التحصيل'],
  ];

  // Write Excel Files
  _createExcelFile('F:\\myApps\\tahsel\\test_edge_cases_internal.xlsx', internalHeaders, internalRows);
  _createExcelFile('F:\\myApps\\tahsel\\test_edge_cases_shipping.xlsx', shippingHeaders, shippingRows);

  // Write CSV Files
  _createCsvFile('F:\\myApps\\tahsel\\test_edge_cases_internal.csv', internalHeaders, internalRows);
  _createCsvFile('F:\\myApps\\tahsel\\test_edge_cases_shipping.csv', shippingHeaders, shippingRows);

  print('Successfully generated edge cases test files!');
}

void _createExcelFile(String filePath, List<String> headers, List<List<dynamic>> rows) {
  var excel = Excel.createExcel();
  Sheet sheetObject = excel['Sheet1'];
  excel.setDefaultSheet('Sheet1');

  sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());
  for (var row in rows) {
    sheetObject.appendRow(row.map((e) => TextCellValue(e.toString())).toList());
  }

  var fileBytes = excel.save();
  if (fileBytes != null) {
    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes);
    print('Generated: $filePath');
  }
}

void _createCsvFile(String filePath, List<String> headers, List<List<dynamic>> rows) {
  final buffer = StringBuffer();
  buffer.writeln(headers.map((e) => '"$e"').join(','));
  for (var row in rows) {
    buffer.writeln(row.map((e) => '"${e.toString()}"').join(','));
  }
  File(filePath)
    ..createSync(recursive: true)
    ..writeAsStringSync(buffer.toString());
  print('Generated: $filePath');
}
