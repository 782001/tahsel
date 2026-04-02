import 'package:dartz/dartz.dart';

import '../../domain/repositories/lang_repository.dart';
import '../datasources/lang_local_data_source.dart';

class LangRepositoryImpl implements LangRepository {
  final LangLocalDataSource langLocalDataSource;

  LangRepositoryImpl({required this.langLocalDataSource});
  @override
  Future<Either<dynamic, bool>> changeLang({required String langCode}) async {
    try {
      final langIsChanged = await langLocalDataSource.changeLang(
        langCode: langCode,
      );
      return Right(langIsChanged);
    } catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<dynamic, String>> getSavedLang() async {
    try {
      final langCode = await langLocalDataSource.getSavedLang();
      return Right(langCode);
    } catch (e) {
      return Left(e);
    }
  }
}
