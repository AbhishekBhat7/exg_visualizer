import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MaterialApp(home: ScanListScreen()));
}

// ==========================================
// PAGE 1: SCAN LIST SCREEN
// ==========================================
class ScanListScreen extends StatefulWidget {
  const ScanListScreen({super.key});

  @override
  State<ScanListScreen> createState() => _ScanListScreenState();
}

class _ScanListScreenState extends State<ScanListScreen> {
  // To keep track of loading state while connecting
  BluetoothDevice? connectingDevice;

  @override
  void initState() {
    super.initState();
    checkPermissionsAndScan();
  }

  Future<void> checkPermissionsAndScan() async {
    // 1. Check Android Permissions
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      if (statuses.values.any((status) => status.isDenied)) {
        showError("Required permissions not granted");
        return;
      }
    }

    // 2. Start Scanning
    try {
      // Start scanning for 15 seconds
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      showError("Error starting scan: $e");
    }
  }

  // Function to handle connection logic
  Future<void> onConnectPressed(BluetoothDevice device) async {
    setState(() {
      connectingDevice = device;
    });

    try {
      // Stop scanning before connecting to ensure stability
      await FlutterBluePlus.stopScan();

      // Attempt to connect
      await device.connect(timeout: const Duration(seconds: 10));

      // If successful, navigate to the next page
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ConnectedDevicePage(device: device),
          ),
        ).then((_) {
          // When returning from the other page, disconnect
          device.disconnect(); 
        });
      }
    } catch (e) {
      showError("Connection failed: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          connectingDevice = null;
        });
      }
    }
  }

  void showError(String message) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BLE Scanner"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: checkPermissionsAndScan,
          )
        ],
      ),
      body: Column(
        children: [
          // StreamBuilder listens to the scan results live
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: FlutterBluePlus.scanResults,
              initialData: const [],
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final results = snapshot.data ?? [];

                if (results.isEmpty) {
                  return const Center(child: Text("No devices found"));
                }

                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final data = results[index];
                    final device = data.device;
                    
                    // Display name or address if name is empty
                    final displayName = device.platformName.isNotEmpty 
                        ? device.platformName 
                        : device.remoteId.str;

                    final isConnecting = connectingDevice == device;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(device.remoteId.str),
                        trailing: isConnecting
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: () => onConnectPressed(device),
                                child: const Text("Connect"),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// PAGE 2: CONNECTED DEVICE SCREEN
// ==========================================
class ConnectedDevicePage extends StatefulWidget {
  final BluetoothDevice device;

  const ConnectedDevicePage({super.key, required this.device});

  @override
  State<ConnectedDevicePage> createState() => _ConnectedDevicePageState();
}

class _ConnectedDevicePageState extends State<ConnectedDevicePage> {
  // Stream to track connection state (Connected/Disconnected)
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  String status = "Connected";

  @override
  void initState() {
    super.initState();
    // Listen to connection changes (e.g., if device disconnects unexpectedly)
    _connectionStateSubscription = widget.device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Device Disconnected")));
           Navigator.pop(context); // Go back if disconnected
        }
      }
    });
  }

  @override
  void dispose() {
    _connectionStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Device Details"),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth_connected, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              "Successfully connected to:",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              widget.device.platformName.isNotEmpty 
                  ? widget.device.platformName 
                  : "Unknown Device",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("ID: ${widget.device.remoteId.str}"),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                await widget.device.disconnect();
                // Listener in initState will handle the navigation pop
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text("Disconnect & Go Back"),
            )
          ],
        ),
      ),
    );
  }
}