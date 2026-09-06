import 'package:equatable/equatable.dart';
import '../../data/models/user_profile_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfileModel profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileUpdating extends ProfileState {
  final UserProfileModel currentProfile;

  const ProfileUpdating(this.currentProfile);

  @override
  List<Object?> get props => [currentProfile];
}

class ProfileUpdateSuccess extends ProfileState {
  final UserProfileModel updatedProfile;

  const ProfileUpdateSuccess(this.updatedProfile);

  @override
  List<Object?> get props => [updatedProfile];
}

class ProfileUpdateError extends ProfileState {
  final String message;
  final UserProfileModel currentProfile;

  const ProfileUpdateError(this.message, this.currentProfile);

  @override
  List<Object?> get props => [message, currentProfile];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
