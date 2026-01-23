// import 'dart:async';
// import 'package:exg_visualizer/Libraries/Colors/Colors.dart'; // Assuming you have these files
// import 'package:exg_visualizer/Libraries/Fonts/text_styles.dart'; // Assuming you have these files
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:intl/intl.dart';

// // --------------------------------------------------------------------------
// // 1. MAIN PAGE (Unchanged)
// // --------------------------------------------------------------------------

// class BleDevicePage extends StatefulWidget {
//   final BluetoothDevice device;
//   final String email;

//   const BleDevicePage({
//     Key? key,
//     required this.device,
//     required this.email,
//   }) : super(key: key);

//   @override
//   State<BleDevicePage> createState() => _BleDevicePageState();
// }

// class _BleDevicePageState extends State<BleDevicePage> {
//   static const String SERVICE_UUID = "13e09a4f-c68c-43cd-822e-46823a5d913c";
//   static const String CHARACTERISTIC_UUID =
//       "18a7eb96-16dc-4877-8ac6-4b0d165e748f";

//   BluetoothCharacteristic? _characteristic;
//   StreamSubscription<List<int>>? _notificationSubscription;
//   StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

//   final StreamController<double> _graphDataController =
//       StreamController<double>.broadcast();

//   String _displayValue = "--";
//   List<int> _rawBytes = [];
//   bool _isLoading = true;
//   bool _isConnected = true;
//   String _errorMessage = "";

//   @override
//   void initState() {
//     super.initState();
//     _listenToConnectionState();
//     _discoverServices();
//   }

//   @override
//   void dispose() {
//     _notificationSubscription?.cancel();
//     _connectionSubscription?.cancel();
//     _graphDataController.close();
//     super.dispose();
//   }

//   void _listenToConnectionState() {
//     _connectionSubscription = widget.device.connectionState.listen((state) {
//       if (mounted) {
//         setState(() {
//           _isConnected = state == BluetoothConnectionState.connected;
//           if (!_isConnected) {
//             _displayValue = "--";
//             _rawBytes = [];
//           }
//         });
//         if (!_isConnected) {
//           _showSnackBar("Device disconnected");
//         }
//       }
//     });
//   }

//   Future<void> _discoverServices() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = "";
//     });

//     try {
//       List<BluetoothService> services = await widget.device.discoverServices();
//       BluetoothCharacteristic? targetCharacteristic;

//       for (BluetoothService service in services) {
//         if (service.uuid.toString().toLowerCase() ==
//             SERVICE_UUID.toLowerCase()) {
//           for (BluetoothCharacteristic characteristic
//               in service.characteristics) {
//             if (characteristic.uuid.toString().toLowerCase() ==
//                 CHARACTERISTIC_UUID.toLowerCase()) {
//               targetCharacteristic = characteristic;
//               break;
//             }
//           }
//         }
//         if (targetCharacteristic != null) break;
//       }

//       if (targetCharacteristic != null) {
//         _characteristic = targetCharacteristic;
//         if (_characteristic!.properties.read) {
//           await _readValue();
//         }
//         if (_characteristic!.properties.notify) {
//           await _subscribeToNotifications();
//         }
//       } else {
//         setState(() {
//           _errorMessage = "Characteristic not found";
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = "Error discovering services: $e";
//       });
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _readValue() async {
//     if (_characteristic == null) return;
//     try {
//       List<int> value = await _characteristic!.read();
//       _updateValue(value);
//     } catch (e) {
//       _showSnackBar("Error reading value: $e");
//     }
//   }

//   Future<void> _subscribeToNotifications() async {
//     if (_characteristic == null) return;
//     try {
//       await _characteristic!.setNotifyValue(true);
//       _notificationSubscription =
//           _characteristic!.lastValueStream.listen((value) {
//         _updateValue(value);
//       });
//       _showSnackBar("Subscribed to notifications");
//     } catch (e) {
//       _showSnackBar("Error subscribing: $e");
//     }
//   }

//   void _updateValue(List<int> bytes) {
//     if (mounted && bytes.isNotEmpty) {
//       String stringVal = String.fromCharCodes(bytes);
//       double? numericVal = double.tryParse(stringVal);
//       if (numericVal != null) {
//         _graphDataController.add(numericVal);
//       }
//       setState(() {
//         _rawBytes = bytes;
//         _displayValue = stringVal;
//       });
//     }
//   }

//   Future<void> _disconnect() async {
//     try {
//       await _notificationSubscription?.cancel();
//       await widget.device.disconnect();
//       if (mounted) {
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       _showSnackBar("Error disconnecting: $e");
//     }
//   }

//   void _showSnackBar(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(message, style: AppTextStyles.regular)),
//       );
//     }
//   }

//   void _openGraphPage() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => LiveExgChartPage(
//           dataStream: _graphDataController.stream,
//           deviceName: widget.device.platformName,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: MainColors.white,
//       appBar: AppBar(
//         backgroundColor: MainColors.white,
//         title: Text(
//           widget.device.platformName,
//           style: AppTextStyles.header.copyWith(fontSize: 20),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: MainColors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(
//               _isConnected
//                   ? Icons.bluetooth_connected
//                   : Icons.bluetooth_disabled,
//               color: _isConnected ? Colors.green : Colors.red,
//             ),
//             onPressed: null, // Display only
//           ),
//         ],
//         elevation: 2,
//       ),
//       body: SafeArea(
//         child: _isLoading ? _buildLoadingView() : _buildContentView(),
//       ),
//     );
//   }

//   Widget _buildLoadingView() {
//     return Center(
//       child: CircularProgressIndicator(color: MainColors.primaryColor),
//     );
//   }

//   Widget _buildContentView() {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildConnectionStatusCard(),
//             const SizedBox(height: 20),
//             _buildValueDisplayCard(),
//             const SizedBox(height: 20),
//             _buildRawDataCard(),
//             const SizedBox(height: 24),
//             _buildGraphButton(),
//             const SizedBox(height: 12),
//             _buildActionButtons(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildGraphButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton.icon(
//         onPressed: _isConnected ? _openGraphPage : null,
//         icon: const Icon(Icons.show_chart, size: 24),
//         label: Text(
//           "OPEN REAL-TIME GRAPH",
//           style: AppTextStyles.bold.copyWith(fontSize: 16),
//         ),
//         style: ElevatedButton.styleFrom(
//           foregroundColor: Colors.white,
//           backgroundColor: Colors.blueGrey[800],
//           padding: const EdgeInsets.symmetric(vertical: 18),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildConnectionStatusCard() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: _isConnected
//             ? Colors.green.withOpacity(0.1)
//             : Colors.red.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: _isConnected ? Colors.green : Colors.red,
//           width: 1,
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             _isConnected ? Icons.check_circle : Icons.error,
//             color: _isConnected ? Colors.green : Colors.red,
//             size: 28,
//           ),
//           const SizedBox(width: 12),
//           Text(
//             _isConnected ? "Connected" : "Disconnected",
//             style: AppTextStyles.bold.copyWith(
//               color: _isConnected ? Colors.green : Colors.red,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildValueDisplayCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: MainColors.black,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Text("LAST RECEIVED VALUE",
//               style: AppTextStyles.regular
//                   .copyWith(color: Colors.white.withOpacity(0.8))),
//           const SizedBox(height: 8),
//           Text(
//             _displayValue,
//             style: AppTextStyles.header
//                 .copyWith(color: Colors.white, fontSize: 48),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRawDataCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Raw Data", style: AppTextStyles.bold),
//             const SizedBox(height: 8),
//             Text("Bytes: ${_rawBytes.toString()}",
//                 style: AppTextStyles.regular.copyWith(color: Colors.grey[700])),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActionButtons() {
//     return Row(
//       children: [
//         Expanded(
//           child: ElevatedButton(
//             onPressed: _isConnected ? _readValue : null,
//             child: const Text("Read Value"),
//             style: ElevatedButton.styleFrom(
//                 backgroundColor: MainColors.primaryColor,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12))),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: OutlinedButton(
//             onPressed: _disconnect,
//             child: const Text("Disconnect"),
//             style: OutlinedButton.styleFrom(
//                 foregroundColor: Colors.red,
//                 side: const BorderSide(color: Colors.red),
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12))),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // --------------------------------------------------------------------------
// // 2. HEAVILY MODIFIED AND INTERACTIVE GRAPH PAGE
// // --------------------------------------------------------------------------

// // Enum to manage which special function is active
// enum ActiveFunction { none, function1, function2 }

// class LiveExgChartPage extends StatefulWidget {
//   final Stream<double> dataStream;
//   final String deviceName;

//   const LiveExgChartPage({
//     Key? key,
//     required this.dataStream,
//     required this.deviceName,
//   }) : super(key: key);

//   @override
//   State<LiveExgChartPage> createState() => _LiveExgChartPageState();
// }

// class _LiveExgChartPageState extends State<LiveExgChartPage> {
//   late StreamSubscription<double> _subscription;
//   final List<FlSpot> _points = [];
//   ActiveFunction _activeFunction = ActiveFunction.none;

//   static const int _maxPointsToKeep = 300;
//   static const int _visibleDurationInMs = 10000;

//   @override
//   void initState() {
//     super.initState();
//     _startListening();
//   }

//   void _startListening() {
//     _subscription = widget.dataStream.listen((originalValue) {
//       // Process value based on the active function
//       double processedValue = originalValue;
//       switch (_activeFunction) {
//         case ActiveFunction.function1:
//           processedValue = originalValue + 5;
//           break;
//         case ActiveFunction.function2:
//           if (originalValue <= 30) {
//             processedValue = originalValue + 10;
//           }
//           break;
//         case ActiveFunction.none:
//           // No processing needed
//           break;
//       }

//       setState(() {
//         final timestamp = DateTime.now().millisecondsSinceEpoch.toDouble();
//         _points.add(FlSpot(timestamp, processedValue));

//         if (_points.length > _maxPointsToKeep) {
//           _points.removeAt(0);
//         }
//       });
//     });
//   }

//   void _clearChart() {
//     setState(() {
//       _points.clear();
//     });
//   }

