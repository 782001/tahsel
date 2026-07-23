import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/inventory_category_entity.dart';
import '../../domain/usecases/inventory_category_usecases.dart';

abstract class InventoryCategoriesState extends Equatable {
  const InventoryCategoriesState();
  @override
  List<Object?> get props => [];
}

class InventoryCategoriesInitial extends InventoryCategoriesState {}

class InventoryCategoriesLoading extends InventoryCategoriesState {}

class InventoryCategoriesLoaded extends InventoryCategoriesState {
  final List<InventoryCategoryEntity> categories;
  const InventoryCategoriesLoaded(this.categories);
  @override
  List<Object?> get props => [categories];
}

class InventoryCategoriesError extends InventoryCategoriesState {
  final String message;
  const InventoryCategoriesError(this.message);
  @override
  List<Object?> get props => [message];
}

class InventoryCategoriesCubit extends Cubit<InventoryCategoriesState> {
  final GetInventoryCategoriesUseCase getCategoriesUseCase;
  final SaveInventoryCategoryUseCase saveCategoryUseCase;
  final DeleteInventoryCategoryUseCase deleteCategoryUseCase;

  InventoryCategoriesCubit({
    required this.getCategoriesUseCase,
    required this.saveCategoryUseCase,
    required this.deleteCategoryUseCase,
  }) : super(InventoryCategoriesInitial());

  Future<void> fetchCategories() async {
    emit(InventoryCategoriesLoading());
    final result = await getCategoriesUseCase();
    result.fold(
      (failure) => emit(InventoryCategoriesError(failure.message)),
      (categories) => emit(InventoryCategoriesLoaded(categories)),
    );
  }

  Future<bool> saveCategory(InventoryCategoryEntity category) async {
    final result = await saveCategoryUseCase(category);
    return result.fold(
      (failure) {
        emit(InventoryCategoriesError(failure.message));
        return false;
      },
      (_) {
        fetchCategories();
        return true;
      },
    );
  }

  Future<bool> deleteCategory(String id) async {
    final result = await deleteCategoryUseCase(id);
    return result.fold(
      (failure) {
        emit(InventoryCategoriesError(failure.message));
        return false;
      },
      (_) {
        fetchCategories();
        return true;
      },
    );
  }
}
