import 'package:equatable/equatable.dart';
import 'column_concept.dart';

class ColumnMappingItem extends Equatable {
  final String rawHeader;
  final int columnIndex;
  final ColumnConcept concept;
  final double confidenceScore;

  const ColumnMappingItem({
    required this.rawHeader,
    required this.columnIndex,
    required this.concept,
    required this.confidenceScore,
  });

  ColumnMappingItem copyWith({
    String? rawHeader,
    int? columnIndex,
    ColumnConcept? concept,
    double? confidenceScore,
  }) {
    return ColumnMappingItem(
      rawHeader: rawHeader ?? this.rawHeader,
      columnIndex: columnIndex ?? this.columnIndex,
      concept: concept ?? this.concept,
      confidenceScore: confidenceScore ?? this.confidenceScore,
    );
  }

  @override
  List<Object?> get props => [rawHeader, columnIndex, concept, confidenceScore];
}

class FileColumnMappingEntity extends Equatable {
  final String fileName;
  final int totalRows;
  final List<String> rawHeaders;
  final Map<ColumnConcept, int?> conceptToColumnIndexMap;
  final List<ColumnMappingItem> mappingItems;
  final bool isConfident;

  const FileColumnMappingEntity({
    required this.fileName,
    required this.totalRows,
    required this.rawHeaders,
    required this.conceptToColumnIndexMap,
    required this.mappingItems,
    required this.isConfident,
  });

  int? getIndex(ColumnConcept concept) => conceptToColumnIndexMap[concept];

  FileColumnMappingEntity copyWithMapping(ColumnConcept concept, int? columnIndex) {
    final updatedMap = Map<ColumnConcept, int?>.from(conceptToColumnIndexMap);
    if (columnIndex == null) {
      updatedMap.remove(concept);
    } else {
      // Clear any concept currently mapped to this column index
      updatedMap.removeWhere((key, value) => value == columnIndex);
      updatedMap[concept] = columnIndex;
    }
    return FileColumnMappingEntity(
      fileName: fileName,
      totalRows: totalRows,
      rawHeaders: rawHeaders,
      conceptToColumnIndexMap: updatedMap,
      mappingItems: mappingItems,
      isConfident: isConfident,
    );
  }

  @override
  List<Object?> get props => [
        fileName,
        totalRows,
        rawHeaders,
        conceptToColumnIndexMap,
        mappingItems,
        isConfident,
      ];
}
