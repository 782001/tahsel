import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../../domain/usecases/login_usecase.dart';

abstract class AuthRemoteDataSourceBase {
  Future<UserModel> login({required LoginParameters parameters});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSourceBase {
  final FirebaseAuth firebaseAuth;

  AuthRemoteDataSourceImpl({required this.firebaseAuth});

  @override
  Future<UserModel> login({required LoginParameters parameters}) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: parameters.email,
        password: parameters.password,
      );
      if (userCredential.user != null) {
        return UserModel.fromFirebaseUser(userCredential.user!);
      } else {
        throw Exception("User not found");
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided for that user.');
      }
      throw Exception(e.message ?? 'Authentication failed');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
