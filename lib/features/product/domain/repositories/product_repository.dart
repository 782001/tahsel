import 'package:dartz/dartz.dart';
import '../../domain/entities/product_entity.dart';
import '../../../../core/error/failures.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<ProductEntity>>> getProducts(String uid);
  Future<Either<Failure, void>> saveProduct(String uid, ProductEntity product);
}
