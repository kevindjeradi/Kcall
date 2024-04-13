import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

class LifecycleManager extends StatefulWidget {
  final Widget child;

  const LifecycleManager({
    super.key,
    required this.child,
  });

  @override
  LifecycleManagerState createState() => LifecycleManagerState();
}

class LifecycleManagerState extends State<LifecycleManager>
    with WidgetsBindingObserver {
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initConnectivity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
      if (!mounted) return;
      _updateConnectionStatus(result);
    } on PlatformException catch (e) {
      print('Couldn\'t check connectivity status : $e');
    }

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    if (mounted) {
      setState(() {
        _connectionStatus = result;
      });
    }
  }

  void onConnected() {
    print("Connected: ${_connectionStatus.join(", ")}");
  }

  void onDisconnected() {
    print("Disconnected");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onResume();
        break;
      case AppLifecycleState.paused:
        onPause();
        break;
      case AppLifecycleState.inactive:
        onInactive();
        break;
      case AppLifecycleState.detached:
        onDetached();
        break;
      default:
        print("Unknown state: $state");
        break;
    }
  }

  void onResume() {
    print("App Resumed");
    initConnectivity();
  }

  void onPause() {
    print("App Paused");
  }

  void onInactive() {
    print("App Inactive");
  }

  void onDetached() {
    print("App Detached");
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
