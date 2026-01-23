 import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleConnectionManager {
  BleConnectionManager._();
  static final BleConnectionManager instance = BleConnectionManager._();

  final ValueNotifier<BluetoothDevice?> connectedDeviceNotifier =
      ValueNotifier<BluetoothDevice?>(null);

  StreamSubscription<BluetoothConnectionState>? _connSub;

  BluetoothDevice? get connectedDevice => connectedDeviceNotifier.value;
  bool get isConnected => connectedDeviceNotifier.value != null;

  void setDevice(BluetoothDevice device) {
    _connSub?.cancel();

    _connSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        connectedDeviceNotifier.value = null;
      }
    });

    connectedDeviceNotifier.value = device;
  }

  Future<void> disconnectDevice() async {
    final device = connectedDevice;
    if (device != null) {
      await device.disconnect();
      connectedDeviceNotifier.value = null;
    }
    await _connSub?.cancel();
    _connSub = null;
  }

  Future<void> sendMessage(String message) async {
    final device = connectedDevice;
    if (device == null) {
      throw Exception('No device connected');
    }

    try {
      const serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
      const characteristicUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

      List<BluetoothService> services = await device.discoverServices();
      BluetoothService targetService = services.firstWhere(
        (service) => service.uuid.toString() == serviceUuid,
        orElse: () => throw Exception('Service not found: $serviceUuid'),
      );

      BluetoothCharacteristic targetCharacteristic =
          targetService.characteristics.firstWhere(
        (char) => char.uuid.toString() == characteristicUuid,
        orElse: () =>
            throw Exception('Characteristic not found: $characteristicUuid'),
      );

      if (!targetCharacteristic.properties.write) {
        throw Exception('Characteristic does not support write');
      }

      final data = utf8.encode(message);
      await targetCharacteristic.write(data, withoutResponse: false);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
  Future<int?> readBatteryLevel() async {
    final device = connectedDevice;
    if (device == null) return null;

    try {
      const batteryServiceUuid = '0000180f-0000-1000-8000-00805f9b34fb';
      const batteryLevelCharUuid = '00002a19-0000-1000-8000-00805f9b34fb';

      final services = await device.discoverServices();
      final batteryService = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == batteryServiceUuid,
      );
      final batteryChar = batteryService.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() == batteryLevelCharUuid,
      );

      final value = await batteryChar.read(); 
      if (value.isNotEmpty) return value.first; 
    } catch (_) {
    }
    return null;
  }
}