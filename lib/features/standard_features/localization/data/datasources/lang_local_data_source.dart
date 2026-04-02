import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/storage/cashhelper.dart';
import 'package:tahsel/core/utils/app_strings.dart';

abstract class LangLocalDataSource {
  Future<bool> changeLang({required String langCode});
  Future<String> getSavedLang();
}

class LangLocalDataSourceImpl implements LangLocalDataSource {
  LangLocalDataSourceImpl();
  @override
  Future<bool> changeLang({required String langCode}) async =>
      await sl<CashHelper>().saveData(key: AppStrings.locale, value: langCode);

  @override
  Future<String> getSavedLang() async =>
      sl<CashHelper>().getData(key: AppStrings.locale) ??
      AppStrings.englishCode;
}
