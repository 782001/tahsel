import 'package:flutter/material.dart';
import 'package:tahsel/core/services/permission_service.dart';

/// A widget that renders [child] if the current user has the required [permission].
/// If the user lacks permission, it renders [fallback] (defaults to [SizedBox.shrink()]).
class PermissionGuard extends StatelessWidget {
  final String? permission;
  final List<String>? permissions;
  final bool matchAll;
  final Widget child;
  final Widget fallback;

  const PermissionGuard({
    super.key,
    this.permission,
    this.permissions,
    this.matchAll = false,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  }) : assert(
          permission != null || permissions != null,
          'Either permission or permissions list must be provided.',
        );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: PermissionService.instance.changeNotifier,
      builder: (context, _, __) {
        final service = PermissionService.instance;
        bool hasAccess = false;

        if (permission != null) {
          hasAccess = service.hasPermission(permission!);
        } else if (permissions != null) {
          hasAccess = matchAll
              ? service.hasAllPermissions(permissions!)
              : service.hasAnyPermission(permissions!);
        }

        return hasAccess ? child : fallback;
      },
    );
  }
}
