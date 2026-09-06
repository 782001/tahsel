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
  final String? projectName;
  final int subscriptionDays;
  final String userType;
  final String platformType;
  final bool isVip;
  final Map<String, dynamic>? currency;
  final String? crn;
  final String? address;
  final String? vat;

  CreateUserParams({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
    required this.projectName,
    this.subscriptionDays = 0,
    this.userType = 'cafe',
    this.platformType = 'mobile',
    this.isVip = false,
    this.currency,
    this.crn,
    this.address,
    this.vat,
  });

  Map<String, dynamic> toMap() => {
    'email': email,
    'password': password,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'projectName': projectName,
    'subscriptionDays': subscriptionDays,
    'userType': userType,
    'platformType': platformType,
    'isVip': isVip,
    if (currency != null) 'currency': currency,
    if (crn != null) 'crn': crn,
    if (address != null) 'address': address,
    if (vat != null) 'vat': vat,
  };
}
