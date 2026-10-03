import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/extensions/extensions.dart';

class ActivityFieldLocalizer {
  ActivityFieldLocalizer._();

  static String localizeKey(BuildContext context, String key) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    switch (key) {
      // ── المبالغ والأسعار / Amounts & Prices ──
      case 'amount':
        return isArabic ? 'المبلغ' : 'Amount';
      case 'oldAmount':
      case 'previousAmount':
        return isArabic ? 'المبلغ السابق' : 'Previous Amount';
      case 'newAmount':
        return isArabic ? 'المبلغ الجديد' : 'New Amount';
      case 'delta':
        return isArabic ? 'الفارق' : 'Difference';
      case 'total':
      case 'totalAmount':
        return isArabic ? 'المبلغ الإجمالي' : 'Total Amount';
      case 'paid':
      case 'paidAmount':
      case 'amountPaid':
        return isArabic ? 'المبلغ المدفوع' : 'Amount Paid';
      case 'remaining':
      case 'remainingAmount':
      case 'remainingDebt':
        return isArabic ? 'المتبقي كدين' : 'Remaining Debt';
      case 'oldTotal':
        return isArabic ? 'الإجمالي السابق' : 'Previous Total';
      case 'newTotal':
        return isArabic ? 'الإجمالي الجديد' : 'New Total';
      case 'deletedAmount':
        return isArabic ? 'المبلغ المحذوف' : 'Deleted Amount';
      case 'totalAmountRemoved':
        return isArabic ? 'إجمالي المحذوف' : 'Total Removed';
      case 'totalSettled':
        return isArabic ? 'إجمالي المسدد' : 'Total Settled';
      case 'creditAmount':
        return isArabic ? 'مبلغ الدين' : 'Debt Amount';
      case 'carriedForwardBalance':
        return isArabic ? 'الرصيد المرحل' : 'Carried Forward Balance';
      case 'currentBalance':
        return isArabic ? 'الرصيد الحالي' : 'Current Balance';
      case 'sellingPrice':
        return isArabic ? 'سعر البيع' : 'Selling Price';
      case 'purchasePrice':
        return isArabic ? 'سعر الشراء' : 'Purchase Price';
      case 'oldSellingPrice':
        return isArabic ? 'سعر البيع السابق' : 'Previous Selling Price';
      case 'newSellingPrice':
        return isArabic ? 'سعر البيع الجديد' : 'New Selling Price';
      case 'oldPurchasePrice':
        return isArabic ? 'سعر الشراء السابق' : 'Previous Purchase Price';
      case 'newPurchasePrice':
        return isArabic ? 'سعر الشراء الجديد' : 'New Purchase Price';
      case 'sellingPriceDelta':
      case 'sellPriceDiff':
      case 'sellDiff':
        return isArabic ? 'فارق سعر البيع' : 'Selling Price Diff';
      case 'purchasePriceDelta':
      case 'purPriceDiff':
      case 'purDiff':
        return isArabic ? 'فارق سعر الشراء' : 'Purchase Price Diff';
      case 'priceDelta':
      case 'priceDiff':
        return isArabic ? 'فارق السعر' : 'Price Difference';
      case 'amountDelta':
      case 'amountDiff':
        return isArabic ? 'فارق المبلغ' : 'Amount Difference';
      case 'totalDelta':
      case 'totalDiff':
        return isArabic ? 'فارق الإجمالي' : 'Total Difference';
      case 'paidDelta':
      case 'paidDiff':
        return isArabic ? 'فارق المدفوع' : 'Paid Difference';
      case 'remainingDelta':
      case 'remainingDiff':
        return isArabic ? 'فارق المتبقي' : 'Remaining Difference';
      case 'debtDelta':
        return isArabic ? 'فارق الدين' : 'Debt Difference';
      case 'balanceDelta':
        return isArabic ? 'فارق الرصيد' : 'Balance Difference';
      case 'oldPaid':
        return isArabic ? 'المدفوع السابق' : 'Previous Paid';
      case 'newPaid':
        return isArabic ? 'المدفوع الجديد' : 'New Paid';
      case 'oldRemaining':
        return isArabic ? 'المتبقي السابق' : 'Previous Remaining';
      case 'newRemaining':
        return isArabic ? 'المتبقي الجديد' : 'New Remaining';
      case 'oldPrice':
        return isArabic ? 'السعر السابق' : 'Previous Price';
      case 'newPrice':
        return isArabic ? 'السعر الجديد' : 'New Price';
      case 'discount':
      case 'discountAmount':
        return isArabic ? 'الخصم' : 'Discount';
      case 'discountRate':
      case 'discountPercent':
        return isArabic ? 'نسبة الخصم' : 'Discount %';
      case 'cost':
      case 'costPrice':
      case 'totalCost':
        return isArabic ? 'التكلفة' : 'Cost';
      case 'profit':
      case 'netProfit':
        return isArabic ? 'الربح' : 'Profit';
      case 'rate':
        return isArabic ? 'سعر الساعة' : 'Hourly Rate';

      // ── الكميات والأعداد / Quantities & Counts ──
      case 'quantity':
        return isArabic ? 'الكمية' : 'Quantity';
      case 'prevQuantity':
      case 'previousQuantity':
      case 'oldQty':
        return isArabic ? 'الكمية السابقة' : 'Previous Quantity';
      case 'newQuantity':
      case 'newQty':
        return isArabic ? 'الكمية الجديدة' : 'New Quantity';
      case 'quantityDelta':
      case 'qtyDelta':
      case 'qtyDiff':
      case 'stockDelta':
        return isArabic ? 'فارق الكمية' : 'Quantity Difference';
      case 'minQuantity':
      case 'minStock':
      case 'alertQuantity':
        return isArabic ? 'حد الطلب / الإنذار' : 'Reorder / Alert Level';
      case 'adjustmentQuantity':
        return isArabic ? 'كمية التسوية' : 'Adjustment Quantity';
      case 'itemsCount':
      case 'itemCount':
        return isArabic ? 'عدد الأصناف' : 'Items Count';
      case 'changesCount':
        return isArabic ? 'عدد التعديلات' : 'Changes Count';
      case 'transactionsCount':
        return isArabic ? 'عدد الحركات' : 'Transactions Count';
      case 'operationsCount':
        return isArabic ? 'عدد العمليات' : 'Operations Count';
      case 'debtsCount':
        return isArabic ? 'عدد الديون' : 'Debts Count';
      case 'advancesCount':
        return isArabic ? 'عدد السلف' : 'Advances Count';
      case 'count':
        return isArabic ? 'العدد الإجمالي' : 'Total Count';

      // ── الأسماء والأطراف / Names & Parties ──
      case 'customerName':
        return isArabic ? 'اسم العميل' : 'Customer Name';
      case 'supplierName':
      case 'supplier':
        return isArabic ? 'اسم المورد' : 'Supplier Name';
      case 'personName':
        return isArabic ? 'اسم الطرف / المورد' : 'Party / Supplier Name';
      case 'productName':
        return isArabic ? 'اسم الصنف' : 'Product Name';
      case 'employeeName':
        return isArabic ? 'اسم الموظف' : 'Employee Name';
      case 'fullName':
        return isArabic ? 'الاسم الكامل' : 'Full Name';
      case 'name':
        return isArabic ? 'الاسم' : 'Name';
      case 'oldName':
        return isArabic ? 'الاسم السابق' : 'Previous Name';
      case 'projectName':
        return isArabic ? 'اسم النشاط' : 'Business Name';

      // ── بيانات الاتصال والمنشأة / Contact & Business ──
      case 'phone':
      case 'phoneNumber':
        return isArabic ? 'رقم الهاتف' : 'Phone Number';
      case 'oldPhone':
        return isArabic ? 'الهاتف السابق' : 'Previous Phone';
      case 'email':
        return isArabic ? 'البريد الإلكتروني' : 'Email';
      case 'address':
        return isArabic ? 'العنوان' : 'Address';
      case 'crn':
      case 'commercialRegistration':
        return isArabic ? 'السجل التجاري' : 'Commercial Reg.';
      case 'vat':
      case 'taxNumber':
        return isArabic ? 'الرقم الضريبي' : 'Tax / VAT Number';
      case 'taxRate':
        return isArabic ? 'نسبة الضريبة' : 'Tax Rate %';
      case 'ledgerNumber':
        return isArabic ? 'رقم الدفتر' : 'Ledger Page';
      case 'referenceNumber':
        return isArabic ? 'الرقم المرجعي' : 'Reference Number';

      // ── المعرفات IDs ──
      case 'productId':
        return isArabic ? 'معرف الصنف' : 'Product ID';
      case 'customerId':
        return isArabic ? 'معرف العميل' : 'Customer ID';
      case 'supplierId':
        return isArabic ? 'معرف المورد' : 'Supplier ID';
      case 'categoryId':
        return isArabic ? 'معرف التصنيف' : 'Category ID';
      case 'employeeId':
        return isArabic ? 'معرف الموظف' : 'Employee ID';
      case 'employeeAuthUid':
        return isArabic ? 'معرف حساب الموظف' : 'Employee Account UID';
      case 'invoiceId':
        return isArabic ? 'معرف الفاتورة' : 'Invoice ID';
      case 'purchaseId':
        return isArabic ? 'معرف فاتورة الشراء' : 'Purchase ID';
      case 'debtId':
        return isArabic ? 'معرف الدين' : 'Debt ID';
      case 'paymentId':
        return isArabic ? 'معرف الدفعة' : 'Payment ID';
      case 'operationId':
        return isArabic ? 'معرف العملية' : 'Operation ID';
      case 'sessionId':
        return isArabic ? 'معرف الجلسة' : 'Session ID';
      case 'transactionId':
        return isArabic ? 'معرف الحركة' : 'Transaction ID';
      case 'attendanceId':
        return isArabic ? 'معرف سجل الحضور' : 'Attendance ID';
      case 'payrollId':
        return isArabic ? 'معرف مسير الرواتب' : 'Payroll ID';
      case 'advanceId':
        return isArabic ? 'معرف السلفة' : 'Advance ID';
      case 'advanceIds':
        return isArabic ? 'معرفات السلف' : 'Advance IDs';
      case 'expenseId':
        return isArabic ? 'معرف المصروف' : 'Expense ID';
      case 'recordId':
        return isArabic ? 'معرف السجل' : 'Record ID';
      case 'remindedDebtIds':
        return isArabic ? 'معرفات الديون للتذكير' : 'Reminded Debt IDs';
      case 'deviceId':
        return isArabic ? 'معرف الجهاز' : 'Device ID';
      case 'roomId':
        return isArabic ? 'الغرفة' : 'Room';

      // ── شؤون الموظفين والرواتب / HR & Payroll ──
      case 'jobTitle':
        return isArabic ? 'المسمى الوظيفي' : 'Job Title';
      case 'rolePreset':
        return isArabic ? 'الدور الوظيفي' : 'Role';
      case 'permissionsCount':
        return isArabic ? 'عدد الصلاحيات' : 'Permissions Count';
      case 'baseSalary':
        return isArabic ? 'الراتب الأساسي' : 'Base Salary';
      case 'netSalary':
        return isArabic ? 'صافي الراتب' : 'Net Salary';
      case 'salaryType':
        return isArabic ? 'نوع الراتب' : 'Salary Type';
      case 'advancesDeducted':
        return isArabic ? 'السلف المخصومة' : 'Deducted Advances';
      case 'deductionsTotal':
        return isArabic ? 'إجمالي الاستقطاعات' : 'Total Deductions';
      case 'overtimeCompensation':
        return isArabic ? 'مكافأة الإضافي' : 'Overtime Pay';
      case 'overtimeHours':
        return isArabic ? 'ساعات الإضافي' : 'Overtime Hours';
      case 'deductionHours':
        return isArabic ? 'ساعات الخصم' : 'Deduction Hours';
      case 'lateMinutes':
        return isArabic ? 'دقائق التأخير' : 'Late Minutes';
      case 'monthKey':
        return isArabic ? 'الشهر' : 'Month';
      case 'checkIn':
        return isArabic ? 'وقت الحضور' : 'Check-in Time';
      case 'checkOut':
        return isArabic ? 'وقت الانصراف' : 'Check-out Time';

      // ── الحالات والأنواع / Statuses & Types ──
      case 'status':
        return isArabic ? 'الحالة' : 'Status';
      case 'statusLabel':
        return isArabic ? 'بيان الحالة' : 'Status Label';
      case 'newStatus':
        return isArabic ? 'الحالة الجديدة' : 'New Status';
      case 'type':
        return isArabic ? 'النوع' : 'Type';
      case 'subType':
        return isArabic ? 'نوع الجلسة' : 'Session Subtype';
      case 'category':
        return isArabic ? 'التصنيف' : 'Category';
      case 'paymentType':
        return isArabic ? 'نوع الدفعة' : 'Payment Type';
      case 'paymentMethod':
        return isArabic ? 'طريقة الدفع' : 'Payment Method';
      case 'action':
        return isArabic ? 'نوع الإجراء' : 'Action Type';
      case 'source':
        return isArabic ? 'المصدر' : 'Source';
      case 'sourceFilter':
        return isArabic ? 'فلتر الحركات' : 'Source Filter';
      case 'direction':
        return isArabic ? 'اتجاه الحركة' : 'Movement Direction';
      case 'isQuotation':
      case 'quotation':
        return isArabic ? 'عرض سعر' : 'Quotation';
      case 'isPurchase':
        return isArabic ? 'فاتورة شراء' : 'Purchase Invoice';
      case 'isFull':
        return isArabic ? 'سداد كامل' : 'Full Payment';
      case 'isFullySettled':
        return isArabic ? 'حالة السداد' : 'Settlement Status';
      case 'hasDebt':
        return isArabic ? 'تتضمن مديونية' : 'Includes Debt';
      case 'isAvailable':
        return isArabic ? 'حالة التوفر' : 'Availability';
      case 'oldStatus':
        return isArabic ? 'الحالة السابقة' : 'Previous Status';
      case 'oldCategory':
        return isArabic ? 'التصنيف السابق' : 'Previous Category';
      case 'newCategory':
        return isArabic ? 'التصنيف الجديد' : 'New Category';
      case 'oldSupplier':
        return isArabic ? 'المورد السابق' : 'Previous Supplier';
      case 'newSupplier':
        return isArabic ? 'المورد الجديد' : 'New Supplier';
      case 'oldCustomer':
        return isArabic ? 'العميل السابق' : 'Previous Customer';
      case 'newCustomer':
        return isArabic ? 'العميل الجديد' : 'New Customer';
      case 'barcode':
        return isArabic ? 'الباركود' : 'Barcode';
      case 'oldBarcode':
        return isArabic ? 'الباركود السابق' : 'Previous Barcode';
      case 'newBarcode':
        return isArabic ? 'الباركود الجديد' : 'New Barcode';
      case 'unit':
        return isArabic ? 'الوحدة' : 'Unit';
      case 'oldUnit':
        return isArabic ? 'الوحدة السابقة' : 'Previous Unit';
      case 'newUnit':
        return isArabic ? 'الوحدة الجديدة' : 'New Unit';
      case 'bank':
      case 'bankAccount':
        return isArabic ? 'الحساب البنكي' : 'Bank Account';
      case 'checkNumber':
        return isArabic ? 'رقم الشيك' : 'Check Number';

      // ── التفاصيل والبيانات العامة / General Details ──
      case 'details':
        return isArabic ? 'التفاصيل' : 'Details';
      case 'description':
        return isArabic ? 'البيان' : 'Description';
      case 'reason':
        return isArabic ? 'السبب' : 'Reason';
      case 'notes':
      case 'note':
        return isArabic ? 'الملاحظات' : 'Notes';
      case 'date':
      case 'paymentDate':
        return isArabic ? 'التاريخ' : 'Date';
      case 'period':
        return isArabic ? 'الفترة المحددة' : 'Period';
      case 'durationMinutes':
        return isArabic ? 'مدة الجلسة (دقائق)' : 'Duration (mins)';
      case 'totalDebt':
        return isArabic ? 'إجمالي الدين' : 'Total Debt';
      case 'filePath':
        return isArabic ? 'مسار الملف' : 'File Path';
      case 'collection':
        return isArabic ? 'مجموعة السجلات' : 'Collection';

      default:
        return key;
    }
  }

  static String formatRole(String role) {
    switch (role.toLowerCase()) {
      case 'cashier':
        return AppStrings.roleCashierLabel.tr();
      case 'accountant':
        return AppStrings.roleAccountantLabel.tr();
      case 'supervisor':
      case 'manager':
        return AppStrings.roleSupervisorLabel.tr();
      case 'storekeeper':
        return AppStrings.roleStorekeeperLabel.tr();
      default:
        return AppStrings.roleCustomLabel.tr();
    }
  }
}
