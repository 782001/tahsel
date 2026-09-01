import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/app_version_model.dart';
import '../../domain/usecases/check_update_usecase.dart';
import '../../domain/usecases/download_update_usecase.dart';

part 'update_state.dart';

class UpdateCubit extends Cubit<UpdateState> {
  final CheckUpdateUseCase _checkUpdateUseCase;
  final DownloadUpdateUseCase _downloadUpdateUseCase;

  UpdateCubit({
    required CheckUpdateUseCase checkUpdateUseCase,
    required DownloadUpdateUseCase downloadUpdateUseCase,
  }) : _checkUpdateUseCase = checkUpdateUseCase,
       _downloadUpdateUseCase = downloadUpdateUseCase,
       super(UpdateInitial());

  Future<void> checkForUpdate() async {
    emit(UpdateChecking());
    try {
      final versionInfo = await _checkUpdateUseCase();
      if (versionInfo != null) {
        emit(UpdateAvailable(versionInfo));
      } else {
        emit(UpdateNotAvailable());
      }
    } catch (e) {
      emit(UpdateError(e.toString()));
    }
  }

  Future<void> startUpdate(AppVersionModel versionInfo) async {
    // جميع المنصات (Android, iOS, Windows) تفتح رابط المتجر مباشرة
    try {
      emit(UpdateRedirectingToStore());
      await _downloadUpdateUseCase.openDownloadLink(versionInfo.downloadUrl);
      emit(UpdateAvailable(versionInfo)); // return to available so dialog stays open
    } catch (e) {
      emit(UpdateError(e.toString()));
    }
  }
}

