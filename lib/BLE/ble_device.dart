// import 'package:exg_visualizer/BLE/csv_exporter.dart';
// import 'dart:async';
// import 'package:exg_visualizer/BLE/db.dart';
// import 'package:exg_visualizer/Libraries/Colors/Colors.dart';
// import 'package:exg_visualizer/Libraries/Fonts/text_styles.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:intl/intl.dart';

// // ✅ Data class to hold 8 values (4 from each characteristic)
// class OctoChannelData {
//   final double value1;
//   final double value2;
//   final double value3;
//   final double value4;
//   final double value5;
//   final double value6;
//   final double value7;
//   final double value8;
//   final DateTime timestamp;

//   OctoChannelData({
//     required this.value1,
//     required this.value2,
//     required this.value3,
//     required this.value4,
//     required this.value5,
//     required this.value6,
//     required this.value7,
//     required this.value8,
//     required this.timestamp,
//   });
// }

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
//   static const String SERVICE_UUID = "12345678-1234-1234-1234-123456789abc";
//   static const String CHARACTERISTIC_UUID_1 =
//       "abcdef01-1234-1234-1234-abcdefabcdef";
//   static const String CHARACTERISTIC_UUID_2 =
//       "abcdef02-1234-1234-1234-abcdefabcdef";

//   BluetoothCharacteristic? _characteristic1;
//   BluetoothCharacteristic? _characteristic2;
//   StreamSubscription<List<int>>? _notificationSubscription1;
//   StreamSubscription<List<int>>? _notificationSubscription2;
//   StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

//   final StreamController<OctoChannelData> _graphDataController =
//       StreamController<OctoChannelData>.broadcast();

//   // Display values for all 8 channels
//   String _displayValue1 = "--";
//   String _displayValue2 = "--";
//   String _displayValue3 = "--";
//   String _displayValue4 = "--";
//   String _displayValue5 = "--";
//   String _displayValue6 = "--";
//   String _displayValue7 = "--";
//   String _displayValue8 = "--";

//   List<int> _rawBytes1 = [];
//   List<int> _rawBytes2 = [];
//   String _rawString1 = "";
//   String _rawString2 = "";
//   bool _isLoading = true;
//   bool _isConnected = true;
//   String _errorMessage = "";

//   // ✅ Latest parsed values from each characteristic
//   double _latestVal1 = 0;
//   double _latestVal2 = 0;
//   double _latestVal3 = 0;
//   double _latestVal4 = 0;
//   double _latestVal5 = 0;
//   double _latestVal6 = 0;
//   double _latestVal7 = 0;
//   double _latestVal8 = 0;

//   bool _char1Found = false;
//   bool _char2Found = false;

//   @override
//   void initState() {
//     super.initState();
//     _listenToConnectionState();
//     _discoverServices();
//   }

//   @override
//   void dispose() {
//     _notificationSubscription1?.cancel();
//     _notificationSubscription2?.cancel();
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
//             _displayValue1 = "--";
//             _displayValue2 = "--";
//             _displayValue3 = "--";
//             _displayValue4 = "--";
//             _displayValue5 = "--";
//             _displayValue6 = "--";
//             _displayValue7 = "--";
//             _displayValue8 = "--";
//             _rawBytes1 = [];
//             _rawBytes2 = [];
//             _rawString1 = "";
//             _rawString2 = "";
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
//       BluetoothCharacteristic? targetChar1;
//       BluetoothCharacteristic? targetChar2;

//       print("📡 Discovered ${services.length} services");

//       for (BluetoothService service in services) {
//         print("  Service: ${service.uuid}");

//         if (service.uuid.toString().toLowerCase() ==
//             SERVICE_UUID.toLowerCase()) {
//           print("  ✅ Found target service!");

//           for (BluetoothCharacteristic characteristic
//               in service.characteristics) {
//             print("    Characteristic: ${characteristic.uuid}");
//             print(
//                 "    Properties: notify=${characteristic.properties.notify}, read=${characteristic.properties.read}");

//             if (characteristic.uuid.toString().toLowerCase() ==
//                 CHARACTERISTIC_UUID_1.toLowerCase()) {
//               targetChar1 = characteristic;
//               print("    ✅ Found target characteristic 1!");
//             }
//             if (characteristic.uuid.toString().toLowerCase() ==
//                 CHARACTERISTIC_UUID_2.toLowerCase()) {
//               targetChar2 = characteristic;
//               print("    ✅ Found target characteristic 2!");
//             }
//           }
//         }
//         if (targetChar1 != null && targetChar2 != null) break;
//       }

//       List<String> notFound = [];

//       if (targetChar1 != null) {
//         _characteristic1 = targetChar1;
//         _char1Found = true;
//         if (_characteristic1!.properties.notify) {
//           await _subscribeToNotifications1();
//         }
//         if (_characteristic1!.properties.read) {
//           await _readValue1();
//         }
//       } else {
//         notFound.add("Char 1: $CHARACTERISTIC_UUID_1");
//         print("❌ Characteristic 1 not found");
//       }

//       if (targetChar2 != null) {
//         _characteristic2 = targetChar2;
//         _char2Found = true;
//         if (_characteristic2!.properties.notify) {
//           await _subscribeToNotifications2();
//         }
//         if (_characteristic2!.properties.read) {
//           await _readValue2();
//         }
//       } else {
//         notFound.add("Char 2: $CHARACTERISTIC_UUID_2");
//         print("❌ Characteristic 2 not found");
//       }

