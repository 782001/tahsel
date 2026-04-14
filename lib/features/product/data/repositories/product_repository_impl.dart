import 'package:dartz/dartz.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<dynamic, List<ProductEntity>>> getProducts(String uid) async {
    try {
      final products = await remoteDataSource.getProducts(uid);
      return Right(products);
    } catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<dynamic, void>> saveProduct(String uid, ProductEntity product) async {
    try {
      await remoteDataSource.saveProduct(uid, ProductModel.fromEntity(product));
      return const Right(null);
    } catch (e) {
      return Left(e);
    }
  }
}
