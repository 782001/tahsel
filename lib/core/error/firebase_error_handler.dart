import 'package:firebase_auth/firebase_auth.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../services/injection_container.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
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
        // CRITICAL FIX: Only logout if we are ONLINE.
        // If offline, errors like 'permission-denied' can happen due to
        // network sync issues or token refresh failures, which should NOT log out the user.
        final bool hasInternet =
            await sl<InternetConnectionChecker>().hasConnection;

        if (hasInternet) {
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
            'Auth-related error ($code) detected while OFFLINE - IGNORING to preserve session',
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
}
