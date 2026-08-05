import '../../domain/entities/order_reconciliation_item.dart';

class TextNormalizationService {
  TextNormalizationService._();

  /// Removes Arabic diacritics (تنوين، فتحة، ضمة، كسرة، شدة، سكون)
  static String removeArabicDiacritics(String text) {
    final diacriticsRegExp = RegExp(r'[\u064B-\u0652]');
    return text.replaceAll(diacriticsRegExp, '');
  }

  /// Normalizes Arabic characters (Alef, Alef Maksura, Teh Marbuta, Waw/Ya with Hamza)
  static String normalizeArabicText(String text) {
    String normalized = removeArabicDiacritics(text);
    normalized = normalized.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
    normalized = normalized.replaceAll('ى', 'ي');
    normalized = normalized.replaceAll('ة', 'ه');
    normalized = normalized.replaceAll('ؤ', 'و');
    normalized = normalized.replaceAll('ئ', 'ي');
    return normalized;
  }

  /// Normalizes general text for matching (trimming, collapse spaces, lowercase, Arabic normalization)
  static String normalizeForMatching(String? text) {
    if (text == null || text.trim().isEmpty) return '';
    String result = text.trim();
    result = normalizeArabicText(result);
    // Remove punctuation except alphanumeric characters and spaces
    result = result.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ');
    // Collapse multiple whitespace
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    return result;
  }

  /// Normalizes phone numbers (handles Egyptian prefixes +20, 20, 0020, missing leading 0, and multiple phones)
  static String normalizePhone(String? phoneInput) {
    if (phoneInput == null || phoneInput.trim().isEmpty) return '';

    // Split multiple phone numbers if separated by delimiters like / - , ; space
    final parts = phoneInput.split(RegExp(r'[\/\-,\s;]'));
    for (final part in parts) {
      final norm = _normalizeSinglePhone(part);
      if (norm.isNotEmpty && norm.length >= 10) {
        return norm;
      }
    }

    return _normalizeSinglePhone(phoneInput);
  }

  static String _normalizeSinglePhone(String phoneInput) {
    // Extract only digits
    String digitsOnly = phoneInput.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return '';

    // Handle international prefixes for Egypt
    if (digitsOnly.startsWith('0020')) {
      digitsOnly = digitsOnly.substring(4);
    } else if (digitsOnly.startsWith('20') && digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(2);
    }

    // Add leading zero if Egyptian mobile number (e.g. 10xxxxxxxx -> 010xxxxxxxx)
    if (digitsOnly.length == 10 &&
        (digitsOnly.startsWith('10') ||
            digitsOnly.startsWith('11') ||
            digitsOnly.startsWith('12') ||
            digitsOnly.startsWith('15'))) {
      digitsOnly = '0$digitsOnly';
    }

    return digitsOnly;
  }

  /// Safely parses doubles from dynamic Excel/CSV cell values
  static double parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();

    String str = value.toString().trim();
    if (str.isEmpty) return 0.0;

    // Remove commas, currency text like LE, EGP, ج.م, جنيه
    str = str.replaceAll(',', '');
    final match = RegExp(r'\d+(\.\d+)?').firstMatch(str);
    if (match != null) {
      return double.tryParse(match.group(0)!) ?? 0.0;
    }
    return 0.0;
  }

  /// Classifies shipping status text into standardized enum
  static ShippingStatusCategory classifyShippingStatus(String? rawStatus) {
    if (rawStatus == null || rawStatus.trim().isEmpty) {
      return ShippingStatusCategory.unknown;
    }

    final norm = normalizeForMatching(rawStatus);

    if (norm.contains('تسليم') ||
        norm.contains('تم التوصيل') ||
        norm.contains('وصلت') ||
        norm.contains('delivered') ||
        norm.contains('completed') ||
        norm.contains('تم الاستلام')) {
      return ShippingStatusCategory.delivered;
    }

    if (norm.contains('ارتجاع') ||
        norm.contains('مرتجع') ||
        norm.contains('ارجاع') ||
        norm.contains('ارداع') ||
        norm.contains('مرفوض') ||
        norm.contains('returned') ||
        norm.contains('refused') ||
        norm.contains('cancelled') ||
        norm.contains('ملغي')) {
      return ShippingStatusCategory.returned;
    }

    if (norm.contains('جاري') ||
        norm.contains('في الطريق') ||
        norm.contains('قيد التوصيل') ||
        norm.contains('out for delivery') ||
        norm.contains('dispatched') ||
        norm.contains('المندوب')) {
      return ShippingStatusCategory.outForDelivery;
    }

    if (norm.contains('شحن') ||
        norm.contains('shipped') ||
        norm.contains('transit') ||
        norm.contains('المستودع') ||
        norm.contains('الفرع')) {
      return ShippingStatusCategory.shipped;
    }

    if (norm.contains('فشل') ||
        norm.contains('مغلق') ||
        norm.contains('لم يرد') ||
        norm.contains('failed') ||
        norm.contains('unreachable')) {
      return ShippingStatusCategory.failedDelivery;
    }

    if (norm.contains('لم يتم') || norm.contains('not shipped') || norm.contains('جديد')) {
      return ShippingStatusCategory.notShipped;
    }

    return ShippingStatusCategory.unknown;
  }

  /// Classifies collection status based on required vs collected amounts
  static CollectionStatusCategory classifyCollectionStatus({
    required double requiredAmount,
    required double collectedAmount,
    String? rawCollectionStatusText,
  }) {
    if (collectedAmount == 0.0) {
      return CollectionStatusCategory.notCollected;
    }

    final diff = (collectedAmount - requiredAmount).abs();
    if (diff < 0.01) {
      return CollectionStatusCategory.fullyCollected;
    }

    if (collectedAmount < requiredAmount) {
      return CollectionStatusCategory.partiallyCollected;
    }

    if (collectedAmount > requiredAmount) {
      return CollectionStatusCategory.overCollected;
    }

    return CollectionStatusCategory.amountMismatch;
  }

  /// Classifies return destination based on text/notes
  static ReturnDestinationCategory classifyReturnDestination({
    required ShippingStatusCategory shippingStatus,
    String? rawStatusText,
    String? notesText,
  }) {
    if (shippingStatus != ShippingStatusCategory.returned) {
      return ReturnDestinationCategory.none;
    }

    final combined = normalizeForMatching(
      '${rawStatusText ?? ""} ${notesText ?? ""}',
    );

    if (combined.contains('الراسل') ||
        combined.contains('المتجر') ||
        combined.contains('التاجر') ||
        combined.contains('returned to store') ||
        combined.contains('merchant') ||
        combined.contains('مخزننا')) {
      return ReturnDestinationCategory.returnedToStore;
    }

    if (combined.contains('شركة الشحن') ||
        combined.contains('المخزن الرئيسي') ||
        combined.contains('في الفرع') ||
        combined.contains('hub') ||
        combined.contains('shipping co')) {
      return ReturnDestinationCategory.returnedToShippingCompany;
    }

    return ReturnDestinationCategory.destinationUnknown;
  }
}