//       if (notFound.isNotEmpty) {
//         setState(() {
//           _errorMessage =
//               "Characteristic(s) not found:\n${notFound.join('\n')}\nService UUID: $SERVICE_UUID";
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = "Error discovering services: $e";
//       });
//       print("❌ Error: $e");
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _readValue1() async {
//     if (_characteristic1 == null) return;
//     try {
//       List<int> value = await _characteristic1!.read();
//       _updateValue1(value);
//     } catch (e) {
//       _showSnackBar("Error reading value 1: $e");
//     }
//   }

//   Future<void> _readValue2() async {
//     if (_characteristic2 == null) return;
//     try {
//       List<int> value = await _characteristic2!.read();
//       _updateValue2(value);
//     } catch (e) {
//       _showSnackBar("Error reading value 2: $e");
//     }
//   }

//   Future<void> _subscribeToNotifications1() async {
//     if (_characteristic1 == null) return;
//     try {
//       await _characteristic1!.setNotifyValue(true);
//       _notificationSubscription1 =
//           _characteristic1!.lastValueStream.listen((value) {
//         _updateValue1(value);
//       });
//       _showSnackBar("✅ Subscribed to characteristic 1 notifications");
//       print("✅ Subscribed to characteristic 1 notifications successfully");
//     } catch (e) {
//       _showSnackBar("Error subscribing to char 1: $e");
//       print("❌ Subscribe char 1 error: $e");
//     }
//   }

//   Future<void> _subscribeToNotifications2() async {
//     if (_characteristic2 == null) return;
//     try {
//       await _characteristic2!.setNotifyValue(true);
//       _notificationSubscription2 =
//           _characteristic2!.lastValueStream.listen((value) {
//         _updateValue2(value);
//       });
//       _showSnackBar("✅ Subscribed to characteristic 2 notifications");
//       print("✅ Subscribed to characteristic 2 notifications successfully");
//     } catch (e) {
//       _showSnackBar("Error subscribing to char 2: $e");
//       print("❌ Subscribe char 2 error: $e");
//     }
//   }

//   /// Parse 4 values from bytes (shared logic)
//   List<double?> _parseValues(List<int> bytes) {
//     if (bytes.isEmpty) return [null, null, null, null];

//     String stringVal = String.fromCharCodes(bytes).trim();
//     double? v1, v2, v3, v4;

//     if (stringVal.contains(',')) {
//       List<String> parts = stringVal.split(',');
//       if (parts.length >= 4) {
//         v1 = double.tryParse(parts[0].trim());
//         v2 = double.tryParse(parts[1].trim());
//         v3 = double.tryParse(parts[2].trim());
//         v4 = double.tryParse(parts[3].trim());
//       } else if (parts.length >= 2) {
//         v1 = double.tryParse(parts[0].trim());
//         v2 = double.tryParse(parts[1].trim());
//         v3 = v1;
//         v4 = v2;
//       }
//     } else {
//       v1 = double.tryParse(stringVal);
//       v2 = v1;
//       v3 = v1;
//       v4 = v1;
//     }

//     return [v1, v2, v3, v4];
//   }

//   void _updateValue1(List<int> bytes) {
//     if (!mounted || bytes.isEmpty) return;

//     String stringVal = String.fromCharCodes(bytes).trim();
//     print("📥 Char1 Received: $stringVal (${bytes.length} bytes)");

//     final parsed = _parseValues(bytes);

//     if (parsed[0] != null &&
//         parsed[1] != null &&
//         parsed[2] != null &&
//         parsed[3] != null) {
//       _latestVal1 = parsed[0]!;
//       _latestVal2 = parsed[1]!;
//       _latestVal3 = parsed[2]!;
//       _latestVal4 = parsed[3]!;

//       _emitCombinedData();
//     }

//     setState(() {
//       _rawBytes1 = bytes;
//       _rawString1 = stringVal;
//       _displayValue1 = parsed[0]?.toStringAsFixed(1) ?? "--";
//       _displayValue2 = parsed[1]?.toStringAsFixed(1) ?? "--";
//       _displayValue3 = parsed[2]?.toStringAsFixed(1) ?? "--";
//       _displayValue4 = parsed[3]?.toStringAsFixed(1) ?? "--";
//     });
//   }

//   void _updateValue2(List<int> bytes) {
//     if (!mounted || bytes.isEmpty) return;

//     String stringVal = String.fromCharCodes(bytes).trim();
//     print("📥 Char2 Received: $stringVal (${bytes.length} bytes)");

//     final parsed = _parseValues(bytes);

//     if (parsed[0] != null &&
//         parsed[1] != null &&
//         parsed[2] != null &&
//         parsed[3] != null) {
//       _latestVal5 = parsed[0]!;
//       _latestVal6 = parsed[1]!;
//       _latestVal7 = parsed[2]!;
//       _latestVal8 = parsed[3]!;

//       _emitCombinedData();
//     }

//     setState(() {
//       _rawBytes2 = bytes;
//       _rawString2 = stringVal;
//       _displayValue5 = parsed[0]?.toStringAsFixed(1) ?? "--";
//       _displayValue6 = parsed[1]?.toStringAsFixed(1) ?? "--";
//       _displayValue7 = parsed[2]?.toStringAsFixed(1) ?? "--";
//       _displayValue8 = parsed[3]?.toStringAsFixed(1) ?? "--";
//     });
//   }

//   /// Emit combined 8-channel data to the stream
//   void _emitCombinedData() {
//     _graphDataController.add(OctoChannelData(
//       value1: _latestVal1,
//       value2: _latestVal2,
//       value3: _latestVal3,
//       value4: _latestVal4,
//       value5: _latestVal5,
//       value6: _latestVal6,
//       value7: _latestVal7,
//       value8: _latestVal8,
//       timestamp: DateTime.now(),
//     ));
//   }

//   Future<void> _disconnect() async {
//     try {
//       await _notificationSubscription1?.cancel();
//       await _notificationSubscription2?.cancel();
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

//   void _openSavedDataPage() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const SavedRecordingsPage(),
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
//           widget.device.platformName.isNotEmpty
//               ? widget.device.platformName
//               : "BLE Device",
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
//             onPressed: null,
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
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(color: MainColors.primaryColor),
//           const SizedBox(height: 16),
//           Text("Discovering services...", style: AppTextStyles.regular),
//         ],
//       ),
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
//             if (_errorMessage.isNotEmpty) ...[
//               _buildErrorCard(),
//               const SizedBox(height: 20),
//             ],
//             _buildCharacteristicStatusCard(),
//             const SizedBox(height: 20),
//             _buildOctoValueDisplayCard(),
//             const SizedBox(height: 20),
//             _buildRawDataCard(),
//             const SizedBox(height: 24),
//             _buildGraphButton(),
//             const SizedBox(height: 12),
//             _buildSavedDataButton(),
//             const SizedBox(height: 12),
//             _buildActionButtons(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCharacteristicStatusCard() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[300]!, width: 1),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text("Characteristics Status",
//               style: AppTextStyles.bold.copyWith(fontSize: 14)),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Icon(
//                 _char1Found ? Icons.check_circle : Icons.cancel,
//                 color: _char1Found ? Colors.green : Colors.red,
//                 size: 18,
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   "Char 1 (CH 1-4): ${_char1Found ? 'Connected' : 'Not Found'}",
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: _char1Found ? Colors.green : Colors.red,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               Icon(
//                 _char2Found ? Icons.check_circle : Icons.cancel,
//                 color: _char2Found ? Colors.green : Colors.red,
//                 size: 18,
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   "Char 2 (CH 5-8): ${_char2Found ? 'Connected' : 'Not Found'}",
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: _char2Found ? Colors.green : Colors.red,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.red.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.red, width: 1),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Icon(Icons.error_outline, color: Colors.red),
//               const SizedBox(width: 8),
//               Text("Error",
//                   style: AppTextStyles.bold.copyWith(color: Colors.red)),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(_errorMessage,
//               style: AppTextStyles.regular.copyWith(fontSize: 12)),
//         ],
//       ),
//     );
//   }

//   Widget _buildGraphButton() {
//     final hasAnyChar = _char1Found || _char2Found;
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton.icon(
//         onPressed: _isConnected && hasAnyChar ? _openGraphPage : null,
//         icon: const Icon(Icons.show_chart, size: 24),
//         label: Text("OPEN REAL-TIME GRAPH (8 CH)",
//             style: AppTextStyles.bold.copyWith(fontSize: 16)),
//         style: ElevatedButton.styleFrom(
//           foregroundColor: Colors.white,
//           backgroundColor: Colors.blueGrey[800],
//           padding: const EdgeInsets.symmetric(vertical: 18),
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       ),
//     );
//   }

//   Widget _buildSavedDataButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: OutlinedButton.icon(
//         onPressed: _openSavedDataPage,
//         icon: const Icon(Icons.folder_open, size: 24),
//         label: Text("VIEW SAVED RECORDINGS",
//             style: AppTextStyles.bold.copyWith(fontSize: 16)),
//         style: OutlinedButton.styleFrom(
//           foregroundColor: Colors.blueGrey[800],
//           side: BorderSide(color: Colors.blueGrey[800]!, width: 2),
//           padding: const EdgeInsets.symmetric(vertical: 18),
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
//         border:
//             Border.all(color: _isConnected ? Colors.green : Colors.red, width: 1),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             _isConnected ? Icons.check_circle : Icons.error,
//             color: _isConnected ? Colors.green : Colors.red,
//             size: 28,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   _isConnected ? "Connected" : "Disconnected",
//                   style: AppTextStyles.bold.copyWith(
//                     color: _isConnected ? Colors.green : Colors.red,
//                     fontSize: 16,
//                   ),
//                 ),
//                 if (_isConnected)
//                   Text(
//                     "Receiving 8-channel data (2 characteristics)",
//                     style: TextStyle(color: Colors.grey[600], fontSize: 12),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOctoValueDisplayCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: MainColors.black,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Text(
//             "LIVE VALUES",
//             style: AppTextStyles.regular
//                 .copyWith(color: Colors.white.withOpacity(0.8)),
//           ),
//           const SizedBox(height: 8),
//           // Characteristic 1 label
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Text("Characteristic 1",
//                 style: TextStyle(
//                     color: Colors.white.withOpacity(0.6), fontSize: 11)),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildChannelDisplay("CH 1", _displayValue1, Colors.blue),
//               Container(
//                   height: 60,
//                   width: 1,
//                   color: Colors.white.withOpacity(0.3)),
//               _buildChannelDisplay("CH 2", _displayValue2, Colors.orange),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildChannelDisplay("CH 3", _displayValue3, Colors.green),
//               Container(
//                   height: 60,
//                   width: 1,
//                   color: Colors.white.withOpacity(0.3)),
//               _buildChannelDisplay("CH 4", _displayValue4, Colors.purple),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Divider(color: Colors.white.withOpacity(0.3)),
//           const SizedBox(height: 8),
//           // Characteristic 2 label
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Text("Characteristic 2",
//                 style: TextStyle(
//                     color: Colors.white.withOpacity(0.6), fontSize: 11)),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildChannelDisplay("CH 5", _displayValue5, Colors.cyan),
//               Container(
//                   height: 60,
//                   width: 1,
//                   color: Colors.white.withOpacity(0.3)),
//               _buildChannelDisplay("CH 6", _displayValue6, Colors.red),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildChannelDisplay("CH 7", _displayValue7, Colors.teal),
//               Container(
//                   height: 60,
//                   width: 1,
//                   color: Colors.white.withOpacity(0.3)),
//               _buildChannelDisplay("CH 8", _displayValue8, Colors.pink),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildChannelDisplay(String label, String value, Color color) {
//     return Expanded(
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.3),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Text(
//               label,
//               style: AppTextStyles.bold
//                   .copyWith(color: color.withOpacity(0.9), fontSize: 12),
//             ),
//           ),
//           const SizedBox(height: 8),
//           FittedBox(
//             fit: BoxFit.scaleDown,
//             child: Text(
//               value,
//               style: AppTextStyles.header
//                   .copyWith(color: color.withOpacity(0.9), fontSize: 28),
//             ),
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
//             const SizedBox(height: 12),
//             Text("Characteristic 1",
//                 style: AppTextStyles.bold
//                     .copyWith(fontSize: 12, color: Colors.grey[500])),
//             const SizedBox(height: 4),
//             _rawDataRow("String",
//                 _rawString1.isEmpty ? "Waiting..." : _rawString1),
//             const SizedBox(height: 4),
//             _rawDataRow(
//                 "Bytes", _rawBytes1.isEmpty ? "[]" : _rawBytes1.toString()),
//             const SizedBox(height: 12),
//             Text("Characteristic 2",
//                 style: AppTextStyles.bold
//                     .copyWith(fontSize: 12, color: Colors.grey[500])),
//             const SizedBox(height: 4),
//             _rawDataRow("String",
//                 _rawString2.isEmpty ? "Waiting..." : _rawString2),
//             const SizedBox(height: 4),
//             _rawDataRow(
//                 "Bytes", _rawBytes2.isEmpty ? "[]" : _rawBytes2.toString()),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _rawDataRow(String label, String value) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         SizedBox(
//           width: 60,
//           child: Text("$label:",
//               style: AppTextStyles.bold
//                   .copyWith(fontSize: 12, color: Colors.grey[600])),
//         ),
//         Expanded(
//           child: Text(value,
//               style: AppTextStyles.regular
//                   .copyWith(fontSize: 12, fontFamily: 'monospace')),
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButtons() {
//     return Row(
//       children: [
//         Expanded(
//           child: ElevatedButton(
//             onPressed: _isConnected && (_characteristic1 != null || _characteristic2 != null)
//                 ? () {
//                     _readValue1();
//                     _readValue2();
//                   }
//                 : null,
//             child: const Text("Read Values"),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: MainColors.primaryColor,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12)),
//             ),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: OutlinedButton(
//             onPressed: _disconnect,
//             child: const Text("Disconnect"),
//             style: OutlinedButton.styleFrom(
//               foregroundColor: Colors.red,
//               side: const BorderSide(color: Colors.red),
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12)),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // =============================================================================
// // LIVE EXG CHART PAGE - 8 CHANNELS
// // =============================================================================

// class LiveExgChartPage extends StatefulWidget {
//   final Stream<OctoChannelData> dataStream;
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
//   late StreamSubscription<OctoChannelData> _subscription;

//   // Display points for all 8 channels
//   final List<FlSpot> _displayPoints1 = [];
//   final List<FlSpot> _displayPoints2 = [];
//   final List<FlSpot> _displayPoints3 = [];
//   final List<FlSpot> _displayPoints4 = [];
//   final List<FlSpot> _displayPoints5 = [];
//   final List<FlSpot> _displayPoints6 = [];
//   final List<FlSpot> _displayPoints7 = [];
//   final List<FlSpot> _displayPoints8 = [];

//   // ALL data points stored for saving
//   final List<DataPoint> _allDataPoints = [];

//   // Channel visibility toggles
//   bool _showChannel1 = true;
//   bool _showChannel2 = true;
//   bool _showChannel3 = true;
//   bool _showChannel4 = true;
//   bool _showChannel5 = true;
//   bool _showChannel6 = true;
//   bool _showChannel7 = true;
//   bool _showChannel8 = true;

//   // Scrolling control
//   bool _isLiveMode = true;
//   double? _viewMinX;
//   double? _viewMaxX;
//   static const double _visibleDuration = 10000;

//   DateTime? _recordingStartTime;

//   // Latest values for legend
//   double _latestValue1 = 0;
//   double _latestValue2 = 0;
//   double _latestValue3 = 0;
//   double _latestValue4 = 0;
//   double _latestValue5 = 0;
//   double _latestValue6 = 0;
//   double _latestValue7 = 0;
//   double _latestValue8 = 0;

//   static const int _maxDisplayPoints = 5000;

//   final DatabaseHelper _dbHelper = DatabaseHelper.instance;
//   Timer? _durationTimer;

//   // Channel colors
//   static const Color _channel1Color = Colors.blue;
//   static const Color _channel2Color = Colors.orange;
//   static const Color _channel3Color = Colors.green;
//   static const Color _channel4Color = Colors.purple;
//   static const Color _channel5Color = Colors.cyan;
//   static const Color _channel6Color = Colors.red;
//   static const Color _channel7Color = Colors.teal;
//   static const Color _channel8Color = Colors.pink;

//   @override
//   void initState() {
//     super.initState();
//     _recordingStartTime = DateTime.now();
//     _startListening();
//     _startDurationTimer();
//   }

//   void _startDurationTimer() {
//     _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (mounted) setState(() {});
//     });
//   }

//   void _startListening() {
//     _subscription = widget.dataStream.listen((data) {
//       final now = data.timestamp;

//       _allDataPoints.add(DataPoint(
//         value1: data.value1,
//         value2: data.value2,
//         value3: data.value3,
//         value4: data.value4,
//         value5: data.value5,
//         value6: data.value6,
//         value7: data.value7,
//         value8: data.value8,
//         timestamp: now,
//         processedValue1: data.value1,
//         processedValue2: data.value2,
//         processedValue3: data.value3,
//         processedValue4: data.value4,
//         processedValue5: data.value5,
//         processedValue6: data.value6,
//         processedValue7: data.value7,
//         processedValue8: data.value8,
//       ));

//       setState(() {
//         final timestamp = now.millisecondsSinceEpoch.toDouble();

//         _displayPoints1.add(FlSpot(timestamp, data.value1));
//         _displayPoints2.add(FlSpot(timestamp, data.value2));
//         _displayPoints3.add(FlSpot(timestamp, data.value3));
//         _displayPoints4.add(FlSpot(timestamp, data.value4));
//         _displayPoints5.add(FlSpot(timestamp, data.value5));
//         _displayPoints6.add(FlSpot(timestamp, data.value6));
//         _displayPoints7.add(FlSpot(timestamp, data.value7));
//         _displayPoints8.add(FlSpot(timestamp, data.value8));

//         _latestValue1 = data.value1;
//         _latestValue2 = data.value2;
//         _latestValue3 = data.value3;
//         _latestValue4 = data.value4;
//         _latestValue5 = data.value5;
//         _latestValue6 = data.value6;
//         _latestValue7 = data.value7;
//         _latestValue8 = data.value8;

//         while (_displayPoints1.length > _maxDisplayPoints) {
//           _displayPoints1.removeAt(0);
//           _displayPoints2.removeAt(0);
//           _displayPoints3.removeAt(0);
//           _displayPoints4.removeAt(0);
//           _displayPoints5.removeAt(0);
//           _displayPoints6.removeAt(0);
//           _displayPoints7.removeAt(0);
//           _displayPoints8.removeAt(0);
//         }
//       });
//     });
//   }

//   void _onHorizontalDragUpdate(DragUpdateDetails details) {
//     if (_displayPoints1.isEmpty) return;

//     final chartWidth = MediaQuery.of(context).size.width - 80;
//     final dragRatio = details.delta.dx / chartWidth;
//     final shift = -dragRatio * _visibleDuration;

//     final dataMinX = _displayPoints1.first.x;
//     final dataMaxX = _displayPoints1.last.x;

//     setState(() {
//       if (_isLiveMode) {
//         _viewMaxX = dataMaxX;
//         _viewMinX = dataMaxX - _visibleDuration;
//         _isLiveMode = false;
//       }

//       double newMinX = (_viewMinX ?? dataMinX) + shift;
//       double newMaxX = (_viewMaxX ?? dataMaxX) + shift;

//       if (newMinX < dataMinX) {
//         newMinX = dataMinX;
//         newMaxX = newMinX + _visibleDuration;
//       }
//       if (newMaxX > dataMaxX) {
//         newMaxX = dataMaxX;
//         newMinX = newMaxX - _visibleDuration;
//         _isLiveMode = true;
//       } else {
//         _isLiveMode = false;
//       }

//       _viewMinX = newMinX;
//       _viewMaxX = newMaxX;
//     });
//   }

//   void _onHorizontalDragEnd(DragEndDetails details) {}

//   void _onDoubleTap() {
//     _resetToLive();
//   }

//   void _resetToLive() {
//     setState(() {
//       _isLiveMode = true;
//       _viewMinX = null;
//       _viewMaxX = null;
//     });
//   }

//   void _clearChart() {
//     setState(() {
//       _displayPoints1.clear();
//       _displayPoints2.clear();
//       _displayPoints3.clear();
//       _displayPoints4.clear();
//       _displayPoints5.clear();
//       _displayPoints6.clear();
//       _displayPoints7.clear();
//       _displayPoints8.clear();
//       _allDataPoints.clear();
//       _recordingStartTime = DateTime.now();
//       _isLiveMode = true;
//       _viewMinX = null;
//       _viewMaxX = null;
//       _latestValue1 = 0;
//       _latestValue2 = 0;
//       _latestValue3 = 0;
//       _latestValue4 = 0;
//       _latestValue5 = 0;
//       _latestValue6 = 0;
//       _latestValue7 = 0;
//       _latestValue8 = 0;
//     });
//   }

//   Future<void> _saveChartData() async {
//     if (_allDataPoints.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content: Text("No data to save!"),
//             backgroundColor: Colors.orange),
//       );
//       return;
//     }

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
//       final sessionId = await _dbHelper.createSession(widget.deviceName);
//       await _dbHelper.saveDataPoints(sessionId, _allDataPoints);

//       if (mounted) {
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Saved ${_allDataPoints.length} data points!"),
//             backgroundColor: Colors.green,
//             action: SnackBarAction(
//               label: "VIEW",
//               textColor: Colors.white,
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                       builder: (context) => const SavedRecordingsPage()),
//                 );
//               },
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content: Text("Error saving: $e"),
//               backgroundColor: Colors.red),
//         );
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _subscription.cancel();
//     _durationTimer?.cancel();
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
//           PopupMenuButton<String>(
//             onSelected: (value) {
//               if (value == 'restart') _showRestartConfirmation();
//               else if (value == 'save') _saveChartData();
//               else if (value == 'view_saved') {
//                 Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => const SavedRecordingsPage()));
//               }
//             },
//             itemBuilder: (context) => [
//               const PopupMenuItem(
//                   value: 'restart',
//                   child: Row(children: [
//                     Icon(Icons.refresh, color: Colors.blue),
//                     SizedBox(width: 8),
//                     Text('Restart')
//                   ])),
//               const PopupMenuItem(
//                   value: 'save',
//                   child: Row(children: [
//                     Icon(Icons.save_alt, color: Colors.green),
//                     SizedBox(width: 8),
//                     Text('Save Data')
//                   ])),
//               const PopupMenuDivider(),
//               const PopupMenuItem(
//                   value: 'view_saved',
//                   child: Row(children: [
//                     Icon(Icons.folder_open, color: Colors.orange),
//                     SizedBox(width: 8),
//                     Text('View Saved')
//                   ])),
//             ],
//             icon: const Icon(Icons.more_vert, color: MainColors.black),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           _buildStatsBar(),
//           const SizedBox(height: 8),
//           _buildChannelToggles(),
//           const SizedBox(height: 8),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: GestureDetector(
//                 onHorizontalDragUpdate: _onHorizontalDragUpdate,
//                 onHorizontalDragEnd: _onHorizontalDragEnd,
//                 onDoubleTap: _onDoubleTap,
//                 child: Container(
//                   padding: const EdgeInsets.only(
//                       top: 24, bottom: 12, right: 20, left: 8),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(16),
//                     color: const Color(0xfff3f6f9),
//                     border: Border.all(color: Colors.grey[300]!, width: 1),
//                   ),
//                   child: _hasNoData()
//                       ? _buildEmptyChart()
//                       : Stack(
//                           children: [
//                             LineChart(_buildChartData(),
//                                 duration: Duration.zero),
//                             Positioned(
//                               top: 8,
//                               right: 8,
//                               child: _isLiveMode
//                                   ? Container(
//                                       padding: const EdgeInsets.symmetric(
//                                           horizontal: 12, vertical: 6),
//                                       decoration: BoxDecoration(
//                                         color: Colors.green.withOpacity(0.1),
//                                         borderRadius:
//                                             BorderRadius.circular(20),
//                                         border: Border.all(
//                                             color: Colors.green, width: 1),
//                                       ),
//                                       child: const Row(
//                                         mainAxisSize: MainAxisSize.min,
//                                         children: [
//                                           Icon(Icons.circle,
//                                               color: Colors.green, size: 8),
//                                           SizedBox(width: 6),
//                                           Text(
//                                             "LIVE",
//                                             style: TextStyle(
//                                               color: Colors.green,
//                                               fontWeight: FontWeight.bold,
//                                               fontSize: 12,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     )
//                                   : ElevatedButton.icon(
//                                       onPressed: _resetToLive,
//                                       icon: const Icon(Icons.skip_next,
//                                           size: 16),
//                                       label: const Text("GO LIVE"),
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: Colors.red,
//                                         foregroundColor: Colors.white,
//                                         padding: const EdgeInsets.symmetric(
//                                             horizontal: 12, vertical: 6),
//                                         textStyle: const TextStyle(
//                                             fontSize: 11,
//                                             fontWeight: FontWeight.bold),
//                                       ),
//                                     ),
//                             ),
//                           ],
//                         ),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           _buildLegend(),
//           const SizedBox(height: 8),
//           _buildScrollInstruction(),
//           const SizedBox(height: 16),
//         ],
//       ),
//     );
//   }

//   Widget _buildScrollInstruction() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         color: Colors.grey.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.swipe, size: 16, color: Colors.grey[600]),
//           const SizedBox(width: 8),
//           Text(
//             "Swipe left/right on graph to scroll • Double-tap for live",
//             style: TextStyle(fontSize: 11, color: Colors.grey[600]),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyChart() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
//           const SizedBox(height: 12),
//           Text("Waiting for data...", style: AppTextStyles.regular),
//           const SizedBox(height: 8),
//           Text("Make sure BLE device is sending data",
//               style: TextStyle(fontSize: 12, color: Colors.grey[500])),
//         ],
//       ),
//     );
//   }

//   bool _hasNoData() {
//     return _displayPoints1.isEmpty &&
//         _displayPoints2.isEmpty &&
//         _displayPoints3.isEmpty &&
//         _displayPoints4.isEmpty &&
//         _displayPoints5.isEmpty &&
//         _displayPoints6.isEmpty &&
//         _displayPoints7.isEmpty &&
//         _displayPoints8.isEmpty;
//   }

//   Widget _buildChannelToggles() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Wrap(
//         spacing: 6,
//         runSpacing: 6,
//         alignment: WrapAlignment.center,
//         children: [
//           _buildChannelChip("CH 1", _showChannel1, _channel1Color,
//               (v) => setState(() => _showChannel1 = v)),
//           _buildChannelChip("CH 2", _showChannel2, _channel2Color,
//               (v) => setState(() => _showChannel2 = v)),
//           _buildChannelChip("CH 3", _showChannel3, _channel3Color,
//               (v) => setState(() => _showChannel3 = v)),
//           _buildChannelChip("CH 4", _showChannel4, _channel4Color,
//               (v) => setState(() => _showChannel4 = v)),
//           _buildChannelChip("CH 5", _showChannel5, _channel5Color,
//               (v) => setState(() => _showChannel5 = v)),
//           _buildChannelChip("CH 6", _showChannel6, _channel6Color,
//               (v) => setState(() => _showChannel6 = v)),
//           _buildChannelChip("CH 7", _showChannel7, _channel7Color,
//               (v) => setState(() => _showChannel7 = v)),
//           _buildChannelChip("CH 8", _showChannel8, _channel8Color,
//               (v) => setState(() => _showChannel8 = v)),
//         ],
//       ),
//     );
//   }

//   Widget _buildChannelChip(
//       String label, bool selected, Color color, Function(bool) onSelected) {
//     return FilterChip(
//       label: Text(label),
//       selected: selected,
//       onSelected: onSelected,
//       selectedColor: color.withOpacity(0.3),
//       checkmarkColor: color,
//       labelStyle: TextStyle(
//           color: selected ? color : Colors.grey,
//           fontWeight: FontWeight.bold,
//           fontSize: 11),
//       visualDensity: VisualDensity.compact,
//     );
//   }

//   Widget _buildLegend() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Wrap(
//         spacing: 12,
//         runSpacing: 6,
//         alignment: WrapAlignment.center,
//         children: [
//           if (_showChannel1)
//             _buildLegendItem("CH1", _latestValue1, _channel1Color),
//           if (_showChannel2)
//             _buildLegendItem("CH2", _latestValue2, _channel2Color),
//           if (_showChannel3)
//             _buildLegendItem("CH3", _latestValue3, _channel3Color),
//           if (_showChannel4)
//             _buildLegendItem("CH4", _latestValue4, _channel4Color),
//           if (_showChannel5)
//             _buildLegendItem("CH5", _latestValue5, _channel5Color),
//           if (_showChannel6)
//             _buildLegendItem("CH6", _latestValue6, _channel6Color),
//           if (_showChannel7)
//             _buildLegendItem("CH7", _latestValue7, _channel7Color),
//           if (_showChannel8)
//             _buildLegendItem("CH8", _latestValue8, _channel8Color),
//         ],
//       ),
//     );
//   }

//   Widget _buildLegendItem(String label, double value, Color color) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(width: 14, height: 3, color: color),
//         const SizedBox(width: 4),
//         Text("$label: ${value.toStringAsFixed(1)}",
//             style: TextStyle(
//                 color: color, fontWeight: FontWeight.bold, fontSize: 11)),
//       ],
//     );
//   }

//   Widget _buildStatsBar() {
//     final duration = _recordingStartTime != null
//         ? DateTime.now().difference(_recordingStartTime!)
//         : Duration.zero;

//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           _statItem(
//               icon: Icons.timer_outlined,
//               label: "Duration",
//               value: _formatDuration(duration)),
//           Container(height: 30, width: 1, color: Colors.grey[300]),
//           _statItem(
//               icon: Icons.data_array,
//               label: "Points",
//               value: _allDataPoints.length.toString()),
//           Container(height: 30, width: 1, color: Colors.grey[300]),
//           _statItem(
//             icon: _isLiveMode ? Icons.circle : Icons.history,
//             label: _isLiveMode ? "Mode" : "Viewing",
//             value: _isLiveMode ? "LIVE" : "HISTORY",
//             valueColor: _isLiveMode ? Colors.green : Colors.orange,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _statItem(
//       {required IconData icon,
//       required String label,
//       required String value,
//       Color? valueColor}) {
//     return Row(
//       children: [
//         Icon(icon, size: 18, color: valueColor ?? MainColors.primaryColor),
//         const SizedBox(width: 6),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(value,
//                 style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                     color: valueColor ?? MainColors.black)),
//             Text(label,
//                 style: TextStyle(fontSize: 9, color: Colors.grey[600])),
//           ],
//         ),
//       ],
//     );
//   }

//   String _formatDuration(Duration duration) {
//     final hours = duration.inHours;
//     final minutes =
//         duration.inMinutes.remainder(60).toString().padLeft(2, '0');
//     final seconds =
//         duration.inSeconds.remainder(60).toString().padLeft(2, '0');
//     if (hours > 0) return "$hours:$minutes:$seconds";
//     return "$minutes:$seconds";
//   }

//   void _showRestartConfirmation() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Restart Recording?"),
//         content: Text(
//             "This will clear ${_allDataPoints.length} recorded data points."),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Cancel")),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _clearChart();
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child:
//                 const Text("Restart", style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   LineChartData _buildChartData() {
//     List<FlSpot> referencePoints = _displayPoints1.isNotEmpty
//         ? _displayPoints1
//         : _displayPoints2.isNotEmpty
//             ? _displayPoints2
//             : _displayPoints3.isNotEmpty
//                 ? _displayPoints3
//                 : _displayPoints4.isNotEmpty
//                     ? _displayPoints4
//                     : _displayPoints5.isNotEmpty
//                         ? _displayPoints5
//                         : _displayPoints6.isNotEmpty
//                             ? _displayPoints6
//                             : _displayPoints7.isNotEmpty
//                                 ? _displayPoints7
//                                 : _displayPoints8;

//     double minX, maxX;

//     if (referencePoints.isEmpty) {
//       final now = DateTime.now().millisecondsSinceEpoch.toDouble();
//       minX = now - 1000;
//       maxX = now;
//     } else {
//       final dataMinX = referencePoints.first.x;
//       final dataMaxX = referencePoints.last.x;
//       final dataRange = dataMaxX - dataMinX;

//       if (_isLiveMode) {
//         if (dataRange < _visibleDuration) {
//           final padding = dataRange * 0.05;
//           minX = dataMinX - padding;
//           maxX = dataMaxX + padding;
//         } else {
//           maxX = dataMaxX;
//           minX = maxX - _visibleDuration;
//         }
//       } else {
//         minX = _viewMinX ?? dataMinX;
//         maxX = _viewMaxX ?? dataMaxX;
//       }
//     }

//     // Dynamic symmetric Y-axis
//     double maxAbsValue = 1;
//     List<List<FlSpot>> allChannelPoints = [];
//     if (_showChannel1) allChannelPoints.add(_displayPoints1);
//     if (_showChannel2) allChannelPoints.add(_displayPoints2);
//     if (_showChannel3) allChannelPoints.add(_displayPoints3);
//     if (_showChannel4) allChannelPoints.add(_displayPoints4);
//     if (_showChannel5) allChannelPoints.add(_displayPoints5);
//     if (_showChannel6) allChannelPoints.add(_displayPoints6);
//     if (_showChannel7) allChannelPoints.add(_displayPoints7);
//     if (_showChannel8) allChannelPoints.add(_displayPoints8);

//     for (var channelPoints in allChannelPoints) {
//       for (var point in channelPoints) {
//         if (point.x >= minX && point.x <= maxX) {
//           if (point.y.abs() > maxAbsValue) {
//             maxAbsValue = point.y.abs();
//           }
//         }
//       }
//     }

//     maxAbsValue = maxAbsValue * 1.1;

//     final double minY = -maxAbsValue;
//     final double maxY = maxAbsValue;
//     final double xAxisInterval = 2000;

//     List<LineChartBarData> lineBars = [];

//     if (_showChannel1 && _displayPoints1.isNotEmpty)
//       lineBars.add(_createLineBar(
//           _getVisiblePoints(_displayPoints1, minX, maxX), _channel1Color));
//     if (_showChannel2 && _displayPoints2.isNotEmpty)
//       lineBars.add(_createLineBar(
//           _getVisiblePoints(_displayPoints2, minX, maxX), _channel2Color));
//     if (_showChannel3 && _displayPoints3.isNotEmpty)
//       lineBars.add(_createLineBar(
//           _getVisiblePoints(_displayPoints3, minX, maxX), _channel3Color));
//     if (_showChannel4 && _displayPoints4.isNotEmpty)
//       lineBars.add(_createLineBar(
//           _getVisiblePoints(_displayPoints4, minX, maxX), _channel4Color));
//     if (_showChannel5 && _displayPoints5.isNotEmpty)
//       lineBars.add(_createLineBar(
//           _getVisiblePoints(_displayPoints5, minX, maxX), _channel5Color));
//     if (_showChannel6 && _displayPoints6.isNotEmpty)
//       lineBars.add(_createLineBar(
//           _getVisiblePoints(_displayPoints6, minX, maxX), _channel6Color));
//     if (_showChannel7 && _displayPoints7.isNotEmpty)
//       lineBars.add(_createLineBar(
//           _getVisiblePoints(_displayPoints7, minX, maxX), _channel7Color));
//     if (_showChannel8 && _displayPoints8.isNotEmpty)
//       lineBars.add(_createLineBar(
//           _getVisiblePoints(_displayPoints8, minX, maxX), _channel8Color));

//     return LineChartData(
//       minX: minX,
//       maxX: maxX,
//       minY: minY,
//       maxY: maxY,
//       clipData: const FlClipData.all(),
//       gridData: FlGridData(
//         show: true,
//         drawVerticalLine: true,
//         horizontalInterval: maxAbsValue / 4,
//         verticalInterval: xAxisInterval,
//         getDrawingHorizontalLine: (value) {
//           if (value.abs() < 0.001) {
//             return FlLine(color: Colors.grey[600]!, strokeWidth: 1.5);
//           }
//           return FlLine(color: Colors.grey[300]!, strokeWidth: 0.8);
//         },
//         getDrawingVerticalLine: (value) =>
//             FlLine(color: Colors.grey[300]!, strokeWidth: 0.8),
//       ),
//       titlesData: FlTitlesData(
//         show: true,
//         rightTitles:
//             const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         topTitles:
//             const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 30,
//             interval: xAxisInterval,
//             getTitlesWidget: (value, meta) {
//               final remainder = value % xAxisInterval;
//               if (remainder.abs() > 100 &&
//                   (xAxisInterval - remainder.abs()) > 100) {
//                 return const SizedBox.shrink();
//               }
//               final date =
//                   DateTime.fromMillisecondsSinceEpoch(value.toInt());
//               return SideTitleWidget(
//                 meta: meta,
//                 space: 8.0,
//                 child: Text(DateFormat('HH:mm:ss').format(date),
//                     style: TextStyle(
//                         color: Colors.grey[700], fontSize: 10)),
//               );
//             },
//           ),
//         ),
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 50,
//             getTitlesWidget: (value, meta) {
//               if (value == meta.max || value == meta.min)
//                 return const SizedBox.shrink();
//               return SideTitleWidget(
//                 meta: meta,
//                 child: Text(
//                   value.toStringAsFixed(1),
//                   style: TextStyle(
//                     color: value.abs() < 0.001
//                         ? Colors.grey[800]
//                         : Colors.grey[600],
//                     fontSize: 10,
//                     fontWeight: value.abs() < 0.001
//                         ? FontWeight.bold
//                         : FontWeight.normal,
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//       borderData: FlBorderData(show: false),
//       lineBarsData: lineBars,
//       lineTouchData: LineTouchData(
//         enabled: true,
//         touchTooltipData: LineTouchTooltipData(
//           getTooltipItems: (touchedSpots) {
//             return touchedSpots.map((spot) {
//               final date =
//                   DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
//               final channelInfo = _getChannelInfo(spot.barIndex);
//               return LineTooltipItem(
//                 '${channelInfo.label}: ${spot.y.toStringAsFixed(1)}\n${DateFormat('HH:mm:ss').format(date)}',
//                 TextStyle(
//                     color: channelInfo.color.withOpacity(0.9),
//                     fontWeight: FontWeight.bold),
//               );
//             }).toList();
//           },
//         ),
//       ),
//     );
//   }

//   List<FlSpot> _getVisiblePoints(
//       List<FlSpot> allPoints, double minX, double maxX) {
//     final buffer = (maxX - minX) * 0.1;
//     return allPoints
//         .where((p) => p.x >= (minX - buffer) && p.x <= (maxX + buffer))
//         .toList();
//   }

//   LineChartBarData _createLineBar(List<FlSpot> spots, Color color) {
//     return LineChartBarData(
//       spots: spots,
//       isCurved: true,
//       color: color,
//       barWidth: 2,
//       isStrokeCapRound: true,
//       dotData: const FlDotData(show: false),
//       belowBarData: BarAreaData(show: false),
//     );
//   }

//   ({String label, Color color}) _getChannelInfo(int barIndex) {
//     List<({String label, Color color})> visibleChannels = [];
//     if (_showChannel1)
//       visibleChannels.add((label: "CH1", color: _channel1Color));
//     if (_showChannel2)
//       visibleChannels.add((label: "CH2", color: _channel2Color));
//     if (_showChannel3)
//       visibleChannels.add((label: "CH3", color: _channel3Color));
//     if (_showChannel4)
//       visibleChannels.add((label: "CH4", color: _channel4Color));
//     if (_showChannel5)
//       visibleChannels.add((label: "CH5", color: _channel5Color));
//     if (_showChannel6)
//       visibleChannels.add((label: "CH6", color: _channel6Color));
//     if (_showChannel7)
//       visibleChannels.add((label: "CH7", color: _channel7Color));
//     if (_showChannel8)
//       visibleChannels.add((label: "CH8", color: _channel8Color));
//     if (barIndex < visibleChannels.length) return visibleChannels[barIndex];
//     return (label: "CH?", color: Colors.grey);
//   }
// }

// // =============================================================================
// // SAVED RECORDINGS PAGE
// // =============================================================================

// class SavedRecordingsPage extends StatefulWidget {
//   const SavedRecordingsPage({Key? key}) : super(key: key);

//   @override
//   State<SavedRecordingsPage> createState() => _SavedRecordingsPageState();
// }

// class _SavedRecordingsPageState extends State<SavedRecordingsPage> {
//   final DatabaseHelper _dbHelper = DatabaseHelper.instance;
//   List<RecordingSession> _sessions = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadSessions();
//   }

//   Future<void> _loadSessions() async {
//     setState(() => _isLoading = true);
//     try {
//       final sessions = await _dbHelper.getAllSessions();
//       setState(() {
//         _sessions = sessions;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content: Text("Error loading sessions: $e"),
//               backgroundColor: Colors.red),
//         );
//       }
//     }
//   }

//   Future<void> _deleteSession(RecordingSession session) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Delete Recording?"),
//         content:
//             Text("Delete recording with ${session.dataCount} data points?"),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text("Cancel")),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child:
//                 const Text("Delete", style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );

//     if (confirm == true && session.id != null) {
//       await _dbHelper.deleteSession(session.id!);
//       _loadSessions();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: MainColors.white,
//       appBar: AppBar(
//         title: Text("Saved Recordings", style: AppTextStyles.header),
//         backgroundColor: MainColors.white,
//         elevation: 1,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: MainColors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           IconButton(
//               icon: const Icon(Icons.refresh, color: MainColors.black),
//               onPressed: _loadSessions),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _sessions.isEmpty
//               ? _buildEmptyState()
//               : _buildSessionsList(),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.folder_off, size: 80, color: Colors.grey[400]),
//           const SizedBox(height: 16),
//           Text("No saved recordings",
//               style: AppTextStyles.bold.copyWith(fontSize: 18)),
//           const SizedBox(height: 8),
//           Text("Start recording from the graph page",
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey[600])),
//         ],
//       ),
//     );
//   }

