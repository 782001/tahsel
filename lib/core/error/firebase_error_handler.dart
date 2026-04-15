import 'package:firebase_auth/firebase_auth.dart';
import '../services/injection_container.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../utils/app_logger.dart';

class FirebaseErrorHandler {
  /// Handles Firebase exceptions globally.
  /// If an auth-related error is detected, it triggers a forced logout.
  static void handle(dynamic e) {
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
        AppLogger.printMessage('Auth-related error detected, forcing logout...');
        try {
          sl<AuthCubit>().forceLogout();
        } catch (err) {
          AppLogger.printMessage('Failed to trigger forceLogout: $err');
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
