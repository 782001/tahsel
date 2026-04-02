import 'package:flutter/services.dart';

import '../../logic/connectivity_cubit.dart';
import '../../logic/connectivity_state.dart';

class NoInternetStateManager {
  bool isChecking = false;
  bool wasDisconnected = false;

  void handleConnectivityChange({
    required ConnectivityState state,
    required VoidCallback onForward,
    required VoidCallback onReverse,
    required VoidCallback onCheckingComplete,
  }) {
    final isDisconnected = state is ConnectivityDisconnected;

    if (isDisconnected && !wasDisconnected) {
      onForward();
      wasDisconnected = true;
    } else if (!isDisconnected && wasDisconnected) {
      onReverse();
      wasDisconnected = false;
    }

    if (isChecking && state is! ConnectivityLoading) {
      isChecking = false;
      onCheckingComplete();
    }
  }

  Future<void> handleRetry({
    required ConnectivityCubit cubit,
    required bool mounted,
    required VoidCallback onStartChecking,
    VoidCallback? onRetryCallback,
  }) async {
    await HapticFeedback.lightImpact();
    if (!mounted) return;

    isChecking = true;
    onStartChecking();

    if (!mounted) return;
    cubit.checkConnectivity();
    onRetryCallback?.call();
  }
}
