import 'package:dartz/dartz.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/error/exceptions.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/core/storage/secure_storage_helper.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repo_base.dart';
import '../../domain/usecases/login_usecase.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthBaseRepository {
  final AuthRemoteDataSourceBase remoteDataSource;
  final SecureStorageHelper secureStorage;
  final InternetConnectionChecker connectionChecker;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
    required this.connectionChecker,
  });

  @override
  Future<Either<Failure, UserEntity>> login({
    required LoginParameters parameters,
  }) async {
    if (!await connectionChecker.hasConnection) {
      return const Left(ServerFailure('auth_network_error'));
    }

    try {
      final result = await remoteDataSource.login(parameters: parameters);
      return Right(result);
    } on ServerException catch (e) {
      AppLogger.printMessage(e.toString());

      return Left(ServerFailure(_mapExceptionToMessage(e.code)));
    } catch (e) {
      AppLogger.printMessage(e.toString());

      return const Left(ServerFailure('auth_default_error'));
    }
  }

  @override
  Future<void> logout() async {
    await secureStorage.deleteData(key: 'token');
    await secureStorage.deleteData(key: 'email');
    await secureStorage.deleteData(key: AppStrings.userTypeKey);
    await remoteDataSource.logout();
  }

  String _mapExceptionToMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'user_not_found':
        return 'auth_user_not_found';
      case 'wrong-password':
      case 'invalid-credential':
        return 'auth_invalid_credential';
      case 'invalid-email':
        return 'auth_invalid_email';
      case 'user-disabled':
      case 'auth_user_disabled':
        return 'auth_user_disabled';
      case 'too-many-requests':
        return 'auth_too_many_requests';
      case 'network-request-failed':
        return 'auth_network_error';
      case 'internal-error':
        return 'auth_default_error';
      case 'account_suspended':
        return 'account_suspended';
      case 'account_expired':
        return 'account_expired';
      case 'platform_not_allowed':
        return 'platform_not_allowed';
      default:
        return 'auth_default_error';
    }
  }
}
