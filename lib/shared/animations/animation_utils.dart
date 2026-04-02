import 'package:flutter/material.dart';

class AnimationUtils {
  static Widget fade({
    required Widget child,
    required AnimationController controller,
    double beginOpacity = 0.0,
    double endOpacity = 1.0,
    Curve curve = Curves.easeInOut,
    VoidCallback? onEnd,
  }) {
    final animation = Tween<double>(
      begin: beginOpacity,
      end: endOpacity,
    ).animate(CurvedAnimation(parent: controller, curve: curve));

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isCompleted && onEnd != null) onEnd();
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static Widget slide({
    required Widget child,
    required AnimationController controller,
    Offset beginOffset = const Offset(1.0, 0.0),
    Offset endOffset = Offset.zero,
    Curve curve = Curves.easeInOut,
    VoidCallback? onEnd,
  }) {
    final animation = Tween<Offset>(
      begin: beginOffset,
      end: endOffset,
    ).animate(CurvedAnimation(parent: controller, curve: curve));

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isCompleted && onEnd != null) onEnd();
        return SlideTransition(position: animation, child: child);
      },
    );
  }

  static Widget scale({
    required Widget child,
    required AnimationController controller,
    double beginScale = 0.0,
    double endScale = 1.0,
    Curve curve = Curves.elasticOut,
    VoidCallback? onEnd,
  }) {
    final animation = Tween<double>(
      begin: beginScale,
      end: endScale,
    ).animate(CurvedAnimation(parent: controller, curve: curve));

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isCompleted && onEnd != null) onEnd();
        return ScaleTransition(scale: animation, child: child);
      },
    );
  }

  static Widget rotate({
    required Widget child,
    required AnimationController controller,
    double beginAngle = 0.0,
    double endAngle = 1.0,
    Curve curve = Curves.easeInOut,
    VoidCallback? onEnd,
  }) {
    final animation = Tween<double>(
      begin: beginAngle,
      end: endAngle,
    ).animate(CurvedAnimation(parent: controller, curve: curve));

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isCompleted && onEnd != null) onEnd();
        return RotationTransition(turns: animation, child: child);
      },
    );
  }
}