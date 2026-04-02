import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _debounceTimer;
  
  static const _debounceDuration = Duration(milliseconds: 500);

  ConnectivityCubit({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
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
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      final isConnected = results.isNotEmpty && 
                         results.first != ConnectivityResult.none;
      
      if (isConnected) {
        if (state is! ConnectivityConnected) {
          emit(ConnectivityConnected(results.first));
        }
      } else {
        if (state is! ConnectivityDisconnected) {
          emit(const ConnectivityDisconnected());
        }
      }
    });
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
    _debounceTimer?.cancel();
    _subscription?.cancel();
    return super.close();
  }
}
