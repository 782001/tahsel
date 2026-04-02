import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/base_usecase/base_usecase.dart';
import '../entities/get_categories_entity.dart';
import '../repositories/get_categories_repo_base.dart';

class GetCategoriesUseCase
    extends BaseUseCase<GetCategoriesResponseEntity, GetCategoriesParameters> {
  final GetCategoriesBaseRepository baseRepository;

  GetCategoriesUseCase({required this.baseRepository});

  @override
  Future<Either<dynamic, GetCategoriesResponseEntity>> call(
      GetCategoriesParameters parameters) async {
    return await baseRepository.call(parameters: parameters);
  }
}

class GetCategoriesParameters extends Equatable {
  

  const GetCategoriesParameters();

  @override
  List<Object?> get props => [];
}
