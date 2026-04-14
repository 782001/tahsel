import 'package:dartz/dartz.dart';
import '../repositories/product_repository.dart';
import '../entities/product_entity.dart';

class GetProductsUseCase {
  final ProductRepository repository;

  GetProductsUseCase(this.repository);

  Future<Either<dynamic, List<ProductEntity>>> call(String uid) {
    return repository.getProducts(uid);
  }
}
