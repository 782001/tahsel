import '../../domain/entities/column_concept.dart';
import '../../domain/entities/column_mapping_entity.dart';
import 'text_normalization_service.dart';

class ColumnDetectorService {
  ColumnDetectorService._();

  static final Map<ColumnConcept, List<String>> _synonyms = {
    ColumnConcept.orderNumber: [
      'رقم الطلب',
      'رقم الاوردر',
      'كود الطلب',
      'كود الاوردر',
      'رقم الشحنة',
      'كود الشحنة',
      'رقم الفاتورة',
      'مسلسل',
      'order id',
      'order no',
      'order number',
      'order #',
      'id',
      'tracking no',
      'tracking id',
      'code',
      'waybill',
    ],
    ColumnConcept.customerName: [
      'اسم العميل',
      'العميل',
      'اسم الزبون',
      'الزبون',
      'اسم المستلم',
      'المستلم',
      'customer',
      'customer name',
      'client name',
      'client',
      'recipient',
      'name',
    ],
    ColumnConcept.phone: [
      'رقم الهاتف',
      'الهاتف',
      'الموبايل',
      'التليفون',
      'رقم الموبايل',
      'جوال',
      'رقم الجوال',
      'phone',
      'mobile',
      'phone number',
      'mobile number',
      'tel',
      'contact',
      'num',
      'num consignee',
    ],
    ColumnConcept.requiredAmount: [
      'المبلغ المطلوب',
      'المبلغ',
      'قيمة الطلب',
      'المطلوب',
      'اجمالي الطلب',
      'قيمة الشحنة',
      'السعر',
      'required amount',
      'cod amount',
      'amount',
      'total',
      'required',
      'total amount',
      'price',
    ],
    ColumnConcept.collectedAmount: [
      'المبلغ المحصل',
      'التحصيل',
      'المحصل',
      'المبلغ المستلم',
      'الصافي',
      'المحصل من العميل',
      'collected amount',
      'collected',
      'collection',
      'paid amount',
      'collected cod',
      'delivered amount',
      'delivered',
    ],
    ColumnConcept.expectedAmount: [
      'المبلغ المتوقع',
      'المتوقع',
      'المطلوب تحصيله',
      'expected amount',
      'expected',
      'expected cod',
      'customer due',
      'due',
    ],
    ColumnConcept.shippingStatus: [
      'حالة الشحن',
      'حالة الطلب',
      'حالة التوصيل',
      'حالة الاوردر',
      'الحالة',
      'shipping status',
      'delivery status',
      'status',
      'order status',
      'state',
    ],
    ColumnConcept.collectionStatus: [
      'حالة التحصيل',
      'تحصيل',
      'موقعية التحصيل',
      'collection status',
      'payment status',
      'paid status',
    ],
    ColumnConcept.returnStatus: [
      'حالة الارجاع',
      'المرتجع',
      'سبب الارجاع',
      'return status',
      'return state',
      'return reason',
    ],
    ColumnConcept.product: [
      'المنتج',
      'اسم المنتج',
      'الصنف',
      'تفاصيل الطلب',
      'المحتوى',
      'محتويات الشحنة',
      'product',
      'product name',
      'item',
      'description',
      'details',
    ],
    ColumnConcept.governorate: [
      'المحافظة',
      'المدينة',
      'المنطقة',
      'governorate',
      'city',
      'state',
      'region',
      'consignee zone',
      'zone',
    ],
    ColumnConcept.address: [
      'العنوان',
      'عنوان العميل',
      'مكان التسليم',
      'address',
      'location',
      'delivery address',
      'consignee region',
      'consignee address',
    ],
    ColumnConcept.date: [
      'التاريخ',
      'تاريخ الطلب',
      'تاريخ الشحن',
      'date',
      'order date',
      'created at',
    ],
  };

