abstract class CategoryState {}

class CategoryInitialState extends CategoryState {}

class GetCategoryByIdLoadingState extends CategoryState {}

class GetCategoryByIdErrorState extends CategoryState {
  GetCategoryByIdErrorState();
}

class GetCategoryByIdSucssesState extends CategoryState {
  final String message;

  GetCategoryByIdSucssesState({required this.message});
}

class GetCategoriesLoadingState extends CategoryState {}

class GetCategoriesErrorState extends CategoryState {
  GetCategoriesErrorState();
}

class GetCategoriesSucssesState extends CategoryState {
  final String message;

  GetCategoriesSucssesState({required this.message});
}