//   void _saveChartData() {
//     // Placeholder for save logic
//     // You can access the data via the `_points` list
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("Save function triggered! ${_points.length} points available."),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _subscription.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: MainColors.white,
//       appBar: AppBar(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Real-Time EXG Signal", style: AppTextStyles.header),
//             Text(widget.deviceName,
//                 style: AppTextStyles.regular.copyWith(fontSize: 12, color: Colors.grey[600])),
//           ],
//         ),
//         backgroundColor: MainColors.white,
//         elevation: 1,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: MainColors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           // --- NEW 3-DOT MENU ---
//           PopupMenuButton<String>(
//             onSelected: (value) {
//               if (value == 'restart') {
//                 _clearChart();
//               } else if (value == 'save') {
//                 _saveChartData();
//               }
//             },
//             itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
//               const PopupMenuItem<String>(
//                 value: 'restart',
//                 child: Row(
//                   children: [
//                     Icon(Icons.refresh, color: Colors.blue),
//                     SizedBox(width: 8),
//                     Text('Restart'),
//                   ],
//                 ),
//               ),
//               const PopupMenuItem<String>(
//                 value: 'save',
//                 child: Row(
//                   children: [
//                     Icon(Icons.save_alt, color: Colors.green),
//                     SizedBox(width: 8),
//                     Text('Save Data'),
//                   ],
//                 ),
//               ),
//             ],
//             icon: const Icon(Icons.more_vert, color: MainColors.black),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 24),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Container(
//                 padding: const EdgeInsets.only(top: 24, bottom: 12, right: 20, left: 8),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(16),
//                   color: const Color(0xfff3f6f9),
//                   border: Border.all(color: Colors.grey[300]!, width: 1),
//                 ),
//                 child: _points.isEmpty
//                     ? Center(
//                         child: Text("Waiting for data...", style: AppTextStyles.regular),
//                       )
//                     : LineChart(
//                         _buildChartData(),
//                         duration: Duration.zero,
//                       ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 24),
//           // --- NEW FUNCTION CONTROLS ---
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: _buildFunctionControls(),
//           ),
//           const SizedBox(height: 24),
//         ],
//       ),
//     );
//   }

//   // --- NEW WIDGET FOR FUNCTION BUTTONS ---
//   Widget _buildFunctionControls() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         // Button for Function 1
//         _functionButton(
//           label: 'Function 1 (+5)',
//           onPressed: () {
//             setState(() {
//               // Toggle behavior: if already active, turn off. Otherwise, activate.
//               _activeFunction = _activeFunction == ActiveFunction.function1
//                   ? ActiveFunction.none
//                   : ActiveFunction.function1;
//             });
//           },
//           isActive: _activeFunction == ActiveFunction.function1,
//         ),
//         // Button for Function 2
//         _functionButton(
//           label: 'Function 2 (<=30, +10)',
//           onPressed: () {
//             setState(() {
//               _activeFunction = _activeFunction == ActiveFunction.function2
//                   ? ActiveFunction.none
//                   : ActiveFunction.function2;
//             });
//           },
//           isActive: _activeFunction == ActiveFunction.function2,
//         ),
//       ],
//     );
//   }

//   // Helper to build a single function button with active/inactive state
//   Widget _functionButton({required String label, required VoidCallback onPressed, required bool isActive}) {
//     final activeStyle = ElevatedButton.styleFrom(
//       backgroundColor: MainColors.primaryColor,
//       foregroundColor: Colors.white,
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//     );

//     final inactiveStyle = OutlinedButton.styleFrom(
//       side: BorderSide(color: MainColors.primaryColor),
//       foregroundColor: MainColors.primaryColor,
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//     );

//     return isActive
//         ? ElevatedButton(onPressed: onPressed, style: activeStyle, child: Text(label))
//         : OutlinedButton(onPressed: onPressed, style: inactiveStyle, child: Text(label));
//   }


//   LineChartData _buildChartData() {
//     final double maxX = _points.isNotEmpty ? _points.last.x : 0;
//     final double minX = maxX - _visibleDurationInMs;

//     return LineChartData(
//       minX: minX,
//       maxX: maxX,
//       clipData: const FlClipData.all(),
//       gridData: FlGridData(
//         show: true,
//         drawVerticalLine: true,
//         horizontalInterval: 20,
//         verticalInterval: 2000,
//         getDrawingHorizontalLine: (value) => FlLine(
//           color: Colors.grey[300],
//           strokeWidth: 0.8,
//         ),
//         getDrawingVerticalLine: (value) => FlLine(
//           color: Colors.grey[300],
//           strokeWidth: 0.8,
//         ),
//       ),
//       titlesData: FlTitlesData(
//         show: true,
//         rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 30,
//             interval: 2000,
//             getTitlesWidget: (value, meta) {
//               final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
//               return SideTitleWidget(
//                 meta: meta,
//                 space: 8.0,
//                 child: Text(
//                   DateFormat('HH:mm:ss').format(date),
//                   style: TextStyle(color: Colors.grey[700], fontSize: 10),
//                 ),
//               );
//             },
//           ),
//         ),
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 45,
//             getTitlesWidget: (value, meta) {
//               if (value == meta.max || value == meta.min) {
//                 return Container();
//               }
//               return SideTitleWidget(
//                 meta: meta,
//                 child: Text(
//                   value.toInt().toString(),
//                   style: TextStyle(color: Colors.grey[700], fontSize: 10, fontWeight: FontWeight.bold),
//                   textAlign: TextAlign.left,
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//       borderData: FlBorderData(show: false),
//       lineBarsData: [
//         LineChartBarData(
//           spots: _points,
//           isCurved: true,
//           color: MainColors.primaryColor,
//           barWidth: 3,
//           isStrokeCapRound: true,
//           dotData: const FlDotData(show: false),
//           belowBarData: BarAreaData(
//             show: true,
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 MainColors.primaryColor.withOpacity(0.3),
//                 MainColors.primaryColor.withOpacity(0.0),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
 

import 'package:exg_visualizer/BLE/csv_exporter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'dart:io';
import 'package:exg_visualizer/BLE/db.dart';
import 'package:exg_visualizer/Libraries/Colors/Colors.dart';
import 'package:exg_visualizer/Libraries/Fonts/text_styles.dart'; 
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

