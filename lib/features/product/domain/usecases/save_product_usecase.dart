import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/product_repository.dart';
import '../entities/product_entity.dart';

class SaveProductParams {
  final String uid;
  final ProductEntity product;

  SaveProductParams({required this.uid, required this.product});
}

class SaveProductUseCase implements BaseUseCase<void, SaveProductParams> {
  final ProductRepository repository;

  SaveProductUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveProductParams params) {
    return repository.saveProduct(params.uid, params.product);
  }
}