  /// Checks if a given text string matches any known concept synonym
  static bool isHeaderKeyword(String text) {
    if (text.trim().isEmpty) return false;
    final norm = TextNormalizationService.normalizeForMatching(text);
    if (norm.isEmpty) return false;

    for (final synonymsList in _synonyms.values) {
      for (final syn in synonymsList) {
        final normSyn = TextNormalizationService.normalizeForMatching(syn);
        if (norm == normSyn || norm.contains(normSyn) || normSyn.contains(norm)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Main entry point for detecting column mappings from raw headers & sample rows
  static FileColumnMappingEntity detectMapping({
    required String fileName,
    required List<String> rawHeaders,
    required List<List<dynamic>> sampleRows,
    required bool isInternalFile,
  }) {
    final Map<ColumnConcept, int?> conceptToColMap = {};
    final List<ColumnMappingItem> items = [];
    final Set<int> mappedColumnIndices = {};

    // 1. Score each column against concepts based on Header Names
    for (int colIdx = 0; colIdx < rawHeaders.length; colIdx++) {
      final header = rawHeaders[colIdx];
      final normHeader = TextNormalizationService.normalizeForMatching(header);

      if (normHeader.isEmpty) continue;

      ColumnConcept? bestConcept;
      double maxScore = 0.0;

      for (final entry in _synonyms.entries) {
        final concept = entry.key;
        final synonymsList = entry.value;

        for (final syn in synonymsList) {
          final normSyn = TextNormalizationService.normalizeForMatching(syn);

          if (normHeader == normSyn) {
            maxScore = 1.0;
            bestConcept = concept;
            break;
          } else if (normHeader.contains(normSyn) || normSyn.contains(normHeader)) {
            final score = 0.8;
            if (score > maxScore) {
              maxScore = score;
              bestConcept = concept;
            }
          }
        }

        if (maxScore == 1.0) break;
      }

      // 2. Data Content Verification using sample rows
      if (sampleRows.isNotEmpty) {
        final colSampleValues = sampleRows
            .where((row) => colIdx < row.length && row[colIdx] != null)
            .map((row) => row[colIdx].toString())
            .toList();

        if (colSampleValues.isNotEmpty) {
          // Phone check
          int phoneMatches = colSampleValues
              .where((v) => RegExp(r'^(\+?20|0)?1[0125]\d{8}$').hasMatch(v.replaceAll(RegExp(r'\D'), '')))
              .length;
          if (phoneMatches / colSampleValues.length > 0.5) {
            if (bestConcept == ColumnConcept.phone || maxScore < 0.9) {
              bestConcept = ColumnConcept.phone;
              maxScore = 0.95;
            }
          }

          // Number / Amount check
          int numericMatches = colSampleValues
              .where((v) => RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(v.replaceAll(RegExp(r'[^\d.]'), '')))
              .length;

          if (numericMatches / colSampleValues.length > 0.7 && bestConcept != ColumnConcept.phone && bestConcept != ColumnConcept.orderNumber) {
            if (bestConcept == null || maxScore < 0.7) {
              bestConcept = isInternalFile
                  ? ColumnConcept.requiredAmount
                  : ColumnConcept.collectedAmount;
              maxScore = 0.75;
            }
          }
        }
      }

      if (bestConcept != null && maxScore >= 0.6) {
        items.add(ColumnMappingItem(
          rawHeader: header,
          columnIndex: colIdx,
          concept: bestConcept,
          confidenceScore: maxScore,
        ));
      }
    }

    // Sort mappings by highest confidence score
    items.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));

    for (final item in items) {
      if (!mappedColumnIndices.contains(item.columnIndex) &&
          !conceptToColMap.containsKey(item.concept)) {
        conceptToColMap[item.concept] = item.columnIndex;
        mappedColumnIndices.add(item.columnIndex);
      }
    }

    // Check confidence: needs at least Order Number or Phone Number
    bool hasOrderNum = conceptToColMap.containsKey(ColumnConcept.orderNumber);
    bool hasPhone = conceptToColMap.containsKey(ColumnConcept.phone);
    bool isConfident = hasOrderNum || hasPhone;

    return FileColumnMappingEntity(
      fileName: fileName,
      totalRows: sampleRows.length,
      rawHeaders: rawHeaders,
      conceptToColumnIndexMap: conceptToColMap,
      mappingItems: items,
      isConfident: isConfident,
    );
  }
}
