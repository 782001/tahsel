import 'package:flutter_test/flutter_test.dart';
import 'package:tahsel/features/update/domain/services/app_version_comparator.dart';

void main() {
  group('AppVersionComparator - Semantic Version Comparison', () {
    test('1.0.10 is greater than 1.0.9 (numeric, not string lexicographical)', () {
      expect(AppVersionComparator.compareVersions('1.0.10', '1.0.9'), equals(1));
      expect(AppVersionComparator.compareVersions('1.0.9', '1.0.10'), equals(-1));
    });

    test('1.1.0 is greater than 1.0.99', () {
      expect(AppVersionComparator.compareVersions('1.1.0', '1.0.99'), equals(1));
    });

    test('2.0.0 is greater than 1.99.99', () {
      expect(AppVersionComparator.compareVersions('2.0.0', '1.99.99'), equals(1));
    });

    test('Identical version strings return 0', () {
      expect(AppVersionComparator.compareVersions('1.0.0', '1.0.0'), equals(0));
      expect(AppVersionComparator.compareVersions('1.2.3', '1.2.3'), equals(0));
    });

    test('Leading zeros and different segment counts handled correctly', () {
      expect(AppVersionComparator.compareVersions('01.02.003', '1.2.3'), equals(0));
      expect(AppVersionComparator.compareVersions('1.0', '1.0.0'), equals(0));
      expect(AppVersionComparator.compareVersions('1', '1.0.0'), equals(0));
    });

    test('Handles suffixes like -beta or +build safely', () {
      expect(AppVersionComparator.compareVersions('1.0.0-beta', '1.0.0'), equals(0));
      expect(AppVersionComparator.compareVersions('1.0.1+15', '1.0.0'), equals(1));
    });
  });

  group('AppVersionComparator - Build Number Parsing', () {
    test('Parses integers, numbers, and strings correctly', () {
      expect(AppVersionComparator.parseBuildNumber(10), equals(10));
      expect(AppVersionComparator.parseBuildNumber('10'), equals(10));
      expect(AppVersionComparator.parseBuildNumber('05'), equals(5));
      expect(AppVersionComparator.parseBuildNumber(5.0), equals(5));
    });

    test('Handles invalid and null build numbers safely', () {
      expect(AppVersionComparator.parseBuildNumber(null), equals(0));
      expect(AppVersionComparator.parseBuildNumber(''), equals(0));
      expect(AppVersionComparator.parseBuildNumber('abc'), equals(0));
    });
  });

  group('AppVersionComparator - Update Required Matrix', () {
    test('Current 1.0.0 + 1 | Remote 1.0.1 + 1 -> Update Available', () {
      final result = AppVersionComparator.isUpdateRequired(
        currentVersion: '1.0.0',
        currentBuild: 1,
        remoteVersion: '1.0.1',
        remoteBuild: 1,
      );
      expect(result, isTrue);
    });

    test('Current 1.0.1 + 1 | Remote 1.0.1 + 2 -> Update Available', () {
      final result = AppVersionComparator.isUpdateRequired(
        currentVersion: '1.0.1',
        currentBuild: 1,
        remoteVersion: '1.0.1',
        remoteBuild: 2,
      );
      expect(result, isTrue);
    });

    test('Current 1.0.1 + 2 | Remote 1.0.1 + 2 -> No Update', () {
      final result = AppVersionComparator.isUpdateRequired(
        currentVersion: '1.0.1',
        currentBuild: 2,
        remoteVersion: '1.0.1',
        remoteBuild: 2,
      );
      expect(result, isFalse);
    });

    test('Current 1.0.2 + 1 | Remote 1.0.1 + 99 -> No Update (Version has priority)', () {
      final result = AppVersionComparator.isUpdateRequired(
        currentVersion: '1.0.2',
        currentBuild: 1,
        remoteVersion: '1.0.1',
        remoteBuild: 99,
      );
      expect(result, isFalse);
    });

    test('Current 1.0.9 + 10 | Remote 1.0.10 + 1 -> Update Available', () {
      final result = AppVersionComparator.isUpdateRequired(
        currentVersion: '1.0.9',
        currentBuild: 10,
        remoteVersion: '1.0.10',
        remoteBuild: 1,
      );
      expect(result, isTrue);
    });

    test('Current 1.1.0 + 1 | Remote 1.0.99 + 999 -> No Update', () {
      final result = AppVersionComparator.isUpdateRequired(
        currentVersion: '1.1.0',
        currentBuild: 1,
        remoteVersion: '1.0.99',
        remoteBuild: 999,
      );
      expect(result, isFalse);
    });

    test('Current 2.0.0 + 1 | Remote 1.99.99 + 999 -> No Update', () {
      final result = AppVersionComparator.isUpdateRequired(
        currentVersion: '2.0.0',
        currentBuild: 1,
        remoteVersion: '1.99.99',
        remoteBuild: 999,
      );
      expect(result, isFalse);
    });
  });

  group('AppVersionComparator - Edge Cases & Robustness', () {
    test('Null or empty versions do not crash', () {
      expect(
        AppVersionComparator.isUpdateRequired(
          currentVersion: null,
          currentBuild: null,
          remoteVersion: '1.0.0',
          remoteBuild: 1,
        ),
        isTrue,
      );

      expect(
        AppVersionComparator.isUpdateRequired(
          currentVersion: '1.0.0',
          currentBuild: 1,
          remoteVersion: null,
          remoteBuild: null,
        ),
        isFalse,
      );
    });

    test('Non-numeric build strings do not crash', () {
      expect(
        AppVersionComparator.isUpdateRequired(
          currentVersion: '1.0.0',
          currentBuild: 'invalid',
          remoteVersion: '1.0.0',
          remoteBuild: '10',
        ),
        isTrue,
      );
    });
  });
}
