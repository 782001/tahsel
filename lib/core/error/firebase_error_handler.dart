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
    return getLocalizedMessage(e);
  }

  /// Converts Firebase exceptions or raw error strings into a localized translation key or clean message.
  static String getLocalizedMessage(dynamic e) {
    String raw = '';
    if (e is FirebaseAuthException) {
      raw = '${e.code} ${e.message ?? ''}';
    } else if (e is FirebaseException) {
      raw = '${e.code} ${e.message ?? ''}';
    } else {
      raw = e?.toString() ?? '';
    }

    final lower = raw.toLowerCase();

    if (lower.contains('email-already-in-use') ||
        lower.contains('email address is already in use')) {
      return 'auth_email_already_in_use';
    }
    if (lower.contains('weak-password') ||
        lower.contains('password is too weak')) {
      return 'auth_weak_password';
    }
    if (lower.contains('invalid-email') ||
        lower.contains('badly formatted')) {
      return 'auth_invalid_email';
    }
    if (lower.contains('operation-not-allowed')) {
      return 'auth_operation_not_allowed';
    }
    if (lower.contains('network-request-failed') ||
        lower.contains('network error')) {
      return 'auth_network_error';
    }
    if (lower.contains('too-many-requests')) {
      return 'auth_too_many_requests';
    }
    if (lower.contains('channel-error')) {
      return 'auth_channel_error';
    }
    if (lower.contains('permission-denied') ||
        lower.contains('permission_denied')) {
      return 'auth_permission_denied';
    }
    if (lower.contains('user-not-found')) {
      return 'auth_user_not_found';
    }
    if (lower.contains('wrong-password') ||
        lower.contains('invalid-credential')) {
      return 'auth_invalid_credential';
    }

    // Clean up raw Firebase error format if possible (e.g. "[firebase_auth/xxx] Message" -> "Message")
    if (raw.contains(']')) {
      final parts = raw.split(']');
      if (parts.length > 1 && parts.last.trim().isNotEmpty) {
        return parts.last.trim();
      }
    }

    if (raw.isNotEmpty) {
      return raw;
    }

    return 'failed_to_create_user';
  }
}
