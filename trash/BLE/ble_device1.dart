// import 'dart:async';
// import 'package:exg_visualizer/Libraries/Colors/Colors.dart';
// import 'package:exg_visualizer/Libraries/Fonts/text_styles.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:intl/intl.dart';

// // --------------------------------------------------------------------------
// // 1. UPDATED MAIN PAGE
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

//   // Stream controller to pass parsed data to the graph
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
//     _graphDataController.close(); // Close the stream
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

//       // Attempt to parse string to double for the graph
//       // Assuming the device sends ASCII numbers like "45.2" or "-12"
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
//             onPressed: _disconnect,
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
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildConnectionStatusCard(),
//           const SizedBox(height: 20),
//           _buildValueDisplayCard(),
//           const SizedBox(height: 20),
//           _buildRawDataCard(),
//           const Spacer(),
//           // Added Graph Button here
//           _buildGraphButton(),
//           const SizedBox(height: 12),
//           _buildActionButtons(),
//         ],
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

//   // ... (Keep existing _buildConnectionStatusCard, _buildValueDisplayCard, 
//   // _buildRawDataCard, _buildUuidInfoCard as they were in your code)
  
//   // Re-pasting helper widgets for completeness of the file context
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
//         gradient: const LinearGradient(
//           colors: [Color.fromRGBO(143, 0, 0, 1), Color.fromRGBO(220, 20, 60, 1)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Column(
//         children: [
//           Text("VALUE", style: TextStyle(color: Colors.white70)),
//           Text(
//             _displayValue,
//             style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRawDataCard() {
//       // Simplified for brevity, use your existing implementation
//       return Text("Raw Bytes: $_rawBytes");
//   }

//   Widget _buildActionButtons() {
//     return Row(
//       children: [
//         Expanded(
//           child: ElevatedButton(
//             onPressed: _isConnected ? _readValue : null,
//             child: Text("Read"),
//             style: ElevatedButton.styleFrom(
//                 backgroundColor: MainColors.primaryColor,
//                 foregroundColor: Colors.white,
//                 padding: EdgeInsets.symmetric(vertical: 16)),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: OutlinedButton(
//             onPressed: _disconnect,
//             child: Text("Disconnect"),
//             style: OutlinedButton.styleFrom(
//                 foregroundColor: Colors.red,
//                 side: BorderSide(color: Colors.red),
//                 padding: EdgeInsets.symmetric(vertical: 16)),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // --------------------------------------------------------------------------
// // 2. NEW RESPONSIVE GRAPH PAGE
// // --------------------------------------------------------------------------

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
//   // Data points for the chart
//   final List<FlSpot> _points = [];
  
//   // Controls
//   bool _isPaused = false;
  
//   // Time window configuration
//   final int _windowSize = 100; // How many points to keep in memory for drawing
//   double _minX = 0;
//   double _maxX = 1000;
  
//   late StreamSubscription<double> _subscription;

//   @override
//   void initState() {
//     super.initState();
//     _startListening();
//   }

//   void _startListening() {
//     _subscription = widget.dataStream.listen((value) {
//       if (!_isPaused) {
//         setState(() {
//           double timestamp = DateTime.now().millisecondsSinceEpoch.toDouble();
          
//           _points.add(FlSpot(timestamp, value));

//           // Manage Infinite Scroll: Remove old points to keep performance high
//           // but allow the graph to flow
//           if (_points.length > _windowSize) {
//             _points.removeAt(0);
//           }
//         });
//       }
//     });
//   }

//   void _restart() {
//     setState(() {
//       _points.clear();
//       _isPaused = false;
//     });
//   }

//   void _togglePause() {
//     setState(() {
//       _isPaused = !_isPaused;
//     });
//   }

//   @override
//   void dispose() {
//     _subscription.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Responsive logic for Tablet vs Mobile
//     bool isTablet = MediaQuery.of(context).size.width > 600;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Real-Time Graph", style: AppTextStyles.header),
//             Text(widget.deviceName, style: TextStyle(fontSize: 12, color: Colors.grey)),
//           ],
//         ),
//         backgroundColor: Colors.white,
//         elevation: 1,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             // The Graph
//             Expanded(
//               child: Container(
//                 padding: const EdgeInsets.only(right: 16, top: 24, bottom: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[50],
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: Colors.grey[200]!),
//                 ),
//                 child: _points.isEmpty
//                     ? Center(child: Text("Waiting for data..."))
//                     : LineChart(
//                         _buildChartData(isTablet),
//                       ),
//               ),
//             ),
            
