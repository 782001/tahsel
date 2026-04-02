import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/app_colors.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17),
        child: body,
      ),
      backgroundColor: backgroundColor ?? AppColors.scafoldBackGround,
    );
  }
}
