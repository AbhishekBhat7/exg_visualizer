import 'dart:async';   
import 'package:exg_visualizer/BLE/ble_device.dart';
import 'package:exg_visualizer/Libraries/Colors/Colors.dart';
import 'package:exg_visualizer/Libraries/Fonts/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothPage extends StatefulWidget {
  final String email;
  const BluetoothPage({Key? key, required this.email}) : super(key: key);

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  final Set<ScanResult> _devices = {};
  final Map<DeviceIdentifier, String> _connectionStatus = {};
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      if (mounted) {
        setState(() {
          _isScanning = isScanning;
        });
      }
    });
    _loadSavedDevices();
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _isScanningSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedDevices() async {
  }

  Future<void> _startScan() async {
    var permissionsGranted = await _checkPermissions();
    if (!permissionsGranted) {
      _showSnackBar(
          "Location and Bluetooth permissions are required for scanning.");
      return;
    }

    var isBluetoothOn =
        await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
    if (!isBluetoothOn) {
      _showSnackBar("Bluetooth is turned off. Please enable it.");
      return;
    }

    await _scanSubscription?.cancel();
    await FlutterBluePlus.stopScan();

    setState(() {
      _devices.clear();
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) {
      _showSnackBar("Error starting scan: $e");
      return;
    }
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          for (ScanResult result in results) {
            if (result.device.platformName.isNotEmpty) {
              _devices.add(result);
              _connectionStatus.putIfAbsent(
                  result.device.remoteId, () => 'Connect');
            }
          }
        });
      }
    }, onError: (e) {
      _showSnackBar("Scan Error: $e");
    });
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: AppTextStyles.regular)),
      );
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();

    if (mounted) {
      setState(() {
        _connectionStatus[device.remoteId] = 'Connecting...';
      });
    }

    try {
      await device.connect(timeout: const Duration(seconds: 15));

      if (mounted) {
        setState(() {
          _connectionStatus[device.remoteId] = 'Connected';
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BleDevicePage(device: device, email: widget.email),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionStatus[device.remoteId] = 'Connection Failed';
        });
      }
      _showSnackBar("Failed to connect to ${device.platformName}: $e");
    }
  }

  Future<void> _refreshScan() async {
    if (!_isScanning) {
      await _startScan();
    }
  }

  Future<bool> _checkPermissions() async {
    var status = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    return status[Permission.location]!.isGranted &&
        status[Permission.bluetoothScan]!.isGranted &&
        status[Permission.bluetoothConnect]!.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MainColors.white,
      appBar: AppBar(
        backgroundColor: MainColors.white,
        title: Text(
          "Devices BLE Connections",
          style: AppTextStyles.header.copyWith(fontSize: 22),
        ),
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back_ios, color: MainColors.black),
        //   onPressed: () => Navigator.pop(context),
        // ),
        elevation: 5,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshScan,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _isScanning ? null : _startScan,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isScanning
                            ? [Colors.grey.shade400, Colors.grey.shade600]
                            : [
                                const Color.fromRGBO(143, 0, 0, 1),
                                const Color.fromRGBO(220, 20, 60, 1),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _isScanning
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: MainColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.add_circle_outline,
                                color: MainColors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          _isScanning ? "Scanning..." : "Connect New Device",
                          style: AppTextStyles.bold.copyWith(
                            color: MainColors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "Available Devices",
                  style: AppTextStyles.subHeader.copyWith(
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _devices.isEmpty
                      ? Center(
                          child: Text(
                            _isScanning
                                ? "Looking for devices..."
                                : "No devices found.\nPull down to scan again.",
                            textAlign: TextAlign.center,
                            style: AppTextStyles.regular
                                .copyWith(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _devices.length,
                          itemBuilder: (context, index) {
                            final result = _devices.elementAt(index);
                            final deviceStatus =
                                _connectionStatus[result.device.remoteId] ??
                                    'Connect';

                            Color iconColor;
                            if (deviceStatus == 'Connecting...') {
                              iconColor = Colors.orange;
                            } else if (deviceStatus == 'Connected') {
                              iconColor = const Color.fromRGBO(143, 0, 0, 1);
                            } else {
                              iconColor = Colors.grey;
                            }

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: MainColors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    offset: const Offset(0, 4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: iconColor,
                                    radius: 28,
                                    child: Icon(Icons.bluetooth,
                                        color: MainColors.white, size: 30),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          result.device.platformName,
                                          style: AppTextStyles.medium
                                              .copyWith(fontSize: 18),
                                        ),
                                        Text(
                                          result.device.remoteId.toString(),
                                          style: AppTextStyles.regular.copyWith(
                                              fontSize: 14, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _connectToDevice(result.device),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: MainColors.white,
                                      backgroundColor: MainColors.primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    child: Text(
                                      deviceStatus,
                                      style: AppTextStyles.bold
                                          .copyWith(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}