import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/storage/cashhelper.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/standard_features/localization/domain/usecases/change_lang.dart';
import 'package:tahsel/features/standard_features/localization/domain/usecases/get_saved_lang.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/features/standard_features/localization/domain/usecases/no_parameter.dart';

part 'locale_state.dart';

class LocaleCubit extends Cubit<LocaleState> {
  final GetSavedLangUseCase getSavedLangUseCase;
  final ChangeLangUseCase changeLangUseCase;
  LocaleCubit({
    required this.getSavedLangUseCase,
    required this.changeLangUseCase,
  }) : super(const ChangeLocaleState(Locale(AppStrings.englishCode)));

  String currentLangCode = AppStrings.englishCode;

  Future<void> getSavedLang() async {
    final response = await getSavedLangUseCase.call(NoParemeters());
    response.fold((failure) => AppLogger.handleLogs(AppStrings.cacheFailure), (
      value,
    ) {
      currentLangCode = value;
      AppStrings.currentLang = value;
      emit(ChangeLocaleState(Locale(currentLangCode)));
    });
  }

  Future<void> _changeLang(String langCode) async {
    final response = await changeLangUseCase.call(langCode);
    response.fold((failure) => AppLogger.handleLogs(AppStrings.cacheFailure), (
      value,
    ) {
      currentLangCode = langCode;
      AppStrings.currentLang = langCode;

      emit(ChangeLocaleState(Locale(currentLangCode)));
    });
  }

  void toEnglish() => _changeLang(AppStrings.englishCode);

  void toArabic() => _changeLang(AppStrings.arabicCode);
}