//   Widget _buildSessionsList() {
//     return RefreshIndicator(
//       onRefresh: _loadSessions,
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: _sessions.length,
//         itemBuilder: (context, index) =>
//             _buildSessionCard(_sessions[index]),
//       ),
//     );
//   }

//   Widget _buildSessionCard(RecordingSession session) {
//     final dateFormat = DateFormat('MMM dd, yyyy');
//     final timeFormat = DateFormat('HH:mm:ss');

//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: InkWell(
//         onTap: () {
//           Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                       builder: (context) =>
//                           RecordingDetailPage(session: session)))
//               .then((_) => _loadSessions());
//         },
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: MainColors.primaryColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Icon(Icons.bluetooth,
//                         color: MainColors.primaryColor, size: 24),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(session.deviceName,
//                             style:
//                                 AppTextStyles.bold.copyWith(fontSize: 16)),
//                         const SizedBox(height: 4),
//                         Text(dateFormat.format(session.startTime),
//                             style: TextStyle(
//                                 color: Colors.grey[600], fontSize: 12)),
//                       ],
//                     ),
//                   ),
//                   IconButton(
//                     icon:
//                         const Icon(Icons.delete_outline, color: Colors.red),
//                     onPressed: () => _deleteSession(session),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               const Divider(height: 1),
//               const SizedBox(height: 12),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   _infoItem(Icons.access_time, "Start",
//                       timeFormat.format(session.startTime)),
//                   _infoItem(
//                       Icons.timer,
//                       "Duration",
//                       session.duration != null
//                           ? _formatDuration(session.duration!)
//                           : "--"),
//                   _infoItem(Icons.data_array, "Points",
//                       session.dataCount.toString()),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _infoItem(IconData icon, String label, String value) {
//     return Column(
//       children: [
//         Icon(icon, size: 18, color: Colors.grey[600]),
//         const SizedBox(height: 4),
//         Text(value,
//             style:
//                 const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
//         Text(label,
//             style: TextStyle(fontSize: 10, color: Colors.grey[600])),
//       ],
//     );
//   }

//   String _formatDuration(Duration d) {
//     if (d.inHours > 0)
//       return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
//     if (d.inMinutes > 0)
//       return "${d.inMinutes}m ${d.inSeconds.remainder(60)}s";
//     return "${d.inSeconds}s";
//   }
// }

// // =============================================================================
// // RECORDING DETAIL PAGE - 8 CHANNELS
// // =============================================================================

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

//   bool _showChannel1 = true;
//   bool _showChannel2 = true;
//   bool _showChannel3 = true;
//   bool _showChannel4 = true;
//   bool _showChannel5 = true;
//   bool _showChannel6 = true;
//   bool _showChannel7 = true;
//   bool _showChannel8 = true;

//   double? _viewMinX;
//   double? _viewMaxX;
//   double _visibleDuration = 10000;
//   double _lastScale = 1.0;
//   bool _isFullView = true;

//   static const double _minVisibleDuration = 2000;
//   static const double _maxVisibleDuration = 60000;

//   static const Color _channel1Color = Colors.blue;
//   static const Color _channel2Color = Colors.orange;
//   static const Color _channel3Color = Colors.green;
//   static const Color _channel4Color = Colors.purple;
//   static const Color _channel5Color = Colors.cyan;
//   static const Color _channel6Color = Colors.red;
//   static const Color _channel7Color = Colors.teal;
//   static const Color _channel8Color = Colors.pink;

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

//         if (_dataPoints.isNotEmpty) {
//           _viewMinX = _dataPoints.first.timestamp.millisecondsSinceEpoch
//               .toDouble();
//           _viewMaxX = _dataPoints.last.timestamp.millisecondsSinceEpoch
//               .toDouble();
//           _visibleDuration = _viewMaxX! - _viewMinX!;
//           _isFullView = true;
//         }
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content: Text("Error: $e"), backgroundColor: Colors.red),
//         );
//       }
//     }
//   }

//   Future<void> _exportToCSV() async {
//     await CSVExporter.exportWithDialog(
//       context: context,
//       session: widget.session,
//       dataPoints: _dataPoints,
//       stats: _stats,
//     );
//   }

//   void _onHorizontalDragUpdate(DragUpdateDetails details) {
//     if (_dataPoints.isEmpty) return;

//     final chartWidth = MediaQuery.of(context).size.width - 80;
//     final dragRatio = details.delta.dx / chartWidth;
//     final currentRange = (_viewMaxX ?? 0) - (_viewMinX ?? 0);
//     final shift = -dragRatio * currentRange;

//     final dataMinX =
//         _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
//     final dataMaxX =
//         _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();

//     setState(() {
//       _isFullView = false;

