import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/base_usecase/base_usecase.dart';
import '../entities/get_category_by_id_entity.dart';
import '../repositories/get_category_by_id_repo_base.dart';

class GetCategoryByIdUseCase
    extends BaseUseCase<GetCategoryByIdResponseEntity, GetCategoryByIdParameters> {
  final GetCategoryByIdBaseRepository baseRepository;

  GetCategoryByIdUseCase({required this.baseRepository});

  @override
  Future<Either<dynamic, GetCategoryByIdResponseEntity>> call(
      GetCategoryByIdParameters parameters) async {
    return await baseRepository.call(parameters: parameters);
  }
}

class GetCategoryByIdParameters extends Equatable {
  

  const GetCategoryByIdParameters();

  @override
  List<Object?> get props => [];
}
