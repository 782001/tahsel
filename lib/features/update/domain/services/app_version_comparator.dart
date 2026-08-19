/// Service responsible for numeric semantic version comparison and build number evaluation.
///
/// Ensures safe parsing and strict evaluation order:
/// 1. Semantic Version comparison first (segment by segment numerically).
/// 2. Build Number comparison only when Version names are equal.
class AppVersionComparator {
  /// Parses a version string like "1.0.10", "01.02.003", "1.0.0-beta" into a list of integers.
  /// Null, empty, or non-numeric strings are handled safely without throwing exceptions.
  static List<int> parseVersionSegments(String? versionStr) {
    if (versionStr == null || versionStr.trim().isEmpty) {
      return [0];
    }

    // Clean version string: take only the primary part before any '+' or '-' (prerelease/build metadata)
    String cleanStr = versionStr.trim();
    if (cleanStr.contains('+')) {
      cleanStr = cleanStr.split('+').first;
    }
    if (cleanStr.contains('-')) {
      cleanStr = cleanStr.split('-').first;
    }

    final rawSegments = cleanStr.split('.');
    final List<int> segments = [];

    for (final seg in rawSegments) {
      // Remove non-digit characters if any remain
      final digitsOnly = seg.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.isNotEmpty) {
        final val = int.tryParse(digitsOnly) ?? 0;
        segments.add(val);
      } else {
        segments.add(0);
      }
    }

    return segments.isEmpty ? [0] : segments;
  }

  /// Compares two version strings semantically (segment by segment numerically).
  ///
  /// Returns:
  /// - `1` if [v1] > [v2]
  /// - `-1` if [v1] < [v2]
  /// - `0` if [v1] == [v2]
  static int compareVersions(String? v1, String? v2) {
    final segs1 = parseVersionSegments(v1);
    final segs2 = parseVersionSegments(v2);

    final maxLength = segs1.length > segs2.length ? segs1.length : segs2.length;

    for (int i = 0; i < maxLength; i++) {
      final int s1 = i < segs1.length ? segs1[i] : 0;
      final int s2 = i < segs2.length ? segs2[i] : 0;

      if (s1 > s2) return 1;
      if (s1 < s2) return -1;
    }

    return 0;
  }

  /// Parses a build number dynamically from `dynamic` (num, int, String, or null) into an integer.
  static int parseBuildNumber(dynamic rawBuild) {
    if (rawBuild == null) return 0;
    if (rawBuild is num) return rawBuild.toInt();
    if (rawBuild is String) {
      final digitsOnly = rawBuild.trim().replaceAll(RegExp(r'\D'), '');
      return int.tryParse(digitsOnly) ?? 0;
    }
    return 0;
  }

  /// Primary logic to determine whether an update is required.
  ///
  /// Rule:
  /// 1. Compare version strings first.
  ///    If [remoteVersion] > [currentVersion] -> true
  ///    If [remoteVersion] < [currentVersion] -> false
  /// 2. If version strings are EQUAL:
  ///    Compare build numbers: returns [remoteBuild] > [currentBuild].
  static bool isUpdateRequired({
    required String? currentVersion,
    required dynamic currentBuild,
    required String? remoteVersion,
    required dynamic remoteBuild,
  }) {
    final int vComparison = compareVersions(remoteVersion, currentVersion);

    if (vComparison > 0) {
      return true;
    }
    if (vComparison < 0) {
      return false;
    }

    // Version strings are equal -> compare build numbers numerically
    final int cBuild = parseBuildNumber(currentBuild);
    final int rBuild = parseBuildNumber(remoteBuild);

    return rBuild > cBuild;
  }
}
