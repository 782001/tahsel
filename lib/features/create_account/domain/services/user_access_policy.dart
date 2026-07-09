class UserAccessPolicy {
  UserAccessPolicy._();

  static const int gracePeriodDays = 0;

  static const String active = 'active';
  static const String suspended = 'suspended';
  static const String disabled = 'disabled';
  static const String deleted = 'deleted';
  static const String expired = 'expired';
  static const String expiringSoon = 'expiring_soon';

  static DateTime? gracePeriodEnd(DateTime? subscriptionEnd) {
    if (subscriptionEnd == null) return null;
    return subscriptionEnd.add(const Duration(days: gracePeriodDays));
  }

  static String computeSubscriptionStatus({
    required DateTime? subscriptionEnd,
    required String accountStatus,
    required bool subscriptionSuspended,
    DateTime? now,
  }) {
    if (accountStatus == deleted || accountStatus == disabled) return expired;
    if (subscriptionSuspended || accountStatus == suspended) return suspended;
    if (subscriptionEnd == null) return expired;

    final effectiveNow = now ?? DateTime.now();
    if (subscriptionEnd.isBefore(effectiveNow)) return expired;

    final daysRemaining = subscriptionEnd.difference(effectiveNow).inDays;
    if (daysRemaining <= 7) return expiringSoon;
    return active;
  }

  static bool isGracePeriodExpired({
    required DateTime? subscriptionEnd,
    DateTime? now,
  }) {
    final graceEnd = gracePeriodEnd(subscriptionEnd);
    if (graceEnd == null) return true;
    return graceEnd.isBefore(now ?? DateTime.now());
  }

  static bool shouldDisableAfterGrace({
    required String accountStatus,
    required bool subscriptionSuspended,
    required DateTime? subscriptionEnd,
    DateTime? now,
  }) {
    if (accountStatus != active) return false;
    if (subscriptionSuspended) return false;
    return isGracePeriodExpired(subscriptionEnd: subscriptionEnd, now: now);
  }

  static bool isLoginAllowed({
    required String accountStatus,
    required bool subscriptionSuspended,
    required DateTime? subscriptionEnd,
    DateTime? now,
  }) {
    if (accountStatus != active) return false;
    if (subscriptionSuspended) return false;
    return !isGracePeriodExpired(subscriptionEnd: subscriptionEnd, now: now);
  }
}
