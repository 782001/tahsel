import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/settings/data/models/user_profile_model.dart';

/// Singleton service for caching, retrieving, and providing the active project/business profile.
/// Ensures 0ms offline-first access for PDF generators, screens, and receipts.
class BusinessProfileService {
  BusinessProfileService._internal();
  static final BusinessProfileService instance = BusinessProfileService._internal();

  UserProfileModel? _cachedProfile;

  /// Returns the current user's UID from FirebaseAuth or AppStrings
  String? get currentUid {
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid != null && authUid.isNotEmpty) return authUid;
    if (AppStrings.userToken.isNotEmpty) return AppStrings.userToken;
    return null;
  }

  /// Gets the business profile for the active account.
  /// 1. Returns in-memory cache if valid.
  /// 2. Falls back to SharedPreferences local storage (Offline-first, 0ms latency).
  /// 3. Falls back to remote Firestore document if cache is empty or [forceRemote] is true.
  Future<UserProfileModel?> getProfile({bool forceRemote = false}) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) return null;

    // 1. In-memory check
    if (_cachedProfile != null && _cachedProfile!.uid == uid && !forceRemote) {
      return _cachedProfile;
    }

    // 2. SharedPreferences local check (Instant, Offline)
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_business_profile_$uid';
      final rawJson = prefs.getString(key);
      if (rawJson != null && rawJson.isNotEmpty && !forceRemote) {
        final map = jsonDecode(rawJson) as Map<String, dynamic>;
        _cachedProfile = UserProfileModel.fromMap(map, uid: uid);
        return _cachedProfile;
      }
    } catch (e) {
      debugPrint('BusinessProfileService local read error: $e');
    }

    // 3. Remote Firestore fallback
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final profile = UserProfileModel.fromMap(
          data,
          uid: uid,
          fallbackEmail: FirebaseAuth.instance.currentUser?.email,
        );
        await saveProfileToCache(profile);
        return profile;
      }
    } catch (e) {
      debugPrint('BusinessProfileService remote read error: $e');
    }

    return _cachedProfile;
  }

  /// Persists the profile in memory and in SharedPreferences keyed by [profile.uid]
  Future<void> saveProfileToCache(UserProfileModel profile) async {
    _cachedProfile = profile;
    if (profile.uid.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_business_profile_${profile.uid}';
      final jsonStr = jsonEncode(profile.toMap());
      await prefs.setString(key, jsonStr);
    } catch (e) {
      debugPrint('BusinessProfileService saveProfileToCache error: $e');
    }
  }

  /// Clears in-memory cache (e.g. on sign out)
  void clearMemoryCache() {
    _cachedProfile = null;
  }
}
