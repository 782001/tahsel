import '../domain/entities/currency_entity.dart';

abstract class WorldCurrencies {
  static const List<CurrencyEntity> allCurrencies = [
    // --- Arab World Currencies ---
    CurrencyEntity(
      code: 'EGP',
      arabicName: 'جنيه مصري',
      englishName: 'Egyptian Pound',
      arabicSymbol: 'ج.م',
      englishSymbol: 'EGP',
    ),
    CurrencyEntity(
      code: 'SAR',
      arabicName: 'ريال سعودي',
      englishName: 'Saudi Riyal',
      arabicSymbol: 'ر.س',
      englishSymbol: 'SAR',
    ),
    CurrencyEntity(
      code: 'AED',
      arabicName: 'درهم إماراتي',
      englishName: 'UAE Dirham',
      arabicSymbol: 'د.إ',
      englishSymbol: 'AED',
    ),
    CurrencyEntity(
      code: 'KWD',
      arabicName: 'دينار كويتي',
      englishName: 'Kuwaiti Dinar',
      arabicSymbol: 'د.ك',
      englishSymbol: 'KWD',
    ),
    CurrencyEntity(
      code: 'QAR',
      arabicName: 'ريال قطري',
      englishName: 'Qatari Riyal',
      arabicSymbol: 'ر.ق',
      englishSymbol: 'QAR',
    ),
    CurrencyEntity(
      code: 'BHD',
      arabicName: 'دينار بحريني',
      englishName: 'Bahraini Dinar',
      arabicSymbol: 'د.ب',
      englishSymbol: 'BHD',
    ),
    CurrencyEntity(
      code: 'OMR',
      arabicName: 'ريال عماني',
      englishName: 'Omani Rial',
      arabicSymbol: 'ر.ع',
      englishSymbol: 'OMR',
    ),
    CurrencyEntity(
      code: 'JOD',
      arabicName: 'دينار أردني',
      englishName: 'Jordanian Dinar',
      arabicSymbol: 'د.أ',
      englishSymbol: 'JOD',
    ),
    CurrencyEntity(
      code: 'IQD',
      arabicName: 'دينار عراقي',
      englishName: 'Iraqi Dinar',
      arabicSymbol: 'د.ع',
      englishSymbol: 'IQD',
    ),
    CurrencyEntity(
      code: 'LYD',
      arabicName: 'دينار ليبي',
      englishName: 'Libyan Dinar',
      arabicSymbol: 'د.ل',
      englishSymbol: 'LYD',
    ),
    CurrencyEntity(
      code: 'DZD',
      arabicName: 'دينار جزائري',
      englishName: 'Algerian Dinar',
      arabicSymbol: 'د.ج',
      englishSymbol: 'DZD',
    ),
    CurrencyEntity(
      code: 'MAD',
      arabicName: 'درهم مغربي',
      englishName: 'Moroccan Dirham',
      arabicSymbol: 'د.م',
      englishSymbol: 'MAD',
    ),
    CurrencyEntity(
      code: 'TND',
      arabicName: 'دينار تونسي',
      englishName: 'Tunisian Dinar',
      arabicSymbol: 'د.ت',
      englishSymbol: 'TND',
    ),
    CurrencyEntity(
      code: 'LBP',
      arabicName: 'ليرة لبنانية',
      englishName: 'Lebanese Pound',
      arabicSymbol: 'ل.ل',
      englishSymbol: 'LBP',
    ),
    CurrencyEntity(
      code: 'SYP',
      arabicName: 'ليرة سورية',
      englishName: 'Syrian Pound',
      arabicSymbol: 'ل.س',
      englishSymbol: 'SYP',
    ),
    CurrencyEntity(
      code: 'YER',
      arabicName: 'ريال يمني',
      englishName: 'Yemeni Rial',
      arabicSymbol: 'ر.ي',
      englishSymbol: 'YER',
    ),
    CurrencyEntity(
      code: 'SDG',
      arabicName: 'جنيه سوداني',
      englishName: 'Sudanese Pound',
      arabicSymbol: 'ج.س',
      englishSymbol: 'SDG',
    ),
    CurrencyEntity(
      code: 'MRU',
      arabicName: 'أوقية موريتانية',
      englishName: 'Mauritanian Ouguiya',
      arabicSymbol: 'أ.م',
      englishSymbol: 'MRU',
    ),
    CurrencyEntity(
      code: 'SOS',
      arabicName: 'شيلينغ صومالي',
      englishName: 'Somali Shilling',
      arabicSymbol: 'ش.ص',
      englishSymbol: 'SOS',
    ),
    CurrencyEntity(
      code: 'DJF',
      arabicName: 'فرنك جيبوتي',
      englishName: 'Djiboutian Franc',
      arabicSymbol: 'ف.ج',
      englishSymbol: 'DJF',
    ),
    CurrencyEntity(
      code: 'KMF',
      arabicName: 'فرنك قمري',
      englishName: 'Comorian Franc',
      arabicSymbol: 'ف.ق',
      englishSymbol: 'KMF',
    ),

    // --- Major Global Currencies ---
    CurrencyEntity(
      code: 'USD',
      arabicName: 'دولار أمريكي',
      englishName: 'US Dollar',
      arabicSymbol: '\$',
      englishSymbol: '\$',
    ),
    CurrencyEntity(
      code: 'EUR',
      arabicName: 'يورو',
      englishName: 'Euro',
      arabicSymbol: '€',
      englishSymbol: '€',
    ),
    CurrencyEntity(
      code: 'GBP',
      arabicName: 'جنيه إسترليني',
      englishName: 'British Pound',
      arabicSymbol: '£',
      englishSymbol: '£',
    ),
    CurrencyEntity(
      code: 'CAD',
      arabicName: 'دولار كندي',
      englishName: 'Canadian Dollar',
      arabicSymbol: 'C\$',
      englishSymbol: 'C\$',
    ),
    CurrencyEntity(
      code: 'AUD',
      arabicName: 'دولار أسترالي',
      englishName: 'Australian Dollar',
      arabicSymbol: 'A\$',
      englishSymbol: 'A\$',
    ),
    CurrencyEntity(
      code: 'CHF',
      arabicName: 'فرنك سويسري',
      englishName: 'Swiss Franc',
      arabicSymbol: 'CHF',
      englishSymbol: 'CHF',
    ),
    CurrencyEntity(
      code: 'TRY',
      arabicName: 'ليرة تركية',
      englishName: 'Turkish Lira',
      arabicSymbol: '₺',
      englishSymbol: 'TRY',
    ),
    CurrencyEntity(
      code: 'CNY',
      arabicName: 'يوان صيني',
      englishName: 'Chinese Yuan',
      arabicSymbol: '¥',
      englishSymbol: 'CNY',
    ),
    CurrencyEntity(
      code: 'INR',
      arabicName: 'روبية هندية',
      englishName: 'Indian Rupee',
      arabicSymbol: '₹',
      englishSymbol: 'INR',
    ),
    CurrencyEntity(
      code: 'JPY',
      arabicName: 'ين ياباني',
      englishName: 'Japanese Yen',
      arabicSymbol: '¥',
      englishSymbol: 'JPY',
    ),
    CurrencyEntity(
      code: 'RUB',
      arabicName: 'روبيل روسي',
      englishName: 'Russian Ruble',
      arabicSymbol: '₽',
      englishSymbol: 'RUB',
    ),
    CurrencyEntity(
      code: 'BRL',
      arabicName: 'ريال برازيلي',
      englishName: 'Brazilian Real',
      arabicSymbol: 'R\$',
      englishSymbol: 'BRL',
    ),
    CurrencyEntity(
      code: 'SEK',
      arabicName: 'كرونة سويدية',
      englishName: 'Swedish Krona',
      arabicSymbol: 'kr',
      englishSymbol: 'SEK',
    ),
    CurrencyEntity(
      code: 'NOK',
      arabicName: 'كرونة نرويجية',
      englishName: 'Norwegian Krone',
      arabicSymbol: 'kr',
      englishSymbol: 'NOK',
    ),
    CurrencyEntity(
      code: 'DKK',
      arabicName: 'كرونة دنماركية',
      englishName: 'Danish Krone',
      arabicSymbol: 'kr',
      englishSymbol: 'DKK',
    ),
    CurrencyEntity(
      code: 'NZD',
      arabicName: 'دولار نيوزيلندي',
      englishName: 'New Zealand Dollar',
      arabicSymbol: 'NZ\$',
      englishSymbol: 'NZ\$',
    ),
    CurrencyEntity(
      code: 'SGD',
      arabicName: 'دولار سنغافوري',
      englishName: 'Singapore Dollar',
      arabicSymbol: 'S\$',
      englishSymbol: 'SGD',
    ),
    CurrencyEntity(
      code: 'HKD',
      arabicName: 'دولار هونغ كونغ',
      englishName: 'Hong Kong Dollar',
      arabicSymbol: 'HK\$',
      englishSymbol: 'HK\$',
    ),
    CurrencyEntity(
      code: 'MYR',
      arabicName: 'رينغيت ماليزي',
      englishName: 'Malaysian Ringgit',
      arabicSymbol: 'RM',
      englishSymbol: 'MYR',
    ),
    CurrencyEntity(
      code: 'IDR',
      arabicName: 'روبية إندونيسية',
      englishName: 'Indonesian Rupiah',
      arabicSymbol: 'Rp',
      englishSymbol: 'IDR',
    ),
    CurrencyEntity(
      code: 'THB',
      arabicName: 'بات تايلاندي',
      englishName: 'Thai Baht',
      arabicSymbol: '฿',
      englishSymbol: 'THB',
    ),
    CurrencyEntity(
      code: 'KRW',
      arabicName: 'وون كوري',
      englishName: 'South Korean Won',
      arabicSymbol: '₩',
      englishSymbol: 'KRW',
    ),
    CurrencyEntity(
      code: 'PKR',
      arabicName: 'روبية باكستانية',
      englishName: 'Pakistani Rupee',
      arabicSymbol: 'Rs',
      englishSymbol: 'PKR',
    ),
    CurrencyEntity(
      code: 'BDT',
      arabicName: 'تاكا بنغلاديشية',
      englishName: 'Bangladeshi Taka',
      arabicSymbol: '৳',
      englishSymbol: 'BDT',
    ),
    CurrencyEntity(
      code: 'LKR',
      arabicName: 'روبية سريلانكية',
      englishName: 'Sri Lankan Rupee',
      arabicSymbol: 'Rs',
      englishSymbol: 'LKR',
    ),
    CurrencyEntity(
      code: 'PHP',
      arabicName: 'بيزو فلبيني',
      englishName: 'Philippine Peso',
      arabicSymbol: '₱',
      englishSymbol: 'PHP',
    ),
    CurrencyEntity(
      code: 'VND',
      arabicName: 'دونغ فيتنامي',
      englishName: 'Vietnamese Dong',
      arabicSymbol: '₫',
      englishSymbol: 'VND',
    ),
    CurrencyEntity(
      code: 'ZAR',
      arabicName: 'راند جنوب إفريقي',
      englishName: 'South African Rand',
      arabicSymbol: 'R',
      englishSymbol: 'ZAR',
    ),
    CurrencyEntity(
      code: 'KES',
      arabicName: 'شيلينغ كيني',
      englishName: 'Kenyan Shilling',
      arabicSymbol: 'KSh',
      englishSymbol: 'KES',
    ),
    CurrencyEntity(
      code: 'NGN',
      arabicName: 'نايرا نيجيرية',
      englishName: 'Nigerian Naira',
      arabicSymbol: '₦',
      englishSymbol: 'NGN',
    ),
    CurrencyEntity(
      code: 'GHS',
      arabicName: 'سيدي غاني',
      englishName: 'Ghanaian Cedi',
      arabicSymbol: 'GH₵',
      englishSymbol: 'GHS',
    ),
    CurrencyEntity(
      code: 'MXN',
      arabicName: 'بيزو مكسيكي',
      englishName: 'Mexican Peso',
      arabicSymbol: 'Mex\$',
      englishSymbol: 'MXN',
    ),
    CurrencyEntity(
      code: 'ARS',
      arabicName: 'بيزو أرجنتيني',
      englishName: 'Argentine Peso',
      arabicSymbol: 'ARS\$',
      englishSymbol: 'ARS',
    ),
    CurrencyEntity(
      code: 'CLP',
      arabicName: 'بيزو تشيلي',
      englishName: 'Chilean Peso',
      arabicSymbol: 'CLP\$',
      englishSymbol: 'CLP',
    ),
    CurrencyEntity(
      code: 'COP',
      arabicName: 'بيزو كولومبي',
      englishName: 'Colombian Peso',
      arabicSymbol: 'COP\$',
      englishSymbol: 'COP',
    ),
    CurrencyEntity(
      code: 'PEN',
      arabicName: 'سول بيروفي',
      englishName: 'Peruvian Sol',
      arabicSymbol: 'S/',
      englishSymbol: 'PEN',
    ),
  ];

  /// O(1) Lookup Map by Currency Code
  static final Map<String, CurrencyEntity> _currenciesByCode = {
    for (final c in allCurrencies) c.code.toUpperCase(): c,
  };

  /// Find currency by code, defaulting to EGP if not found.
  static CurrencyEntity findByCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      return CurrencyEntity.defaultCurrency;
    }
    return _currenciesByCode[code.trim().toUpperCase()] ??
        CurrencyEntity.defaultCurrency;
  }

  /// Search currencies by name or code
  static List<CurrencyEntity> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return allCurrencies;

    return allCurrencies.where((c) {
      return c.code.toLowerCase().contains(q) ||
          c.arabicName.toLowerCase().contains(q) ||
          c.englishName.toLowerCase().contains(q) ||
          c.arabicSymbol.toLowerCase().contains(q) ||
          c.englishSymbol.toLowerCase().contains(q);
    }).toList();
  }
}
