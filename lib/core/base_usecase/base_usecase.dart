import 'package:dartz/dartz.dart';

abstract class BaseUseCase<T, Parameters> {
  Future<Either<dynamic, T>> call(Parameters parameters);
}
