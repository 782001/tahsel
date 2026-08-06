import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity _connectivity;
  final InternetConnectionChecker _connectionChecker;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _stabilityTimer;

  /// Generation counter to invalidate stale verification attempts.
  /// Incremented every time a new connectivity event arrives.
  int _generation = 0;

  /// Stabilization delay before verifying real internet after network interface comes up.
  /// This gives DNS + gRPC/Firestore SDK time to establish their sockets.
  static const _stabilizationDelay = Duration(milliseconds: 1500);

  /// Delay between retry attempts when internet check fails transiently.
  static const _retryDelay = Duration(seconds: 1);

  /// Maximum number of real-internet verification attempts after reconnection.
  static const _maxRetries = 3;

  ConnectivityCubit({
    Connectivity? connectivity,
    InternetConnectionChecker? connectionChecker,
  })  : _connectivity = connectivity ?? Connectivity(),
        _connectionChecker = connectionChecker ?? InternetConnectionChecker(),
        super(const ConnectivityInitial()) {
    _initialize();
  }

  void _initialize() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
      onError: _handleError,
      cancelOnError: false,
    );
    checkConnectivity();
  }

  Future<void> checkConnectivity() async {
    try {
      if (state is! ConnectivityLoading) {
        emit(const ConnectivityLoading());
      }
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (error) {
      _handleError(error);
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    // Invalidate any in-flight verification from a previous event
    _generation++;
    _stabilityTimer?.cancel();

    final hasNetworkInterface =
        results.isNotEmpty && results.first != ConnectivityResult.none;

    if (!hasNetworkInterface) {
      // ─── Disconnection: emit IMMEDIATELY (0ms) ───
      if (state is! ConnectivityDisconnected) {
        emit(const ConnectivityDisconnected());
      }
    } else {
      // ─── Reconnection: wait for stabilization + verify real internet ───
      final capturedGeneration = _generation;
      _stabilityTimer = Timer(_stabilizationDelay, () {
        _verifyRealInternet(results.first, generation: capturedGeneration);
      });
    }
  }

  /// Performs actual internet reachability check with retries.
  /// Only emits [ConnectivityConnected] when a real HTTP/DNS lookup succeeds.
  /// [generation] ensures this verification is abandoned if a newer connectivity
  /// event has arrived (e.g. WiFi dropped during the await).
  Future<void> _verifyRealInternet(
    ConnectivityResult interfaceResult, {
    required int generation,
    int attempt = 1,
  }) async {
    // Guard: if cubit was closed or a newer event invalidated us, abort.
    if (isClosed || generation != _generation) return;

    final hasRealInternet = await _connectionChecker.hasConnection;

    // Re-check after the await — a newer event may have arrived during the lookup
    if (isClosed || generation != _generation) return;

    if (hasRealInternet) {
      if (state is! ConnectivityConnected) {
        emit(ConnectivityConnected(interfaceResult));
      }
    } else if (attempt < _maxRetries) {
      // Internet not stable yet — retry after a short delay
      _stabilityTimer?.cancel();
      _stabilityTimer = Timer(_retryDelay, () {
        _verifyRealInternet(
          interfaceResult,
          generation: generation,
          attempt: attempt + 1,
        );
      });
    }
    // If all retries exhausted, stay in current state (Disconnected).
    // The next connectivity_plus event will re-trigger verification.
  }

  void _handleError(Object error) {
    final errorMessage = error.toString();
    if (state is! ConnectivityError ||
        (state as ConnectivityError).message != errorMessage) {
      emit(ConnectivityError(errorMessage));
    }
  }

  @override
  Future<void> close() {
    _stabilityTimer?.cancel();
    _subscription?.cancel();
    return super.close();
  }
}