//       double newMinX = (_viewMinX ?? dataMinX) + shift;
//       double newMaxX = (_viewMaxX ?? dataMaxX) + shift;

//       if (newMinX < dataMinX) {
//         newMinX = dataMinX;
//         newMaxX = newMinX + currentRange;
//       }
//       if (newMaxX > dataMaxX) {
//         newMaxX = dataMaxX;
//         newMinX = newMaxX - currentRange;
//       }

//       _viewMinX = newMinX;
//       _viewMaxX = newMaxX;
//     });
//   }

//   void _onScaleStart(ScaleStartDetails details) {
//     _lastScale = 1.0;
//   }

//   void _onScaleUpdate(ScaleUpdateDetails details) {
//     if (_dataPoints.isEmpty) return;

//     if (details.scale != 1.0) {
//       final scaleDiff = details.scale / _lastScale;
//       _lastScale = details.scale;

//       setState(() {
//         _isFullView = false;

//         final currentRange = (_viewMaxX ?? 0) - (_viewMinX ?? 0);
//         double newRange = currentRange / scaleDiff;
//         newRange =
//             newRange.clamp(_minVisibleDuration, _maxVisibleDuration);

//         if (_viewMinX != null && _viewMaxX != null) {
//           final center = (_viewMinX! + _viewMaxX!) / 2;
//           _viewMinX = center - newRange / 2;
//           _viewMaxX = center + newRange / 2;

//           final dataMinX = _dataPoints.first.timestamp
//               .millisecondsSinceEpoch
//               .toDouble();
//           final dataMaxX = _dataPoints.last.timestamp
//               .millisecondsSinceEpoch
//               .toDouble();

//           if (_viewMinX! < dataMinX) {
//             _viewMinX = dataMinX;
//             _viewMaxX = dataMinX + newRange;
//           }
//           if (_viewMaxX! > dataMaxX) {
//             _viewMaxX = dataMaxX;
//             _viewMinX = dataMaxX - newRange;
//           }
//         }

//         _visibleDuration = newRange;
//       });
//     }

//     if (details.scale == 1.0 && details.focalPointDelta.dx != 0) {
//       _onHorizontalDragUpdate(
//         DragUpdateDetails(
//           globalPosition: details.focalPoint,
//           delta: details.focalPointDelta,
//         ),
//       );
//     }
//   }

//   void _zoomIn() {
//     if (_dataPoints.isEmpty) return;

//     setState(() {
//       _isFullView = false;

//       final currentRange = (_viewMaxX ?? 0) - (_viewMinX ?? 0);
//       double newRange = (currentRange / 1.5)
//           .clamp(_minVisibleDuration, _maxVisibleDuration);

//       final center = ((_viewMinX ?? 0) + (_viewMaxX ?? 0)) / 2;
//       _viewMinX = center - newRange / 2;
//       _viewMaxX = center + newRange / 2;

//       _clampToDataBounds();
//       _visibleDuration = newRange;
//     });
//   }

//   void _zoomOut() {
//     if (_dataPoints.isEmpty) return;

//     setState(() {
//       final currentRange = (_viewMaxX ?? 0) - (_viewMinX ?? 0);
//       final dataMinX =
//           _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
//       final dataMaxX =
//           _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
//       final totalRange = dataMaxX - dataMinX;

//       double newRange = (currentRange * 1.5)
//           .clamp(_minVisibleDuration, totalRange);

//       final center = ((_viewMinX ?? 0) + (_viewMaxX ?? 0)) / 2;
//       _viewMinX = center - newRange / 2;
//       _viewMaxX = center + newRange / 2;

//       _clampToDataBounds();
//       _visibleDuration = newRange;

//       if ((_viewMaxX! - _viewMinX!) >= totalRange * 0.99) {
//         _isFullView = true;
//         _viewMinX = dataMinX;
//         _viewMaxX = dataMaxX;
//       } else {
//         _isFullView = false;
//       }
//     });
//   }

//   void _clampToDataBounds() {
//     if (_dataPoints.isEmpty) return;

//     final dataMinX =
//         _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
//     final dataMaxX =
//         _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
//     final currentRange =
//         (_viewMaxX ?? dataMaxX) - (_viewMinX ?? dataMinX);

//     if (_viewMinX! < dataMinX) {
//       _viewMinX = dataMinX;
//       _viewMaxX = dataMinX + currentRange;
//     }
//     if (_viewMaxX! > dataMaxX) {
//       _viewMaxX = dataMaxX;
//       _viewMinX = dataMaxX - currentRange;
//     }
//   }

//   void _resetToFullView() {
//     if (_dataPoints.isEmpty) return;

//     setState(() {
//       _viewMinX =
//           _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
//       _viewMaxX =
//           _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
//       _visibleDuration = _viewMaxX! - _viewMinX!;
//       _isFullView = true;
//     });
//   }

//   String _getViewTimeRange() {
//     if (_viewMinX == null || _viewMaxX == null) return "";
//     final startTime =
//         DateTime.fromMillisecondsSinceEpoch(_viewMinX!.toInt());
//     final endTime =
//         DateTime.fromMillisecondsSinceEpoch(_viewMaxX!.toInt());
//     final format = DateFormat('HH:mm:ss');
//     return "${format.format(startTime)} - ${format.format(endTime)}";
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: MainColors.white,
//       appBar: AppBar(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Recording Details", style: AppTextStyles.header),
//             Text(widget.session.deviceName,
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
//           IconButton(
//             onPressed: _dataPoints.isNotEmpty ? _exportToCSV : null,
//             icon: Icon(Icons.file_download,
//                 color:
//                     _dataPoints.isNotEmpty ? Colors.green : Colors.grey),
//             tooltip: "Export CSV",
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _dataPoints.isEmpty
//               ? Center(
//                   child: Text("No data", style: AppTextStyles.bold))
//               : SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       _buildSessionInfo(),
//                       _buildStatsCard(),
//                       _buildExportButton(),
//                       const SizedBox(height: 16),
//                       _buildChannelToggles(),
//                       const SizedBox(height: 8),
//                       _buildZoomControls(),
//                       const SizedBox(height: 8),
//                       _buildChartSection(),
//                       _buildDataTable(),
//                       const SizedBox(height: 24),
//                     ],
//                   ),
//                 ),
//     );
//   }

//   Widget _buildZoomControls() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           IconButton(
//             onPressed: _zoomOut,
//             icon: const Icon(Icons.zoom_out),
//             tooltip: "Zoom Out (show more time)",
//             style: IconButton.styleFrom(
//               backgroundColor: Colors.grey[200],
//             ),
//           ),
//           const SizedBox(width: 8),
//           Container(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Text(
//               _isFullView
//                   ? "Full View"
//                   : "${(_visibleDuration / 1000).toStringAsFixed(0)}s window",
//               style: const TextStyle(
//                   fontWeight: FontWeight.bold, fontSize: 12),
//             ),
//           ),
//           const SizedBox(width: 8),
//           IconButton(
//             onPressed: _zoomIn,
//             icon: const Icon(Icons.zoom_in),
//             tooltip: "Zoom In (show less time)",
//             style: IconButton.styleFrom(
//               backgroundColor: Colors.grey[200],
//             ),
//           ),
//           const SizedBox(width: 16),
//           if (!_isFullView)
//             TextButton.icon(
//               onPressed: _resetToFullView,
//               icon: const Icon(Icons.fullscreen, size: 18),
//               label: const Text("Full"),
//               style: TextButton.styleFrom(
//                 foregroundColor: MainColors.primaryColor,
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSessionInfo() {
//     final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: MainColors.primaryColor.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         children: [
//           Row(children: [
//             const Icon(Icons.calendar_today, size: 18),
//             const SizedBox(width: 8),
//             Text(
//                 "Recorded: ${dateFormat.format(widget.session.startTime)}",
//                 style: AppTextStyles.regular),
//           ]),
//           if (widget.session.duration != null) ...[
//             const SizedBox(height: 8),
//             Row(children: [
//               const Icon(Icons.timer, size: 18),
//               const SizedBox(width: 8),
//               Text(
//                   "Duration: ${_formatDuration(widget.session.duration!)}",
//                   style: AppTextStyles.regular),
//             ]),
//           ],
//           const SizedBox(height: 8),
//           Row(children: [
//             const Icon(Icons.layers, size: 18),
//             const SizedBox(width: 8),
//             Text("Channels: 8 (2 characteristics × 4 channels)",
//                 style: AppTextStyles.regular),
//           ]),
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
//               color: Colors.grey.withOpacity(0.1),
//               spreadRadius: 1,
//               blurRadius: 4)
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text("Statistics", style: AppTextStyles.bold),
//           const SizedBox(height: 12),
//           _buildChannelStats("Channel 1", _channel1Color, 'min_value1',
//               'max_value1', 'avg_value1'),
//           const SizedBox(height: 6),
//           _buildChannelStats("Channel 2", _channel2Color, 'min_value2',
//               'max_value2', 'avg_value2'),
//           const SizedBox(height: 6),
//           _buildChannelStats("Channel 3", _channel3Color, 'min_value3',
//               'max_value3', 'avg_value3'),
//           const SizedBox(height: 6),
//           _buildChannelStats("Channel 4", _channel4Color, 'min_value4',
//               'max_value4', 'avg_value4'),
//           const SizedBox(height: 6),
//           _buildChannelStats("Channel 5", _channel5Color, 'min_value5',
//               'max_value5', 'avg_value5'),
//           const SizedBox(height: 6),
//           _buildChannelStats("Channel 6", _channel6Color, 'min_value6',
//               'max_value6', 'avg_value6'),
//           const SizedBox(height: 6),
//           _buildChannelStats("Channel 7", _channel7Color, 'min_value7',
//               'max_value7', 'avg_value7'),
//           const SizedBox(height: 6),
//           _buildChannelStats("Channel 8", _channel8Color, 'min_value8',
//               'max_value8', 'avg_value8'),
//         ],
//       ),
//     );
//   }

//   Widget _buildChannelStats(
//       String name, Color color, String minKey, String maxKey, String avgKey) {
//     return Row(
//       children: [
//         Container(
//             width: 12,
//             height: 12,
//             decoration: BoxDecoration(
//                 color: color, borderRadius: BorderRadius.circular(2))),
//         const SizedBox(width: 8),
//         Expanded(
//           child: Text(
//             "$name: Min ${_formatStat(_stats[minKey])} | Max ${_formatStat(_stats[maxKey])} | Avg ${_formatStat(_stats[avgKey])}",
//             style: const TextStyle(fontSize: 11),
//           ),
//         ),
//       ],
//     );
//   }

//   String _formatStat(dynamic v) =>
//       v != null ? (v as num).toStringAsFixed(1) : "N/A";

//   Widget _buildExportButton() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: SizedBox(
//         width: double.infinity,
//         child: ElevatedButton.icon(
//           onPressed: _exportToCSV,
//           icon: const Icon(Icons.file_download),
//           label: const Text("EXPORT TO CSV (8 CHANNELS)"),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.green[600],
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12)),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildChannelToggles() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Wrap(
//         spacing: 6,
//         runSpacing: 6,
//         alignment: WrapAlignment.center,
//         children: [
//           _buildChip("CH 1", _showChannel1, _channel1Color,
//               (v) => setState(() => _showChannel1 = v)),
//           _buildChip("CH 2", _showChannel2, _channel2Color,
//               (v) => setState(() => _showChannel2 = v)),
//           _buildChip("CH 3", _showChannel3, _channel3Color,
//               (v) => setState(() => _showChannel3 = v)),
//           _buildChip("CH 4", _showChannel4, _channel4Color,
//               (v) => setState(() => _showChannel4 = v)),
//           _buildChip("CH 5", _showChannel5, _channel5Color,
//               (v) => setState(() => _showChannel5 = v)),
//           _buildChip("CH 6", _showChannel6, _channel6Color,
//               (v) => setState(() => _showChannel6 = v)),
//           _buildChip("CH 7", _showChannel7, _channel7Color,
//               (v) => setState(() => _showChannel7 = v)),
//           _buildChip("CH 8", _showChannel8, _channel8Color,
//               (v) => setState(() => _showChannel8 = v)),
//         ],
//       ),
//     );
//   }

//   Widget _buildChip(
//       String label, bool selected, Color color, Function(bool) onSelected) {
//     return FilterChip(
//       label: Text(label),
//       selected: selected,
//       onSelected: onSelected,
//       selectedColor: color.withOpacity(0.3),
//       checkmarkColor: color,
//       labelStyle: TextStyle(
//           color: selected ? color : Colors.grey,
//           fontWeight: FontWeight.bold,
//           fontSize: 11),
//       visualDensity: VisualDensity.compact,
//     );
//   }

//   Widget _buildChartSection() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: GestureDetector(
//         onScaleStart: _onScaleStart,
//         onScaleUpdate: _onScaleUpdate,
//         onDoubleTap: _resetToFullView,
//         child: Container(
//           height: 300,
//           padding: const EdgeInsets.only(
//               top: 24, bottom: 12, right: 20, left: 8),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             color: const Color(0xfff3f6f9),
//             border: Border.all(color: Colors.grey[300]!),
//           ),
//           child: Stack(
//             children: [
//               LineChart(_buildChartData()),
//               Positioned(
//                 top: 8,
//                 right: 8,
//                 child: _isFullView
//                     ? Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 10, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.green.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                           border:
//                               Border.all(color: Colors.green, width: 1),
//                         ),
//                         child: const Text(
//                           "FULL VIEW",
//                           style: TextStyle(
//                             color: Colors.green,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 10,
//                           ),
//                         ),
//                       )
//                     : Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 10, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.orange.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                           border:
//                               Border.all(color: Colors.orange, width: 1),
//                         ),
//                         child: Text(
//                           _getViewTimeRange(),
//                           style: const TextStyle(
//                             color: Colors.orange,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 10,
//                           ),
//                         ),
//                       ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   LineChartData _buildChartData() {
//     List<LineChartBarData> lineBars = [];

//     List<FlSpot> spots1 = [];
//     List<FlSpot> spots2 = [];
//     List<FlSpot> spots3 = [];
//     List<FlSpot> spots4 = [];
//     List<FlSpot> spots5 = [];
//     List<FlSpot> spots6 = [];
//     List<FlSpot> spots7 = [];
//     List<FlSpot> spots8 = [];

//     final minX = _viewMinX ??
//         (_dataPoints.isNotEmpty
//             ? _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble()
//             : 0);
//     final maxX = _viewMaxX ??
//         (_dataPoints.isNotEmpty
//             ? _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble()
//             : 1);
//     final buffer = (maxX - minX) * 0.1;

//     for (var p in _dataPoints) {
//       final x = p.timestamp.millisecondsSinceEpoch.toDouble();
//       if (x >= (minX - buffer) && x <= (maxX + buffer)) {
//         spots1.add(FlSpot(x, p.value1));
//         spots2.add(FlSpot(x, p.value2));
//         spots3.add(FlSpot(x, p.value3));
//         spots4.add(FlSpot(x, p.value4));
//         spots5.add(FlSpot(x, p.value5));
//         spots6.add(FlSpot(x, p.value6));
//         spots7.add(FlSpot(x, p.value7));
//         spots8.add(FlSpot(x, p.value8));
//       }
//     }

//     // Dynamic symmetric Y-axis
//     double maxAbsValue = 1;
//     void _checkSpots(List<FlSpot> spots) {
//       for (var spot in spots) {
//         if (spot.y.abs() > maxAbsValue) maxAbsValue = spot.y.abs();
//       }
//     }

//     if (_showChannel1) _checkSpots(spots1);
//     if (_showChannel2) _checkSpots(spots2);
//     if (_showChannel3) _checkSpots(spots3);
//     if (_showChannel4) _checkSpots(spots4);
//     if (_showChannel5) _checkSpots(spots5);
//     if (_showChannel6) _checkSpots(spots6);
//     if (_showChannel7) _checkSpots(spots7);
//     if (_showChannel8) _checkSpots(spots8);
//     maxAbsValue = maxAbsValue * 1.1;

//     LineChartBarData _makeLine(List<FlSpot> spots, Color color) {
//       return LineChartBarData(
//         spots: spots,
//         isCurved: true,
//         color: color,
//         barWidth: 2,
//         dotData: const FlDotData(show: false),
//         belowBarData: BarAreaData(
//           show: true,
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               color.withOpacity(0.15),
//               color.withOpacity(0.0)
//             ],
//           ),
//         ),
//       );
//     }

//     if (_showChannel1 && spots1.isNotEmpty)
//       lineBars.add(_makeLine(spots1, _channel1Color));
//     if (_showChannel2 && spots2.isNotEmpty)
//       lineBars.add(_makeLine(spots2, _channel2Color));
//     if (_showChannel3 && spots3.isNotEmpty)
//       lineBars.add(_makeLine(spots3, _channel3Color));
//     if (_showChannel4 && spots4.isNotEmpty)
//       lineBars.add(_makeLine(spots4, _channel4Color));
//     if (_showChannel5 && spots5.isNotEmpty)
//       lineBars.add(_makeLine(spots5, _channel5Color));
//     if (_showChannel6 && spots6.isNotEmpty)
//       lineBars.add(_makeLine(spots6, _channel6Color));
//     if (_showChannel7 && spots7.isNotEmpty)
//       lineBars.add(_makeLine(spots7, _channel7Color));
//     if (_showChannel8 && spots8.isNotEmpty)
//       lineBars.add(_makeLine(spots8, _channel8Color));

//     return LineChartData(
//       minX: minX,
//       maxX: maxX,
//       minY: -maxAbsValue,
//       maxY: maxAbsValue,
//       clipData: const FlClipData.all(),
//       lineBarsData: lineBars,
//       gridData: FlGridData(
//         show: true,
//         drawVerticalLine: true,
//         horizontalInterval: maxAbsValue / 4,
//         getDrawingHorizontalLine: (value) {
//           if (value.abs() < 0.001) {
//             return FlLine(
//                 color: Colors.grey[600]!, strokeWidth: 1.5);
//           }
//           return FlLine(
//               color: Colors.grey[300]!, strokeWidth: 0.8);
//         },
//         getDrawingVerticalLine: (value) =>
//             FlLine(color: Colors.grey[300]!, strokeWidth: 0.8),
//       ),
//       titlesData: FlTitlesData(
//         rightTitles: const AxisTitles(
//             sideTitles: SideTitles(showTitles: false)),
//         topTitles: const AxisTitles(
//             sideTitles: SideTitles(showTitles: false)),
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 30,
//             getTitlesWidget: (value, meta) {
//               if (value == meta.min || value == meta.max)
//                 return const SizedBox.shrink();
//               final date = DateTime.fromMillisecondsSinceEpoch(
//                   value.toInt());
//               return SideTitleWidget(
//                 meta: meta,
//                 child: Text(
//                   DateFormat('mm:ss').format(date),
//                   style: TextStyle(
//                       fontSize: 10, color: Colors.grey[700]),
//                 ),
//               );
//             },
//           ),
//         ),
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 50,
//             getTitlesWidget: (value, meta) {
//               if (value == meta.max || value == meta.min)
//                 return const SizedBox.shrink();
//               return SideTitleWidget(
//                 meta: meta,
//                 child: Text(
//                   value.toStringAsFixed(1),
//                   style: TextStyle(
//                     fontSize: 10,
//                     color: value.abs() < 0.001
//                         ? Colors.grey[800]
//                         : Colors.grey[600],
//                     fontWeight: value.abs() < 0.001
//                         ? FontWeight.bold
//                         : FontWeight.normal,
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//       borderData: FlBorderData(show: false),
//       lineTouchData: LineTouchData(
//         enabled: true,
//         touchTooltipData: LineTouchTooltipData(
//           getTooltipItems: (touchedSpots) {
//             return touchedSpots.map((spot) {
//               final date = DateTime.fromMillisecondsSinceEpoch(
//                   spot.x.toInt());
//               final channelInfo =
//                   _getChannelInfo(spot.barIndex);
//               return LineTooltipItem(
//                 '${channelInfo.label}: ${spot.y.toStringAsFixed(1)}\n${DateFormat('HH:mm:ss').format(date)}',
//                 TextStyle(
//                     color:
//                         channelInfo.color.withOpacity(0.9),
//                     fontWeight: FontWeight.bold),
//               );
//             }).toList();
//           },
//         ),
//       ),
//     );
//   }

//   ({String label, Color color}) _getChannelInfo(int barIndex) {
//     List<({String label, Color color})> visibleChannels = [];
//     if (_showChannel1) {
//       visibleChannels.add((label: "CH1", color: _channel1Color));
//     }
//     if (_showChannel2) {
//       visibleChannels.add((label: "CH2", color: _channel2Color));
//     }
//     if (_showChannel3) {
//       visibleChannels.add((label: "CH3", color: _channel3Color));
//     }
//     if (_showChannel4) {
//       visibleChannels.add((label: "CH4", color: _channel4Color));
//     }
//     if (_showChannel5) {
//       visibleChannels.add((label: "CH5", color: _channel5Color));
//     }
//     if (_showChannel6) {
//       visibleChannels.add((label: "CH6", color: _channel6Color));
//     }
//     if (_showChannel7) {
//       visibleChannels.add((label: "CH7", color: _channel7Color));
//     }
//     if (_showChannel8) {
//       visibleChannels.add((label: "CH8", color: _channel8Color));
//     }
//     if (barIndex < visibleChannels.length) {
//       return visibleChannels[barIndex];
//     }
//     return (label: "CH?", color: Colors.grey);
//   }

//   Widget _buildDataTable() {
//     final displayPoints = _dataPoints.take(50).toList();
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[300]!),
//       ),
//       child: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                     "Data Points (${displayPoints.length}/${_dataPoints.length})",
//                     style: AppTextStyles.bold),
//                 Text("Showing first 50",
//                     style: TextStyle(
//                         fontSize: 11, color: Colors.grey[600])),
//               ],
//             ),
//           ),
//           const Divider(height: 1),
//           // Header row
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Column(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 12, vertical: 8),
//                   color: Colors.grey[100],
//                   child: Row(
//                     children: [
//                       SizedBox(
//                           width: 40,
//                           child: Text("#",
//                               style: TextStyle(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.grey[700]))),
//                       SizedBox(
//                           width: 80,
//                           child: Text("Time",
//                               style: TextStyle(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.grey[700]))),
//                       SizedBox(
//                           width: 55,
//                           child: Text("CH1",
//                               style: TextStyle(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                   color: _channel1Color))),
//                       SizedBox(
//                           width: 55,
//                           child: Text("CH2",
//                               style: TextStyle(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                   color: _channel2Color))),
//                       SizedBox(
//                           width: 55,
//                           child: Text("CH3",
//                               style: TextStyle(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                   color: _channel3Color))),
//                       SizedBox(
//                           width: 55,
//                           child: Text("CH4",
//                               style: TextStyle(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                   color: _channel4Color))),
//                       SizedBox(
//                           width: 55,
//                           child: Text("CH5",
//                               style: TextStyle(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                   color: _channel5Color))),
//                       SizedBox(
//                           width: 55,
//                           child: Text("CH6",
//                               style: TextStyle(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                   color: _channel6Color))),
//                       SizedBox(
//                           width: 55,
//                           child: Text("CH7",
//                               style: TextStyle(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                   color: _channel7Color))),
//                       SizedBox(
//                           width: 55,
//                           child: Text("CH8",
//                               style: TextStyle(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                   color: _channel8Color))),
//                     ],
//                   ),
//                 ),
//                 ...displayPoints.asMap().entries.map((e) {
//                   final p = e.value;
//                   return Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 12, vertical: 8),
//                     color: e.key % 2 == 0
//                         ? Colors.white
//                         : Colors.grey[50],
//                     child: Row(
//                       children: [
//                         SizedBox(
//                             width: 40,
//                             child: Text("${e.key + 1}",
//                                 style:
//                                     const TextStyle(fontSize: 11))),
//                         SizedBox(
//                             width: 80,
//                             child: Text(
//                                 DateFormat('HH:mm:ss')
//                                     .format(p.timestamp),
//                                 style:
//                                     const TextStyle(fontSize: 11))),
//                         SizedBox(
//                             width: 55,
//                             child: Text(
//                                 p.value1.toStringAsFixed(1),
//                                 style:
//                                     const TextStyle(fontSize: 11))),
//                         SizedBox(
//                             width: 55,
//                             child: Text(
//                                 p.value2.toStringAsFixed(1),
//                                 style:
//                                     const TextStyle(fontSize: 11))),
//                         SizedBox(
//                             width: 55,
//                             child: Text(
//                                 p.value3.toStringAsFixed(1),
//                                 style:
//                                     const TextStyle(fontSize: 11))),
//                         SizedBox(
//                             width: 55,
//                             child: Text(
//                                 p.value4.toStringAsFixed(1),
//                                 style:
//                                     const TextStyle(fontSize: 11))),
//                         SizedBox(
//                             width: 55,
//                             child: Text(
//                                 p.value5.toStringAsFixed(1),
//                                 style:
//                                     const TextStyle(fontSize: 11))),
//                         SizedBox(
//                             width: 55,
//                             child: Text(
//                                 p.value6.toStringAsFixed(1),
//                                 style:
//                                     const TextStyle(fontSize: 11))),
//                         SizedBox(
//                             width: 55,
//                             child: Text(
//                                 p.value7.toStringAsFixed(1),
//                                 style:
//                                     const TextStyle(fontSize: 11))),
//                         SizedBox(
//                             width: 55,
//                             child: Text(
//                                 p.value8.toStringAsFixed(1),
//                                 style:
//                                     const TextStyle(fontSize: 11))),
//                       ],
//                     ),
//                   );
//                 }),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatDuration(Duration d) {
//     if (d.inHours > 0) {
//       return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
//     }
//     if (d.inMinutes > 0)
//     {
//       return "${d.inMinutes}m ${d.inSeconds.remainder(60)}s";
//     }
//     return "${d.inSeconds}s";
//   }
// }



