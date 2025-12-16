import 'dart:async';
import 'package:flutter/material.dart';
import 'connectivity_servicer.dart';

class ConnectivityWatcher extends StatefulWidget {
  final Widget child;

  const ConnectivityWatcher({required this.child, super.key});

  @override
  State<ConnectivityWatcher> createState() => _ConnectivityWatcherState();
}

class _ConnectivityWatcherState extends State<ConnectivityWatcher> {
  StreamSubscription<bool>? _subscription;
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();

    _subscription =
        InternetService.connectionStreams.listen((hasInternet) {
      if (mounted) {
        setState(() {
          _hasInternet = hasInternet;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// 🔑 Provide internet status down the tree
    return _ConnectivityScope(
      hasInternet: _hasInternet,
      child: widget.child,
    );
  }
}

/// 🔑 Simple inherited widget to access internet anywhere
class _ConnectivityScope extends InheritedWidget {
  final bool hasInternet;

  const _ConnectivityScope({
    required this.hasInternet,
    required super.child,
  });

  static bool of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_ConnectivityScope>()
            ?.hasInternet ??
        true;
  }

  @override
  bool updateShouldNotify(_ConnectivityScope oldWidget) {
    return hasInternet != oldWidget.hasInternet;
  }
}
