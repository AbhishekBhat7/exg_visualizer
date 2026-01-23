import 'dart:async';
import 'package:exg_visualizer/Libraries/Colors/Colors.dart';
import 'package:exg_visualizer/Libraries/Fonts/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleDevicePage extends StatefulWidget {
  final BluetoothDevice device;
  final String email;

  const BleDevicePage({
    Key? key,
    required this.device,
    required this.email,
  }) : super(key: key);

  @override
  State<BleDevicePage> createState() => _BleDevicePageState();
}

class _BleDevicePageState extends State<BleDevicePage> {
  // Your specific Service and Characteristic UUIDs
  static const String SERVICE_UUID = "13e09a4f-c68c-43cd-822e-46823a5d913c";
  static const String CHARACTERISTIC_UUID =
      "18a7eb96-16dc-4877-8ac6-4b0d165e748f";

  BluetoothCharacteristic? _characteristic;
  StreamSubscription<List<int>>? _notificationSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  String _displayValue = "--";
  List<int> _rawBytes = [];
  bool _isLoading = true;
  bool _isConnected = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _listenToConnectionState();
    _discoverServices();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  void _listenToConnectionState() {
    _connectionSubscription = widget.device.connectionState.listen((state) {
      if (mounted) {
        setState(() {
          _isConnected = state == BluetoothConnectionState.connected;
          if (!_isConnected) {
            _displayValue = "--";
            _rawBytes = [];
          }
        });

        if (!_isConnected) {
          _showSnackBar("Device disconnected");
        }
      }
    });
  }

  Future<void> _discoverServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      List<BluetoothService> services = await widget.device.discoverServices();

      BluetoothCharacteristic? targetCharacteristic;

      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() ==
            SERVICE_UUID.toLowerCase()) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() ==
                CHARACTERISTIC_UUID.toLowerCase()) {
              targetCharacteristic = characteristic;
              break;
            }
          }
        }
        if (targetCharacteristic != null) break;
      }

      if (targetCharacteristic != null) {
        _characteristic = targetCharacteristic;

        // Read initial value
        if (_characteristic!.properties.read) {
          await _readValue();
        }

        // Subscribe to notifications
        if (_characteristic!.properties.notify) {
          await _subscribeToNotifications();
        }
      } else {
        setState(() {
          _errorMessage = "Characteristic not found";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error discovering services: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _readValue() async {
    if (_characteristic == null) return;

    try {
      List<int> value = await _characteristic!.read();
      _updateValue(value);
    } catch (e) {
      _showSnackBar("Error reading value: $e");
    }
  }

  Future<void> _subscribeToNotifications() async {
    if (_characteristic == null) return;

    try {
      await _characteristic!.setNotifyValue(true);
      _notificationSubscription =
          _characteristic!.lastValueStream.listen((value) {
        _updateValue(value);
      });
      _showSnackBar("Subscribed to notifications");
    } catch (e) {
      _showSnackBar("Error subscribing: $e");
    }
  }

  void _updateValue(List<int> bytes) {
    if (mounted && bytes.isNotEmpty) {
      setState(() {
        _rawBytes = bytes;
        // Convert bytes to ASCII string (like "42" from 0x34-32)
        _displayValue = String.fromCharCodes(bytes);
      });
    }
  }

  Future<void> _disconnect() async {
    try {
      await _notificationSubscription?.cancel();
      await widget.device.disconnect();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar("Error disconnecting: $e");
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: AppTextStyles.regular)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MainColors.white,
      appBar: AppBar(
        backgroundColor: MainColors.white,
        title: Text(
          widget.device.platformName,
          style: AppTextStyles.header.copyWith(fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: MainColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: _disconnect,
          ),
        ],
        elevation: 2,
      ),
      body: SafeArea(
        child: _isLoading ? _buildLoadingView() : _buildContentView(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: MainColors.primaryColor,
          ),
          const SizedBox(height: 20),
          Text(
            "Discovering Services...",
            style: AppTextStyles.regular.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection Status Card
          _buildConnectionStatusCard(),
          const SizedBox(height: 20),

          // Main Value Display Card
          _buildValueDisplayCard(),
          const SizedBox(height: 20),

          // Raw Data Card
          _buildRawDataCard(),
          const SizedBox(height: 20),

          // UUID Info Card
          _buildUuidInfoCard(),

          const Spacer(),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isConnected
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isConnected ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.check_circle : Icons.error,
            color: _isConnected ? Colors.green : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Connection Status",
                style: AppTextStyles.regular.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                _isConnected ? "Connected" : "Disconnected",
                style: AppTextStyles.bold.copyWith(
                  color: _isConnected ? Colors.green : Colors.red,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueDisplayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(143, 0, 0, 1),
            Color.fromRGBO(220, 20, 60, 1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(143, 0, 0, 0.3),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "CHARACTERISTIC VALUE",
            style: AppTextStyles.regular.copyWith(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _displayValue,
            style: AppTextStyles.bold.copyWith(
              color: MainColors.white,
              fontSize: 72,
            ),
          ),
          const SizedBox(height: 8),
          if (_errorMessage.isNotEmpty)
            Text(
              _errorMessage,
              style: AppTextStyles.regular.copyWith(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRawDataCard() {
    String hexString = _rawBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join('-');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Raw Data (Hex)",
            style: AppTextStyles.medium.copyWith(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MainColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Text(
                  "(0x) ",
                  style: AppTextStyles.regular.copyWith(
                    color: Colors.grey,
                    fontSize: 16,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  hexString.isEmpty ? "No data" : hexString,
                  style: AppTextStyles.medium.copyWith(
                    fontSize: 18,
                    fontFamily: 'monospace',
                    color: MainColors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  '"$_displayValue"',
                  style: AppTextStyles.medium.copyWith(
                    fontSize: 16,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUuidInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                "Service Information",
                style: AppTextStyles.medium.copyWith(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildUuidRow("Service UUID", SERVICE_UUID),
          const SizedBox(height: 8),
          _buildUuidRow("Characteristic UUID", CHARACTERISTIC_UUID),
          const SizedBox(height: 8),
          _buildUuidRow("Properties", "NOTIFY, READ"),
        ],
      ),
    );
  }

  Widget _buildUuidRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.regular.copyWith(
            color: Colors.grey[500],
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.regular.copyWith(
            fontSize: 12,
            fontFamily: 'monospace',
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isConnected ? _readValue : null,
            icon: const Icon(Icons.refresh, size: 20),
            label: Text(
              "Read Value",
              style: AppTextStyles.bold.copyWith(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: MainColors.white,
              backgroundColor: MainColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _disconnect,
            icon: const Icon(Icons.bluetooth_disabled, size: 20),
            label: Text(
              "Disconnect",
              style: AppTextStyles.bold.copyWith(fontSize: 14),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}