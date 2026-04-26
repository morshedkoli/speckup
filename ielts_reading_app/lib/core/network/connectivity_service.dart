import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService(this._connectivity);

  Future<bool> get isConnected async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.contains(ConnectivityResult.none)) {
        return false;
      }
      return true;
    } catch (_) {
      return false; // Safely assume no connection if error
    }
  }

  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      return !results.contains(ConnectivityResult.none);
    });
  }
}

@riverpod
ConnectivityService connectivityService(Ref ref) {
  return ConnectivityService(Connectivity());
}

@riverpod
Future<bool> isConnected(Ref ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.isConnected;
}
