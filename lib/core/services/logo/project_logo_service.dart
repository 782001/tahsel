import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tahsel/core/utils/app_logger.dart';

/// Service for managing the business/project logo locally on device per user account (UID).
/// It provides zero-cost, instant offline loading without syncing to Firebase Storage.
class ProjectLogoService {
  ProjectLogoService._internal();
  static final ProjectLogoService instance = ProjectLogoService._internal();

  /// Reactive notifier holding the current account's logo file path (or null if none set).
  /// Any UI widget can listen to this notifier (via ValueListenableBuilder) to update instantly.
  final ValueNotifier<String?> logoNotifier = ValueNotifier<String?>(null);

  bool _initialized = false;

  /// Initializes the service and registers an auth state listener to automatically
  /// switch logos when users sign in, switch accounts, or sign out.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Load logo for current user immediately
    await refreshCurrentLogo();

    // Listen to auth changes so switching accounts instantly switches logos
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      await refreshCurrentLogo(uid: user?.uid);
    });
  }

  /// Get current user UID
  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  /// Refresh the active logo notifier for the given [uid] or the current user.
  Future<void> refreshCurrentLogo({String? uid}) async {
    final targetUid = uid ?? _currentUid;
    if (targetUid == null || targetUid.isEmpty) {
      logoNotifier.value = null;
      return;
    }

    final path = await getLogoPath(uid: targetUid);
    logoNotifier.value = path;
  }

  /// Returns the directory where project logos are stored.
  Future<Directory> _getLogosDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final logosDir = Directory('${appDir.path}/project_logos');
    if (!await logosDir.exists()) {
      await logosDir.create(recursive: true);
    }
    return logosDir;
  }

  /// Get the local file path of the project logo for the given [uid] (or active user).
  Future<String?> getLogoPath({String? uid}) async {
    final targetUid = uid ?? _currentUid;
    if (targetUid == null || targetUid.isEmpty) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'project_logo_$targetUid';
      final path = prefs.getString(key);

      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          return path;
        } else {
          // File was removed from storage, clear dead pref
          await prefs.remove(key);
        }
      }
    } catch (_) {}

    return null;
  }

  /// Get the File object for the project logo of [uid] (or active user).
  Future<File?> getLogoFile({String? uid}) async {
    final path = await getLogoPath(uid: uid);
    if (path != null) {
      return File(path);
    }
    return null;
  }

  /// Get raw bytes of the project logo (useful for PDF generation, receipt printing, etc.)
  Future<Uint8List?> getLogoBytes({String? uid}) async {
    try {
      final file = await getLogoFile(uid: uid);
      if (file != null && await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (_) {}
    return null;
  }

  /// Saves a new project logo from [sourceFilePath] locally for the given [uid] (or active user).
  /// Automatically cleans up any previously stored logo file for this account to save disk space.
  Future<File?> saveLogo(String sourceFilePath, {String? uid}) async {
    final targetUid = uid ?? _currentUid;
    if (targetUid == null || targetUid.isEmpty) return null;

    try {
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) return null;

      final logosDir = await _getLogosDirectory();
      final prefs = await SharedPreferences.getInstance();
      final key = 'project_logo_$targetUid';

      // 1. Clean up old logo file if it exists
      final oldPath = prefs.getString(key);
      if (oldPath != null && oldPath.isNotEmpty) {
        try {
          final oldFile = File(oldPath);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (_) {}
      }

      // 2. Extract file extension or default to .png
      String ext = '.png';
      final lastDot = sourceFilePath.lastIndexOf('.');
      if (lastDot != -1) {
        ext = sourceFilePath.substring(lastDot);
      }

      // 3. Create unique destination path with timestamp to bust image caches
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final destPath = '${logosDir.path}/logo_${targetUid}_$timestamp$ext';

      // 4. Copy the file into the local sandbox
      final savedFile = await sourceFile.copy(destPath);

      // 5. Persist path in SharedPreferences
      await prefs.setString(key, savedFile.path);

      // 6. Update reactive notifier
      logoNotifier.value = savedFile.path;

      return savedFile;
    } catch (e) {
      AppLogger.printMessage('ProjectLogoService saveLogo error: $e');
      return null;
    }
  }

  /// Removes the stored project logo for [uid] (or active user) and cleans up the file.
  Future<void> deleteLogo({String? uid}) async {
    final targetUid = uid ?? _currentUid;
    if (targetUid == null || targetUid.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'project_logo_$targetUid';
      final path = prefs.getString(key);

      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
        await prefs.remove(key);
      }

      logoNotifier.value = null;
    } catch (e) {
      AppLogger.printMessage('ProjectLogoService deleteLogo error: $e');
    }
  }
}
