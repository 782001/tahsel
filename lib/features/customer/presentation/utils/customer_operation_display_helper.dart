import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/customer/domain/entities/customer_operation.dart';

extension CustomerOperationDisplay on CustomerOperation {
  /// Detects whether this operation represents a price offer / quotation (عرض سعر)
  bool get isQuotation {
    final act = activityName.toLowerCase().trim();
    final det = (details ?? '').toLowerCase().trim();
    final nts = (notes ?? '').toLowerCase().trim();

    return act.contains('quotation') ||
        act.contains('quote') ||
        act.contains('عرض') ||
        act.contains('سعر') ||
        det.contains('quotation') ||
        det.contains('عرض سعر') ||
        nts.contains('quotation') ||
        nts.contains('عرض سعر');
  }

  /// Detects whether this operation represents a customer surplus settlement (تسوية فائض للعميل)
  /// يعتمد التحقق حصراً على القيمة السالبة (أقل من صفر / تبدأ بـ -)
  bool get isSettlement => amount < 0;

  /// Returns a clean, human-friendly localized title for the operation
  /// completely avoiding raw system database tags like "(shop)" or "(invoice)".
  String get localizedTitle {
    // 1. Priority check for Quotations (عرض سعر)
    if (isQuotation) {
      return AppStrings.invoiceStatusQuotation.tr();
    }

    // 2. Priority check for Customer Surplus Settlement (تسوية فائض للعميل)
    if (isSettlement) {
      return AppStrings.customerSurplusSettlement.tr();
    }

    final act = activityName.toLowerCase().trim();

    switch (type) {
      case CustomerOperationType.payment:
        if (invoiceId != null ||
            act.contains('invoice') ||
            act.contains('فاتور')) {
          return AppStrings.invoicePayment.tr();
        }
        if (act.contains('ps') ||
            act.contains('session') ||
            act.contains('playstation') ||
            act.contains('جلس')) {
          return AppStrings.sessionPayment.tr();
        }
        if (id.contains('cash') ||
            act.contains('cash') ||
            act.contains('نقد')) {
          return AppStrings.instantCashPayment.tr();
        }
        return AppStrings.directPayment.tr();

      case CustomerOperationType.purchase:
        if (invoiceId != null ||
            act.contains('invoice') ||
            act.contains('فاتور')) {
          return AppStrings.salesInvoice.tr();
        }
        if (act.contains('ps') ||
            act.contains('session') ||
            act.contains('playstation') ||
            act.contains('جلس')) {
          return AppStrings.gamingSession.tr();
        }
        if (act == 'shop' ||
            act.contains('cash') ||
            act.contains('sale') ||
            act.contains('محل') ||
            act.contains('مباشر')) {
          return AppStrings.directSale.tr();
        }
        return AppStrings.purchase.tr();

      case CustomerOperationType.debt:
        if (invoiceId != null ||
            act.contains('invoice') ||
            act.contains('فاتور')) {
          return AppStrings.creditInvoice.tr();
        }
        if (act.contains('ps') ||
            act.contains('session') ||
            act.contains('playstation') ||
            act.contains('جلس')) {
          return AppStrings.creditSession.tr();
        }
        if (act == 'shop' ||
            act.contains('محل') ||
            act.contains('مشتري')) {
          return AppStrings.creditPurchase.tr();
        }
        return AppStrings.deferredDebt.tr();

      case CustomerOperationType.quotation:
        return AppStrings.invoiceStatusQuotation.tr();
    }
  }
}
