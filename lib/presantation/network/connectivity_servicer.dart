import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class InternetService {
  static final Connectivity _connectivity = Connectivity();
  static final _controller = StreamController<bool>.broadcast();
  static StreamSubscription? _connectivitySubscription;
  static StreamSubscription? _internetSubscription;

  static Stream<bool> get connectionStreams => _controller.stream;

  static Future<void> initialize() async {
    // Cancel existing subscriptions before re-initializing
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();

    // ✅ Listen for connectivity changes (supports both old/new API)
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) async {
          // Handle both new (List<ConnectivityResult>) and old (ConnectivityResult)
          final results = result is List<ConnectivityResult> ? result : [result];

          if (results.contains(ConnectivityResult.none)) {
            _controller.add(false);
          } else {
            final hasAccess = await InternetConnection().hasInternetAccess;
            _controller.add(hasAccess);
          }
        });

    // ✅ Listen for real internet access changes
    _internetSubscription =
        InternetConnection().onStatusChange.listen((status) {
          final connected = status == InternetStatus.connected;
          _controller.add(connected);
        });
  }

  static Future<bool> hasInternet() async {
    final results = await _connectivity.checkConnectivity();
    final list =
    results is List<ConnectivityResult> ? results : [results];

    if (list.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  static void dispose() {
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    _controller.close();
  }
}
