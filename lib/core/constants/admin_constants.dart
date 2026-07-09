class AdminConstants {
  AdminConstants._();

  static const String usersCollection = 'users';
  static const String adminsCollection = 'admins';

  static const List<int> subscriptionPresets = [30, 60, 90];
  static const List<int> expirationWindows = [7, 14, 30];

  static const String roleSuperAdmin = 'super_admin';
  static const String roleAdmin = 'admin';
  static const String roleSupport = 'support';
}
