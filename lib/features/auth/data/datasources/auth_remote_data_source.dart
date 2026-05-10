import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserModel> login({required LoginParameters parameters}) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: parameters.email,
        password: parameters.password,
      );
      if (userCredential.user != null) {
        // Fetch user type from Firestore
        final doc = await firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        final userType = doc.exists ? doc.get('userType') : 'cafe';

        return UserModel.fromFirebaseUser(
          userCredential.user!,
          userType: userType,
        );
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
    try {
      await firestore.terminate();
      await firestore.clearPersistence();
    } catch (e) {
      // Ignore if cache is already cleared or throws
    }
    await firebaseAuth.signOut();
  }
}
