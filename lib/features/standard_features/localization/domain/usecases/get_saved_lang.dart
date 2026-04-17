import 'package:tahsel/core/base_usecase/base_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:tahsel/core/error/failures.dart';
import '../repositories/lang_repository.dart';

class GetSavedLangUseCase implements BaseUseCase<String, NoParams> {
  final LangRepository langRepository;

  GetSavedLangUseCase({required this.langRepository});

  @override
  Future<Either<Failure, String>> call(NoParams params) async {
    return await langRepository.getSavedLang();
  }
}
