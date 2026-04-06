import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/widgets/exit_confirmation_dialog.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_state.dart';
import 'package:tahsel/features/main_layout/presentation/widgets/bottom_nav_bar.dart';
import 'package:tahsel/features/standard_features/localization/presentation/cubit/locale_cubit.dart';
import 'package:tahsel/features/standard_features/theme/presentation/cubit/theme_cubit.dart';
import 'package:tahsel/features/standard_features/theme/presentation/cubit/theme_state.dart';

class MainLayoutScreen extends StatelessWidget {
  const MainLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<LocaleCubit, LocaleState>(
          builder: (context, localeState) {
            return BlocConsumer<MainLayoutCubit, MainLayoutState>(
              listener: (context, state) {},
              builder: (context, state) {
                var cubit = BlocProvider.of<MainLayoutCubit>(context);

                return PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, result) async {
                    if (didPop) return;

                    // 1. If not on Home tab (index 0), go back to Home
                    if (cubit.currentIndex != 0) {
                      cubit.changeBottomNav(0);
                      return;
                    }

                    // 2. If already on Home tab, show exit confirmation dialog
                    final shouldExit = await showDialog<bool>(
                      context: context,
                      builder: (context) => const ExitConfirmationDialog(),
                    );

                    if (shouldExit ?? false) {
                      // Final exit from the app
                      SystemNavigator.pop();
                    }
                  },
                  child: Scaffold(
                    extendBody: true,
                    backgroundColor: AppColors.scafoldBackGround,
                    body: cubit.bottomScreens[cubit.currentIndex],
                    bottomNavigationBar: BottomNavBar(cubit: cubit),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
