import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
  ConnectivityResult _lastResult = ConnectivityResult.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initConnectivity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> initConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    handleConnectivityChange(connectivityResult);
    Connectivity().onConnectivityChanged.listen(handleConnectivityChange);
  }

  void handleConnectivityChange(ConnectivityResult result) {
    setState(() {
      _lastResult = result;
    });
    if (result == ConnectivityResult.none) {
      onDisconnected();
    } else {
      onConnected(result);
    }
  }

  void onConnected(ConnectivityResult result) {
    print(
        "Connected to ${result == ConnectivityResult.mobile ? 'Mobile' : 'WiFi'}");
    // Implement actions to take when connected, like fetching data or enabling features
  }

  void onDisconnected() {
    print("No connectivity");
    // Implement actions to take when disconnected, like notifying the user or disabling features
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
        // Optionally handle unknown states or do nothing
        print("Unknown state: $state");
        break;
    }
  }

  void onResume() {
    print("App Resumed");
    // Additional actions on resume can go here
  }

  void onPause() {
    print("App Paused");
    // Additional actions on pause can go here
  }

  void onInactive() {
    print("App Inactive");
    // Additional actions on inactive can go here
  }

  void onDetached() {
    print("App Detached");
    // Additional actions on detached can go here
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
