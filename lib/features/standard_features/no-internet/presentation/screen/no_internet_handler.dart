import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/connectivity_cubit.dart';
import '../../logic/connectivity_state.dart';
import '../widget/no_internet_animations.dart';
import '../widget/no_internet_overlay.dart';
import '../widget/no_internet_state_manager.dart';

class NoInternetHandler extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRetry;

  const NoInternetHandler({
    super.key,
    required this.child,
    this.onRetry,
  });

  @override
  State<NoInternetHandler> createState() => _NoInternetHandlerState();
}

class _NoInternetHandlerState extends State<NoInternetHandler>
    with SingleTickerProviderStateMixin {
  late final NoInternetAnimations _animations;
  late final NoInternetStateManager _stateManager;
  late final ConnectivityCubit _cubit;

  @override
  void initState() {
    super.initState();
    _animations = NoInternetAnimations.create(this);
    _stateManager = NoInternetStateManager();
    _cubit = context.read<ConnectivityCubit>();
    _checkInitialConnectivity();
  }

  void _checkInitialConnectivity() {
    _cubit.checkConnectivity();
  }

  @override
  void dispose() {
    _animations.dispose();
    super.dispose();
  }

  void _handleConnectivityChange(BuildContext context, ConnectivityState state) {
    _stateManager.handleConnectivityChange(
      state: state,
      onForward: _animations.forward,
      onReverse: _animations.reverse,
      onCheckingComplete: () => setState(() {}),
    );
  }

  Future<void> _handleRetry() async {
    await _stateManager.handleRetry(
      cubit: _cubit,
      mounted: mounted,
      onStartChecking: () => setState(() {}),
      onRetryCallback: widget.onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<ConnectivityCubit, ConnectivityState>(
        listener: _handleConnectivityChange,
        buildWhen: (previous, current) =>
            previous.runtimeType != current.runtimeType,
        builder: (context, state) {
          return Stack(
            children: [
              widget.child,
              if (state is ConnectivityDisconnected)
                FadeTransition(
                  opacity: _animations.fadeAnimation,
                  child: NoInternetOverlay(
                    scaleAnimation: _animations.scaleAnimation,
                    slideAnimation: _animations.slideAnimation,
                    colorAnimation: _animations.colorAnimation,
                    isChecking: _stateManager.isChecking,
                    onRetry: _handleRetry,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
