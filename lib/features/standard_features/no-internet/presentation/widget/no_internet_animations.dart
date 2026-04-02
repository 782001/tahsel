import 'package:flutter/material.dart';

class NoInternetAnimations {
  final AnimationController controller;
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;
  final Animation<Offset> slideAnimation;
  final Animation<Color?> colorAnimation;

  NoInternetAnimations({
    required this.controller,
    required this.fadeAnimation,
    required this.scaleAnimation,
    required this.slideAnimation,
    required this.colorAnimation,
  });

  factory NoInternetAnimations.create(TickerProvider vsync) {
    final controller = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 600),
    );

    final fadeAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    final scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ),
    );

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );

    final colorAnimation = ColorTween(
      begin: const Color(0xFF424242),
      end: const Color(0xFFFF5252),
    ).animate(controller);

    return NoInternetAnimations(
      controller: controller,
      fadeAnimation: fadeAnimation,
      scaleAnimation: scaleAnimation,
      slideAnimation: slideAnimation,
      colorAnimation: colorAnimation,
    );
  }

  void dispose() {
    controller.dispose();
  }

  void forward() {
    controller.forward();
  }

  void reverse() {
    controller.reverse();
  }
}
