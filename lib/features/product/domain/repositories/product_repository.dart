import 'package:dartz/dartz.dart';
import '../../domain/entities/product_entity.dart';

abstract class ProductRepository {
  Future<Either<dynamic, List<ProductEntity>>> getProducts(String uid);
  Future<Either<dynamic, void>> saveProduct(String uid, ProductEntity product);
}
