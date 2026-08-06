import 'package:firebase_auth/firebase_auth.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../services/injection_container.dart';
import '../utils/app_logger.dart';

class FirebaseErrorHandler {
  /// Handles Firebase exceptions globally.
  /// If an auth-related error is detected, it triggers a forced logout.
  static void handle(dynamic e) async {
    if (e is FirebaseAuthException || e is FirebaseException) {
      final String code = _getErrorCode(e);

      AppLogger.printMessage('Firebase Error Detected: $code');

      final authErrorCodes = [
        'permission-denied',
        'unauthenticated',
        'user-not-found',
        'user-disabled',
        'invalid-credential',
        'expired-token',
        'user-token-expired',
      ];

      if (authErrorCodes.contains(code)) {
        // CRITICAL FIX: Only logout if internet is verified stable.
        // If offline/unstable, errors like 'permission-denied' can happen due to
        // network sync issues or token refresh failures, which should NOT log out the user.
        final bool isOnlineAndStable =
            sl<ConnectivityCubit>().state is ConnectivityConnected;

        if (isOnlineAndStable) {
          AppLogger.printMessage(
            'Auth-related error detected while ONLINE, forcing logout...',
          );
          try {
            sl<AuthCubit>().forceLogout();
          } catch (err) {
            AppLogger.printMessage('Failed to trigger forceLogout: $err');
          }
        } else {
          AppLogger.printMessage(
            'Auth-related error ($code) detected while OFFLINE/UNSTABLE - IGNORING to preserve session',
          );
        }
      }
    }
  }

  static String _getErrorCode(dynamic e) {
    if (e is FirebaseAuthException) return e.code;
    if (e is FirebaseException) return e.code;
    return e.toString();
  }

  static String getMessage(dynamic e) {
    if (e is FirebaseAuthException) return e.message ?? e.code;
    if (e is FirebaseException) return e.message ?? e.code;
    return e.toString();
  }
}
