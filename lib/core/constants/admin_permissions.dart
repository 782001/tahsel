/// Role-based permissions enforced in Firestore rules and mirrored client-side.
class AdminPermissions {
  AdminPermissions._();

  static const usersRead = 'users.read';
  static const usersWrite = 'users.write';
  static const subscriptionsWrite = 'subscriptions.write';
  static const subscriptionsRead = 'subscriptions.read';
  static const notificationsWrite = 'notifications.write';
  static const notificationsRead = 'notifications.read';
  static const auditRead = 'audit.read';
  static const auditWrite = 'audit.write';
  static const settingsRead = 'settings.read';
  static const settingsWrite = 'settings.write';
  static const adminsWrite = 'admins.write';

  static const superAdmin = 'super_admin';
  static const admin = 'admin';
  static const support = 'support';

  static List<String> forRole(String role) {
    switch (role) {
      case superAdmin:
        return ['*'];
      case admin:
        return [
          usersRead,
          usersWrite,
          subscriptionsWrite,
          subscriptionsRead,
          notificationsWrite,
          notificationsRead,
          auditRead,
          auditWrite,
          settingsRead,
        ];
      case support:
        return [
          usersRead,
          subscriptionsRead,
          notificationsRead,
          auditRead,
        ];
      default:
        return [];
    }
  }

  static bool has(String role, List<String>? stored, String permission) {
    if (role == superAdmin) return true;
    final perms = stored ?? forRole(role);
    if (perms.contains('*')) return true;
    return perms.contains(permission);
  }

  static bool canWriteUsers(String role) =>
      role == superAdmin || role == admin;

  static bool canWriteSubscriptions(String role) =>
      role == superAdmin || role == admin;

  static bool canWriteNotifications(String role) =>
      role == superAdmin || role == admin;

  static bool canWriteSettings(String role) => role == superAdmin;

  static bool canWriteAudit(String role) =>
      role == superAdmin || role == admin;
}