//             const SizedBox(height: 24),
            
//             // Controls
//             _buildControls(isTablet),
//           ],
//         ),
//       ),
//     );
//   }

//   LineChartData _buildChartData(bool isTablet) {
//     // Calculate Min/Max X to create the scrolling effect
//     double currentX = _points.isNotEmpty ? _points.last.x : 0;
//     // Show last 5 seconds (5000ms) or adjust based on preference
//     double minX = currentX - 5000; 
    
//     return LineChartData(
//       gridData: FlGridData(
//         show: true,
//         drawVerticalLine: true,
//         getDrawingHorizontalLine: (value) => FlLine(
//           color: Colors.grey[300],
//           strokeWidth: 1,
//         ),
//         getDrawingVerticalLine: (value) => FlLine(
//           color: Colors.grey[300],
//           strokeWidth: 1,
//         ),
//       ),
//       titlesData: FlTitlesData(
//         show: true,
//         rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 30,
//             interval: 1000, // Every 1 second
//             getTitlesWidget: (value, meta) {
//               final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
//               // Format: Min:Sec:MS
//               return Padding(
//                 padding: const EdgeInsets.only(top: 8.0),
//                 child: Text(
//                   DateFormat('mm:ss').format(date),
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: isTablet ? 12 : 10,
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             interval: 20, // Ticks every 20 units
//             reservedSize: 45,
//             getTitlesWidget: (value, meta) {
//               return Text(
//                 value.toInt().toString(),
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontSize: isTablet ? 12 : 10,
//                   fontWeight: FontWeight.bold,
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//       borderData: FlBorderData(
//         show: true,
//         border: Border.all(color: const Color(0xff37434d).withOpacity(0.1)),
//       ),
//       // Set MinX and MaxX to create the scrolling window effect
//       minX: _points.length < 10 ? null : minX, // Don't scroll until we have some data
//       maxX: _points.length < 10 ? null : currentX,
//       // Allow Y axis to auto-scale, but ensure we see 0
//       baselineX: 0,
//       lineBarsData: [
//         LineChartBarData(
//           spots: _points,
//           isCurved: true,
//           color: MainColors.primaryColor,
//           barWidth: isTablet ? 3 : 2,
//           isStrokeCapRound: true,
//           dotData: FlDotData(show: false), // Hide dots for smoother line
//           belowBarData: BarAreaData(
//             show: true,
//             color: MainColors.primaryColor.withOpacity(0.1),
//             // Gradient for positive/negative visual
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                  MainColors.primaryColor.withOpacity(0.3),
//                  Colors.blue.withOpacity(0.3),
//               ]
//             )
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildControls(bool isTablet) {
//     double iconSize = isTablet ? 32 : 24;
//     double fontSize = isTablet ? 18 : 14;

//     return Container(
//       padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         borderRadius: BorderRadius.circular(50),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           // STOP (Clear and Pause)
//           IconButton(
//             onPressed: () {
//               setState(() {
//                 _points.clear();
//                 _isPaused = true;
//               });
//             },
//             icon: Icon(Icons.stop_circle_outlined, color: Colors.red, size: iconSize + 10),
//             tooltip: "Stop & Clear",
//           ),
          
//           // PAUSE / RESUME
//           ElevatedButton.icon(
//             onPressed: _togglePause,
//             icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, size: iconSize),
//             label: Text(_isPaused ? "RESUME" : "PAUSE", style: TextStyle(fontSize: fontSize)),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _isPaused ? Colors.green : Colors.orange,
//               foregroundColor: Colors.white,
//               padding: EdgeInsets.symmetric(
//                 horizontal: isTablet ? 40 : 20, 
//                 vertical: isTablet ? 20 : 12
//               ),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//             ),
//           ),

//           // RESTART
//           IconButton(
//             onPressed: _restart,
//             icon: Icon(Icons.refresh, color: Colors.blue, size: iconSize + 10),
//             tooltip: "Restart",
//           ),
//         ],
//       ),
//     );
//   }
// }



/////////////////



import 'dart:async';
import 'package:exg_visualizer/Libraries/Colors/Colors.dart'; // Assuming you have these files
import 'package:exg_visualizer/Libraries/Fonts/text_styles.dart'; // Assuming you have these files
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';

// --------------------------------------------------------------------------
// 1. MAIN PAGE (Largely Unchanged)
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
            onPressed: null, // Display only
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
      // decoration: BoxDecoration(
      //   gradient: const LinearGradient(
      //     colors: [Color(0xFF6A1B9A), Color(0xFFD81B60)],
      //     begin: Alignment.topLeft,
      //     end: Alignment.bottomRight,
      //   ),
      //   borderRadius: BorderRadius.circular(20),
      //   boxShadow: [
      //     BoxShadow(
      //         color: Colors.black.withOpacity(0.1),
      //         blurRadius: 10,
      //         offset: const Offset(0, 5))
      //   ],
      // ),
      color: MainColors.black,
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
// 2. NEW AND IMPROVED RESPONSIVE GRAPH PAGE
// --------------------------------------------------------------------------

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
  final List<FlSpot> _points = [];
  bool _isPaused = false;

  // --- CONFIGURATION ---
  /// The number of data points to keep in memory. This allows panning backwards.
  static const int _maxPointsToKeep = 300;
  /// The duration of data to display on the screen at once (in milliseconds).
  static const int _visibleDurationInMs = 10000; // 10 seconds

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _subscription = widget.dataStream.listen((value) {
      if (_isPaused) return;

      setState(() {
        final now = DateTime.now();
        final timestamp = now.millisecondsSinceEpoch.toDouble();

        _points.add(FlSpot(timestamp, value));

        // Keep the list from growing indefinitely
        if (_points.length > _maxPointsToKeep) {
          _points.removeAt(0);
        }
      });
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _clearChart() {
    setState(() {
      _points.clear();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
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
                style: AppTextStyles.regular.copyWith(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        backgroundColor: MainColors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: MainColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          // --- THE GRAPH ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.only(top: 24, bottom: 12, right: 20, left: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xfff3f6f9), // Light background for the chart
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: _points.isEmpty
                    ? Center(
                        child: Text("Waiting for data...", style: AppTextStyles.regular),
                      )
                    : LineChart(
                        _buildChartData(),
                        duration: Duration.zero, // No animation on rebuild
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // --- THE CONTROLS ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildControls(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    // Determine the visible window for the X-axis
    final double maxX = _points.isNotEmpty ? _points.last.x : 0;
    final double minX = maxX - _visibleDurationInMs;

    return LineChartData(
      // --- INTERACTIVITY & SCROLLING ---
      minX: minX,
      maxX: maxX,
      // The Y-axis will auto-scale by not setting minY/maxY. This handles negative values.
      clipData: const FlClipData.all(), // Prevents line from drawing outside the chart area

      // --- GRID ---
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 20, // Adjust based on your data's scale
        verticalInterval: 2000, // Grid line every 2 seconds
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey[300],
          strokeWidth: 0.8,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey[300],
          strokeWidth: 0.8,
        ),
      ),

      // --- AXIS TITLES ---
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 2000, // Title every 2 seconds
            getTitlesWidget: (value, meta) {
              // Convert timestamp back to DateTime for formatting
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              // Format: HH:mm:ss
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
            // interval: is dynamic by default, which is great for auto-scaling
            getTitlesWidget: (value, meta) {
              // Only show titles that aren't at the very top or bottom of the axis
              if (value == meta.max || value == meta.min) {
                return Container();
              }
              return Text(
                value.toInt().toString(),
                style: TextStyle(color: Colors.grey[700], fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              );
            },
          ),
        ),
      ),
      
      // --- BORDER ---
      borderData: FlBorderData(show: false),

      // --- LINE DATA ---
      lineBarsData: [
        LineChartBarData(
          spots: _points,
          isCurved: true,
          color: MainColors.primaryColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false), // Hide dots for a clean line
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
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[800],
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // CLEAR Button
          IconButton(
            onPressed: _clearChart,
            icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white70),
            tooltip: "Clear Chart",
          ),

          // PAUSE / RESUME Button
          ElevatedButton.icon(
            onPressed: _togglePause,
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, size: 28),
            label: Text(_isPaused ? "RESUME" : "PAUSE", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPaused ? Colors.green[600] : Colors.orange[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),

          // RESTART (Does the same as Clear in this context)
          IconButton(
            onPressed: _clearChart,
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: "Restart",
          ),
        ],
      ),
    );
  }
}