// --------------------------------------------------------------------------
// 1. MAIN BLE DEVICE PAGE
// --------------------------------------------------------------------------

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
  static const String SERVICE_UUID = "13e09a4f-c68c-43cd-822e-46823a5d913c";
  static const String CHARACTERISTIC_UUID =
      "18a7eb96-16dc-4877-8ac6-4b0d165e748f";

  BluetoothCharacteristic? _characteristic;
  StreamSubscription<List<int>>? _notificationSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  final StreamController<double> _graphDataController =
      StreamController<double>.broadcast();

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
    _graphDataController.close();
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
        if (_characteristic!.properties.read) {
          await _readValue();
        }
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
      String stringVal = String.fromCharCodes(bytes);
      double? numericVal = double.tryParse(stringVal);
      if (numericVal != null) {
        _graphDataController.add(numericVal);
      }
      setState(() {
        _rawBytes = bytes;
        _displayValue = stringVal;
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

  void _openGraphPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveExgChartPage(
          dataStream: _graphDataController.stream,
          deviceName: widget.device.platformName,
        ),
      ),
    );
  }

  void _openSavedDataPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SavedRecordingsPage(),
      ),
    );
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
              _isConnected
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_disabled,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: null,
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
      child: CircularProgressIndicator(color: MainColors.primaryColor),
    );
  }

  Widget _buildContentView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConnectionStatusCard(),
            const SizedBox(height: 20),
            _buildValueDisplayCard(),
            const SizedBox(height: 20),
            _buildRawDataCard(),
            const SizedBox(height: 24),
            _buildGraphButton(),
            const SizedBox(height: 12),
            _buildSavedDataButton(), // NEW BUTTON
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isConnected ? _openGraphPage : null,
        icon: const Icon(Icons.show_chart, size: 24),
        label: Text(
          "OPEN REAL-TIME GRAPH",
          style: AppTextStyles.bold.copyWith(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blueGrey[800],
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // NEW: Button to view saved recordings
  Widget _buildSavedDataButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _openSavedDataPage,
        icon: const Icon(Icons.folder_open, size: 24),
        label: Text(
          "VIEW SAVED RECORDINGS",
          style: AppTextStyles.bold.copyWith(fontSize: 16),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blueGrey[800],
          side: BorderSide(color: Colors.blueGrey[800]!, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
          Text(
            _isConnected ? "Connected" : "Disconnected",
            style: AppTextStyles.bold.copyWith(
              color: _isConnected ? Colors.green : Colors.red,
              fontSize: 16,
            ),
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
        color: MainColors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("LAST RECEIVED VALUE",
              style: AppTextStyles.regular
                  .copyWith(color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 8),
          Text(
            _displayValue,
            style: AppTextStyles.header
                .copyWith(color: Colors.white, fontSize: 48),
          ),
        ],
      ),
    );
  }

  Widget _buildRawDataCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Raw Data", style: AppTextStyles.bold),
            const SizedBox(height: 8),
            Text("Bytes: ${_rawBytes.toString()}",
                style: AppTextStyles.regular.copyWith(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isConnected ? _readValue : null,
            child: const Text("Read Value"),
            style: ElevatedButton.styleFrom(
                backgroundColor: MainColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _disconnect,
            child: const Text("Disconnect"),
            style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------------------
// 2. LIVE EXG CHART PAGE WITH SCROLLING AND STORAGE
// --------------------------------------------------------------------------

// enum ActiveFunction { none, function1, function2 }

// class LiveExgChartPage extends StatefulWidget {
//   final Stream<double> dataStream;
//   final String deviceName;

//   const LiveExgChartPage({
//     Key? key,
//     required this.dataStream,
//     required this.deviceName,
//   }) : super(key: key);

//   @override
//   State<LiveExgChartPage> createState() => _LiveExgChartPageState();
// }

// class _LiveExgChartPageState extends State<LiveExgChartPage> {
//   late StreamSubscription<double> _subscription;

//   // Display points (limited for performance)
//   final List<FlSpot> _displayPoints = [];

//   // ALL data points stored for saving
//   final List<DataPoint> _allDataPoints = [];

//   ActiveFunction _activeFunction = ActiveFunction.none;

//   // Scrolling control
//   bool _autoScroll = true;
//   double? _manualMinX;
//   double? _manualMaxX;

//   // Recording state
//   bool _isRecording = true;
//   DateTime? _recordingStartTime;

//   static const int _maxDisplayPoints = 500; // Increased for better scrolling
//   static const double _visibleDurationInMs = 10000;

//   final DatabaseHelper _dbHelper = DatabaseHelper.instance;

//   @override
//   void initState() {
//     super.initState();
//     _recordingStartTime = DateTime.now();
//     _startListening();
//   }

//   void _startListening() {
//     _subscription = widget.dataStream.listen((originalValue) {
//       if (!_isRecording) return;

//       final now = DateTime.now();

//       // Store original value with timestamp (for saving)
//       _allDataPoints.add(DataPoint(
//         value: originalValue,
//         timestamp: now,
//         processedValue: _processValue(originalValue),
//       ));

//       // Process value for display
//       double processedValue = _processValue(originalValue);

//       setState(() {
//         final timestamp = now.millisecondsSinceEpoch.toDouble();
//         _displayPoints.add(FlSpot(timestamp, processedValue));

//         // Keep display points manageable
//         if (_displayPoints.length > _maxDisplayPoints) {
//           _displayPoints.removeAt(0);
//         }
//       });
//     });
//   }

//   double _processValue(double originalValue) {
//     switch (_activeFunction) {
//       case ActiveFunction.function1:
//         return originalValue + 5;
//       case ActiveFunction.function2:
//         if (originalValue <= 30) {
//           return originalValue + 10;
//         }
//         return originalValue;
//       case ActiveFunction.none:
//         return originalValue;
//     }
//   }

//   void _clearChart() {
//     setState(() {
//       _displayPoints.clear();
//       _allDataPoints.clear();
//       _recordingStartTime = DateTime.now();
//       _autoScroll = true;
//       _manualMinX = null;
//       _manualMaxX = null;
//     });
//   }

//   void _toggleRecording() {
//     setState(() {
//       _isRecording = !_isRecording;
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(_isRecording ? "Recording resumed" : "Recording paused"),
//         backgroundColor: _isRecording ? Colors.green : Colors.orange,
//         duration: const Duration(seconds: 1),
//       ),
//     );
//   }

//   Future<void> _saveChartData() async {
//     if (_allDataPoints.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("No data to save!"),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     // Show saving dialog
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const Center(
//         child: Card(
//           child: Padding(
//             padding: EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 16),
//                 Text("Saving data..."),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );

//     try {
//       // Create session
//       final sessionId = await _dbHelper.createSession(widget.deviceName);

//       // Save all data points
//       await _dbHelper.saveDataPoints(sessionId, _allDataPoints);

//       if (mounted) {
//         Navigator.pop(context); // Close dialog
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//                 "Saved ${_allDataPoints.length} data points successfully!"),
//             backgroundColor: Colors.green,
//             action: SnackBarAction(
//               label: "VIEW",
//               textColor: Colors.white,
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const SavedRecordingsPage(),
//                   ),
//                 );
//               },
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         Navigator.pop(context); // Close dialog
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Error saving data: $e"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   void _onHorizontalDragUpdate(DragUpdateDetails details) {
//     if (_displayPoints.isEmpty) return;

//     setState(() {
//       _autoScroll = false;

//       final chartWidth = MediaQuery.of(context).size.width - 80;
//       final dragRatio = details.delta.dx / chartWidth;
//       final timeSpan = _visibleDurationInMs;
//       final shift = -dragRatio * timeSpan;

//       final currentMaxX = _manualMaxX ?? _displayPoints.last.x;
//       final currentMinX = _manualMinX ?? (currentMaxX - _visibleDurationInMs);

//       final dataMinX = _displayPoints.first.x;
//       final dataMaxX = _displayPoints.last.x;

//       double newMinX = currentMinX + shift;
//       double newMaxX = currentMaxX + shift;

//       // Clamp to data bounds
//       if (newMinX < dataMinX) {
//         newMinX = dataMinX;
//         newMaxX = dataMinX + _visibleDurationInMs;
//       }
//       if (newMaxX > dataMaxX) {
//         newMaxX = dataMaxX;
//         newMinX = dataMaxX - _visibleDurationInMs;
//         // If at the end, re-enable auto-scroll
//         _autoScroll = true;
//       }

//       _manualMinX = newMinX;
//       _manualMaxX = newMaxX;
//     });
//   }

//   void _resetToLive() {
//     setState(() {
//       _autoScroll = true;
//       _manualMinX = null;
//       _manualMaxX = null;
//     });
//   }

//   @override
//   void dispose() {
//     _subscription.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: MainColors.white,
//       appBar: AppBar(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Real-Time EXG Signal", style: AppTextStyles.header),
//             Text(widget.deviceName,
//                 style: AppTextStyles.regular
//                     .copyWith(fontSize: 12, color: Colors.grey[600])),
//           ],
//         ),
//         backgroundColor: MainColors.white,
//         elevation: 1,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: MainColors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           // Recording indicator
//           Container(
//             margin: const EdgeInsets.only(right: 8),
//             child: IconButton(
//               onPressed: _toggleRecording,
//               icon: Icon(
//                 _isRecording ? Icons.pause_circle : Icons.play_circle,
//                 color: _isRecording ? Colors.red : Colors.green,
//                 size: 28,
//               ),
//             ),
//           ),
//           PopupMenuButton<String>(
//             onSelected: (value) {
//               if (value == 'restart') {
//                 _showRestartConfirmation();
//               } else if (value == 'save') {
//                 _saveChartData();
//               } else if (value == 'view_saved') {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const SavedRecordingsPage(),
//                   ),
//                 );
//               }
//             },
//             itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
//               const PopupMenuItem<String>(
//                 value: 'restart',
//                 child: Row(
//                   children: [
//                     Icon(Icons.refresh, color: Colors.blue),
//                     SizedBox(width: 8),
//                     Text('Restart'),
//                   ],
//                 ),
//               ),
//               const PopupMenuItem<String>(
//                 value: 'save',
//                 child: Row(
//                   children: [
//                     Icon(Icons.save_alt, color: Colors.green),
//                     SizedBox(width: 8),
//                     Text('Save Data'),
//                   ],
//                 ),
//               ),
//               const PopupMenuDivider(),
//               const PopupMenuItem<String>(
//                 value: 'view_saved',
//                 child: Row(
//                   children: [
//                     Icon(Icons.folder_open, color: Colors.orange),
//                     SizedBox(width: 8),
//                     Text('View Saved'),
//                   ],
//                 ),
//               ),
//             ],
//             icon: const Icon(Icons.more_vert, color: MainColors.black),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Stats bar
//           _buildStatsBar(),
//           const SizedBox(height: 8),
//           // Chart
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: GestureDetector(
//                 onHorizontalDragUpdate: _onHorizontalDragUpdate,
//                 child: Container(
//                   padding: const EdgeInsets.only(
//                       top: 24, bottom: 12, right: 20, left: 8),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(16),
//                     color: const Color(0xfff3f6f9),
//                     border: Border.all(color: Colors.grey[300]!, width: 1),
//                   ),
//                   child: _displayPoints.isEmpty
//                       ? Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.show_chart,
//                                   size: 48, color: Colors.grey[400]),
//                               const SizedBox(height: 12),
//                               Text("Waiting for data...",
//                                   style: AppTextStyles.regular),
//                             ],
//                           ),
//                         )
//                       : Stack(
//                           children: [
//                             LineChart(
//                               _buildChartData(),
//                               duration: Duration.zero,
//                             ),
//                             // Show "Go to Live" button when scrolled back
//                             if (!_autoScroll)
//                               Positioned(
//                                 top: 8,
//                                 right: 8,
//                                 child: ElevatedButton.icon(
//                                   onPressed: _resetToLive,
//                                   icon: const Icon(Icons.skip_next, size: 18),
//                                   label: const Text("LIVE"),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.red,
//                                     foregroundColor: Colors.white,
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 12, vertical: 8),
//                                     textStyle: const TextStyle(
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.bold),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           // Function controls
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: _buildFunctionControls(),
//           ),
//           const SizedBox(height: 16),
//           // Scroll hint
//           if (_displayPoints.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 16),
//               child: Text(
//                 "← Swipe horizontally to scroll through data →",
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                   fontStyle: FontStyle.italic,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatsBar() {
//     final duration = _recordingStartTime != null
//         ? DateTime.now().difference(_recordingStartTime!)
//         : Duration.zero;

//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _statItem(
//             icon: Icons.timer,
//             label: "Duration",
//             value: _formatDuration(duration),
//           ),
//           _statItem(
//             icon: Icons.data_array,
//             label: "Points",
//             value: _allDataPoints.length.toString(),
//           ),
//           _statItem(
//             icon: _isRecording ? Icons.fiber_manual_record : Icons.pause,
//             label: "Status",
//             value: _isRecording ? "Recording" : "Paused",
//             valueColor: _isRecording ? Colors.red : Colors.orange,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _statItem({
//     required IconData icon,
//     required String label,
//     required String value,
//     Color? valueColor,
//   }) {
//     return Column(
//       children: [
//         Icon(icon, size: 20, color: valueColor ?? Colors.grey[700]),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: valueColor ?? MainColors.black,
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(fontSize: 10, color: Colors.grey[600]),
//         ),
//       ],
//     );
//   }

//   String _formatDuration(Duration duration) {
//     final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
//     final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
//     return "$minutes:$seconds";
//   }

//   void _showRestartConfirmation() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Restart Recording?"),
//         content: Text(
//             "This will clear ${_allDataPoints.length} recorded data points. Are you sure?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _clearChart();
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: const Text("Restart", style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFunctionControls() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         _functionButton(
//           label: 'Func 1 (+5)',
//           onPressed: () {
//             setState(() {
//               _activeFunction = _activeFunction == ActiveFunction.function1
//                   ? ActiveFunction.none
//                   : ActiveFunction.function1;
//             });
//           },
//           isActive: _activeFunction == ActiveFunction.function1,
//         ),
//         _functionButton(
//           label: 'Func 2 (≤30, +10)',
//           onPressed: () {
//             setState(() {
//               _activeFunction = _activeFunction == ActiveFunction.function2
//                   ? ActiveFunction.none
//                   : ActiveFunction.function2;
//             });
//           },
//           isActive: _activeFunction == ActiveFunction.function2,
//         ),
//       ],
//     );
//   }

//   Widget _functionButton({
//     required String label,
//     required VoidCallback onPressed,
//     required bool isActive,
//   }) {
//     final activeStyle = ElevatedButton.styleFrom(
//       backgroundColor: MainColors.primaryColor,
//       foregroundColor: Colors.white,
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//     );

//     final inactiveStyle = OutlinedButton.styleFrom(
//       side: BorderSide(color: MainColors.primaryColor),
//       foregroundColor: MainColors.primaryColor,
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//     );

//     return isActive
//         ? ElevatedButton(
//             onPressed: onPressed, style: activeStyle, child: Text(label))
//         : OutlinedButton(
//             onPressed: onPressed, style: inactiveStyle, child: Text(label));
//   }

//   LineChartData _buildChartData() {
//     double maxX, minX;

//     if (_autoScroll) {
//       maxX = _displayPoints.isNotEmpty ? _displayPoints.last.x : 0;
//       minX = maxX - _visibleDurationInMs;
//     } else {
//       maxX = _manualMaxX ?? (_displayPoints.isNotEmpty ? _displayPoints.last.x : 0);
//       minX = _manualMinX ?? (maxX - _visibleDurationInMs);
//     }

//     return LineChartData(
//       minX: minX,
//       maxX: maxX,
//       clipData: const FlClipData.all(),
//       gridData: FlGridData(
//         show: true,
//         drawVerticalLine: true,
//         horizontalInterval: 20,
//         verticalInterval: 2000,
//         getDrawingHorizontalLine: (value) => FlLine(
//           color: Colors.grey[300],
//           strokeWidth: 0.8,
//         ),
//         getDrawingVerticalLine: (value) => FlLine(
//           color: Colors.grey[300],
//           strokeWidth: 0.8,
//         ),
//       ),
//       titlesData: FlTitlesData(
//         show: true,
//         rightTitles:
//             const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 30,
//             interval: 2000,
//             getTitlesWidget: (value, meta) {
//               final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
//               return SideTitleWidget(
//                 meta: meta,
//                 space: 8.0,
//                 child: Text(
//                   DateFormat('HH:mm:ss').format(date),
//                   style: TextStyle(color: Colors.grey[700], fontSize: 10),
//                 ),
//               );
//             },
//           ),
//         ),
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 45,
//             getTitlesWidget: (value, meta) {
//               if (value == meta.max || value == meta.min) {
//                 return Container();
//               }
//               return SideTitleWidget(
//                 meta: meta,
//                 child: Text(
//                   value.toInt().toString(),
//                   style: TextStyle(
//                       color: Colors.grey[700],
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold),
//                   textAlign: TextAlign.left,
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//       borderData: FlBorderData(show: false),
//       lineBarsData: [
//         LineChartBarData(
//           spots: _displayPoints,
//           isCurved: true,
//           color: MainColors.primaryColor,
//           barWidth: 2.5,
//           isStrokeCapRound: true,
//           dotData: const FlDotData(show: false),
//           belowBarData: BarAreaData(
//             show: true,
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 MainColors.primaryColor.withOpacity(0.3),
//                 MainColors.primaryColor.withOpacity(0.0),
//               ],
//             ),
//           ),
//         ),
//       ],
//       lineTouchData: LineTouchData(
//         enabled: true,
//         touchTooltipData: LineTouchTooltipData(
//           getTooltipItems: (touchedSpots) {
//             return touchedSpots.map((spot) {
//               final date =
//                   DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
//               return LineTooltipItem(
//                 '${spot.y.toStringAsFixed(2)}\n${DateFormat('HH:mm:ss').format(date)}',
//                 const TextStyle(
//                     color: Colors.white, fontWeight: FontWeight.bold),
//               );
//             }).toList();
//           },
//         ),
//       ),
//     );
//   }
// }




// --------------------------------------------------------------------------
// 2. LIVE EXG CHART PAGE WITH SCROLLING AND STORAGE (UPDATED)
// --------------------------------------------------------------------------

enum ActiveFunction { none, function1, function2 }

class LiveExgChartPage extends StatefulWidget {
  final Stream<double> dataStream;
  final String deviceName;

  const LiveExgChartPage({
    Key? key,
    required this.dataStream,
    required this.deviceName,
  }) : super(key: key);

  @override
  State<LiveExgChartPage> createState() => _LiveExgChartPageState();
}

class _LiveExgChartPageState extends State<LiveExgChartPage> {
  late StreamSubscription<double> _subscription;

  // Display points (limited for performance)
  final List<FlSpot> _displayPoints = [];

  // ALL data points stored for saving
  final List<DataPoint> _allDataPoints = [];

  ActiveFunction _activeFunction = ActiveFunction.none;

  // Scrolling control
  bool _autoScroll = true;
  double? _manualMinX;
  double? _manualMaxX;

  // Recording start time for duration
  DateTime? _recordingStartTime;

  static const int _maxDisplayPoints = 500;
  static const double _visibleDurationInMs = 10000;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Timer for updating duration display
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _recordingStartTime = DateTime.now();
    _startListening();
    _startDurationTimer();
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _startListening() {
    _subscription = widget.dataStream.listen((originalValue) {
      final now = DateTime.now();

      // Store original value with timestamp (for saving)
      _allDataPoints.add(DataPoint(
        value: originalValue,
        timestamp: now,
        processedValue: _processValue(originalValue),
      ));

      // Process value for display
      double processedValue = _processValue(originalValue);

      setState(() {
        final timestamp = now.millisecondsSinceEpoch.toDouble();
        _displayPoints.add(FlSpot(timestamp, processedValue));

        // Keep display points manageable
        if (_displayPoints.length > _maxDisplayPoints) {
          _displayPoints.removeAt(0);
        }
      });
    });
  }

  double _processValue(double originalValue) {
    switch (_activeFunction) {
      case ActiveFunction.function1:
        return originalValue + 5;
      case ActiveFunction.function2:
        if (originalValue <= 30) {
          return originalValue + 10;
        }
        return originalValue;
      case ActiveFunction.none:
        return originalValue;
    }
  }

  void _clearChart() {
    setState(() {
      _displayPoints.clear();
      _allDataPoints.clear();
      _recordingStartTime = DateTime.now();
      _autoScroll = true;
      _manualMinX = null;
      _manualMaxX = null;
    });
  }

  Future<void> _saveChartData() async {
    if (_allDataPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No data to save!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show saving dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Saving data..."),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Create session
      final sessionId = await _dbHelper.createSession(widget.deviceName);

      // Save all data points
      await _dbHelper.saveDataPoints(sessionId, _allDataPoints);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Saved ${_allDataPoints.length} data points successfully!"),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: "VIEW",
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedRecordingsPage(),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving data: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_displayPoints.isEmpty) return;

    setState(() {
      _autoScroll = false;

      final chartWidth = MediaQuery.of(context).size.width - 80;
      final dragRatio = details.delta.dx / chartWidth;
      final timeSpan = _visibleDurationInMs;
      final shift = -dragRatio * timeSpan;

      final currentMaxX = _manualMaxX ?? _displayPoints.last.x;
      final currentMinX = _manualMinX ?? (currentMaxX - _visibleDurationInMs);

      final dataMinX = _displayPoints.first.x;
      final dataMaxX = _displayPoints.last.x;

      double newMinX = currentMinX + shift;
      double newMaxX = currentMaxX + shift;

      // Clamp to data bounds
      if (newMinX < dataMinX) {
        newMinX = dataMinX;
        newMaxX = dataMinX + _visibleDurationInMs;
      }
      if (newMaxX > dataMaxX) {
        newMaxX = dataMaxX;
        newMinX = dataMaxX - _visibleDurationInMs;
        // If at the end, re-enable auto-scroll
        _autoScroll = true;
      }

      _manualMinX = newMinX;
      _manualMaxX = newMaxX;
    });
  }

  void _resetToLive() {
    setState(() {
      _autoScroll = true;
      _manualMinX = null;
      _manualMaxX = null;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MainColors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Real-Time EXG Signal", style: AppTextStyles.header),
            Text(widget.deviceName,
                style: AppTextStyles.regular
                    .copyWith(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        backgroundColor: MainColors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: MainColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Only the 3-dot menu, removed pause/resume button
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'restart') {
                _showRestartConfirmation();
              } else if (value == 'save') {
                _saveChartData();
              } else if (value == 'view_saved') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedRecordingsPage(),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'restart',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Restart'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.save_alt, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Save Data'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'view_saved',
                child: Row(
                  children: [
                    Icon(Icons.folder_open, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('View Saved'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: MainColors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar - only Duration and Points
          _buildStatsBar(),
          const SizedBox(height: 8),
          // Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                child: Container(
                  padding: const EdgeInsets.only(
                      top: 24, bottom: 12, right: 20, left: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xfff3f6f9),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: _displayPoints.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.show_chart,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text("Waiting for data...",
                                  style: AppTextStyles.regular),
                            ],
                          ),
                        )
                      : Stack(
                          children: [
                            LineChart(
                              _buildChartData(),
                              duration: Duration.zero,
                            ),
                            // Show "Go to Live" button when scrolled back
                            if (!_autoScroll)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: ElevatedButton.icon(
                                  onPressed: _resetToLive,
                                  icon: const Icon(Icons.skip_next, size: 18),
                                  label: const Text("LIVE"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Function controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildFunctionControls(),
          ),
          const SizedBox(height: 16),
          // Scroll hint
          if (_displayPoints.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                "← Swipe horizontally to scroll through data →",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Updated stats bar - only Duration and Points (removed Status)
  Widget _buildStatsBar() {
    final duration = _recordingStartTime != null
        ? DateTime.now().difference(_recordingStartTime!)
        : Duration.zero;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(
            icon: Icons.timer_outlined,
            label: "Duration",
            value: _formatDuration(duration),
          ),
          // Vertical divider
          Container(
            height: 40,
            width: 1,
            color: Colors.grey[300],
          ),
          _statItem(
            icon: Icons.data_array,
            label: "Points",
            value: _allDataPoints.length.toString(),
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: MainColors.primaryColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: MainColors.black,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    
    if (hours > 0) {
      return "$hours:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  void _showRestartConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Restart Recording?"),
        content: Text(
            "This will clear ${_allDataPoints.length} recorded data points. Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearChart();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Restart", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _functionButton(
          label: 'Func 1 (+5)',
          onPressed: () {
            setState(() {
              _activeFunction = _activeFunction == ActiveFunction.function1
                  ? ActiveFunction.none
                  : ActiveFunction.function1;
            });
          },
          isActive: _activeFunction == ActiveFunction.function1,
        ),
        _functionButton(
          label: 'Func 2 (≤30, +10)',
          onPressed: () {
            setState(() {
              _activeFunction = _activeFunction == ActiveFunction.function2
                  ? ActiveFunction.none
                  : ActiveFunction.function2;
            });
          },
          isActive: _activeFunction == ActiveFunction.function2,
        ),
      ],
    );
  }

  Widget _functionButton({
    required String label,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    final activeStyle = ElevatedButton.styleFrom(
      backgroundColor: MainColors.primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );

    final inactiveStyle = OutlinedButton.styleFrom(
      side: BorderSide(color: MainColors.primaryColor),
      foregroundColor: MainColors.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );

    return isActive
        ? ElevatedButton(
            onPressed: onPressed, style: activeStyle, child: Text(label))
        : OutlinedButton(
            onPressed: onPressed, style: inactiveStyle, child: Text(label));
  }

  LineChartData _buildChartData() {
    double maxX, minX;

    if (_autoScroll) {
      maxX = _displayPoints.isNotEmpty ? _displayPoints.last.x : 0;
      minX = maxX - _visibleDurationInMs;
    } else {
      maxX = _manualMaxX ?? (_displayPoints.isNotEmpty ? _displayPoints.last.x : 0);
      minX = _manualMinX ?? (maxX - _visibleDurationInMs);
    }

    return LineChartData(
      minX: minX,
      maxX: maxX,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 20,
        verticalInterval: 2000,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey[300],
          strokeWidth: 0.8,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey[300],
          strokeWidth: 0.8,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 2000,
            getTitlesWidget: (value, meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return SideTitleWidget(
                meta: meta,
                space: 8.0,
                child: Text(
                  DateFormat('HH:mm:ss').format(date),
                  style: TextStyle(color: Colors.grey[700], fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              if (value == meta.max || value == meta.min) {
                return Container();
              }
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: _displayPoints,
          isCurved: true,
          color: MainColors.primaryColor,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                MainColors.primaryColor.withOpacity(0.3),
                MainColors.primaryColor.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date =
                  DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(2)}\n${DateFormat('HH:mm:ss').format(date)}',
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// 3. SAVED RECORDINGS PAGE
// --------------------------------------------------------------------------

class SavedRecordingsPage extends StatefulWidget {
  const SavedRecordingsPage({Key? key}) : super(key: key);

  @override
  State<SavedRecordingsPage> createState() => _SavedRecordingsPageState();
}

class _SavedRecordingsPageState extends State<SavedRecordingsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<RecordingSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await _dbHelper.getAllSessions();
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading sessions: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSession(RecordingSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Recording?"),
        content: Text(
            "This will permanently delete this recording with ${session.dataCount} data points."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && session.id != null) {
      await _dbHelper.deleteSession(session.id!);
      _loadSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Recording deleted"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MainColors.white,
      appBar: AppBar(
        title: Text("Saved Recordings", style: AppTextStyles.header),
        backgroundColor: MainColors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: MainColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: MainColors.black),
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? _buildEmptyState()
              : _buildSessionsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No saved recordings",
            style: AppTextStyles.bold.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            "Start recording and save data from\nthe real-time graph page",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          return _buildSessionCard(session);
        },
      ),
    );
  }

  Widget _buildSessionCard(RecordingSession session) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm:ss');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecordingDetailPage(session: session),
            ),
          ).then((_) => _loadSessions());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: MainColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.bluetooth,
                        color: MainColors.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.deviceName,
                          style: AppTextStyles.bold.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(session.startTime),
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteSession(session),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoItem(
                    icon: Icons.access_time,
                    label: "Start",
                    value: timeFormat.format(session.startTime),
                  ),
                  _infoItem(
                    icon: Icons.timer,
                    label: "Duration",
                    value: session.duration != null
                        ? _formatDuration(session.duration!)
                        : "--",
                  ),
                  _infoItem(
                    icon: Icons.data_array,
                    label: "Points",
                    value: session.dataCount.toString(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else if (minutes > 0) {
      return "${minutes}m ${seconds}s";
    } else {
      return "${seconds}s";
    }
  }
}

// --------------------------------------------------------------------------
// 4. RECORDING DETAIL PAGE - VIEW SAVED DATA
// --------------------------------------------------------------------------

// class RecordingDetailPage extends StatefulWidget {
//   final RecordingSession session;

//   const RecordingDetailPage({Key? key, required this.session})
//       : super(key: key);

//   @override
//   State<RecordingDetailPage> createState() => _RecordingDetailPageState();
// }

// class _RecordingDetailPageState extends State<RecordingDetailPage> {
//   final DatabaseHelper _dbHelper = DatabaseHelper.instance;
//   List<DataPoint> _dataPoints = [];
//   Map<String, dynamic> _stats = {};
//   bool _isLoading = true;

//   // Scrolling/zooming control
//   double? _visibleMinX;
//   double? _visibleMaxX;
//   bool _showAllData = true;
//   static const double _defaultVisibleDuration = 30000; // 30 seconds

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     setState(() => _isLoading = true);
//     try {
//       final dataPoints =
//           await _dbHelper.getSessionDataPoints(widget.session.id!);
//       final stats = await _dbHelper.getSessionStats(widget.session.id!);

//       setState(() {
//         _dataPoints = dataPoints;
//         _stats = stats;
//         _isLoading = false;

//         // Initialize visible range
//         if (_dataPoints.isNotEmpty) {
//           _visibleMinX =
//               _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
//           _visibleMaxX =
//               _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
//         }
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Error loading data: $e"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   List<FlSpot> _getDisplaySpots() {
//     return _dataPoints.map((point) {
//       return FlSpot(
//         point.timestamp.millisecondsSinceEpoch.toDouble(),
//         point.value,
//       );
//     }).toList();
//   }

//   void _onHorizontalDragUpdate(DragUpdateDetails details) {
//     if (_dataPoints.isEmpty || _showAllData) return;

//     setState(() {
//       final chartWidth = MediaQuery.of(context).size.width - 80;
//       final visibleDuration = (_visibleMaxX ?? 0) - (_visibleMinX ?? 0);
//       final dragRatio = details.delta.dx / chartWidth;
//       final shift = -dragRatio * visibleDuration;

//       final dataMinX =
//           _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
//       final dataMaxX =
//           _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();

//       double newMinX = (_visibleMinX ?? dataMinX) + shift;
//       double newMaxX = (_visibleMaxX ?? dataMaxX) + shift;

//       // Clamp
//       if (newMinX < dataMinX) {
//         newMinX = dataMinX;
//         newMaxX = newMinX + visibleDuration;
//       }
//       if (newMaxX > dataMaxX) {
//         newMaxX = dataMaxX;
//         newMinX = newMaxX - visibleDuration;
//       }

//       _visibleMinX = newMinX;
//       _visibleMaxX = newMaxX;
//     });
//   }

//   void _zoomIn() {
//     if (_dataPoints.isEmpty) return;

//     setState(() {
//       _showAllData = false;
//       final currentRange = (_visibleMaxX ?? 0) - (_visibleMinX ?? 0);
//       final center = ((_visibleMaxX ?? 0) + (_visibleMinX ?? 0)) / 2;
//       final newRange = currentRange / 2;

//       _visibleMinX = center - newRange / 2;
//       _visibleMaxX = center + newRange / 2;
//     });
//   }

//   void _zoomOut() {
//     if (_dataPoints.isEmpty) return;

//     setState(() {
//       final dataMinX =
//           _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
//       final dataMaxX =
//           _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
//       final dataRange = dataMaxX - dataMinX;

//       final currentRange = (_visibleMaxX ?? dataMaxX) - (_visibleMinX ?? dataMinX);
//       final center = ((_visibleMaxX ?? dataMaxX) + (_visibleMinX ?? dataMinX)) / 2;
//       var newRange = currentRange * 2;

//       if (newRange >= dataRange) {
//         _showAllData = true;
//         _visibleMinX = dataMinX;
//         _visibleMaxX = dataMaxX;
//       } else {
//         var newMinX = center - newRange / 2;
//         var newMaxX = center + newRange / 2;

//         if (newMinX < dataMinX) {
//           newMinX = dataMinX;
//           newMaxX = newMinX + newRange;
//         }
//         if (newMaxX > dataMaxX) {
//           newMaxX = dataMaxX;
//           newMinX = newMaxX - newRange;
//         }

//         _visibleMinX = newMinX;
//         _visibleMaxX = newMaxX;
//       }
//     });
//   }

//   void _resetZoom() {
//     if (_dataPoints.isEmpty) return;

//     setState(() {
//       _showAllData = true;
//       _visibleMinX =
//           _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
//       _visibleMaxX =
//           _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

//     return Scaffold(
//       backgroundColor: MainColors.white,
//       appBar: AppBar(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Recording Details", style: AppTextStyles.header),
//             Text(
//               widget.session.deviceName,
//               style: AppTextStyles.regular
//                   .copyWith(fontSize: 12, color: Colors.grey[600]),
//             ),
//           ],
//         ),
//         backgroundColor: MainColors.white,
//         elevation: 1,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: MainColors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _dataPoints.isEmpty
//               ? _buildEmptyState()
//               : _buildContent(dateFormat),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.data_array, size: 80, color: Colors.grey[400]),
//           const SizedBox(height: 16),
//           Text(
//             "No data points found",
//             style: AppTextStyles.bold.copyWith(fontSize: 18),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildContent(DateFormat dateFormat) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           // Session info
//           _buildSessionInfoCard(dateFormat),

//           // Stats card
//           _buildStatsCard(),

//           // Chart section
//           const SizedBox(height: 16),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text("Signal Data", style: AppTextStyles.bold),
//                 Row(
//                   children: [
//                     IconButton(
//                       onPressed: _zoomIn,
//                       icon: const Icon(Icons.zoom_in),
//                       tooltip: "Zoom In",
//                     ),
//                     IconButton(
//                       onPressed: _zoomOut,
//                       icon: const Icon(Icons.zoom_out),
//                       tooltip: "Zoom Out",
//                     ),
//                     IconButton(
//                       onPressed: _resetZoom,
//                       icon: const Icon(Icons.fit_screen),
//                       tooltip: "Fit All",
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // Chart
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: GestureDetector(
//               onHorizontalDragUpdate: _onHorizontalDragUpdate,
//               child: Container(
//                 height: 300,
//                 padding: const EdgeInsets.only(
//                     top: 24, bottom: 12, right: 20, left: 8),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(16),
//                   color: const Color(0xfff3f6f9),
//                   border: Border.all(color: Colors.grey[300]!, width: 1),
//                 ),
//                 child: LineChart(
//                   _buildChartData(),
//                   duration: const Duration(milliseconds: 150),
//                 ),
//               ),
//             ),
//           ),

//           // Scroll hint
//           Padding(
//             padding: const EdgeInsets.only(bottom: 8),
//             child: Text(
//               "← Swipe to scroll • Use zoom buttons to adjust view →",
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[600],
//                 fontStyle: FontStyle.italic,
//               ),
//             ),
//           ),

//           // Data table
//           _buildDataTable(),

//           const SizedBox(height: 24),
//         ],
//       ),
//     );
//   }

//   Widget _buildSessionInfoCard(DateFormat dateFormat) {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: MainColors.primaryColor.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               const Icon(Icons.calendar_today, size: 18),
//               const SizedBox(width: 8),
//               Text(
//                 "Recorded: ${dateFormat.format(widget.session.startTime)}",
//                 style: AppTextStyles.regular,
//               ),
//             ],
//           ),
//           if (widget.session.duration != null) ...[
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 const Icon(Icons.timer, size: 18),
//                 const SizedBox(width: 8),
//                 Text(
//                   "Duration: ${_formatDuration(widget.session.duration!)}",
//                   style: AppTextStyles.regular,
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildStatsCard() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 4,
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _statItem(
//             label: "Points",
//             value: _stats['count']?.toString() ?? "0",
//             color: Colors.blue,
//           ),
//           _statItem(
//             label: "Min",
//             value: (_stats['min_value'] as num?)?.toStringAsFixed(1) ?? "0",
//             color: Colors.green,
//           ),
//           _statItem(
//             label: "Max",
//             value: (_stats['max_value'] as num?)?.toStringAsFixed(1) ?? "0",
//             color: Colors.red,
//           ),
//           _statItem(
//             label: "Avg",
//             value: (_stats['avg_value'] as num?)?.toStringAsFixed(1) ?? "0",
//             color: Colors.orange,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _statItem({
//     required String label,
//     required String value,
//     required Color color,
//   }) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Text(
//             value,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//               color: color,
//             ),
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
//       ],
//     );
//   }

//   Widget _buildDataTable() {
//     final displayPoints =
//         _dataPoints.take(100).toList(); // Show first 100 for performance

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[300]!),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text("Data Points", style: AppTextStyles.bold),
//                 Text(
//                   "Showing ${displayPoints.length} of ${_dataPoints.length}",
//                   style: TextStyle(color: Colors.grey[600], fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//           const Divider(height: 1),
//           // Header
//           Container(
//             color: Colors.grey[100],
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             child: const Row(
//               children: [
//                 Expanded(
//                     flex: 1,
//                     child: Text("#",
//                         style: TextStyle(fontWeight: FontWeight.bold))),
//                 Expanded(
//                     flex: 2,
//                     child: Text("Time",
//                         style: TextStyle(fontWeight: FontWeight.bold))),
//                 Expanded(
//                     flex: 2,
//                     child: Text("Value",
//                         style: TextStyle(fontWeight: FontWeight.bold))),
//               ],
//             ),
//           ),
//           // Data rows
//           ...displayPoints.asMap().entries.map((entry) {
//             final index = entry.key;
//             final point = entry.value;
//             final timeFormat = DateFormat('HH:mm:ss.SSS');

//             return Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               decoration: BoxDecoration(
//                 color: index % 2 == 0 ? Colors.white : Colors.grey[50],
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                       flex: 1,
//                       child: Text("${index + 1}",
//                           style: TextStyle(color: Colors.grey[600]))),
//                   Expanded(
//                       flex: 2,
//                       child: Text(timeFormat.format(point.timestamp))),
//                   Expanded(flex: 2, child: Text(point.value.toStringAsFixed(2))),
//                 ],
//               ),
//             );
//           }),
//           if (_dataPoints.length > 100)
//             Container(
//               padding: const EdgeInsets.all(16),
//               alignment: Alignment.center,
//               child: Text(
//                 "... and ${_dataPoints.length - 100} more data points",
//                 style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   LineChartData _buildChartData() {
//     final spots = _getDisplaySpots();

//     return LineChartData(
//       minX: _visibleMinX,
//       maxX: _visibleMaxX,
//       clipData: const FlClipData.all(),
//       gridData: FlGridData(
//         show: true,
//         drawVerticalLine: true,
//         horizontalInterval: 20,
//         getDrawingHorizontalLine: (value) => FlLine(
//           color: Colors.grey[300],
//           strokeWidth: 0.8,
//         ),
//         getDrawingVerticalLine: (value) => FlLine(
//           color: Colors.grey[300],
//           strokeWidth: 0.8,
//         ),
//       ),
//       titlesData: FlTitlesData(
//         show: true,
//         rightTitles:
//             const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 30,
//             getTitlesWidget: (value, meta) {
//               final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
//               return SideTitleWidget(
//                 meta: meta,
//                 space: 8.0,
//                 child: Text(
//                   DateFormat('mm:ss').format(date),
//                   style: TextStyle(color: Colors.grey[700], fontSize: 10),
//                 ),
//               );
//             },
//           ),
//         ),
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 45,
//             getTitlesWidget: (value, meta) {
//               if (value == meta.max || value == meta.min) {
//                 return Container();
//               }
//               return SideTitleWidget(
//                 meta: meta,
//                 child: Text(
//                   value.toInt().toString(),
//                   style: TextStyle(
//                       color: Colors.grey[700],
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//       borderData: FlBorderData(show: false),
//       lineBarsData: [
//         LineChartBarData(
//           spots: spots,
//           isCurved: true,
//           color: MainColors.primaryColor,
//           barWidth: 2,
//           isStrokeCapRound: true,
//           dotData: FlDotData(
//             show: spots.length < 50, // Show dots only when zoomed in
//           ),
//           belowBarData: BarAreaData(
//             show: true,
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 MainColors.primaryColor.withOpacity(0.3),
//                 MainColors.primaryColor.withOpacity(0.0),
//               ],
//             ),
//           ),
//         ),
//       ],
//       lineTouchData: LineTouchData(
//         enabled: true,
//         touchTooltipData: LineTouchTooltipData(
//           getTooltipItems: (touchedSpots) {
//             return touchedSpots.map((spot) {
//               final date =
//                   DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
//               return LineTooltipItem(
//                 '${spot.y.toStringAsFixed(2)}\n${DateFormat('HH:mm:ss').format(date)}',
//                 const TextStyle(
//                     color: Colors.white, fontWeight: FontWeight.bold),
//               );
//             }).toList();
//           },
//         ),
//       ),
//     );
//   }

//   String _formatDuration(Duration duration) {
//     final hours = duration.inHours;
//     final minutes = duration.inMinutes.remainder(60);
//     final seconds = duration.inSeconds.remainder(60);

//     if (hours > 0) {
//       return "${hours}h ${minutes}m ${seconds}s";
//     } else if (minutes > 0) {
//       return "${minutes}m ${seconds}s";
//     } else {
//       return "${seconds}s";
//     }
//   }
// }


 
// --------------------------------------------------------------------------
// 4. RECORDING DETAIL PAGE - VIEW SAVED DATA WITH CSV EXPORT
// --------------------------------------------------------------------------

// class RecordingDetailPage extends StatefulWidget {
//   final RecordingSession session;

//   const RecordingDetailPage({Key? key, required this.session})
//       : super(key: key);

//   @override
//   State<RecordingDetailPage> createState() => _RecordingDetailPageState();
// }

// class _RecordingDetailPageState extends State<RecordingDetailPage> {
//   final DatabaseHelper _dbHelper = DatabaseHelper.instance;
//   List<DataPoint> _dataPoints = [];
//   Map<String, dynamic> _stats = {};
//   bool _isLoading = true;
//   bool _isExporting = false;

//   // Scrolling/zooming control
//   double? _visibleMinX;
//   double? _visibleMaxX;
//   bool _showAllData = true;
//   static const double _defaultVisibleDuration = 30000; // 30 seconds

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     setState(() => _isLoading = true);
//     try {
//       final dataPoints =
//           await _dbHelper.getSessionDataPoints(widget.session.id!);
//       final stats = await _dbHelper.getSessionStats(widget.session.id!);

//       setState(() {
//         _dataPoints = dataPoints;
//         _stats = stats;
//         _isLoading = false;

//         // Initialize visible range
//         if (_dataPoints.isNotEmpty) {
//           _visibleMinX =
//               _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
//           _visibleMaxX =
//               _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
//         }
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Error loading data: $e"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // --------------------------------------------------------------------------
//   // CSV EXPORT FUNCTIONALITY
//   // --------------------------------------------------------------------------

//   Future<void> _exportToCSV() async {
//     if (_dataPoints.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("No data to export!"),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     setState(() => _isExporting = true);

//     try {
//       // Generate CSV content
//       final csvContent = _generateCSVContent();

//       // Get file path
//       final fileName = _generateFileName();
//       final filePath = await _saveCSVFile(fileName, csvContent);

//       setState(() => _isExporting = false);

//       if (mounted) {
//         // Show options dialog
//         _showExportSuccessDialog(filePath, fileName);
//       }
//     } catch (e) {
//       setState(() => _isExporting = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Error exporting data: $e"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   String _generateCSVContent() {
//     final StringBuffer buffer = StringBuffer();

//     // Add metadata as comments
//     buffer.writeln('# EXG Recording Export');
//     buffer.writeln('# Device: ${widget.session.deviceName}');
//     buffer.writeln('# Start Time: ${widget.session.startTime.toIso8601String()}');
//     if (widget.session.endTime != null) {
//       buffer.writeln('# End Time: ${widget.session.endTime!.toIso8601String()}');
//     }
//     buffer.writeln('# Total Points: ${_dataPoints.length}');
//     buffer.writeln('# Min Value: ${_stats['min_value'] ?? 'N/A'}');
//     buffer.writeln('# Max Value: ${_stats['max_value'] ?? 'N/A'}');
//     buffer.writeln('# Avg Value: ${(_stats['avg_value'] as num?)?.toStringAsFixed(2) ?? 'N/A'}');
//     buffer.writeln('#');

//     // Add CSV header
//     buffer.writeln('Index,Timestamp,DateTime,Value,Processed Value');

//     // Add data rows
//     for (int i = 0; i < _dataPoints.length; i++) {
//       final point = _dataPoints[i];
//       final dateTimeStr = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(point.timestamp);
//       final timestampMs = point.timestamp.millisecondsSinceEpoch;
      
//       buffer.writeln(
//         '${i + 1},$timestampMs,$dateTimeStr,${point.value},${point.processedValue ?? point.value}'
//       );
//     }

//     return buffer.toString();
//   }

//   String _generateFileName() {
//     final dateStr = DateFormat('yyyyMMdd_HHmmss').format(widget.session.startTime);
//     final deviceName = widget.session.deviceName.replaceAll(RegExp(r'[^\w]'), '_');
//     return 'EXG_${deviceName}_$dateStr.csv';
//   }

//   Future<String> _saveCSVFile(String fileName, String content) async {
//     final directory = await getApplicationDocumentsDirectory();
//     final filePath = '${directory.path}/$fileName';
//     final file = File(filePath);
//     await file.writeAsString(content);
//     return filePath;
//   }

//   void _showExportSuccessDialog(String filePath, String fileName) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.green.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
//             ),
//             const SizedBox(width: 12),
//             const Text("Export Successful"),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Your data has been exported successfully!",
//               style: TextStyle(color: Colors.grey[700]),
//             ),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.description, color: Colors.blue, size: 20),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       fileName,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w500,
//                         fontSize: 13,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "${_dataPoints.length} data points exported",
//               style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Close"),
//           ),
//           ElevatedButton.icon(
//             onPressed: () {
//               Navigator.pop(context);
//               _shareCSVFile(filePath);
//             },
//             icon: const Icon(Icons.share, size: 18),
//             label: const Text("Share"),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: MainColors.primaryColor,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _shareCSVFile(String filePath) async {
//     try {
//       await Share.shareXFiles(
//         [XFile(filePath)],
//         subject: 'EXG Recording Data - ${widget.session.deviceName}',
//         text: 'EXG recording data exported on ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
//       );
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Error sharing file: $e"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // --------------------------------------------------------------------------
//   // REST OF THE EXISTING CODE
//   // --------------------------------------------------------------------------

//   List<FlSpot> _getDisplaySpots() {
//     return _dataPoints.map((point) {
//       return FlSpot(
//         point.timestamp.millisecondsSinceEpoch.toDouble(),
//         point.value,
//       );
//     }).toList();
//   }

//   void _onHorizontalDragUpdate(DragUpdateDetails details) {
//     if (_dataPoints.isEmpty || _showAllData) return;

//     setState(() {
//       final chartWidth = MediaQuery.of(context).size.width - 80;
//       final visibleDuration = (_visibleMaxX ?? 0) - (_visibleMinX ?? 0);
//       final dragRatio = details.delta.dx / chartWidth;
//       final shift = -dragRatio * visibleDuration;

//       final dataMinX =
//           _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
//       final dataMaxX =
//           _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();

//       double newMinX = (_visibleMinX ?? dataMinX) + shift;
//       double newMaxX = (_visibleMaxX ?? dataMaxX) + shift;

//       // Clamp
//       if (newMinX < dataMinX) {
//         newMinX = dataMinX;
//         newMaxX = newMinX + visibleDuration;
//       }
//       if (newMaxX > dataMaxX) {
//         newMaxX = dataMaxX;
//         newMinX = newMaxX - visibleDuration;
//       }

//       _visibleMinX = newMinX;
//       _visibleMaxX = newMaxX;
//     });
//   }

//   void _zoomIn() {
//     if (_dataPoints.isEmpty) return;

//     setState(() {
//       _showAllData = false;
//       final currentRange = (_visibleMaxX ?? 0) - (_visibleMinX ?? 0);
//       final center = ((_visibleMaxX ?? 0) + (_visibleMinX ?? 0)) / 2;
//       final newRange = currentRange / 2;

//       _visibleMinX = center - newRange / 2;
//       _visibleMaxX = center + newRange / 2;
//     });
//   }

//   void _zoomOut() {
//     if (_dataPoints.isEmpty) return;

//     setState(() {
//       final dataMinX =
//           _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
//       final dataMaxX =
//           _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
//       final dataRange = dataMaxX - dataMinX;

//       final currentRange = (_visibleMaxX ?? dataMaxX) - (_visibleMinX ?? dataMinX);
//       final center = ((_visibleMaxX ?? dataMaxX) + (_visibleMinX ?? dataMinX)) / 2;
//       var newRange = currentRange * 2;

//       if (newRange >= dataRange) {
//         _showAllData = true;
//         _visibleMinX = dataMinX;
//         _visibleMaxX = dataMaxX;
//       } else {
//         var newMinX = center - newRange / 2;
//         var newMaxX = center + newRange / 2;

//         if (newMinX < dataMinX) {
//           newMinX = dataMinX;
//           newMaxX = newMinX + newRange;
//         }
//         if (newMaxX > dataMaxX) {
//           newMaxX = dataMaxX;
//           newMinX = newMaxX - newRange;
//         }

//         _visibleMinX = newMinX;
//         _visibleMaxX = newMaxX;
//       }
//     });
//   }

//   void _resetZoom() {
//     if (_dataPoints.isEmpty) return;

//     setState(() {
//       _showAllData = true;
//       _visibleMinX =
//           _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
//       _visibleMaxX =
//           _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

//     return Scaffold(
//       backgroundColor: MainColors.white,
//       appBar: AppBar(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Recording Details", style: AppTextStyles.header),
//             Text(
//               widget.session.deviceName,
//               style: AppTextStyles.regular
//                   .copyWith(fontSize: 12, color: Colors.grey[600]),
//             ),
//           ],
//         ),
//         backgroundColor: MainColors.white,
//         elevation: 1,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: MainColors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           // Export to CSV option in menu
//           PopupMenuButton<String>(
//             onSelected: (value) {
//               if (value == 'export_csv') {
//                 _exportToCSV();
//               }
//             },
//             itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
//               const PopupMenuItem<String>(
//                 value: 'export_csv',
//                 child: Row(
//                   children: [
//                     Icon(Icons.file_download, color: Colors.green),
//                     SizedBox(width: 8),
//                     Text('Export to CSV'),
//                   ],
//                 ),
//               ),
//             ],
//             icon: const Icon(Icons.more_vert, color: MainColors.black),
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _dataPoints.isEmpty
//               ? _buildEmptyState()
//               : Stack(
//                   children: [
//                     _buildContent(dateFormat),
//                     // Loading overlay for export
//                     if (_isExporting)
//                       Container(
//                         color: Colors.black.withOpacity(0.3),
//                         child: const Center(
//                           child: Card(
//                             child: Padding(
//                               padding: EdgeInsets.all(24),
//                               child: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   CircularProgressIndicator(),
//                                   SizedBox(height: 16),
//                                   Text("Exporting to CSV..."),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.data_array, size: 80, color: Colors.grey[400]),
//           const SizedBox(height: 16),
//           Text(
//             "No data points found",
//             style: AppTextStyles.bold.copyWith(fontSize: 18),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildContent(DateFormat dateFormat) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           // Session info
//           _buildSessionInfoCard(dateFormat),

//           // Stats card
//           _buildStatsCard(),

//           // Export button (prominent)
//           _buildExportButton(),

//           // Chart section
//           const SizedBox(height: 16),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text("Signal Data", style: AppTextStyles.bold),
//                 Row(
//                   children: [
//                     IconButton(
//                       onPressed: _zoomIn,
//                       icon: const Icon(Icons.zoom_in),
//                       tooltip: "Zoom In",
//                     ),
//                     IconButton(
//                       onPressed: _zoomOut,
//                       icon: const Icon(Icons.zoom_out),
//                       tooltip: "Zoom Out",
//                     ),
//                     IconButton(
//                       onPressed: _resetZoom,
//                       icon: const Icon(Icons.fit_screen),
//                       tooltip: "Fit All",
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // Chart
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: GestureDetector(
//               onHorizontalDragUpdate: _onHorizontalDragUpdate,
//               child: Container(
//                 height: 300,
//                 padding: const EdgeInsets.only(
//                     top: 24, bottom: 12, right: 20, left: 8),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(16),
//                   color: const Color(0xfff3f6f9),
//                   border: Border.all(color: Colors.grey[300]!, width: 1),
//                 ),
//                 child: LineChart(
//                   _buildChartData(),
//                   duration: const Duration(milliseconds: 150),
//                 ),
//               ),
//             ),
//           ),

//           // Scroll hint
//           Padding(
//             padding: const EdgeInsets.only(bottom: 8),
//             child: Text(
//               "← Swipe to scroll • Use zoom buttons to adjust view →",
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[600],
//                 fontStyle: FontStyle.italic,
//               ),
//             ),
//           ),

//           // Data table
//           _buildDataTable(),

//           const SizedBox(height: 24),
//         ],
//       ),
//     );
//   }

//   // NEW: Prominent Export Button
//   Widget _buildExportButton() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: SizedBox(
//         width: double.infinity,
//         child: ElevatedButton.icon(
//           onPressed: _isExporting ? null : _exportToCSV,
//           icon: _isExporting
//               ? const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 )
//               : const Icon(Icons.file_download, size: 22),
//           label: Text(
//             _isExporting ? "EXPORTING..." : "EXPORT TO CSV",
//             style: AppTextStyles.bold.copyWith(fontSize: 15),
//           ),
//           style: ElevatedButton.styleFrom(
//             foregroundColor: Colors.white,
//             backgroundColor: Colors.green[600],
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             elevation: 2,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSessionInfoCard(DateFormat dateFormat) {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: MainColors.primaryColor.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               const Icon(Icons.calendar_today, size: 18),
//               const SizedBox(width: 8),
//               Text(
//                 "Recorded: ${dateFormat.format(widget.session.startTime)}",
//                 style: AppTextStyles.regular,
//               ),
//             ],
//           ),
//           if (widget.session.duration != null) ...[
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 const Icon(Icons.timer, size: 18),
//                 const SizedBox(width: 8),
//                 Text(
//                   "Duration: ${_formatDuration(widget.session.duration!)}",
//                   style: AppTextStyles.regular,
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildStatsCard() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 4,
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _statItem(
//             label: "Points",
//             value: _stats['count']?.toString() ?? "0",
//             color: Colors.blue,
//           ),
//           _statItem(
//             label: "Min",
//             value: (_stats['min_value'] as num?)?.toStringAsFixed(1) ?? "0",
//             color: Colors.green,
//           ),
//           _statItem(
//             label: "Max",
//             value: (_stats['max_value'] as num?)?.toStringAsFixed(1) ?? "0",
//             color: Colors.red,
//           ),
//           _statItem(
//             label: "Avg",
//             value: (_stats['avg_value'] as num?)?.toStringAsFixed(1) ?? "0",
//             color: Colors.orange,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _statItem({
//     required String label,
//     required String value,
//     required Color color,
//   }) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Text(
//             value,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//               color: color,
//             ),
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
//       ],
//     );
//   }

//   Widget _buildDataTable() {
//     final displayPoints =
//         _dataPoints.take(100).toList(); // Show first 100 for performance

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[300]!),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text("Data Points", style: AppTextStyles.bold),
//                 Text(
//                   "Showing ${displayPoints.length} of ${_dataPoints.length}",
//                   style: TextStyle(color: Colors.grey[600], fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//           const Divider(height: 1),
//           // Header
//           Container(
//             color: Colors.grey[100],
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             child: const Row(
//               children: [
//                 Expanded(
//                     flex: 1,
//                     child: Text("#",
//                         style: TextStyle(fontWeight: FontWeight.bold))),
//                 Expanded(
//                     flex: 2,
//                     child: Text("Time",
//                         style: TextStyle(fontWeight: FontWeight.bold))),
//                 Expanded(
//                     flex: 2,
//                     child: Text("Value",
//                         style: TextStyle(fontWeight: FontWeight.bold))),
//               ],
//             ),
//           ),
//           // Data rows
//           ...displayPoints.asMap().entries.map((entry) {
//             final index = entry.key;
//             final point = entry.value;
//             final timeFormat = DateFormat('HH:mm:ss.SSS');

//             return Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               decoration: BoxDecoration(
//                 color: index % 2 == 0 ? Colors.white : Colors.grey[50],
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                       flex: 1,
//                       child: Text("${index + 1}",
//                           style: TextStyle(color: Colors.grey[600]))),
//                   Expanded(
//                       flex: 2,
//                       child: Text(timeFormat.format(point.timestamp))),
//                   Expanded(flex: 2, child: Text(point.value.toStringAsFixed(2))),
//                 ],
//               ),
//             );
//           }),
//           if (_dataPoints.length > 100)
//             Container(
//               padding: const EdgeInsets.all(16),
//               alignment: Alignment.center,
//               child: Text(
//                 "... and ${_dataPoints.length - 100} more data points",
//                 style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   LineChartData _buildChartData() {
//     final spots = _getDisplaySpots();

//     return LineChartData(
//       minX: _visibleMinX,
//       maxX: _visibleMaxX,
//       clipData: const FlClipData.all(),
//       gridData: FlGridData(
//         show: true,
//         drawVerticalLine: true,
//         horizontalInterval: 20,
//         getDrawingHorizontalLine: (value) => FlLine(
//           color: Colors.grey[300],
//           strokeWidth: 0.8,
//         ),
//         getDrawingVerticalLine: (value) => FlLine(
//           color: Colors.grey[300],
//           strokeWidth: 0.8,
//         ),
//       ),
//       titlesData: FlTitlesData(
//         show: true,
//         rightTitles:
//             const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 30,
//             getTitlesWidget: (value, meta) {
//               final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
//               return SideTitleWidget(
//                 meta: meta,
//                 space: 8.0,
//                 child: Text(
//                   DateFormat('mm:ss').format(date),
//                   style: TextStyle(color: Colors.grey[700], fontSize: 10),
//                 ),
//               );
//             },
//           ),
//         ),
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 45,
//             getTitlesWidget: (value, meta) {
//               if (value == meta.max || value == meta.min) {
//                 return Container();
//               }
//               return SideTitleWidget(
//                 meta: meta,
//                 child: Text(
//                   value.toInt().toString(),
//                   style: TextStyle(
//                       color: Colors.grey[700],
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//       borderData: FlBorderData(show: false),
//       lineBarsData: [
//         LineChartBarData(
//           spots: spots,
//           isCurved: true,
//           color: MainColors.primaryColor,
//           barWidth: 2,
//           isStrokeCapRound: true,
//           dotData: FlDotData(
//             show: spots.length < 50, // Show dots only when zoomed in
//           ),
//           belowBarData: BarAreaData(
//             show: true,
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 MainColors.primaryColor.withOpacity(0.3),
//                 MainColors.primaryColor.withOpacity(0.0),
//               ],
//             ),
//           ),
//         ),
//       ],
//       lineTouchData: LineTouchData(
//         enabled: true,
//         touchTooltipData: LineTouchTooltipData(
//           getTooltipItems: (touchedSpots) {
//             return touchedSpots.map((spot) {
//               final date =
//                   DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
//               return LineTooltipItem(
//                 '${spot.y.toStringAsFixed(2)}\n${DateFormat('HH:mm:ss').format(date)}',
//                 const TextStyle(
//                     color: Colors.white, fontWeight: FontWeight.bold),
//               );
//             }).toList();
//           },
//         ),
//       ),
//     );
//   }

//   String _formatDuration(Duration duration) {
//     final hours = duration.inHours;
//     final minutes = duration.inMinutes.remainder(60);
//     final seconds = duration.inSeconds.remainder(60);

//     if (hours > 0) {
//       return "${hours}h ${minutes}m ${seconds}s";
//     } else if (minutes > 0) {
//       return "${minutes}m ${seconds}s";
//     } else {
//       return "${seconds}s";
//     }
//   }
// }




 
// --------------------------------------------------------------------------
// RECORDING DETAIL PAGE - VIEW SAVED DATA WITH CSV EXPORT
// --------------------------------------------------------------------------

class RecordingDetailPage extends StatefulWidget {
  final RecordingSession session;

  const RecordingDetailPage({Key? key, required this.session})
      : super(key: key);

  @override
  State<RecordingDetailPage> createState() => _RecordingDetailPageState();
}

class _RecordingDetailPageState extends State<RecordingDetailPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<DataPoint> _dataPoints = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  // Scrolling/zooming control
  double? _visibleMinX;
  double? _visibleMaxX;
  bool _showAllData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dataPoints =
          await _dbHelper.getSessionDataPoints(widget.session.id!);
      final stats = await _dbHelper.getSessionStats(widget.session.id!);

      setState(() {
        _dataPoints = dataPoints;
        _stats = stats;
        _isLoading = false;

        if (_dataPoints.isNotEmpty) {
          _visibleMinX =
              _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
          _visibleMaxX =
              _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading data: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Use the CSVExporter utility
  Future<void> _exportToCSV() async {
    await CSVExporter.exportWithDialog(
      context: context,
      session: widget.session,
      dataPoints: _dataPoints,
      stats: _stats,
    );
  }

  List<FlSpot> _getDisplaySpots() {
    return _dataPoints.map((point) {
      return FlSpot(
        point.timestamp.millisecondsSinceEpoch.toDouble(),
        point.value,
      );
    }).toList();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_dataPoints.isEmpty || _showAllData) return;

    setState(() {
      final chartWidth = MediaQuery.of(context).size.width - 80;
      final visibleDuration = (_visibleMaxX ?? 0) - (_visibleMinX ?? 0);
      final dragRatio = details.delta.dx / chartWidth;
      final shift = -dragRatio * visibleDuration;

      final dataMinX =
          _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
      final dataMaxX =
          _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();

      double newMinX = (_visibleMinX ?? dataMinX) + shift;
      double newMaxX = (_visibleMaxX ?? dataMaxX) + shift;

      if (newMinX < dataMinX) {
        newMinX = dataMinX;
        newMaxX = newMinX + visibleDuration;
      }
      if (newMaxX > dataMaxX) {
        newMaxX = dataMaxX;
        newMinX = newMaxX - visibleDuration;
      }

      _visibleMinX = newMinX;
      _visibleMaxX = newMaxX;
    });
  }

  void _zoomIn() {
    if (_dataPoints.isEmpty) return;

    setState(() {
      _showAllData = false;
      final currentRange = (_visibleMaxX ?? 0) - (_visibleMinX ?? 0);
      final center = ((_visibleMaxX ?? 0) + (_visibleMinX ?? 0)) / 2;
      final newRange = currentRange / 2;

      _visibleMinX = center - newRange / 2;
      _visibleMaxX = center + newRange / 2;
    });
  }

  void _zoomOut() {
    if (_dataPoints.isEmpty) return;

    setState(() {
      final dataMinX =
          _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
      final dataMaxX =
          _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
      final dataRange = dataMaxX - dataMinX;

      final currentRange =
          (_visibleMaxX ?? dataMaxX) - (_visibleMinX ?? dataMinX);
      final center =
          ((_visibleMaxX ?? dataMaxX) + (_visibleMinX ?? dataMinX)) / 2;
      var newRange = currentRange * 2;

      if (newRange >= dataRange) {
        _showAllData = true;
        _visibleMinX = dataMinX;
        _visibleMaxX = dataMaxX;
      } else {
        var newMinX = center - newRange / 2;
        var newMaxX = center + newRange / 2;

        if (newMinX < dataMinX) {
          newMinX = dataMinX;
          newMaxX = newMinX + newRange;
        }
        if (newMaxX > dataMaxX) {
          newMaxX = dataMaxX;
          newMinX = newMaxX - newRange;
        }

        _visibleMinX = newMinX;
        _visibleMaxX = newMaxX;
      }
    });
  }

  void _resetZoom() {
    if (_dataPoints.isEmpty) return;

    setState(() {
      _showAllData = true;
      _visibleMinX =
          _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
      _visibleMaxX =
          _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Scaffold(
      backgroundColor: MainColors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Recording Details", style: AppTextStyles.header),
            Text(
              widget.session.deviceName,
              style: AppTextStyles.regular
                  .copyWith(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        backgroundColor: MainColors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: MainColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Export button in app bar
          IconButton(
            onPressed: _dataPoints.isNotEmpty ? _exportToCSV : null,
            icon: Icon(
              Icons.file_download,
              color: _dataPoints.isNotEmpty ? Colors.green : Colors.grey,
            ),
            tooltip: "Export to CSV",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dataPoints.isEmpty
              ? _buildEmptyState()
              : _buildContent(dateFormat),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.data_array, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No data points found",
            style: AppTextStyles.bold.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(DateFormat dateFormat) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Session info
          _buildSessionInfoCard(dateFormat),

          // Stats card
          _buildStatsCard(),

          // Export button (prominent)
          _buildExportButton(),

          // Chart section
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Signal Data", style: AppTextStyles.bold),
                Row(
                  children: [
                    IconButton(
                      onPressed: _zoomIn,
                      icon: const Icon(Icons.zoom_in),
                      tooltip: "Zoom In",
                    ),
                    IconButton(
                      onPressed: _zoomOut,
                      icon: const Icon(Icons.zoom_out),
                      tooltip: "Zoom Out",
                    ),
                    IconButton(
                      onPressed: _resetZoom,
                      icon: const Icon(Icons.fit_screen),
                      tooltip: "Fit All",
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Chart
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              child: Container(
                height: 300,
                padding: const EdgeInsets.only(
                    top: 24, bottom: 12, right: 20, left: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xfff3f6f9),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: LineChart(
                  _buildChartData(),
                  duration: const Duration(milliseconds: 150),
                ),
              ),
            ),
          ),

          // Scroll hint
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              "← Swipe to scroll • Use zoom buttons to adjust view →",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          // Data table
          _buildDataTable(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _exportToCSV,
          icon: const Icon(Icons.file_download, size: 22),
          label: Text(
            "EXPORT TO CSV",
            style: AppTextStyles.bold.copyWith(fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green[600],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionInfoCard(DateFormat dateFormat) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MainColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 8),
              Text(
                "Recorded: ${dateFormat.format(widget.session.startTime)}",
                style: AppTextStyles.regular,
              ),
            ],
          ),
          if (widget.session.duration != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Duration: ${_formatDuration(widget.session.duration!)}",
                  style: AppTextStyles.regular,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(
            label: "Points",
            value: _stats['count']?.toString() ?? "0",
            color: Colors.blue,
          ),
          _statItem(
            label: "Min",
            value: (_stats['min_value'] as num?)?.toStringAsFixed(1) ?? "0",
            color: Colors.green,
          ),
          _statItem(
            label: "Max",
            value: (_stats['max_value'] as num?)?.toStringAsFixed(1) ?? "0",
            color: Colors.red,
          ),
          _statItem(
            label: "Avg",
            value: (_stats['avg_value'] as num?)?.toStringAsFixed(1) ?? "0",
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDataTable() {
    final displayPoints = _dataPoints.take(100).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Data Points", style: AppTextStyles.bold),
                Text(
                  "Showing ${displayPoints.length} of ${_dataPoints.length}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                Expanded(
                    flex: 1,
                    child: Text("#",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text("Time",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text("Value",
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          ...displayPoints.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;
            final timeFormat = DateFormat('HH:mm:ss.SSS');

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: index % 2 == 0 ? Colors.white : Colors.grey[50],
              ),
              child: Row(
                children: [
                  Expanded(
                      flex: 1,
                      child: Text("${index + 1}",
                          style: TextStyle(color: Colors.grey[600]))),
                  Expanded(
                      flex: 2,
                      child: Text(timeFormat.format(point.timestamp))),
                  Expanded(
                      flex: 2, child: Text(point.value.toStringAsFixed(2))),
                ],
              ),
            );
          }),
          if (_dataPoints.length > 100)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Text(
                "... and ${_dataPoints.length - 100} more data points",
                style: TextStyle(
                    color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    final spots = _getDisplaySpots();

    return LineChartData(
      minX: _visibleMinX,
      maxX: _visibleMaxX,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey[300],
          strokeWidth: 0.8,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey[300],
          strokeWidth: 0.8,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return SideTitleWidget(
                meta: meta,
                space: 8.0,
                child: Text(
                  DateFormat('mm:ss').format(date),
                  style: TextStyle(color: Colors.grey[700], fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              if (value == meta.max || value == meta.min) {
                return Container();
              }
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: MainColors.primaryColor,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: spots.length < 50,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                MainColors.primaryColor.withOpacity(0.3),
                MainColors.primaryColor.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date =
                  DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(2)}\n${DateFormat('HH:mm:ss').format(date)}',
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return "${hours}h ${minutes}m ${seconds}s";
    } else if (minutes > 0) {
      return "${minutes}m ${seconds}s";
    } else {
      return "${seconds}s";
    }
  }
}