import 'package:tahsel/core/base_usecase/base_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:tahsel/features/standard_features/localization/domain/usecases/no_parameter.dart';
import '../repositories/lang_repository.dart';

class GetSavedLangUseCase implements BaseUseCase<String, NoParemeters> {
  final LangRepository langRepository;
  GetSavedLangUseCase({required this.langRepository});
  @override
  Future<Either<dynamic, String>> call(NoParemeters params) async {
    return await langRepository.getSavedLang();
  }
}
