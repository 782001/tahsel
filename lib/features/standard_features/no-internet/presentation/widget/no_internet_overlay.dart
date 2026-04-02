import 'package:flutter/material.dart';

import 'no_internet_card.dart';

class NoInternetOverlay extends StatelessWidget {
  final Animation<double> scaleAnimation;
  final Animation<Offset> slideAnimation;
  final Animation<Color?> colorAnimation;
  final bool isChecking;
  final VoidCallback onRetry;

  const NoInternetOverlay({
    super.key,
    required this.scaleAnimation,
    required this.slideAnimation,
    required this.colorAnimation,
    required this.isChecking,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xF2FFFFFF),
      child: Center(
        child: ScaleTransition(
          scale: scaleAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: NoInternetCard(
              colorAnimation: colorAnimation,
              isChecking: isChecking,
              onRetry: onRetry,
            ),
          ),
        ),
      ),
    );
  }
}
