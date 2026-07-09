import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/core/error/firebase_error_handler.dart';
import 'package:tahsel/features/create_account/data/datasources/create_account_remote_data_source.dart';
import 'package:tahsel/features/create_account/domain/repositories/create_account_repository.dart';

class CreateAccountRepositoryImpl implements CreateAccountRepository {
  CreateAccountRepositoryImpl(this._remote);

  final CreateAccountRemoteDataSource _remote;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(FirebaseErrorHandler.getMessage(e)));
    } on FirebaseException catch (e) {
      return Left(ServerFailure(FirebaseErrorHandler.getMessage(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> createUser(
    Map<String, dynamic> data,
  ) => _guard(() => _remote.createUser(data));
}
