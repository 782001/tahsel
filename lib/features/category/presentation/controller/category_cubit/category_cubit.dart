import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/utils/app_logger.dart';

import '../../../domain/entities/get_category_by_id_entity.dart';
import '../../../domain/usecases/get_category_by_id_usecase.dart';
import 'category_states.dart';
import '../../../domain/entities/get_categories_entity.dart';
import '../../../domain/usecases/get_categories_usecase.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final GetCategoryByIdUseCase kGetCategoryByIdUseCase;

  final GetCategoriesUseCase kGetCategoriesUseCase;

  CategoryCubit({
    required this.kGetCategoryByIdUseCase,
    required this.kGetCategoriesUseCase,
  }) : super(CategoryInitialState());

  static CategoryCubit get(context) => BlocProvider.of<CategoryCubit>(context);
  GetCategoryByIdResponseEntity? getCategoryByIdResponseEntity;
  void getCategoryByIdMethod() async {
    emit(GetCategoryByIdLoadingState());

    final response = await kGetCategoryByIdUseCase(GetCategoryByIdParameters());

    response.fold(
      (failure) {
        AppLogger.handleLogs('Failure: GetCategoryByIdErrorState');
        emit(GetCategoryByIdErrorState());
      },
      (r) {
        getCategoryByIdResponseEntity = r;
        AppLogger.handleLogs('Success: ${r.message}');
        emit(GetCategoryByIdSucssesState(message: r.message!));
      },
    );
  }

  GetCategoriesResponseEntity? getCategoriesResponseEntity;
  void getCategoriesMethod() async {
    emit(GetCategoriesLoadingState());

    final response = await kGetCategoriesUseCase(GetCategoriesParameters());

    response.fold(
      (failure) {
        AppLogger.handleLogs('Failure: GetCategoriesErrorState');
        emit(GetCategoriesErrorState());
      },
      (r) {
        getCategoriesResponseEntity = r;
        AppLogger.handleLogs('Success: ${r.message}');
        emit(GetCategoriesSucssesState(message: r.message ?? ''));
      },
    );
  }
}
