import 'package:dartz/dartz.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/create_account/domain/repositories/create_account_repository.dart';

class CreateUserUseCase
    extends BaseUseCase<Map<String, dynamic>, CreateUserParams> {
  CreateUserUseCase(this._repo);
  final CreateAccountRepository _repo;
  @override
  Future<Either<Failure, Map<String, dynamic>>> call(CreateUserParams params) =>
      _repo.createUser(params.toMap());
}

class CreateUserParams {
  final String email;
  final String password;
  final String fullName;
  final String? phoneNumber;
  final int subscriptionDays;
  final String userType;
  final String platformType;

  CreateUserParams({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
    this.subscriptionDays = 0,
    this.userType = 'cafe',
    this.platformType = 'mobile',
  });

  Map<String, dynamic> toMap() => {
    'email': email,
    'password': password,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'subscriptionDays': subscriptionDays,
    'userType': userType,
    'platformType': platformType,
  };
}
