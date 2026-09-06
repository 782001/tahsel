import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/services/profile/business_profile_service.dart';
import 'package:tahsel/features/create_account/data/utils/search_keywords_builder.dart';
import '../../data/models/user_profile_model.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  ProfileCubit({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  })  : _firestore = firestore,
        _firebaseAuth = firebaseAuth,
        super(ProfileInitial());

  Future<void> loadProfile() async {
    final uid = AppStrings.userToken;
    if (uid.isEmpty) {
      final currentAuthUser = _firebaseAuth.currentUser;
      if (currentAuthUser != null) {
        AppStrings.userToken = currentAuthUser.uid;
      } else {
        emit(const ProfileError('User session is invalid'));
        return;
      }
    }

    final targetUid = AppStrings.userToken;
    emit(ProfileLoading());

    try {
      final doc = await _firestore.collection('users').doc(targetUid).get();
      if (!doc.exists) {
        emit(const ProfileError('User document not found'));
        return;
      }

      final data = doc.data() ?? {};
      final currentUser = _firebaseAuth.currentUser;
      final profile = UserProfileModel.fromMap(
        data,
        uid: targetUid,
        fallbackEmail: currentUser?.email,
      );

      await BusinessProfileService.instance.saveProfileToCache(profile);
      emit(ProfileLoaded(profile));
    } catch (e) {
      AppLogger.printMessage('ProfileCubit.loadProfile error: $e');
      emit(ProfileError(e.toString()));
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String projectName,
    String? phoneNumber,
    String? crn,
    String? address,
    String? vat,
  }) async {
    final currentState = state;
    UserProfileModel currentProfile;
    if (currentState is ProfileLoaded) {
      currentProfile = currentState.profile;
    } else if (currentState is ProfileUpdateError) {
      currentProfile = currentState.currentProfile;
    } else if (currentState is ProfileUpdateSuccess) {
      currentProfile = currentState.updatedProfile;
    } else {
      final uid = AppStrings.userToken;
      final email = _firebaseAuth.currentUser?.email ?? '';
      currentProfile = UserProfileModel(
        uid: uid,
        email: email,
        fullName: fullName,
        projectName: projectName,
      );
    }

    emit(ProfileUpdating(currentProfile));

    try {
      final uid = currentProfile.uid.isNotEmpty ? currentProfile.uid : AppStrings.userToken;
      final email = currentProfile.email.isNotEmpty ? currentProfile.email : (_firebaseAuth.currentUser?.email ?? '');

      final trimmedFullName = fullName.trim();
      final trimmedProjectName = projectName.trim();
      final trimmedPhone = (phoneNumber ?? '').trim();
      final trimmedCrn = (crn ?? '').trim();
      final trimmedAddress = (address ?? '').trim();
      final trimmedVat = (vat ?? '').trim();

      final updates = {
        'fullName': trimmedFullName,
        'projectName': trimmedProjectName,
        'phoneNumber': trimmedPhone,
        'crn': trimmedCrn,
        'address': trimmedAddress,
        'vat': trimmedVat,
        'searchKeywords': SearchKeywordsBuilder.build(
          uid: uid,
          fullName: trimmedFullName,
          email: email,
          phoneNumber: trimmedPhone,
        ),
      };

      await _firestore.collection('users').doc(uid).update(updates);

      // Best effort display name sync with FirebaseAuth
      try {
        await _firebaseAuth.currentUser?.updateDisplayName(trimmedFullName);
      } catch (_) {}

      final updatedProfile = currentProfile.copyWith(
        fullName: trimmedFullName,
        projectName: trimmedProjectName,
        phoneNumber: trimmedPhone,
        crn: trimmedCrn,
        address: trimmedAddress,
        vat: trimmedVat,
      );

      await BusinessProfileService.instance.saveProfileToCache(updatedProfile);
      emit(ProfileUpdateSuccess(updatedProfile));
      emit(ProfileLoaded(updatedProfile));
      return true;
    } catch (e) {
      AppLogger.printMessage('ProfileCubit.updateProfile error: $e');
      emit(ProfileUpdateError(e.toString(), currentProfile));
      emit(ProfileLoaded(currentProfile));
      return false;
    }
  }
}
