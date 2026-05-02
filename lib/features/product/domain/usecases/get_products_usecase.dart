import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/product_repository.dart';
import '../entities/product_entity.dart';

class GetProductsParams {
  final String uid;

  GetProductsParams({required this.uid});
}

class GetProductsUseCase
    implements BaseUseCase<List<ProductEntity>, GetProductsParams> {
  final ProductRepository repository;

  GetProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call(GetProductsParams params) {
    return repository.getProducts(params.uid);
  }
}
