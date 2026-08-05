enum ColumnConcept {
  orderNumber,
  customerName,
  phone,
  requiredAmount,
  collectedAmount,
  expectedAmount,
  shippingStatus,
  collectionStatus,
  returnStatus,
  product,
  governorate,
  address,
  date,
  unknown,
}

extension ColumnConceptExtension on ColumnConcept {
  String get keyName {
    switch (this) {
      case ColumnConcept.orderNumber:
        return 'orderNumber';
      case ColumnConcept.customerName:
        return 'customerName';
      case ColumnConcept.phone:
        return 'phone';
      case ColumnConcept.requiredAmount:
        return 'requiredAmount';
      case ColumnConcept.collectedAmount:
        return 'collectedAmount';
      case ColumnConcept.expectedAmount:
        return 'expectedAmount';
      case ColumnConcept.shippingStatus:
        return 'shippingStatus';
      case ColumnConcept.collectionStatus:
        return 'collectionStatus';
      case ColumnConcept.returnStatus:
        return 'returnStatus';
      case ColumnConcept.product:
        return 'product';
      case ColumnConcept.governorate:
        return 'governorate';
      case ColumnConcept.address:
        return 'address';
      case ColumnConcept.date:
        return 'date';
      case ColumnConcept.unknown:
        return 'unknown';
    }
  }

  bool get isRequiredForMatching {
    return this == ColumnConcept.orderNumber ||
        this == ColumnConcept.phone ||
        this == ColumnConcept.customerName;
  }
}
