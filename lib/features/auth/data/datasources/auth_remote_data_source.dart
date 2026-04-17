import 'package:firebase_auth/firebase_auth.dart';
import 'package:tahsel/core/error/exceptions.dart';
import '../models/user_model.dart';
import '../../domain/usecases/login_usecase.dart';

abstract class AuthRemoteDataSourceBase {
  Future<UserModel> login({required LoginParameters parameters});
  Future<void> logout();
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
      throw ServerException(e.code);
    } catch (e) {
      throw ServerException('default');
    }
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }
}