import 'package:exg_visualizer/BLE/csv_exporter.dart';
import 'dart:async';
import 'package:exg_visualizer/BLE/db.dart';
import 'package:exg_visualizer/Libraries/Colors/Colors.dart';
import 'package:exg_visualizer/Libraries/Fonts/text_styles.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';

// ✅ Channel label constants
class ChannelLabels {
  static const String ch1 = "EEG(Left)";
  static const String ch2 = "EEG(Right)";
  static const String ch3 = "PAL1.5";
  static const String ch4 = "PAR1.5";
  static const String ch5 = "PAR3";
  static const String ch6 = "PBL1.5";
  static const String ch7 = "PBR1.5";
  static const String ch8 = "NoN";

  // Short labels for compact UI elements
  static const String ch1Short = "EEG(L)";
  static const String ch2Short = "EEG(R)";
  static const String ch3Short = "PAL1.5";
  static const String ch4Short = "PAR1.5";
  static const String ch5Short = "PAR3";
  static const String ch6Short = "PBL1.5";
  static const String ch7Short = "PBR1.5";
  static const String ch8Short = "NoN";
}

// ✅ Data class to hold 8 values (4 from each characteristic)
class OctoChannelData {
  final double value1;
  final double value2;
  final double value3;
  final double value4;
  final double value5;
  final double value6;
  final double value7;
  final double value8;
  final DateTime timestamp;

