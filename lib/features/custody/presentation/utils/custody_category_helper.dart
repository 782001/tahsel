import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/custody/domain/entities/custody_expense_item.dart';

class CustodyCategoryHelper {
  /// Returns a properly localized category name for display in UI or PDF.
  static String getLocalizedCategoryName(String rawCategory, {bool? isArabic}) {
    final trimmed = rawCategory.trim();
    final lower = trimmed.toLowerCase();
    final isAr = isArabic ?? (AppStrings.currentLang == 'ar');

    if (lower == 'purchases' ||
        lower == 'custody_category_purchases' ||
        trimmed == 'مشتريات' ||
        lower == 'purchase') {
      return isAr ? 'مشتريات' : 'Purchases';
    }
    if (lower == 'expenses' ||
        lower == 'custody_category_expenses' ||
        trimmed == 'مصروفات تشغيلية' ||
        trimmed == 'مصروفات' ||
        trimmed == 'المصاريف' ||
        lower == 'operating expenses' ||
        lower == 'expense') {
      return isAr ? 'مصروفات تشغيلية' : 'Operating Expenses';
    }
    if (lower == 'change_return' ||
        lower == 'custody_category_change_return' ||
        trimmed == 'رد باقي / فكة' ||
        trimmed == 'إرجاع بواقي / فكة' ||
        lower == 'change return' ||
        lower == 'change return / float') {
      return isAr ? 'رد باقي / فكة' : 'Change Return / Float';
    }
    if (lower == 'emergency' ||
        lower == 'custody_category_emergency' ||
        trimmed == 'مصروفات طارئة' ||
        trimmed == 'طوارئ ونثريات' ||
        lower == 'emergency expenses' ||
        lower == 'emergency & misc') {
      return isAr ? 'مصروفات طارئة' : 'Emergency Expenses';
    }
    if (lower == 'other' ||
        lower == 'custody_category_other' ||
        trimmed == 'أخرى' ||
        lower == 'other') {
      return isAr ? 'أخرى' : 'Other';
    }
    if (lower == 'debt_payment' ||
        lower == 'my_debts' ||
        lower == 'debt' ||
        trimmed == 'سداد ديون' ||
        trimmed == 'سداد دين' ||
        lower == 'debt payment') {
      return isAr ? 'سداد ديون' : 'Debt Payment';
    }
    return trimmed;
  }

  /// Tries to map an English machine key (e.g., 'expenses', 'emergency') to its localized name.
  /// Returns null if [raw] is custom user text.
  static String? tryMapCategoryKeyToLocalized(String raw, {bool? isArabic}) {
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();
    final isAr = isArabic ?? (AppStrings.currentLang == 'ar');

    if (lower == 'purchases' || lower == 'custody_category_purchases') {
      return isAr ? 'مشتريات' : 'Purchases';
    }
    if (lower == 'expenses' || lower == 'custody_category_expenses') {
      return isAr ? 'مصروفات تشغيلية' : 'Operating Expenses';
    }
    if (lower == 'change_return' || lower == 'custody_category_change_return') {
      return isAr ? 'رد باقي / فكة' : 'Change Return / Float';
    }
    if (lower == 'emergency' || lower == 'custody_category_emergency') {
      return isAr ? 'مصروفات طارئة' : 'Emergency Expenses';
    }
    if (lower == 'other' || lower == 'custody_category_other') {
      return isAr ? 'أخرى' : 'Other';
    }
    if (lower == 'debt_payment' || lower == 'my_debts' || lower == 'debt') {
      return isAr ? 'سداد ديون' : 'Debt Payment';
    }
    if (lower == 'deficit_settlement_expense' ||
        trimmed == 'عجز تسوية' ||
        lower == 'settlement deficit') {
      return isAr ? 'عجز تسوية' : 'Settlement Deficit';
    }
    return null;
  }

  /// Determines the primary display title for a custody expense item.
  /// Translates machine keys dynamically even if stored previously in English.
  static String getExpenseDisplayTitle(CustodyExpenseItem item, {bool? isArabic}) {
    String desc = item.description.trim();
    if (desc.isNotEmpty) {
      desc = desc
          .replaceAll('(purchase_items_count)', '')
          .replaceAll('purchase_items_count', '')
          .replaceAll(RegExp(r'\(\s*\)'), '')
          .trim();

      final mapped = tryMapCategoryKeyToLocalized(desc, isArabic: isArabic);
      if (mapped != null) {
        return mapped;
      }
      if (desc.isNotEmpty) {
        return desc;
      }
    }
    return getLocalizedCategoryName(item.category, isArabic: isArabic);
  }

  /// Checks if an expense item represents an inventory purchase.
  static bool isPurchase(CustodyExpenseItem item) {
    if (item.id.startsWith('cust_exp_pur_') || item.id.startsWith('pur_')) {
      return true;
    }
    final lower = item.category.trim().toLowerCase();
    return lower == 'purchases' ||
        lower == 'custody_category_purchases' ||
        item.category.trim() == 'مشتريات';
  }
}

extension CustodyExpenseItemPresentationX on CustodyExpenseItem {
  String get displayTitle => CustodyCategoryHelper.getExpenseDisplayTitle(this);
  String get displayCategory =>
      CustodyCategoryHelper.getLocalizedCategoryName(category);
  bool get isPurchaseItem => CustodyCategoryHelper.isPurchase(this);
}
