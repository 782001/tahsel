import 'package:dartz/dartz.dart';

abstract class LangRepository {
  Future<Either<dynamic, bool>> changeLang({required String langCode});
  Future<Either<dynamic, String>> getSavedLang();
}
