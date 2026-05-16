import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/widgets/exit_confirmation_dialog.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_state.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/main_layout/presentation/widgets/bottom_nav_bar.dart';
import 'package:tahsel/features/main_layout/presentation/widgets/side_nav_bar.dart';
import 'package:tahsel/features/offline_sync/presentation/widgets/offline_banner.dart';
import 'package:tahsel/features/offline_sync/presentation/widgets/sync_status_listener.dart';
import 'package:tahsel/features/standard_features/localization/presentation/cubit/locale_cubit.dart';
import 'package:tahsel/features/standard_features/theme/presentation/cubit/theme_cubit.dart';
import 'package:tahsel/features/standard_features/theme/presentation/cubit/theme_state.dart';
import 'package:tahsel/features/update/presentation/cubit/update_cubit.dart';
import 'package:tahsel/features/update/presentation/widgets/update_dialog.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger update check
    context.read<UpdateCubit>().checkForUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UpdateCubit, UpdateState>(
      listener: (context, state) {
        if (state is UpdateAvailable) {
          showDialog(
            context: context,
            barrierDismissible: !state.versionInfo.forceUpdate,
            builder: (context) => UpdateDialog(versionInfo: state.versionInfo),
          );
        } else if (state is UpdateError) {
          AppLogger.printMessage("DEBUG: UpdateCubit Error: ${state.message}");
        } else if (state is UpdateNotAvailable) {
          AppLogger.printMessage("DEBUG: UpdateCubit: No update available.");
        }
      },
      child: BlocBuilder<ThemeCubit, ThemeState>(
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

                      if (cubit.currentIndex != 0) {
                        cubit.changeBottomNav(0);
                        return;
                      }

                      final shouldExit = await showDialog<bool>(
                        context: context,
                        builder: (context) => const ExitConfirmationDialog(),
                      );

                      if (shouldExit ?? false) {
                        SystemNavigator.pop();
                      }
                    },
                    child: Scaffold(
                      extendBody: true,
                      backgroundColor: AppColors.scafoldBackGround,
                      bottomNavigationBar: ResponsiveLayout.isDesktop(context)
                          ? null
                          : BottomNavBar(cubit: cubit),
                      body: SafeArea(
                        child: SyncStatusListener(
                          child: OfflineBanner(
                            child: ResponsiveLayout(
                              mobile: cubit.screens[cubit.currentIndex],
                              desktop: Row(
                                children: [
                                  SideNavBar(cubit: cubit),
                                  Expanded(
                                    child: cubit.screens[cubit.currentIndex],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
