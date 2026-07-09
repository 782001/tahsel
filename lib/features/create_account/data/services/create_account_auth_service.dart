import 'package:firebase_auth/firebase_auth.dart';
import 'package:tahsel/core/utils/app_logger.dart';

/// Creates Firebase Auth users without signing out the current admin session.
class CreateAccountService {
  Future<UserCredential> createAuthUser({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.signOut();
      return await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      AppLogger.printMessage(e);
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) {
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }
}
