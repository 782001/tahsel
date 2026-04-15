import 'package:dartz/dartz.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repo_base.dart';
import '../../domain/usecases/login_usecase.dart';
import '../datasources/auth_remote_data_source.dart';
import 'package:tahsel/core/storage/secure_storage_helper.dart';

class AuthRepositoryImpl implements AuthBaseRepository {
  final AuthRemoteDataSourceBase remoteDataSource;
  final SecureStorageHelper secureStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  @override
  Future<Either<dynamic, UserEntity>> login({
    required LoginParameters parameters,
  }) async {
    try {
      final result = await remoteDataSource.login(parameters: parameters);
      return Right(result);
    } catch (e) {
      // In a real app, you would handle network errors and exceptions properly
      // mapping them to failures. Here we are simplifying.
      return Left(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    await secureStorage.deleteData(key: 'token');
    await secureStorage.deleteData(key: 'email');
    await remoteDataSource.logout();
  }
}
