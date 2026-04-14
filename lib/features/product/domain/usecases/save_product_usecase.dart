import 'package:dartz/dartz.dart';
import '../repositories/product_repository.dart';
import '../entities/product_entity.dart';

class SaveProductUseCase {
  final ProductRepository repository;

  SaveProductUseCase(this.repository);

  Future<Either<dynamic, void>> call(String uid, ProductEntity product) {
    return repository.saveProduct(uid, product);
  }
}
