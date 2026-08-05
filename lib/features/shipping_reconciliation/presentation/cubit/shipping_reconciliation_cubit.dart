import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/column_concept.dart';
import '../../domain/entities/column_mapping_entity.dart';
import '../../domain/entities/order_reconciliation_item.dart';
import '../../domain/repositories/shipping_reconciliation_repository.dart';
import 'shipping_reconciliation_state.dart';

class ShippingReconciliationCubit
    extends Cubit<ShippingReconciliationState> {
  final ShippingReconciliationRepository _repository;

  ShippingReconciliationCubit({
    required ShippingReconciliationRepository repository,
  })  : _repository = repository,
        super(ShippingReconciliationInitial());

  RawFileData? _internalFile;
  FileColumnMappingEntity? _internalMapping;
  RawFileData? _shippingFile;
  FileColumnMappingEntity? _shippingMapping;

  Future<void> pickInternalFile({
    required List<int> bytes,
    required String fileName,
  }) async {
    final parseResult = await _repository.parseFileBytes(
      bytes: bytes,
      fileName: fileName,
    );

    parseResult.fold(
      (failure) {
        emit(ShippingReconciliationFailureState(errorMessage: failure));
      },
      (rawFile) async {
        _internalFile = rawFile;
        final mappingResult = await _repository.detectColumnMapping(
          rawFile: rawFile,
          isInternalFile: true,
        );

        mappingResult.fold(
          (failure) => emit(ShippingReconciliationFailureState(errorMessage: failure)),
          (mapping) {
            _internalMapping = mapping;
            _emitFilesLoadedState();
          },
        );
      },
    );
  }

  Future<void> pickShippingFile({
    required List<int> bytes,
    required String fileName,
  }) async {
    final parseResult = await _repository.parseFileBytes(
      bytes: bytes,
      fileName: fileName,
    );

    parseResult.fold(
      (failure) {
        emit(ShippingReconciliationFailureState(errorMessage: failure));
      },
      (rawFile) async {
        _shippingFile = rawFile;
        final mappingResult = await _repository.detectColumnMapping(
          rawFile: rawFile,
          isInternalFile: false,
        );

        mappingResult.fold(
          (failure) => emit(ShippingReconciliationFailureState(errorMessage: failure)),
          (mapping) {
            _shippingMapping = mapping;
            _emitFilesLoadedState();
          },
        );
      },
    );
  }

  void _emitFilesLoadedState() {
    emit(ShippingReconciliationFilesLoaded(
      internalFile: _internalFile,
      internalMapping: _internalMapping,
      shippingFile: _shippingFile,
      shippingMapping: _shippingMapping,
    ));
  }

  void backToFilesStep() {
    _emitFilesLoadedState();
  }

  void updateInternalMapping(ColumnConcept concept, int? columnIndex) {
    if (_internalMapping == null) return;
    _internalMapping = _internalMapping!.copyWithMapping(concept, columnIndex);
    if (state is ShippingReconciliationMappingReviewState) {
      openMappingReviewScreen();
    } else {
      _emitFilesLoadedState();
    }
  }

  void updateShippingMapping(ColumnConcept concept, int? columnIndex) {
    if (_shippingMapping == null) return;
    _shippingMapping = _shippingMapping!.copyWithMapping(concept, columnIndex);
    if (state is ShippingReconciliationMappingReviewState) {
      openMappingReviewScreen();
    } else {
      _emitFilesLoadedState();
    }
  }

  void openMappingReviewScreen() {
    if (_internalFile != null &&
        _internalMapping != null &&
        _shippingFile != null &&
        _shippingMapping != null) {
      emit(ShippingReconciliationMappingReviewState(
        internalFile: _internalFile!,
        internalMapping: _internalMapping!,
        shippingFile: _shippingFile!,
        shippingMapping: _shippingMapping!,
      ));
    }
  }

  Future<void> startReconciliation() async {
    if (_internalFile == null ||
        _internalMapping == null ||
        _shippingFile == null ||
        _shippingMapping == null) {
      emit(ShippingReconciliationFailureState(
        errorMessage: AppStrings.pleaseUploadBothFiles.tr(),
      ));
      return;
    }

    emit(ShippingReconciliationProcessingState(
      message: AppStrings.analyzingAndReconcilingMessage.tr(),
    ));

    final result = await _repository.reconcile(
      internalFile: _internalFile!,
      internalMapping: _internalMapping!,
      shippingFile: _shippingFile!,
      shippingMapping: _shippingMapping!,
    );

    result.fold(
      (failure) => emit(ShippingReconciliationFailureState(errorMessage: failure)),
      (reconciliationData) {
        emit(ShippingReconciliationSuccessState(
          dashboard: reconciliationData.dashboard,
          allItems: reconciliationData.items,
          filteredItems: reconciliationData.items,
          searchQuery: '',
          selectedFilter: ReconciliationFilterChip.all,
        ));
      },
    );
  }

  void applySearchAndFilter({
    String? query,
    ReconciliationFilterChip? filter,
  }) {
    final currentState = state;
    if (currentState is! ShippingReconciliationSuccessState) return;

    final newQuery = query ?? currentState.searchQuery;
    final newFilter = filter ?? currentState.selectedFilter;

    final q = newQuery.trim().toLowerCase();

    final filtered = currentState.allItems.where((item) {
      // 1. Search Query Filter
      bool matchesSearch = q.isEmpty ||
          item.displayOrderNumber.toLowerCase().contains(q) ||
          item.displayCustomerName.toLowerCase().contains(q) ||
          item.displayPhone.toLowerCase().contains(q) ||
          item.displayProduct.toLowerCase().contains(q);

      if (!matchesSearch) return false;

      // 2. Chip Filter
      switch (newFilter) {
        case ReconciliationFilterChip.all:
          return true;
        case ReconciliationFilterChip.delivered:
          return item.shippingStatus == ShippingStatusCategory.delivered;
        case ReconciliationFilterChip.returned:
          return item.shippingStatus == ShippingStatusCategory.returned;
        case ReconciliationFilterChip.notShipped:
          return item.shippingStatus == ShippingStatusCategory.notShipped ||
              item.matchStatus == OrderMatchStatus.missingFromShipping;
        case ReconciliationFilterChip.fullyCollected:
          return item.collectionStatus == CollectionStatusCategory.fullyCollected;
        case ReconciliationFilterChip.partiallyCollected:
          return item.collectionStatus == CollectionStatusCategory.partiallyCollected;
        case ReconciliationFilterChip.notCollected:
          return item.collectionStatus == CollectionStatusCategory.notCollected;
        case ReconciliationFilterChip.conflicts:
          return item.matchStatus == OrderMatchStatus.conflict ||
              item.matchStatus == OrderMatchStatus.duplicate;
        case ReconciliationFilterChip.missing:
          return item.matchStatus == OrderMatchStatus.missingFromShipping ||
              item.matchStatus == OrderMatchStatus.shippingReportOnly;
      }
    }).toList();

    emit(currentState.copyWith(
      filteredItems: filtered,
      searchQuery: newQuery,
      selectedFilter: newFilter,
    ));
  }

  void resetSession() {
    _internalFile = null;
    _internalMapping = null;
    _shippingFile = null;
    _shippingMapping = null;
    emit(ShippingReconciliationInitial());
  }
}