  OctoChannelData({
    required this.value1,
    required this.value2,
    required this.value3,
    required this.value4,
    required this.value5,
    required this.value6,
    required this.value7,
    required this.value8,
    required this.timestamp,
  });
}

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
  static const String SERVICE_UUID = "12345678-1234-1234-1234-123456789abc";
  static const String CHARACTERISTIC_UUID_1 =
      "abcdef01-1234-1234-1234-abcdefabcdef";
  static const String CHARACTERISTIC_UUID_2 =
      "abcdef02-1234-1234-1234-abcdefabcdef";

  BluetoothCharacteristic? _characteristic1;
  BluetoothCharacteristic? _characteristic2;
  StreamSubscription<List<int>>? _notificationSubscription1;
  StreamSubscription<List<int>>? _notificationSubscription2;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  final StreamController<OctoChannelData> _graphDataController =
      StreamController<OctoChannelData>.broadcast();

  // Display values for all 8 channels
  String _displayValue1 = "--";
  String _displayValue2 = "--";
  String _displayValue3 = "--";
  String _displayValue4 = "--";
  String _displayValue5 = "--";
  String _displayValue6 = "--";
  String _displayValue7 = "--";
  String _displayValue8 = "--";

  List<int> _rawBytes1 = [];
  List<int> _rawBytes2 = [];
  String _rawString1 = "";
  String _rawString2 = "";
  bool _isLoading = true;
  bool _isConnected = true;
  String _errorMessage = "";

  // Latest parsed values from each characteristic
  double _latestVal1 = 0;
  double _latestVal2 = 0;
  double _latestVal3 = 0;
  double _latestVal4 = 0;
  double _latestVal5 = 0;
  double _latestVal6 = 0;
  double _latestVal7 = 0;
  double _latestVal8 = 0;

  bool _char1Found = false;
  bool _char2Found = false;

  @override
  void initState() {
    super.initState();
    _listenToConnectionState();
    _discoverServices();
  }

  @override
  void dispose() {
    _notificationSubscription1?.cancel();
    _notificationSubscription2?.cancel();
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
            _displayValue1 = "--";
            _displayValue2 = "--";
            _displayValue3 = "--";
            _displayValue4 = "--";
            _displayValue5 = "--";
            _displayValue6 = "--";
            _displayValue7 = "--";
            _displayValue8 = "--";
            _rawBytes1 = [];
            _rawBytes2 = [];
            _rawString1 = "";
            _rawString2 = "";
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
      BluetoothCharacteristic? targetChar1;
      BluetoothCharacteristic? targetChar2;

      print("📡 Discovered ${services.length} services");

      for (BluetoothService service in services) {
        print("  Service: ${service.uuid}");

        if (service.uuid.toString().toLowerCase() ==
            SERVICE_UUID.toLowerCase()) {
          print("  ✅ Found target service!");

          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            print("    Characteristic: ${characteristic.uuid}");
            print(
                "    Properties: notify=${characteristic.properties.notify}, read=${characteristic.properties.read}");

            if (characteristic.uuid.toString().toLowerCase() ==
                CHARACTERISTIC_UUID_1.toLowerCase()) {
              targetChar1 = characteristic;
              print(
                  "    ✅ Found Char 1 (${ChannelLabels.ch1}, ${ChannelLabels.ch2}, ${ChannelLabels.ch3}, ${ChannelLabels.ch4})!");
            }
            if (characteristic.uuid.toString().toLowerCase() ==
                CHARACTERISTIC_UUID_2.toLowerCase()) {
              targetChar2 = characteristic;
              print(
                  "    ✅ Found Char 2 (${ChannelLabels.ch5}, ${ChannelLabels.ch6}, ${ChannelLabels.ch7}, ${ChannelLabels.ch8})!");
            }
          }
        }
        if (targetChar1 != null && targetChar2 != null) break;
      }

      List<String> notFound = [];

      if (targetChar1 != null) {
        _characteristic1 = targetChar1;
        _char1Found = true;
        if (_characteristic1!.properties.notify) {
          await _subscribeToNotifications1();
        }
        if (_characteristic1!.properties.read) {
          await _readValue1();
        }
      } else {
        notFound.add("Char 1: $CHARACTERISTIC_UUID_1");
        print("❌ Characteristic 1 not found");
      }

      if (targetChar2 != null) {
        _characteristic2 = targetChar2;
        _char2Found = true;
        if (_characteristic2!.properties.notify) {
          await _subscribeToNotifications2();
        }
        if (_characteristic2!.properties.read) {
          await _readValue2();
        }
      } else {
        notFound.add("Char 2: $CHARACTERISTIC_UUID_2");
        print("❌ Characteristic 2 not found");
      }

      if (notFound.isNotEmpty) {
        setState(() {
          _errorMessage =
              "Characteristic(s) not found:\n${notFound.join('\n')}\nService UUID: $SERVICE_UUID";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error discovering services: $e";
      });
      print("❌ Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _readValue1() async {
    if (_characteristic1 == null) return;
    try {
      List<int> value = await _characteristic1!.read();
      _updateValue1(value);
    } catch (e) {
      _showSnackBar("Error reading value 1: $e");
    }
  }

  Future<void> _readValue2() async {
    if (_characteristic2 == null) return;
    try {
      List<int> value = await _characteristic2!.read();
      _updateValue2(value);
    } catch (e) {
      _showSnackBar("Error reading value 2: $e");
    }
  }

  Future<void> _subscribeToNotifications1() async {
    if (_characteristic1 == null) return;
    try {
      await _characteristic1!.setNotifyValue(true);
      _notificationSubscription1 =
          _characteristic1!.lastValueStream.listen((value) {
        _updateValue1(value);
      });
      _showSnackBar(
          "✅ Subscribed to Char 1 (${ChannelLabels.ch1Short}-${ChannelLabels.ch4Short})");
      print("✅ Subscribed to characteristic 1 notifications successfully");
    } catch (e) {
      _showSnackBar("Error subscribing to char 1: $e");
      print("❌ Subscribe char 1 error: $e");
    }
  }

  Future<void> _subscribeToNotifications2() async {
    if (_characteristic2 == null) return;
    try {
      await _characteristic2!.setNotifyValue(true);
      _notificationSubscription2 =
          _characteristic2!.lastValueStream.listen((value) {
        _updateValue2(value);
      });
      _showSnackBar(
          "✅ Subscribed to Char 2 (${ChannelLabels.ch5Short}-${ChannelLabels.ch8Short})");
      print("✅ Subscribed to characteristic 2 notifications successfully");
    } catch (e) {
      _showSnackBar("Error subscribing to char 2: $e");
      print("❌ Subscribe char 2 error: $e");
    }
  }

  /// Parse 4 values from bytes (shared logic)
  List<double?> _parseValues(List<int> bytes) {
    if (bytes.isEmpty) return [null, null, null, null];

    String stringVal = String.fromCharCodes(bytes).trim();
    double? v1, v2, v3, v4;

    if (stringVal.contains(',')) {
      List<String> parts = stringVal.split(',');
      if (parts.length >= 4) {
        v1 = double.tryParse(parts[0].trim());
        v2 = double.tryParse(parts[1].trim());
        v3 = double.tryParse(parts[2].trim());
        v4 = double.tryParse(parts[3].trim());
      } else if (parts.length >= 2) {
        v1 = double.tryParse(parts[0].trim());
        v2 = double.tryParse(parts[1].trim());
        v3 = v1;
        v4 = v2;
      }
    } else {
      v1 = double.tryParse(stringVal);
      v2 = v1;
      v3 = v1;
      v4 = v1;
    }

    return [v1, v2, v3, v4];
  }

  void _updateValue1(List<int> bytes) {
    if (!mounted || bytes.isEmpty) return;

    String stringVal = String.fromCharCodes(bytes).trim();
    print("📥 Char1 Received: $stringVal (${bytes.length} bytes)");

    final parsed = _parseValues(bytes);

    if (parsed[0] != null &&
        parsed[1] != null &&
        parsed[2] != null &&
        parsed[3] != null) {
      _latestVal1 = parsed[0]!;
      _latestVal2 = parsed[1]!;
      _latestVal3 = parsed[2]!;
      _latestVal4 = parsed[3]!;

      _emitCombinedData();
    }

    setState(() {
      _rawBytes1 = bytes;
      _rawString1 = stringVal;
      _displayValue1 = parsed[0]?.toStringAsFixed(1) ?? "--";
      _displayValue2 = parsed[1]?.toStringAsFixed(1) ?? "--";
      _displayValue3 = parsed[2]?.toStringAsFixed(1) ?? "--";
      _displayValue4 = parsed[3]?.toStringAsFixed(1) ?? "--";
    });
  }

  void _updateValue2(List<int> bytes) {
    if (!mounted || bytes.isEmpty) return;

    String stringVal = String.fromCharCodes(bytes).trim();
    print("📥 Char2 Received: $stringVal (${bytes.length} bytes)");

    final parsed = _parseValues(bytes);

    if (parsed[0] != null &&
        parsed[1] != null &&
        parsed[2] != null &&
        parsed[3] != null) {
      _latestVal5 = parsed[0]!;
      _latestVal6 = parsed[1]!;
      _latestVal7 = parsed[2]!;
      _latestVal8 = parsed[3]!;

      _emitCombinedData();
    }

    setState(() {
      _rawBytes2 = bytes;
      _rawString2 = stringVal;
      _displayValue5 = parsed[0]?.toStringAsFixed(1) ?? "--";
      _displayValue6 = parsed[1]?.toStringAsFixed(1) ?? "--";
      _displayValue7 = parsed[2]?.toStringAsFixed(1) ?? "--";
      _displayValue8 = parsed[3]?.toStringAsFixed(1) ?? "--";
    });
  }

  /// Emit combined 8-channel data to the stream
  void _emitCombinedData() {
    _graphDataController.add(OctoChannelData(
      value1: _latestVal1,
      value2: _latestVal2,
      value3: _latestVal3,
      value4: _latestVal4,
      value5: _latestVal5,
      value6: _latestVal6,
      value7: _latestVal7,
      value8: _latestVal8,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _disconnect() async {
    try {
      await _notificationSubscription1?.cancel();
      await _notificationSubscription2?.cancel();
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
          widget.device.platformName.isNotEmpty
              ? widget.device.platformName
              : "BLE Device",
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: MainColors.primaryColor),
          const SizedBox(height: 16),
          Text("Discovering services...", style: AppTextStyles.regular),
        ],
      ),
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
            if (_errorMessage.isNotEmpty) ...[
              _buildErrorCard(),
              const SizedBox(height: 20),
            ],
            _buildCharacteristicStatusCard(),
            const SizedBox(height: 20),
            _buildOctoValueDisplayCard(),
            const SizedBox(height: 20),
            _buildRawDataCard(),
            const SizedBox(height: 24),
            _buildGraphButton(),
            const SizedBox(height: 12),
            _buildSavedDataButton(),
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacteristicStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Characteristics Status",
              style: AppTextStyles.bold.copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                _char1Found ? Icons.check_circle : Icons.cancel,
                color: _char1Found ? Colors.green : Colors.red,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Char 1 (${ChannelLabels.ch1Short}, ${ChannelLabels.ch2Short}, ${ChannelLabels.ch3Short}, ${ChannelLabels.ch4Short}): ${_char1Found ? 'Connected' : 'Not Found'}",
                  style: TextStyle(
                    fontSize: 12,
                    color: _char1Found ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _char2Found ? Icons.check_circle : Icons.cancel,
                color: _char2Found ? Colors.green : Colors.red,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Char 2 (${ChannelLabels.ch5Short}, ${ChannelLabels.ch6Short}, ${ChannelLabels.ch7Short}, ${ChannelLabels.ch8Short}): ${_char2Found ? 'Connected' : 'Not Found'}",
                  style: TextStyle(
                    fontSize: 12,
                    color: _char2Found ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Text("Error",
                  style: AppTextStyles.bold.copyWith(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_errorMessage,
              style: AppTextStyles.regular.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildGraphButton() {
    final hasAnyChar = _char1Found || _char2Found;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isConnected && hasAnyChar ? _openGraphPage : null,
        icon: const Icon(Icons.show_chart, size: 24),
        label: Text("OPEN REAL-TIME GRAPH (8 CH)",
            style: AppTextStyles.bold.copyWith(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blueGrey[800],
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSavedDataButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _openSavedDataPage,
        icon: const Icon(Icons.folder_open, size: 24),
        label: Text("VIEW SAVED RECORDINGS",
            style: AppTextStyles.bold.copyWith(fontSize: 16)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blueGrey[800],
          side: BorderSide(color: Colors.blueGrey[800]!, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            color: _isConnected ? Colors.green : Colors.red, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.check_circle : Icons.error,
            color: _isConnected ? Colors.green : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnected ? "Connected" : "Disconnected",
                  style: AppTextStyles.bold.copyWith(
                    color: _isConnected ? Colors.green : Colors.red,
                    fontSize: 16,
                  ),
                ),
                if (_isConnected)
                  Text(
                    "Receiving 8-channel data (2 characteristics)",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOctoValueDisplayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MainColors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "LIVE VALUES",
            style: AppTextStyles.regular
                .copyWith(color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 8),
          // Characteristic 1 label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
                "Characteristic 1 — EEG & PA Channels",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 11)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildChannelDisplay(
                  ChannelLabels.ch1, _displayValue1, Colors.blue),
              Container(
                  height: 60,
                  width: 1,
                  color: Colors.white.withOpacity(0.3)),
              _buildChannelDisplay(
                  ChannelLabels.ch2, _displayValue2, Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildChannelDisplay(
                  ChannelLabels.ch3, _displayValue3, Colors.green),
              Container(
                  height: 60,
                  width: 1,
                  color: Colors.white.withOpacity(0.3)),
              _buildChannelDisplay(
                  ChannelLabels.ch4, _displayValue4, Colors.purple),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 8),
          // Characteristic 2 label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
                "Characteristic 2 — PA, PB & NoN Channels",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 11)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildChannelDisplay(
                  ChannelLabels.ch5, _displayValue5, Colors.cyan),
              Container(
                  height: 60,
                  width: 1,
                  color: Colors.white.withOpacity(0.3)),
              _buildChannelDisplay(
                  ChannelLabels.ch6, _displayValue6, Colors.red),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildChannelDisplay(
                  ChannelLabels.ch7, _displayValue7, Colors.teal),
              Container(
                  height: 60,
                  width: 1,
                  color: Colors.white.withOpacity(0.3)),
              _buildChannelDisplay(
                  ChannelLabels.ch8, _displayValue8, Colors.pink),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChannelDisplay(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: AppTextStyles.bold
                    .copyWith(color: color.withOpacity(0.9), fontSize: 11),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.header
                  .copyWith(color: color.withOpacity(0.9), fontSize: 28),
            ),
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
            const SizedBox(height: 12),
            Text(
                "Characteristic 1 (${ChannelLabels.ch1Short}, ${ChannelLabels.ch2Short}, ${ChannelLabels.ch3Short}, ${ChannelLabels.ch4Short})",
                style: AppTextStyles.bold
                    .copyWith(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 4),
            _rawDataRow(
                "String", _rawString1.isEmpty ? "Waiting..." : _rawString1),
            const SizedBox(height: 4),
            _rawDataRow(
                "Bytes", _rawBytes1.isEmpty ? "[]" : _rawBytes1.toString()),
            const SizedBox(height: 12),
            Text(
                "Characteristic 2 (${ChannelLabels.ch5Short}, ${ChannelLabels.ch6Short}, ${ChannelLabels.ch7Short}, ${ChannelLabels.ch8Short})",
                style: AppTextStyles.bold
                    .copyWith(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 4),
            _rawDataRow(
                "String", _rawString2.isEmpty ? "Waiting..." : _rawString2),
            const SizedBox(height: 4),
            _rawDataRow(
                "Bytes", _rawBytes2.isEmpty ? "[]" : _rawBytes2.toString()),
          ],
        ),
      ),
    );
  }

  Widget _rawDataRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text("$label:",
              style: AppTextStyles.bold
                  .copyWith(fontSize: 12, color: Colors.grey[600])),
        ),
        Expanded(
          child: Text(value,
              style: AppTextStyles.regular
                  .copyWith(fontSize: 12, fontFamily: 'monospace')),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isConnected &&
                    (_characteristic1 != null || _characteristic2 != null)
                ? () {
                    _readValue1();
                    _readValue2();
                  }
                : null,
            child: const Text("Read Values"),
            style: ElevatedButton.styleFrom(
              backgroundColor: MainColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
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
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// LIVE EXG CHART PAGE - 8 CHANNELS
// =============================================================================

class LiveExgChartPage extends StatefulWidget {
  final Stream<OctoChannelData> dataStream;
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
  late StreamSubscription<OctoChannelData> _subscription;

  // Display points for all 8 channels
  final List<FlSpot> _displayPoints1 = [];
  final List<FlSpot> _displayPoints2 = [];
  final List<FlSpot> _displayPoints3 = [];
  final List<FlSpot> _displayPoints4 = [];
  final List<FlSpot> _displayPoints5 = [];
  final List<FlSpot> _displayPoints6 = [];
  final List<FlSpot> _displayPoints7 = [];
  final List<FlSpot> _displayPoints8 = [];

  // ALL data points stored for saving
  final List<DataPoint> _allDataPoints = [];

  // Channel visibility toggles
  bool _showChannel1 = true;
  bool _showChannel2 = true;
  bool _showChannel3 = true;
  bool _showChannel4 = true;
  bool _showChannel5 = true;
  bool _showChannel6 = true;
  bool _showChannel7 = true;
  bool _showChannel8 = true;

  // Scrolling control
  bool _isLiveMode = true;
  double? _viewMinX;
  double? _viewMaxX;
  static const double _visibleDuration = 10000;

  DateTime? _recordingStartTime;

  // Latest values for legend
  double _latestValue1 = 0;
  double _latestValue2 = 0;
  double _latestValue3 = 0;
  double _latestValue4 = 0;
  double _latestValue5 = 0;
  double _latestValue6 = 0;
  double _latestValue7 = 0;
  double _latestValue8 = 0;

  static const int _maxDisplayPoints = 5000;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Timer? _durationTimer;

  // Channel colors
  static const Color _channel1Color = Colors.blue;
  static const Color _channel2Color = Colors.orange;
  static const Color _channel3Color = Colors.green;
  static const Color _channel4Color = Colors.purple;
  static const Color _channel5Color = Colors.cyan;
  static const Color _channel6Color = Colors.red;
  static const Color _channel7Color = Colors.teal;
  static const Color _channel8Color = Colors.pink;

  @override
  void initState() {
    super.initState();
    _recordingStartTime = DateTime.now();
    _startListening();
    _startDurationTimer();
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  void _startListening() {
    _subscription = widget.dataStream.listen((data) {
      final now = data.timestamp;

      _allDataPoints.add(DataPoint(
        value1: data.value1,
        value2: data.value2,
        value3: data.value3,
        value4: data.value4,
        value5: data.value5,
        value6: data.value6,
        value7: data.value7,
        value8: data.value8,
        timestamp: now,
        processedValue1: data.value1,
        processedValue2: data.value2,
        processedValue3: data.value3,
        processedValue4: data.value4,
        processedValue5: data.value5,
        processedValue6: data.value6,
        processedValue7: data.value7,
        processedValue8: data.value8,
      ));

      setState(() {
        final timestamp = now.millisecondsSinceEpoch.toDouble();

        _displayPoints1.add(FlSpot(timestamp, data.value1));
        _displayPoints2.add(FlSpot(timestamp, data.value2));
        _displayPoints3.add(FlSpot(timestamp, data.value3));
        _displayPoints4.add(FlSpot(timestamp, data.value4));
        _displayPoints5.add(FlSpot(timestamp, data.value5));
        _displayPoints6.add(FlSpot(timestamp, data.value6));
        _displayPoints7.add(FlSpot(timestamp, data.value7));
        _displayPoints8.add(FlSpot(timestamp, data.value8));

        _latestValue1 = data.value1;
        _latestValue2 = data.value2;
        _latestValue3 = data.value3;
        _latestValue4 = data.value4;
        _latestValue5 = data.value5;
        _latestValue6 = data.value6;
        _latestValue7 = data.value7;
        _latestValue8 = data.value8;

        while (_displayPoints1.length > _maxDisplayPoints) {
          _displayPoints1.removeAt(0);
          _displayPoints2.removeAt(0);
          _displayPoints3.removeAt(0);
          _displayPoints4.removeAt(0);
          _displayPoints5.removeAt(0);
          _displayPoints6.removeAt(0);
          _displayPoints7.removeAt(0);
          _displayPoints8.removeAt(0);
        }
      });
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_displayPoints1.isEmpty) return;

    final chartWidth = MediaQuery.of(context).size.width - 80;
    final dragRatio = details.delta.dx / chartWidth;
    final shift = -dragRatio * _visibleDuration;

    final dataMinX = _displayPoints1.first.x;
    final dataMaxX = _displayPoints1.last.x;

    setState(() {
      if (_isLiveMode) {
        _viewMaxX = dataMaxX;
        _viewMinX = dataMaxX - _visibleDuration;
        _isLiveMode = false;
      }

      double newMinX = (_viewMinX ?? dataMinX) + shift;
      double newMaxX = (_viewMaxX ?? dataMaxX) + shift;

      if (newMinX < dataMinX) {
        newMinX = dataMinX;
        newMaxX = newMinX + _visibleDuration;
      }
      if (newMaxX > dataMaxX) {
        newMaxX = dataMaxX;
        newMinX = newMaxX - _visibleDuration;
        _isLiveMode = true;
      } else {
        _isLiveMode = false;
      }

      _viewMinX = newMinX;
      _viewMaxX = newMaxX;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {}

  void _onDoubleTap() {
    _resetToLive();
  }

  void _resetToLive() {
    setState(() {
      _isLiveMode = true;
      _viewMinX = null;
      _viewMaxX = null;
    });
  }

  void _clearChart() {
    setState(() {
      _displayPoints1.clear();
      _displayPoints2.clear();
      _displayPoints3.clear();
      _displayPoints4.clear();
      _displayPoints5.clear();
      _displayPoints6.clear();
      _displayPoints7.clear();
      _displayPoints8.clear();
      _allDataPoints.clear();
      _recordingStartTime = DateTime.now();
      _isLiveMode = true;
      _viewMinX = null;
      _viewMaxX = null;
      _latestValue1 = 0;
      _latestValue2 = 0;
      _latestValue3 = 0;
      _latestValue4 = 0;
      _latestValue5 = 0;
      _latestValue6 = 0;
      _latestValue7 = 0;
      _latestValue8 = 0;
    });
  }

  Future<void> _saveChartData() async {
    if (_allDataPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No data to save!"),
            backgroundColor: Colors.orange),
      );
      return;
    }

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
      final sessionId = await _dbHelper.createSession(widget.deviceName);
      await _dbHelper.saveDataPoints(sessionId, _allDataPoints);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Saved ${_allDataPoints.length} data points!"),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: "VIEW",
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SavedRecordingsPage()),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error saving: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'restart')
                _showRestartConfirmation();
              else if (value == 'save')
                _saveChartData();
              else if (value == 'view_saved') {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SavedRecordingsPage()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'restart',
                  child: Row(children: [
                    Icon(Icons.refresh, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Restart')
                  ])),
              const PopupMenuItem(
                  value: 'save',
                  child: Row(children: [
                    Icon(Icons.save_alt, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Save Data')
                  ])),
              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: 'view_saved',
                  child: Row(children: [
                    Icon(Icons.folder_open, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('View Saved')
                  ])),
            ],
            icon: const Icon(Icons.more_vert, color: MainColors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsBar(),
          const SizedBox(height: 8),
          _buildChannelToggles(),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                onDoubleTap: _onDoubleTap,
                child: Container(
                  padding: const EdgeInsets.only(
                      top: 24, bottom: 12, right: 20, left: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xfff3f6f9),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: _hasNoData()
                      ? _buildEmptyChart()
                      : Stack(
                          children: [
                            LineChart(_buildChartData(),
                                duration: Duration.zero),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: _isLiveMode
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                            color: Colors.green, width: 1),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.circle,
                                              color: Colors.green, size: 8),
                                          SizedBox(width: 6),
                                          Text(
                                            "LIVE",
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ElevatedButton.icon(
                                      onPressed: _resetToLive,
                                      icon: const Icon(Icons.skip_next,
                                          size: 16),
                                      label: const Text("GO LIVE"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        textStyle: const TextStyle(
                                            fontSize: 11,
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
          const SizedBox(height: 12),
          _buildLegend(),
          const SizedBox(height: 8),
          _buildScrollInstruction(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildScrollInstruction() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swipe, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            "Swipe left/right on graph to scroll • Double-tap for live",
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text("Waiting for data...", style: AppTextStyles.regular),
          const SizedBox(height: 8),
          Text("Make sure BLE device is sending data",
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  bool _hasNoData() {
    return _displayPoints1.isEmpty &&
        _displayPoints2.isEmpty &&
        _displayPoints3.isEmpty &&
        _displayPoints4.isEmpty &&
        _displayPoints5.isEmpty &&
        _displayPoints6.isEmpty &&
        _displayPoints7.isEmpty &&
        _displayPoints8.isEmpty;
  }

  Widget _buildChannelToggles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          _buildChannelChip(ChannelLabels.ch1Short, _showChannel1,
              _channel1Color, (v) => setState(() => _showChannel1 = v)),
          _buildChannelChip(ChannelLabels.ch2Short, _showChannel2,
              _channel2Color, (v) => setState(() => _showChannel2 = v)),
          _buildChannelChip(ChannelLabels.ch3Short, _showChannel3,
              _channel3Color, (v) => setState(() => _showChannel3 = v)),
          _buildChannelChip(ChannelLabels.ch4Short, _showChannel4,
              _channel4Color, (v) => setState(() => _showChannel4 = v)),
          _buildChannelChip(ChannelLabels.ch5Short, _showChannel5,
              _channel5Color, (v) => setState(() => _showChannel5 = v)),
          _buildChannelChip(ChannelLabels.ch6Short, _showChannel6,
              _channel6Color, (v) => setState(() => _showChannel6 = v)),
          _buildChannelChip(ChannelLabels.ch7Short, _showChannel7,
              _channel7Color, (v) => setState(() => _showChannel7 = v)),
          _buildChannelChip(ChannelLabels.ch8Short, _showChannel8,
              _channel8Color, (v) => setState(() => _showChannel8 = v)),
        ],
      ),
    );
  }

  Widget _buildChannelChip(
      String label, bool selected, Color color, Function(bool) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: color,
      labelStyle: TextStyle(
          color: selected ? color : Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 10),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          if (_showChannel1)
            _buildLegendItem(
                ChannelLabels.ch1Short, _latestValue1, _channel1Color),
          if (_showChannel2)
            _buildLegendItem(
                ChannelLabels.ch2Short, _latestValue2, _channel2Color),
          if (_showChannel3)
            _buildLegendItem(
                ChannelLabels.ch3Short, _latestValue3, _channel3Color),
          if (_showChannel4)
            _buildLegendItem(
                ChannelLabels.ch4Short, _latestValue4, _channel4Color),
          if (_showChannel5)
            _buildLegendItem(
                ChannelLabels.ch5Short, _latestValue5, _channel5Color),
          if (_showChannel6)
            _buildLegendItem(
                ChannelLabels.ch6Short, _latestValue6, _channel6Color),
          if (_showChannel7)
            _buildLegendItem(
                ChannelLabels.ch7Short, _latestValue7, _channel7Color),
          if (_showChannel8)
            _buildLegendItem(
                ChannelLabels.ch8Short, _latestValue8, _channel8Color),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 3, color: color),
        const SizedBox(width: 4),
        Text("$label: ${value.toStringAsFixed(1)}",
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 10)),
      ],
    );
  }

  Widget _buildStatsBar() {
    final duration = _recordingStartTime != null
        ? DateTime.now().difference(_recordingStartTime!)
        : Duration.zero;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              value: _formatDuration(duration)),
          Container(height: 30, width: 1, color: Colors.grey[300]),
          _statItem(
              icon: Icons.data_array,
              label: "Points",
              value: _allDataPoints.length.toString()),
          Container(height: 30, width: 1, color: Colors.grey[300]),
          _statItem(
            icon: _isLiveMode ? Icons.circle : Icons.history,
            label: _isLiveMode ? "Mode" : "Viewing",
            value: _isLiveMode ? "LIVE" : "HISTORY",
            valueColor: _isLiveMode ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _statItem(
      {required IconData icon,
      required String label,
      required String value,
      Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: valueColor ?? MainColors.primaryColor),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: valueColor ?? MainColors.black)),
            Text(label,
                style: TextStyle(fontSize: 9, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return "$hours:$minutes:$seconds";
    return "$minutes:$seconds";
  }

  void _showRestartConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Restart Recording?"),
        content: Text(
            "This will clear ${_allDataPoints.length} recorded data points."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearChart();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text("Restart", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    List<FlSpot> referencePoints = _displayPoints1.isNotEmpty
        ? _displayPoints1
        : _displayPoints2.isNotEmpty
            ? _displayPoints2
            : _displayPoints3.isNotEmpty
                ? _displayPoints3
                : _displayPoints4.isNotEmpty
                    ? _displayPoints4
                    : _displayPoints5.isNotEmpty
                        ? _displayPoints5
                        : _displayPoints6.isNotEmpty
                            ? _displayPoints6
                            : _displayPoints7.isNotEmpty
                                ? _displayPoints7
                                : _displayPoints8;

    double minX, maxX;

    if (referencePoints.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch.toDouble();
      minX = now - 1000;
      maxX = now;
    } else {
      final dataMinX = referencePoints.first.x;
      final dataMaxX = referencePoints.last.x;
      final dataRange = dataMaxX - dataMinX;

      if (_isLiveMode) {
        if (dataRange < _visibleDuration) {
          final padding = dataRange * 0.05;
          minX = dataMinX - padding;
          maxX = dataMaxX + padding;
        } else {
          maxX = dataMaxX;
          minX = maxX - _visibleDuration;
        }
      } else {
        minX = _viewMinX ?? dataMinX;
        maxX = _viewMaxX ?? dataMaxX;
      }
    }

    // Dynamic symmetric Y-axis
    double maxAbsValue = 1;
    List<List<FlSpot>> allChannelPoints = [];
    if (_showChannel1) allChannelPoints.add(_displayPoints1);
    if (_showChannel2) allChannelPoints.add(_displayPoints2);
    if (_showChannel3) allChannelPoints.add(_displayPoints3);
    if (_showChannel4) allChannelPoints.add(_displayPoints4);
    if (_showChannel5) allChannelPoints.add(_displayPoints5);
    if (_showChannel6) allChannelPoints.add(_displayPoints6);
    if (_showChannel7) allChannelPoints.add(_displayPoints7);
    if (_showChannel8) allChannelPoints.add(_displayPoints8);

    for (var channelPoints in allChannelPoints) {
      for (var point in channelPoints) {
        if (point.x >= minX && point.x <= maxX) {
          if (point.y.abs() > maxAbsValue) {
            maxAbsValue = point.y.abs();
          }
        }
      }
    }

    maxAbsValue = maxAbsValue * 1.1;

    final double minY = -maxAbsValue;
    final double maxY = maxAbsValue;
    final double xAxisInterval = 2000;

    List<LineChartBarData> lineBars = [];

    if (_showChannel1 && _displayPoints1.isNotEmpty)
      lineBars.add(_createLineBar(
          _getVisiblePoints(_displayPoints1, minX, maxX), _channel1Color));
    if (_showChannel2 && _displayPoints2.isNotEmpty)
      lineBars.add(_createLineBar(
          _getVisiblePoints(_displayPoints2, minX, maxX), _channel2Color));
    if (_showChannel3 && _displayPoints3.isNotEmpty)
      lineBars.add(_createLineBar(
          _getVisiblePoints(_displayPoints3, minX, maxX), _channel3Color));
    if (_showChannel4 && _displayPoints4.isNotEmpty)
      lineBars.add(_createLineBar(
          _getVisiblePoints(_displayPoints4, minX, maxX), _channel4Color));
    if (_showChannel5 && _displayPoints5.isNotEmpty)
      lineBars.add(_createLineBar(
          _getVisiblePoints(_displayPoints5, minX, maxX), _channel5Color));
    if (_showChannel6 && _displayPoints6.isNotEmpty)
      lineBars.add(_createLineBar(
          _getVisiblePoints(_displayPoints6, minX, maxX), _channel6Color));
    if (_showChannel7 && _displayPoints7.isNotEmpty)
      lineBars.add(_createLineBar(
          _getVisiblePoints(_displayPoints7, minX, maxX), _channel7Color));
    if (_showChannel8 && _displayPoints8.isNotEmpty)
      lineBars.add(_createLineBar(
          _getVisiblePoints(_displayPoints8, minX, maxX), _channel8Color));

    return LineChartData(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: maxAbsValue / 4,
        verticalInterval: xAxisInterval,
        getDrawingHorizontalLine: (value) {
          if (value.abs() < 0.001) {
            return FlLine(color: Colors.grey[600]!, strokeWidth: 1.5);
          }
          return FlLine(color: Colors.grey[300]!, strokeWidth: 0.8);
        },
        getDrawingVerticalLine: (value) =>
            FlLine(color: Colors.grey[300]!, strokeWidth: 0.8),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: xAxisInterval,
            getTitlesWidget: (value, meta) {
              final remainder = value % xAxisInterval;
              if (remainder.abs() > 100 &&
                  (xAxisInterval - remainder.abs()) > 100) {
                return const SizedBox.shrink();
              }
              final date =
                  DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return SideTitleWidget(
                meta: meta,
                space: 8.0,
                child: Text(DateFormat('HH:mm:ss').format(date),
                    style:
                        TextStyle(color: Colors.grey[700], fontSize: 10)),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              if (value == meta.max || value == meta.min)
                return const SizedBox.shrink();
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    color: value.abs() < 0.001
                        ? Colors.grey[800]
                        : Colors.grey[600],
                    fontSize: 10,
                    fontWeight: value.abs() < 0.001
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: lineBars,
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date =
                  DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
              final channelInfo = _getChannelInfo(spot.barIndex);
              return LineTooltipItem(
                '${channelInfo.label}: ${spot.y.toStringAsFixed(1)}\n${DateFormat('HH:mm:ss').format(date)}',
                TextStyle(
                    color: channelInfo.color.withOpacity(0.9),
                    fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  List<FlSpot> _getVisiblePoints(
      List<FlSpot> allPoints, double minX, double maxX) {
    final buffer = (maxX - minX) * 0.1;
    return allPoints
        .where((p) => p.x >= (minX - buffer) && p.x <= (maxX + buffer))
        .toList();
  }

  LineChartBarData _createLineBar(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  ({String label, Color color}) _getChannelInfo(int barIndex) {
    List<({String label, Color color})> visibleChannels = [];
    if (_showChannel1)
      visibleChannels
          .add((label: ChannelLabels.ch1Short, color: _channel1Color));
    if (_showChannel2)
      visibleChannels
          .add((label: ChannelLabels.ch2Short, color: _channel2Color));
    if (_showChannel3)
      visibleChannels
          .add((label: ChannelLabels.ch3Short, color: _channel3Color));
    if (_showChannel4)
      visibleChannels
          .add((label: ChannelLabels.ch4Short, color: _channel4Color));
    if (_showChannel5)
      visibleChannels
          .add((label: ChannelLabels.ch5Short, color: _channel5Color));
    if (_showChannel6)
      visibleChannels
          .add((label: ChannelLabels.ch6Short, color: _channel6Color));
    if (_showChannel7)
      visibleChannels
          .add((label: ChannelLabels.ch7Short, color: _channel7Color));
    if (_showChannel8)
      visibleChannels
          .add((label: ChannelLabels.ch8Short, color: _channel8Color));
    if (barIndex < visibleChannels.length) return visibleChannels[barIndex];
    return (label: "??", color: Colors.grey);
  }
}

// =============================================================================
// SAVED RECORDINGS PAGE
// =============================================================================

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
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteSession(RecordingSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Recording?"),
        content:
            Text("Delete recording with ${session.dataCount} data points?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && session.id != null) {
      await _dbHelper.deleteSession(session.id!);
      _loadSessions();
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
              onPressed: _loadSessions),
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
          Text("No saved recordings",
              style: AppTextStyles.bold.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text("Start recording from the graph page",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600])),
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
        itemBuilder: (context, index) =>
            _buildSessionCard(_sessions[index]),
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
                      builder: (context) =>
                          RecordingDetailPage(session: session)))
              .then((_) => _loadSessions());
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
                        Text(session.deviceName,
                            style:
                                AppTextStyles.bold.copyWith(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(dateFormat.format(session.startTime),
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteSession(session),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoItem(Icons.access_time, "Start",
                      timeFormat.format(session.startTime)),
                  _infoItem(
                      Icons.timer,
                      "Duration",
                      session.duration != null
                          ? _formatDuration(session.duration!)
                          : "--"),
                  _infoItem(Icons.data_array, "Points",
                      session.dataCount.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0)
      return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
    if (d.inMinutes > 0)
      return "${d.inMinutes}m ${d.inSeconds.remainder(60)}s";
    return "${d.inSeconds}s";
  }
}

// =============================================================================
// RECORDING DETAIL PAGE - 8 CHANNELS
// =============================================================================

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

  bool _showChannel1 = true;
  bool _showChannel2 = true;
  bool _showChannel3 = true;
  bool _showChannel4 = true;
  bool _showChannel5 = true;
  bool _showChannel6 = true;
  bool _showChannel7 = true;
  bool _showChannel8 = true;

  double? _viewMinX;
  double? _viewMaxX;
  double _visibleDuration = 10000;
  double _lastScale = 1.0;
  bool _isFullView = true;

  static const double _minVisibleDuration = 2000;
  static const double _maxVisibleDuration = 60000;

  static const Color _channel1Color = Colors.blue;
  static const Color _channel2Color = Colors.orange;
  static const Color _channel3Color = Colors.green;
  static const Color _channel4Color = Colors.purple;
  static const Color _channel5Color = Colors.cyan;
  static const Color _channel6Color = Colors.red;
  static const Color _channel7Color = Colors.teal;
  static const Color _channel8Color = Colors.pink;

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
          _viewMinX = _dataPoints.first.timestamp.millisecondsSinceEpoch
              .toDouble();
          _viewMaxX = _dataPoints.last.timestamp.millisecondsSinceEpoch
              .toDouble();
          _visibleDuration = _viewMaxX! - _viewMinX!;
          _isFullView = true;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportToCSV() async {
    await CSVExporter.exportWithDialog(
      context: context,
      session: widget.session,
      dataPoints: _dataPoints,
      stats: _stats,
    );
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_dataPoints.isEmpty) return;

    final chartWidth = MediaQuery.of(context).size.width - 80;
    final dragRatio = details.delta.dx / chartWidth;
    final currentRange = (_viewMaxX ?? 0) - (_viewMinX ?? 0);
    final shift = -dragRatio * currentRange;

    final dataMinX =
        _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
    final dataMaxX =
        _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();

    setState(() {
      _isFullView = false;

      double newMinX = (_viewMinX ?? dataMinX) + shift;
      double newMaxX = (_viewMaxX ?? dataMaxX) + shift;

      if (newMinX < dataMinX) {
        newMinX = dataMinX;
        newMaxX = newMinX + currentRange;
      }
      if (newMaxX > dataMaxX) {
        newMaxX = dataMaxX;
        newMinX = newMaxX - currentRange;
      }

      _viewMinX = newMinX;
      _viewMaxX = newMaxX;
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastScale = 1.0;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_dataPoints.isEmpty) return;

    if (details.scale != 1.0) {
      final scaleDiff = details.scale / _lastScale;
      _lastScale = details.scale;

      setState(() {
        _isFullView = false;

        final currentRange = (_viewMaxX ?? 0) - (_viewMinX ?? 0);
        double newRange = currentRange / scaleDiff;
        newRange =
            newRange.clamp(_minVisibleDuration, _maxVisibleDuration);

        if (_viewMinX != null && _viewMaxX != null) {
          final center = (_viewMinX! + _viewMaxX!) / 2;
          _viewMinX = center - newRange / 2;
          _viewMaxX = center + newRange / 2;

          final dataMinX = _dataPoints.first.timestamp
              .millisecondsSinceEpoch
              .toDouble();
          final dataMaxX = _dataPoints.last.timestamp
              .millisecondsSinceEpoch
              .toDouble();

          if (_viewMinX! < dataMinX) {
            _viewMinX = dataMinX;
            _viewMaxX = dataMinX + newRange;
          }
          if (_viewMaxX! > dataMaxX) {
            _viewMaxX = dataMaxX;
            _viewMinX = dataMaxX - newRange;
          }
        }

        _visibleDuration = newRange;
      });
    }

    if (details.scale == 1.0 && details.focalPointDelta.dx != 0) {
      _onHorizontalDragUpdate(
        DragUpdateDetails(
          globalPosition: details.focalPoint,
          delta: details.focalPointDelta,
        ),
      );
    }
  }

  void _zoomIn() {
    if (_dataPoints.isEmpty) return;

    setState(() {
      _isFullView = false;

      final currentRange = (_viewMaxX ?? 0) - (_viewMinX ?? 0);
      double newRange = (currentRange / 1.5)
          .clamp(_minVisibleDuration, _maxVisibleDuration);

      final center = ((_viewMinX ?? 0) + (_viewMaxX ?? 0)) / 2;
      _viewMinX = center - newRange / 2;
      _viewMaxX = center + newRange / 2;

      _clampToDataBounds();
      _visibleDuration = newRange;
    });
  }

  void _zoomOut() {
    if (_dataPoints.isEmpty) return;

    setState(() {
      final currentRange = (_viewMaxX ?? 0) - (_viewMinX ?? 0);
      final dataMinX =
          _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
      final dataMaxX =
          _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
      final totalRange = dataMaxX - dataMinX;

      double newRange =
          (currentRange * 1.5).clamp(_minVisibleDuration, totalRange);

      final center = ((_viewMinX ?? 0) + (_viewMaxX ?? 0)) / 2;
      _viewMinX = center - newRange / 2;
      _viewMaxX = center + newRange / 2;

      _clampToDataBounds();
      _visibleDuration = newRange;

      if ((_viewMaxX! - _viewMinX!) >= totalRange * 0.99) {
        _isFullView = true;
        _viewMinX = dataMinX;
        _viewMaxX = dataMaxX;
      } else {
        _isFullView = false;
      }
    });
  }

  void _clampToDataBounds() {
    if (_dataPoints.isEmpty) return;

    final dataMinX =
        _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
    final dataMaxX =
        _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
    final currentRange =
        (_viewMaxX ?? dataMaxX) - (_viewMinX ?? dataMinX);

    if (_viewMinX! < dataMinX) {
      _viewMinX = dataMinX;
      _viewMaxX = dataMinX + currentRange;
    }
    if (_viewMaxX! > dataMaxX) {
      _viewMaxX = dataMaxX;
      _viewMinX = dataMaxX - currentRange;
    }
  }

  void _resetToFullView() {
    if (_dataPoints.isEmpty) return;

    setState(() {
      _viewMinX =
          _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
      _viewMaxX =
          _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
      _visibleDuration = _viewMaxX! - _viewMinX!;
      _isFullView = true;
    });
  }

  String _getViewTimeRange() {
    if (_viewMinX == null || _viewMaxX == null) return "";
    final startTime =
        DateTime.fromMillisecondsSinceEpoch(_viewMinX!.toInt());
    final endTime =
        DateTime.fromMillisecondsSinceEpoch(_viewMaxX!.toInt());
    final format = DateFormat('HH:mm:ss');
    return "${format.format(startTime)} - ${format.format(endTime)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MainColors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Recording Details", style: AppTextStyles.header),
            Text(widget.session.deviceName,
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
          IconButton(
            onPressed: _dataPoints.isNotEmpty ? _exportToCSV : null,
            icon: Icon(Icons.file_download,
                color:
                    _dataPoints.isNotEmpty ? Colors.green : Colors.grey),
            tooltip: "Export CSV",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dataPoints.isEmpty
              ? Center(
                  child: Text("No data", style: AppTextStyles.bold))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSessionInfo(),
                      _buildStatsCard(),
                      _buildExportButton(),
                      const SizedBox(height: 16),
                      _buildChannelToggles(),
                      const SizedBox(height: 8),
                      _buildZoomControls(),
                      const SizedBox(height: 8),
                      _buildChartSection(),
                      _buildDataTable(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildZoomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _zoomOut,
            icon: const Icon(Icons.zoom_out),
            tooltip: "Zoom Out",
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[200],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isFullView
                  ? "Full View"
                  : "${(_visibleDuration / 1000).toStringAsFixed(0)}s window",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _zoomIn,
            icon: const Icon(Icons.zoom_in),
            tooltip: "Zoom In",
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[200],
            ),
          ),
          const SizedBox(width: 16),
          if (!_isFullView)
            TextButton.icon(
              onPressed: _resetToFullView,
              icon: const Icon(Icons.fullscreen, size: 18),
              label: const Text("Full"),
              style: TextButton.styleFrom(
                foregroundColor: MainColors.primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionInfo() {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MainColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.calendar_today, size: 18),
            const SizedBox(width: 8),
            Text(
                "Recorded: ${dateFormat.format(widget.session.startTime)}",
                style: AppTextStyles.regular),
          ]),
          if (widget.session.duration != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.timer, size: 18),
              const SizedBox(width: 8),
              Text(
                  "Duration: ${_formatDuration(widget.session.duration!)}",
                  style: AppTextStyles.regular),
            ]),
          ],
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.layers, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  "Channels: ${ChannelLabels.ch1Short}, ${ChannelLabels.ch2Short}, ${ChannelLabels.ch3Short}, ${ChannelLabels.ch4Short}, ${ChannelLabels.ch5Short}, ${ChannelLabels.ch6Short}, ${ChannelLabels.ch7Short}, ${ChannelLabels.ch8Short}",
                  style: AppTextStyles.regular.copyWith(fontSize: 12)),
            ),
          ]),
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
              blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Statistics", style: AppTextStyles.bold),
          const SizedBox(height: 12),
          _buildChannelStats(ChannelLabels.ch1, _channel1Color,
              'min_value1', 'max_value1', 'avg_value1'),
          const SizedBox(height: 6),
          _buildChannelStats(ChannelLabels.ch2, _channel2Color,
              'min_value2', 'max_value2', 'avg_value2'),
          const SizedBox(height: 6),
          _buildChannelStats(ChannelLabels.ch3, _channel3Color,
              'min_value3', 'max_value3', 'avg_value3'),
          const SizedBox(height: 6),
          _buildChannelStats(ChannelLabels.ch4, _channel4Color,
              'min_value4', 'max_value4', 'avg_value4'),
          const SizedBox(height: 6),
          _buildChannelStats(ChannelLabels.ch5, _channel5Color,
              'min_value5', 'max_value5', 'avg_value5'),
          const SizedBox(height: 6),
          _buildChannelStats(ChannelLabels.ch6, _channel6Color,
              'min_value6', 'max_value6', 'avg_value6'),
          const SizedBox(height: 6),
          _buildChannelStats(ChannelLabels.ch7, _channel7Color,
              'min_value7', 'max_value7', 'avg_value7'),
          const SizedBox(height: 6),
          _buildChannelStats(ChannelLabels.ch8, _channel8Color,
              'min_value8', 'max_value8', 'avg_value8'),
        ],
      ),
    );
  }

  Widget _buildChannelStats(
      String name, Color color, String minKey, String maxKey, String avgKey) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "$name: Min ${_formatStat(_stats[minKey])} | Max ${_formatStat(_stats[maxKey])} | Avg ${_formatStat(_stats[avgKey])}",
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  String _formatStat(dynamic v) =>
      v != null ? (v as num).toStringAsFixed(1) : "N/A";

  Widget _buildExportButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _exportToCSV,
          icon: const Icon(Icons.file_download),
          label: const Text("EXPORT TO CSV (8 CHANNELS)"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelToggles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          _buildChip(ChannelLabels.ch1Short, _showChannel1, _channel1Color,
              (v) => setState(() => _showChannel1 = v)),
          _buildChip(ChannelLabels.ch2Short, _showChannel2, _channel2Color,
              (v) => setState(() => _showChannel2 = v)),
          _buildChip(ChannelLabels.ch3Short, _showChannel3, _channel3Color,
              (v) => setState(() => _showChannel3 = v)),
          _buildChip(ChannelLabels.ch4Short, _showChannel4, _channel4Color,
              (v) => setState(() => _showChannel4 = v)),
          _buildChip(ChannelLabels.ch5Short, _showChannel5, _channel5Color,
              (v) => setState(() => _showChannel5 = v)),
          _buildChip(ChannelLabels.ch6Short, _showChannel6, _channel6Color,
              (v) => setState(() => _showChannel6 = v)),
          _buildChip(ChannelLabels.ch7Short, _showChannel7, _channel7Color,
              (v) => setState(() => _showChannel7 = v)),
          _buildChip(ChannelLabels.ch8Short, _showChannel8, _channel8Color,
              (v) => setState(() => _showChannel8 = v)),
        ],
      ),
    );
  }

  Widget _buildChip(
      String label, bool selected, Color color, Function(bool) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: color,
      labelStyle: TextStyle(
          color: selected ? color : Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 10),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildChartSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onDoubleTap: _resetToFullView,
        child: Container(
          height: 300,
          padding: const EdgeInsets.only(
              top: 24, bottom: 12, right: 20, left: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xfff3f6f9),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Stack(
            children: [
              LineChart(_buildChartData()),
              Positioned(
                top: 8,
                right: 8,
                child: _isFullView
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.green, width: 1),
                        ),
                        child: const Text(
                          "FULL VIEW",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.orange, width: 1),
                        ),
                        child: Text(
                          _getViewTimeRange(),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LineChartData _buildChartData() {
    List<LineChartBarData> lineBars = [];

    List<FlSpot> spots1 = [];
    List<FlSpot> spots2 = [];
    List<FlSpot> spots3 = [];
    List<FlSpot> spots4 = [];
    List<FlSpot> spots5 = [];
    List<FlSpot> spots6 = [];
    List<FlSpot> spots7 = [];
    List<FlSpot> spots8 = [];

    final minX = _viewMinX ??
        (_dataPoints.isNotEmpty
            ? _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble()
            : 0);
    final maxX = _viewMaxX ??
        (_dataPoints.isNotEmpty
            ? _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble()
            : 1);
    final buffer = (maxX - minX) * 0.1;

    for (var p in _dataPoints) {
      final x = p.timestamp.millisecondsSinceEpoch.toDouble();
      if (x >= (minX - buffer) && x <= (maxX + buffer)) {
        spots1.add(FlSpot(x, p.value1));
        spots2.add(FlSpot(x, p.value2));
        spots3.add(FlSpot(x, p.value3));
        spots4.add(FlSpot(x, p.value4));
        spots5.add(FlSpot(x, p.value5));
        spots6.add(FlSpot(x, p.value6));
        spots7.add(FlSpot(x, p.value7));
        spots8.add(FlSpot(x, p.value8));
      }
    }

    // Dynamic symmetric Y-axis
    double maxAbsValue = 1;
    void checkSpots(List<FlSpot> spots) {
      for (var spot in spots) {
        if (spot.y.abs() > maxAbsValue) maxAbsValue = spot.y.abs();
      }
    }

    if (_showChannel1) checkSpots(spots1);
    if (_showChannel2) checkSpots(spots2);
    if (_showChannel3) checkSpots(spots3);
    if (_showChannel4) checkSpots(spots4);
    if (_showChannel5) checkSpots(spots5);
    if (_showChannel6) checkSpots(spots6);
    if (_showChannel7) checkSpots(spots7);
    if (_showChannel8) checkSpots(spots8);
    maxAbsValue = maxAbsValue * 1.1;

    LineChartBarData makeLine(List<FlSpot> spots, Color color) {
      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.0)
            ],
          ),
        ),
      );
    }

    if (_showChannel1 && spots1.isNotEmpty) {
      lineBars.add(makeLine(spots1, _channel1Color));
    }
    if (_showChannel2 && spots2.isNotEmpty) {
      lineBars.add(makeLine(spots2, _channel2Color));
    }
    if (_showChannel3 && spots3.isNotEmpty) {
      lineBars.add(makeLine(spots3, _channel3Color));
    }
    if (_showChannel4 && spots4.isNotEmpty) {
      lineBars.add(makeLine(spots4, _channel4Color));
    }
    if (_showChannel5 && spots5.isNotEmpty) {
      lineBars.add(makeLine(spots5, _channel5Color));
    }
    if (_showChannel6 && spots6.isNotEmpty) {
      lineBars.add(makeLine(spots6, _channel6Color));
    }
    if (_showChannel7 && spots7.isNotEmpty) {
      lineBars.add(makeLine(spots7, _channel7Color));
    }
    if (_showChannel8 && spots8.isNotEmpty) {
      lineBars.add(makeLine(spots8, _channel8Color));
    }

    return LineChartData(
      minX: minX,
      maxX: maxX,
      minY: -maxAbsValue,
      maxY: maxAbsValue,
      clipData: const FlClipData.all(),
      lineBarsData: lineBars,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: maxAbsValue / 4,
        getDrawingHorizontalLine: (value) {
          if (value.abs() < 0.001) {
            return FlLine(
                color: Colors.grey[600]!, strokeWidth: 1.5);
          }
          return FlLine(
              color: Colors.grey[300]!, strokeWidth: 0.8);
        },
        getDrawingVerticalLine: (value) =>
            FlLine(color: Colors.grey[300]!, strokeWidth: 0.8),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value == meta.min || value == meta.max)
                return const SizedBox.shrink();
              final date = DateTime.fromMillisecondsSinceEpoch(
                  value.toInt());
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  DateFormat('mm:ss').format(date),
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey[700]),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              if (value == meta.max || value == meta.min)
                return const SizedBox.shrink();
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 10,
                    color: value.abs() < 0.001
                        ? Colors.grey[800]
                        : Colors.grey[600],
                    fontWeight: value.abs() < 0.001
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date = DateTime.fromMillisecondsSinceEpoch(
                  spot.x.toInt());
              final channelInfo =
                  _getChannelInfo(spot.barIndex);
              return LineTooltipItem(
                '${channelInfo.label}: ${spot.y.toStringAsFixed(1)}\n${DateFormat('HH:mm:ss').format(date)}',
                TextStyle(
                    color:
                        channelInfo.color.withOpacity(0.9),
                    fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  ({String label, Color color}) _getChannelInfo(int barIndex) {
    List<({String label, Color color})> visibleChannels = [];
    if (_showChannel1) {
      visibleChannels
          .add((label: ChannelLabels.ch1Short, color: _channel1Color));
    }
    if (_showChannel2) {
      visibleChannels
          .add((label: ChannelLabels.ch2Short, color: _channel2Color));
    }
    if (_showChannel3) {
      visibleChannels
          .add((label: ChannelLabels.ch3Short, color: _channel3Color));
    }
    if (_showChannel4) {
      visibleChannels
          .add((label: ChannelLabels.ch4Short, color: _channel4Color));
    }
    if (_showChannel5) {
      visibleChannels
          .add((label: ChannelLabels.ch5Short, color: _channel5Color));
    }
    if (_showChannel6) {
      visibleChannels
          .add((label: ChannelLabels.ch6Short, color: _channel6Color));
    }
    if (_showChannel7) {
      visibleChannels
          .add((label: ChannelLabels.ch7Short, color: _channel7Color));
    }
    if (_showChannel8) {
      visibleChannels
          .add((label: ChannelLabels.ch8Short, color: _channel8Color));
    }
    if (barIndex < visibleChannels.length) {
      return visibleChannels[barIndex];
    }
    return (label: "??", color: Colors.grey);
  }

  Widget _buildDataTable() {
    final displayPoints = _dataPoints.take(50).toList();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    "Data Points (${displayPoints.length}/${_dataPoints.length})",
                    style: AppTextStyles.bold),
                Text("Showing first 50",
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      SizedBox(
                          width: 40,
                          child: Text("#",
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700]))),
                      SizedBox(
                          width: 80,
                          child: Text("Time",
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700]))),
                      SizedBox(
                          width: 60,
                          child: Text(ChannelLabels.ch1Short,
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _channel1Color))),
                      SizedBox(
                          width: 60,
                          child: Text(ChannelLabels.ch2Short,
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _channel2Color))),
                      SizedBox(
                          width: 55,
                          child: Text(ChannelLabels.ch3Short,
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _channel3Color))),
                      SizedBox(
                          width: 55,
                          child: Text(ChannelLabels.ch4Short,
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _channel4Color))),
                      SizedBox(
                          width: 50,
                          child: Text(ChannelLabels.ch5Short,
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _channel5Color))),
                      SizedBox(
                          width: 55,
                          child: Text(ChannelLabels.ch6Short,
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _channel6Color))),
                      SizedBox(
                          width: 55,
                          child: Text(ChannelLabels.ch7Short,
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _channel7Color))),
                      SizedBox(
                          width: 45,
                          child: Text(ChannelLabels.ch8Short,
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _channel8Color))),
                    ],
                  ),
                ),
                ...displayPoints.asMap().entries.map((e) {
                  final p = e.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    color: e.key % 2 == 0
                        ? Colors.white
                        : Colors.grey[50],
                    child: Row(
                      children: [
                        SizedBox(
                            width: 40,
                            child: Text("${e.key + 1}",
                                style:
                                    const TextStyle(fontSize: 10))),
                        SizedBox(
                            width: 80,
                            child: Text(
                                DateFormat('HH:mm:ss')
                                    .format(p.timestamp),
                                style:
                                    const TextStyle(fontSize: 10))),
                        SizedBox(
                            width: 60,
                            child: Text(
                                p.value1.toStringAsFixed(1),
                                style:
                                    const TextStyle(fontSize: 10))),
                        SizedBox(
                            width: 60,
                            child: Text(
                                p.value2.toStringAsFixed(1),
                                style:
                                    const TextStyle(fontSize: 10))),
                        SizedBox(
                            width: 55,
                            child: Text(
                                p.value3.toStringAsFixed(1),
                                style:
                                    const TextStyle(fontSize: 10))),
                        SizedBox(
                            width: 55,
                            child: Text(
                                p.value4.toStringAsFixed(1),
                                style:
                                    const TextStyle(fontSize: 10))),
                        SizedBox(
                            width: 50,
                            child: Text(
                                p.value5.toStringAsFixed(1),
                                style:
                                    const TextStyle(fontSize: 10))),
                        SizedBox(
                            width: 55,
                            child: Text(
                                p.value6.toStringAsFixed(1),
                                style:
                                    const TextStyle(fontSize: 10))),
                        SizedBox(
                            width: 55,
                            child: Text(
                                p.value7.toStringAsFixed(1),
                                style:
                                    const TextStyle(fontSize: 10))),
                        SizedBox(
                            width: 45,
                            child: Text(
                                p.value8.toStringAsFixed(1),
                                style:
                                    const TextStyle(fontSize: 10))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
    }
    if (d.inMinutes > 0) {
      return "${d.inMinutes}m ${d.inSeconds.remainder(60)}s";
    }
    return "${d.inSeconds}s";
  }
}