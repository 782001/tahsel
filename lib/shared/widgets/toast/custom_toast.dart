import 'package:fluttertoast/fluttertoast.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/responsive_text.dart';

void showSuccessToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    fontAsset: Assets.fontsDGAgnadeenRegular,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.TOP,
    timeInSecForIosWeb: 1,
    backgroundColor: AppColors.green,
    textColor: AppColors.whiteColor,
    fontSize: getResponsiveFontSize(fontSize: 14),
  );
}

void showfailureToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    fontAsset: Assets.fontsDGAgnadeenRegular,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.TOP,
    timeInSecForIosWeb: 1,
    backgroundColor: AppColors.redColor,
    textColor: AppColors.whiteColor,
    fontSize: getResponsiveFontSize(fontSize: 14),
  );
}
