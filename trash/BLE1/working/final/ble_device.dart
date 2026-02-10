import 'package:exg_visualizer/BLE/csv_exporter.dart';
import 'dart:async';
import 'package:exg_visualizer/BLE/db.dart';
import 'package:exg_visualizer/Libraries/Colors/Colors.dart';
import 'package:exg_visualizer/Libraries/Fonts/text_styles.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';

// ✅ Data class to hold 4 values
class QuadChannelData {
  final double value1;
  final double value2;
  final double value3;
  final double value4;
  final DateTime timestamp;

  QuadChannelData({
    required this.value1,
    required this.value2,
    required this.value3,
    required this.value4,
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
  static const String CHARACTERISTIC_UUID = "abcdef01-1234-1234-1234-abcdefabcdef";

  BluetoothCharacteristic? _characteristic;
  StreamSubscription<List<int>>? _notificationSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  final StreamController<QuadChannelData> _graphDataController =
      StreamController<QuadChannelData>.broadcast();

  String _displayValue1 = "--";
  String _displayValue2 = "--";
  String _displayValue3 = "--";
  String _displayValue4 = "--";
  List<int> _rawBytes = [];
  String _rawString = "";
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
            _displayValue1 = "--";
            _displayValue2 = "--";
            _displayValue3 = "--";
            _displayValue4 = "--";
            _rawBytes = [];
            _rawString = "";
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

      print("📡 Discovered ${services.length} services");

      for (BluetoothService service in services) {
        print("  Service: ${service.uuid}");
        
        if (service.uuid.toString().toLowerCase() ==
            SERVICE_UUID.toLowerCase()) {
          print("  ✅ Found target service!");
          
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            print("    Characteristic: ${characteristic.uuid}");
            print("    Properties: notify=${characteristic.properties.notify}, read=${characteristic.properties.read}");
            
            if (characteristic.uuid.toString().toLowerCase() ==
                CHARACTERISTIC_UUID.toLowerCase()) {
              targetCharacteristic = characteristic;
              print("    ✅ Found target characteristic!");
              break;
            }
          }
        }
        if (targetCharacteristic != null) break;
      }

      if (targetCharacteristic != null) {
        _characteristic = targetCharacteristic;
        
        if (_characteristic!.properties.notify) {
          await _subscribeToNotifications();
        }
        
        if (_characteristic!.properties.read) {
          await _readValue();
        }
      } else {
        setState(() {
          _errorMessage = "Characteristic not found.\nService UUID: $SERVICE_UUID\nChar UUID: $CHARACTERISTIC_UUID";
        });
        print("❌ Characteristic not found");
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
      _showSnackBar("✅ Subscribed to notifications");
      print("✅ Subscribed to notifications successfully");
    } catch (e) {
      _showSnackBar("Error subscribing: $e");
      print("❌ Subscribe error: $e");
    }
  }

  void _updateValue(List<int> bytes) {
    if (!mounted || bytes.isEmpty) return;

    String stringVal = String.fromCharCodes(bytes).trim();
    
    print("📥 Received: $stringVal (${bytes.length} bytes)");

    double? val1;
    double? val2;
    double? val3;
    double? val4;

    if (stringVal.contains(',')) {
      List<String> parts = stringVal.split(',');
      
      if (parts.length >= 4) {
        val1 = double.tryParse(parts[0].trim());
        val2 = double.tryParse(parts[1].trim());
        val3 = double.tryParse(parts[2].trim());
        val4 = double.tryParse(parts[3].trim());
      } else if (parts.length >= 2) {
        val1 = double.tryParse(parts[0].trim());
        val2 = double.tryParse(parts[1].trim());
        val3 = val1;
        val4 = val2;
      }
    } else {
      val1 = double.tryParse(stringVal);
      val2 = val1;
      val3 = val1;
      val4 = val1;
    }

    if (val1 != null && val2 != null && val3 != null && val4 != null) {
      _graphDataController.add(QuadChannelData(
        value1: val1,
        value2: val2,
        value3: val3,
        value4: val4,
        timestamp: DateTime.now(),
      ));
    }

    setState(() {
      _rawBytes = bytes;
      _rawString = stringVal;
      _displayValue1 = val1?.toStringAsFixed(1) ?? "--";
      _displayValue2 = val2?.toStringAsFixed(1) ?? "--";
      _displayValue3 = val3?.toStringAsFixed(1) ?? "--";
      _displayValue4 = val4?.toStringAsFixed(1) ?? "--";
    });
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
            
            _buildQuadValueDisplayCard(),
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
              Text("Error", style: AppTextStyles.bold.copyWith(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_errorMessage, style: AppTextStyles.regular.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildGraphButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isConnected && _errorMessage.isEmpty ? _openGraphPage : null,
        icon: const Icon(Icons.show_chart, size: 24),
        label: Text("OPEN REAL-TIME GRAPH", style: AppTextStyles.bold.copyWith(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blueGrey[800],
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        label: Text("VIEW SAVED RECORDINGS", style: AppTextStyles.bold.copyWith(fontSize: 16)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blueGrey[800],
          side: BorderSide(color: Colors.blueGrey[800]!, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isConnected ? Colors.green : Colors.red, width: 1),
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
                    "Receiving 4-channel data",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuadValueDisplayCard() {
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
            style: AppTextStyles.regular.copyWith(color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildChannelDisplay("CH 1", _displayValue1, Colors.blue),
              Container(height: 60, width: 1, color: Colors.white.withOpacity(0.3)),
              _buildChannelDisplay("CH 2", _displayValue2, Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildChannelDisplay("CH 3", _displayValue3, Colors.green),
              Container(height: 60, width: 1, color: Colors.white.withOpacity(0.3)),
              _buildChannelDisplay("CH 4", _displayValue4, Colors.purple),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: AppTextStyles.bold.copyWith(color: color.withOpacity(0.9), fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.header.copyWith(color: color.withOpacity(0.9), fontSize: 28),
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
            _rawDataRow("String", _rawString.isEmpty ? "Waiting..." : _rawString),
            const SizedBox(height: 8),
            _rawDataRow("Bytes", _rawBytes.isEmpty ? "[]" : _rawBytes.toString()),
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
          child: Text("$label:", style: AppTextStyles.bold.copyWith(fontSize: 12, color: Colors.grey[600])),
        ),
        Expanded(
          child: Text(value, style: AppTextStyles.regular.copyWith(fontSize: 12, fontFamily: 'monospace')),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isConnected && _characteristic != null ? _readValue : null,
            child: const Text("Read Value"),
            style: ElevatedButton.styleFrom(
              backgroundColor: MainColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// LIVE EXG CHART PAGE - SIMPLIFIED WITH GRAPH SCROLLING
// =============================================================================

class LiveExgChartPage extends StatefulWidget {
  final Stream<QuadChannelData> dataStream;
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
  late StreamSubscription<QuadChannelData> _subscription;

  // Display points for all 4 channels
  final List<FlSpot> _displayPoints1 = [];
  final List<FlSpot> _displayPoints2 = [];
  final List<FlSpot> _displayPoints3 = [];
  final List<FlSpot> _displayPoints4 = [];

  // ALL data points stored for saving
  final List<DataPoint> _allDataPoints = [];

  // Channel visibility toggles
  bool _showChannel1 = true;
  bool _showChannel2 = true;
  bool _showChannel3 = true;
  bool _showChannel4 = true;

  // ✅ SCROLLING CONTROL
  bool _isLiveMode = true;
  double? _viewMinX;
  double? _viewMaxX;
  static const double _visibleDuration = 10000; // Fixed 10 seconds visible window
  
  // Recording start time
  DateTime? _recordingStartTime;

  // Latest values for legend
  double _latestValue1 = 0;
  double _latestValue2 = 0;
  double _latestValue3 = 0;
  double _latestValue4 = 0;

  // ✅ INCREASED MAX POINTS TO PREVENT DATA LOSS
  static const int _maxDisplayPoints = 5000;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Timer? _durationTimer;

  // Channel colors
  static const Color _channel1Color = Colors.blue;
  static const Color _channel2Color = Colors.orange;
  static const Color _channel3Color = Colors.green;
  static const Color _channel4Color = Colors.purple;

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
        timestamp: now,
        processedValue1: data.value1,
        processedValue2: data.value2,
        processedValue3: data.value3,
        processedValue4: data.value4,
      ));

      setState(() {
        final timestamp = now.millisecondsSinceEpoch.toDouble();

        _displayPoints1.add(FlSpot(timestamp, data.value1));
        _displayPoints2.add(FlSpot(timestamp, data.value2));
        _displayPoints3.add(FlSpot(timestamp, data.value3));
        _displayPoints4.add(FlSpot(timestamp, data.value4));

        _latestValue1 = data.value1;
        _latestValue2 = data.value2;
        _latestValue3 = data.value3;
        _latestValue4 = data.value4;

        // Keep display points manageable but with more history
        while (_displayPoints1.length > _maxDisplayPoints) {
          _displayPoints1.removeAt(0);
          _displayPoints2.removeAt(0);
          _displayPoints3.removeAt(0);
          _displayPoints4.removeAt(0);
        }
      });
    });
  }

  // ✅ SCROLL HANDLING - Swipe on graph to scroll through history
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_displayPoints1.isEmpty) return;

    final chartWidth = MediaQuery.of(context).size.width - 80;
    final dragRatio = details.delta.dx / chartWidth;
    final shift = -dragRatio * _visibleDuration;

    final dataMinX = _displayPoints1.first.x;
    final dataMaxX = _displayPoints1.last.x;

    setState(() {
      if (_isLiveMode) {
        // First drag - initialize view position
        _viewMaxX = dataMaxX;
        _viewMinX = dataMaxX - _visibleDuration;
        _isLiveMode = false;
      }

      double newMinX = (_viewMinX ?? dataMinX) + shift;
      double newMaxX = (_viewMaxX ?? dataMaxX) + shift;

      // Clamp to data bounds
      if (newMinX < dataMinX) {
        newMinX = dataMinX;
        newMaxX = newMinX + _visibleDuration;
      }
      if (newMaxX > dataMaxX) {
        newMaxX = dataMaxX;
        newMinX = newMaxX - _visibleDuration;
        // If we scrolled to the end, go back to live mode
        _isLiveMode = true;
      } else {
        _isLiveMode = false;
      }

      _viewMinX = newMinX;
      _viewMaxX = newMaxX;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    // Optional: Add momentum scrolling or snap behavior here
  }

  // ✅ DOUBLE TAP TO RESET TO LIVE
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
      _allDataPoints.clear();
      _recordingStartTime = DateTime.now();
      _isLiveMode = true;
      _viewMinX = null;
      _viewMaxX = null;
      _latestValue1 = 0;
      _latestValue2 = 0;
      _latestValue3 = 0;
      _latestValue4 = 0;
    });
  }

  Future<void> _saveChartData() async {
    if (_allDataPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No data to save!"), backgroundColor: Colors.orange),
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
                  MaterialPageRoute(builder: (context) => const SavedRecordingsPage()),
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
          SnackBar(content: Text("Error saving: $e"), backgroundColor: Colors.red),
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
                style: AppTextStyles.regular.copyWith(fontSize: 12, color: Colors.grey[600])),
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
              if (value == 'restart') _showRestartConfirmation();
              else if (value == 'save') _saveChartData();
              else if (value == 'view_saved') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedRecordingsPage()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'restart', child: Row(children: [Icon(Icons.refresh, color: Colors.blue), SizedBox(width: 8), Text('Restart')])),
              const PopupMenuItem(value: 'save', child: Row(children: [Icon(Icons.save_alt, color: Colors.green), SizedBox(width: 8), Text('Save Data')])),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'view_saved', child: Row(children: [Icon(Icons.folder_open, color: Colors.orange), SizedBox(width: 8), Text('View Saved')])),
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
          
          // ✅ SCROLLABLE CHART - Swipe left/right to scroll
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                onDoubleTap: _onDoubleTap,
                child: Container(
                  padding: const EdgeInsets.only(top: 24, bottom: 12, right: 20, left: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xfff3f6f9),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: _hasNoData()
                      ? _buildEmptyChart()
                      : Stack(
                          children: [
                            LineChart(_buildChartData(), duration: Duration.zero),
                            
                            // ✅ LIVE INDICATOR (Green text) OR GO LIVE BUTTON (Red)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: _isLiveMode
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.green, width: 1),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.circle, color: Colors.green, size: 8),
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
                                  // ✅ RED "GO LIVE" BUTTON when viewing history
                                  : ElevatedButton.icon(
                                      onPressed: _resetToLive,
                                      icon: const Icon(Icons.skip_next, size: 16),
                                      label: const Text("GO LIVE"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
          Text("Make sure BLE device is sending data", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  bool _hasNoData() {
    return _displayPoints1.isEmpty && _displayPoints2.isEmpty && _displayPoints3.isEmpty && _displayPoints4.isEmpty;
  }

  Widget _buildChannelToggles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildChannelChip("CH 1", _showChannel1, _channel1Color, (v) => setState(() => _showChannel1 = v)),
          _buildChannelChip("CH 2", _showChannel2, _channel2Color, (v) => setState(() => _showChannel2 = v)),
          _buildChannelChip("CH 3", _showChannel3, _channel3Color, (v) => setState(() => _showChannel3 = v)),
          _buildChannelChip("CH 4", _showChannel4, _channel4Color, (v) => setState(() => _showChannel4 = v)),
        ],
      ),
    );
  }

  Widget _buildChannelChip(String label, bool selected, Color color, Function(bool) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: color,
      labelStyle: TextStyle(color: selected ? color : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          if (_showChannel1) _buildLegendItem("CH1", _latestValue1, _channel1Color),
          if (_showChannel2) _buildLegendItem("CH2", _latestValue2, _channel2Color),
          if (_showChannel3) _buildLegendItem("CH3", _latestValue3, _channel3Color),
          if (_showChannel4) _buildLegendItem("CH4", _latestValue4, _channel4Color),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 3, color: color),
        const SizedBox(width: 6),
        Text("$label: ${value.toStringAsFixed(1)}", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatsBar() {
    final duration = _recordingStartTime != null ? DateTime.now().difference(_recordingStartTime!) : Duration.zero;

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
          _statItem(icon: Icons.timer_outlined, label: "Duration", value: _formatDuration(duration)),
          Container(height: 30, width: 1, color: Colors.grey[300]),
          _statItem(icon: Icons.data_array, label: "Points", value: _allDataPoints.length.toString()),
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

  Widget _statItem({required IconData icon, required String label, required String value, Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: valueColor ?? MainColors.primaryColor),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: valueColor ?? MainColors.black)),
            Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return "$hours:$minutes:$seconds";
    return "$minutes:$seconds";
  }

  void _showRestartConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Restart Recording?"),
        content: Text("This will clear ${_allDataPoints.length} recorded data points."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
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

  // ✅ CHART DATA WITH DYNAMIC SYMMETRIC Y-AXIS
  LineChartData _buildChartData() {
    List<FlSpot> referencePoints = _displayPoints1.isNotEmpty
        ? _displayPoints1
        : _displayPoints2.isNotEmpty
            ? _displayPoints2
            : _displayPoints3.isNotEmpty
                ? _displayPoints3
                : _displayPoints4;

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

    // ✅ CALCULATE DYNAMIC SYMMETRIC Y-AXIS
    double maxAbsValue = 1; // Default minimum range
    
    // Get all visible points
    List<FlSpot> allVisiblePoints = [];
    if (_showChannel1) {
      allVisiblePoints.addAll(_displayPoints1.where((p) => p.x >= minX && p.x <= maxX));
    }
    if (_showChannel2) {
      allVisiblePoints.addAll(_displayPoints2.where((p) => p.x >= minX && p.x <= maxX));
    }
    if (_showChannel3) {
      allVisiblePoints.addAll(_displayPoints3.where((p) => p.x >= minX && p.x <= maxX));
    }
    if (_showChannel4) {
      allVisiblePoints.addAll(_displayPoints4.where((p) => p.x >= minX && p.x <= maxX));
    }

    // Find the maximum absolute value from visible data
    for (var point in allVisiblePoints) {
      if (point.y.abs() > maxAbsValue) {
        maxAbsValue = point.y.abs();
      }
    }

    // Add 10% padding to the max value
    maxAbsValue = maxAbsValue * 1.1;

    final double minY = -maxAbsValue;
    final double maxY = maxAbsValue;

    final double xAxisInterval = 2000; // 2 seconds interval

    List<LineChartBarData> lineBars = [];

    if (_showChannel1 && _displayPoints1.isNotEmpty) {
      lineBars.add(_createLineBar(_getVisiblePoints(_displayPoints1, minX, maxX), _channel1Color));
    }
    if (_showChannel2 && _displayPoints2.isNotEmpty) {
      lineBars.add(_createLineBar(_getVisiblePoints(_displayPoints2, minX, maxX), _channel2Color));
    }
    if (_showChannel3 && _displayPoints3.isNotEmpty) {
      lineBars.add(_createLineBar(_getVisiblePoints(_displayPoints3, minX, maxX), _channel3Color));
    }
    if (_showChannel4 && _displayPoints4.isNotEmpty) {
      lineBars.add(_createLineBar(_getVisiblePoints(_displayPoints4, minX, maxX), _channel4Color));
    }

    return LineChartData(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: maxAbsValue / 4, // Dynamic interval based on data
        verticalInterval: xAxisInterval,
        getDrawingHorizontalLine: (value) {
          // Make the zero line more prominent
          if (value.abs() < 0.001) {
            return FlLine(color: Colors.grey[600]!, strokeWidth: 1.5);
          }
          return FlLine(color: Colors.grey[300]!, strokeWidth: 0.8);
        },
        getDrawingVerticalLine: (value) => FlLine(color: Colors.grey[300]!, strokeWidth: 0.8),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: xAxisInterval,
            getTitlesWidget: (value, meta) {
              final remainder = value % xAxisInterval;
              if (remainder.abs() > 100 && (xAxisInterval - remainder.abs()) > 100) {
                return const SizedBox.shrink();
              }
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return SideTitleWidget(
                meta: meta,
                space: 8.0,
                child: Text(DateFormat('HH:mm:ss').format(date), style: TextStyle(color: Colors.grey[700], fontSize: 10)),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              // Don't show labels at the very edges
              if (value == meta.max || value == meta.min) return const SizedBox.shrink();
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    color: value.abs() < 0.001 ? Colors.grey[800] : Colors.grey[600],
                    fontSize: 10,
                    fontWeight: value.abs() < 0.001 ? FontWeight.bold : FontWeight.normal,
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
              final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
              final channelInfo = _getChannelInfo(spot.barIndex);
              return LineTooltipItem(
                '${channelInfo.label}: ${spot.y.toStringAsFixed(1)}\n${DateFormat('HH:mm:ss').format(date)}',
                TextStyle(color: channelInfo.color.withOpacity(0.9), fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  // ✅ Get visible points within the X range
  List<FlSpot> _getVisiblePoints(List<FlSpot> allPoints, double minX, double maxX) {
    // Include points slightly outside the range for smooth line drawing
    final buffer = (maxX - minX) * 0.1;
    return allPoints.where((p) => p.x >= (minX - buffer) && p.x <= (maxX + buffer)).toList();
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
    if (_showChannel1) visibleChannels.add((label: "CH1", color: _channel1Color));
    if (_showChannel2) visibleChannels.add((label: "CH2", color: _channel2Color));
    if (_showChannel3) visibleChannels.add((label: "CH3", color: _channel3Color));
    if (_showChannel4) visibleChannels.add((label: "CH4", color: _channel4Color));
    if (barIndex < visibleChannels.length) return visibleChannels[barIndex];
    return (label: "CH?", color: Colors.grey);
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
          SnackBar(content: Text("Error loading sessions: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteSession(RecordingSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Recording?"),
        content: Text("Delete recording with ${session.dataCount} data points?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
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
          IconButton(icon: const Icon(Icons.refresh, color: MainColors.black), onPressed: _loadSessions),
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
          Text("No saved recordings", style: AppTextStyles.bold.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text("Start recording from the graph page", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
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
        itemBuilder: (context, index) => _buildSessionCard(_sessions[index]),
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
          Navigator.push(context, MaterialPageRoute(builder: (context) => RecordingDetailPage(session: session)))
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
                    child: Icon(Icons.bluetooth, color: MainColors.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.deviceName, style: AppTextStyles.bold.copyWith(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(dateFormat.format(session.startTime), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                  _infoItem(Icons.access_time, "Start", timeFormat.format(session.startTime)),
                  _infoItem(Icons.timer, "Duration", session.duration != null ? _formatDuration(session.duration!) : "--"),
                  _infoItem(Icons.data_array, "Points", session.dataCount.toString()),
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
    if (d.inMinutes > 0) return "${d.inMinutes}m ${d.inSeconds.remainder(60)}s";
    return "${d.inSeconds}s";
  }
}

// =============================================================================
// RECORDING DETAIL PAGE
// =============================================================================

// class RecordingDetailPage extends StatefulWidget {
//   final RecordingSession session;
//   const RecordingDetailPage({Key? key, required this.session}) : super(key: key);

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

//   double? _visibleMinX;
//   double? _visibleMaxX;

//   static const Color _channel1Color = Colors.blue;
//   static const Color _channel2Color = Colors.orange;
//   static const Color _channel3Color = Colors.green;
//   static const Color _channel4Color = Colors.purple;

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     setState(() => _isLoading = true);
//     try {
//       final dataPoints = await _dbHelper.getSessionDataPoints(widget.session.id!);
//       final stats = await _dbHelper.getSessionStats(widget.session.id!);

//       setState(() {
//         _dataPoints = dataPoints;
//         _stats = stats;
//         _isLoading = false;

//         if (_dataPoints.isNotEmpty) {
//           _visibleMinX = _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
//           _visibleMaxX = _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
//         }
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: MainColors.white,
//       appBar: AppBar(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Recording Details", style: AppTextStyles.header),
//             Text(widget.session.deviceName, style: AppTextStyles.regular.copyWith(fontSize: 12, color: Colors.grey[600])),
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
//             icon: Icon(Icons.file_download, color: _dataPoints.isNotEmpty ? Colors.green : Colors.grey),
//             tooltip: "Export CSV",
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _dataPoints.isEmpty
//               ? Center(child: Text("No data", style: AppTextStyles.bold))
//               : SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       _buildSessionInfo(),
//                       _buildStatsCard(),
//                       _buildExportButton(),
//                       const SizedBox(height: 16),
//                       _buildChannelToggles(),
//                       const SizedBox(height: 16),
//                       _buildChartSection(),
//                       _buildDataTable(),
//                       const SizedBox(height: 24),
//                     ],
//                   ),
//                 ),
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
//             Text("Recorded: ${dateFormat.format(widget.session.startTime)}", style: AppTextStyles.regular),
//           ]),
//           if (widget.session.duration != null) ...[
//             const SizedBox(height: 8),
//             Row(children: [
//               const Icon(Icons.timer, size: 18),
//               const SizedBox(width: 8),
//               Text("Duration: ${_formatDuration(widget.session.duration!)}", style: AppTextStyles.regular),
//             ]),
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
//         boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4)],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text("Statistics", style: AppTextStyles.bold),
//           const SizedBox(height: 12),
//           _buildChannelStats("Channel 1", _channel1Color, 'min_value1', 'max_value1', 'avg_value1'),
//           const SizedBox(height: 8),
//           _buildChannelStats("Channel 2", _channel2Color, 'min_value2', 'max_value2', 'avg_value2'),
//           const SizedBox(height: 8),
//           _buildChannelStats("Channel 3", _channel3Color, 'min_value3', 'max_value3', 'avg_value3'),
//           const SizedBox(height: 8),
//           _buildChannelStats("Channel 4", _channel4Color, 'min_value4', 'max_value4', 'avg_value4'),
//         ],
//       ),
//     );
//   }

//   Widget _buildChannelStats(String name, Color color, String minKey, String maxKey, String avgKey) {
//     return Row(
//       children: [
//         Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
//         const SizedBox(width: 8),
//         Expanded(
//           child: Text(
//             "$name: Min ${_formatStat(_stats[minKey])} | Max ${_formatStat(_stats[maxKey])} | Avg ${_formatStat(_stats[avgKey])}",
//             style: const TextStyle(fontSize: 12),
//           ),
//         ),
//       ],
//     );
//   }

//   String _formatStat(dynamic v) => v != null ? (v as num).toStringAsFixed(1) : "N/A";

//   Widget _buildExportButton() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: SizedBox(
//         width: double.infinity,
//         child: ElevatedButton.icon(
//           onPressed: _exportToCSV,
//           icon: const Icon(Icons.file_download),
//           label: const Text("EXPORT TO CSV"),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.green[600],
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildChannelToggles() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Wrap(
//         spacing: 8,
//         alignment: WrapAlignment.center,
//         children: [
//           FilterChip(label: const Text("CH 1"), selected: _showChannel1, onSelected: (v) => setState(() => _showChannel1 = v), selectedColor: _channel1Color.withOpacity(0.3)),
//           FilterChip(label: const Text("CH 2"), selected: _showChannel2, onSelected: (v) => setState(() => _showChannel2 = v), selectedColor: _channel2Color.withOpacity(0.3)),
//           FilterChip(label: const Text("CH 3"), selected: _showChannel3, onSelected: (v) => setState(() => _showChannel3 = v), selectedColor: _channel3Color.withOpacity(0.3)),
//           FilterChip(label: const Text("CH 4"), selected: _showChannel4, onSelected: (v) => setState(() => _showChannel4 = v), selectedColor: _channel4Color.withOpacity(0.3)),
//         ],
//       ),
//     );
//   }

//   Widget _buildChartSection() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Container(
//         height: 300,
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           color: const Color(0xfff3f6f9),
//           border: Border.all(color: Colors.grey[300]!),
//         ),
//         child: LineChart(_buildChartData()),
//       ),
//     );
//   }

//   LineChartData _buildChartData() {
//     List<LineChartBarData> lineBars = [];

//     // Calculate dynamic symmetric Y-axis
//     double maxAbsValue = 1;
//     for (var p in _dataPoints) {
//       if (_showChannel1 && p.value1.abs() > maxAbsValue) maxAbsValue = p.value1.abs();
//       if (_showChannel2 && p.value2.abs() > maxAbsValue) maxAbsValue = p.value2.abs();
//       if (_showChannel3 && p.value3.abs() > maxAbsValue) maxAbsValue = p.value3.abs();
//       if (_showChannel4 && p.value4.abs() > maxAbsValue) maxAbsValue = p.value4.abs();
//     }
//     maxAbsValue = maxAbsValue * 1.1;

//     if (_showChannel1) {
//       lineBars.add(LineChartBarData(
//         spots: _dataPoints.map((p) => FlSpot(p.timestamp.millisecondsSinceEpoch.toDouble(), p.value1)).toList(),
//         isCurved: true, color: _channel1Color, barWidth: 2, dotData: const FlDotData(show: false),
//       ));
//     }
//     if (_showChannel2) {
//       lineBars.add(LineChartBarData(
//         spots: _dataPoints.map((p) => FlSpot(p.timestamp.millisecondsSinceEpoch.toDouble(), p.value2)).toList(),
//         isCurved: true, color: _channel2Color, barWidth: 2, dotData: const FlDotData(show: false),
//       ));
//     }
//     if (_showChannel3) {
//       lineBars.add(LineChartBarData(
//         spots: _dataPoints.map((p) => FlSpot(p.timestamp.millisecondsSinceEpoch.toDouble(), p.value3)).toList(),
//         isCurved: true, color: _channel3Color, barWidth: 2, dotData: const FlDotData(show: false),
//       ));
//     }
//     if (_showChannel4) {
//       lineBars.add(LineChartBarData(
//         spots: _dataPoints.map((p) => FlSpot(p.timestamp.millisecondsSinceEpoch.toDouble(), p.value4)).toList(),
//         isCurved: true, color: _channel4Color, barWidth: 2, dotData: const FlDotData(show: false),
//       ));
//     }

//     return LineChartData(
//       minX: _visibleMinX,
//       maxX: _visibleMaxX,
//       minY: -maxAbsValue,
//       maxY: maxAbsValue,
//       lineBarsData: lineBars,
//       gridData: FlGridData(
//         show: true,
//         horizontalInterval: maxAbsValue / 4,
//         getDrawingHorizontalLine: (value) {
//           if (value.abs() < 0.001) {
//             return FlLine(color: Colors.grey[600]!, strokeWidth: 1.5);
//           }
//           return FlLine(color: Colors.grey[300]!, strokeWidth: 0.8);
//         },
//       ),
//       titlesData: FlTitlesData(
//         rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 30,
//             getTitlesWidget: (value, meta) {
//               final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
//               return Text(DateFormat('mm:ss').format(date), style: const TextStyle(fontSize: 10));
//             },
//           ),
//         ),
//         leftTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 50,
//             getTitlesWidget: (value, meta) {
//               if (value == meta.max || value == meta.min) return const SizedBox.shrink();
//               return Text(
//                 value.toStringAsFixed(1),
//                 style: TextStyle(
//                   fontSize: 10,
//                   color: value.abs() < 0.001 ? Colors.grey[800] : Colors.grey[600],
//                   fontWeight: value.abs() < 0.001 ? FontWeight.bold : FontWeight.normal,
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//       borderData: FlBorderData(show: false),
//     );
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
//             child: Text("Data Points (${displayPoints.length}/${_dataPoints.length})", style: AppTextStyles.bold),
//           ),
//           const Divider(height: 1),
//           ...displayPoints.asMap().entries.map((e) {
//             final p = e.value;
//             return Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               color: e.key % 2 == 0 ? Colors.white : Colors.grey[50],
//               child: Row(
//                 children: [
//                   Expanded(child: Text("${e.key + 1}", style: const TextStyle(fontSize: 11))),
//                   Expanded(flex: 2, child: Text(DateFormat('HH:mm:ss').format(p.timestamp), style: const TextStyle(fontSize: 11))),
//                   Expanded(child: Text(p.value1.toStringAsFixed(1), style: const TextStyle(fontSize: 11))),
//                   Expanded(child: Text(p.value2.toStringAsFixed(1), style: const TextStyle(fontSize: 11))),
//                   Expanded(child: Text(p.value3.toStringAsFixed(1), style: const TextStyle(fontSize: 11))),
//                   Expanded(child: Text(p.value4.toStringAsFixed(1), style: const TextStyle(fontSize: 11))),
//                 ],
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   String _formatDuration(Duration d) {
//     if (d.inHours > 0) return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
//     if (d.inMinutes > 0) return "${d.inMinutes}m ${d.inSeconds.remainder(60)}s";
//     return "${d.inSeconds}s";
//   }
// }


// =============================================================================
// RECORDING DETAIL PAGE - WITH ZOOM CONTROLS (RESTORED)
// =============================================================================

class RecordingDetailPage extends StatefulWidget {
  final RecordingSession session;
  const RecordingDetailPage({Key? key, required this.session}) : super(key: key);

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

  // ✅ ZOOM & SCROLL CONTROL
  double? _viewMinX;
  double? _viewMaxX;
  double _visibleDuration = 10000; // 10 seconds visible window
  double _lastScale = 1.0;
  bool _isFullView = true; // Start with full view of all data

  static const double _minVisibleDuration = 2000;  // 2 seconds min
  static const double _maxVisibleDuration = 60000; // 60 seconds max

  static const Color _channel1Color = Colors.blue;
  static const Color _channel2Color = Colors.orange;
  static const Color _channel3Color = Colors.green;
  static const Color _channel4Color = Colors.purple;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dataPoints = await _dbHelper.getSessionDataPoints(widget.session.id!);
      final stats = await _dbHelper.getSessionStats(widget.session.id!);

      setState(() {
        _dataPoints = dataPoints;
        _stats = stats;
        _isLoading = false;

        if (_dataPoints.isNotEmpty) {
          _viewMinX = _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
          _viewMaxX = _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
          _visibleDuration = _viewMaxX! - _viewMinX!;
          _isFullView = true;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
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

  // ✅ SCROLL HANDLING
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_dataPoints.isEmpty) return;

    final chartWidth = MediaQuery.of(context).size.width - 80;
    final dragRatio = details.delta.dx / chartWidth;
    final currentRange = (_viewMaxX ?? 0) - (_viewMinX ?? 0);
    final shift = -dragRatio * currentRange;

    final dataMinX = _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
    final dataMaxX = _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();

    setState(() {
      _isFullView = false;
      
      double newMinX = (_viewMinX ?? dataMinX) + shift;
      double newMaxX = (_viewMaxX ?? dataMaxX) + shift;

      // Clamp to data bounds
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

  // ✅ PINCH TO ZOOM
  void _onScaleStart(ScaleStartDetails details) {
    _lastScale = 1.0;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_dataPoints.isEmpty) return;

    // Handle pinch zoom
    if (details.scale != 1.0) {
      final scaleDiff = details.scale / _lastScale;
      _lastScale = details.scale;

      setState(() {
        _isFullView = false;
        
        final currentRange = (_viewMaxX ?? 0) - (_viewMinX ?? 0);
        double newRange = currentRange / scaleDiff;
        newRange = newRange.clamp(_minVisibleDuration, _maxVisibleDuration);
        
        // Adjust view to zoom from center
        if (_viewMinX != null && _viewMaxX != null) {
          final center = (_viewMinX! + _viewMaxX!) / 2;
          _viewMinX = center - newRange / 2;
          _viewMaxX = center + newRange / 2;
          
          // Clamp to data bounds
          final dataMinX = _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
          final dataMaxX = _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
          
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
    
    // Handle pan (single finger drag)
    if (details.scale == 1.0 && details.focalPointDelta.dx != 0) {
      _onHorizontalDragUpdate(
        DragUpdateDetails(
          globalPosition: details.focalPoint,
          delta: details.focalPointDelta,
        ),
      );
    }
  }

  // ✅ ZOOM CONTROLS
  void _zoomIn() {
    if (_dataPoints.isEmpty) return;
    
    setState(() {
      _isFullView = false;
      
      final currentRange = (_viewMaxX ?? 0) - (_viewMinX ?? 0);
      double newRange = (currentRange / 1.5).clamp(_minVisibleDuration, _maxVisibleDuration);
      
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
      final dataMinX = _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
      final dataMaxX = _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
      final totalRange = dataMaxX - dataMinX;
      
      double newRange = (currentRange * 1.5).clamp(_minVisibleDuration, totalRange);
      
      final center = ((_viewMinX ?? 0) + (_viewMaxX ?? 0)) / 2;
      _viewMinX = center - newRange / 2;
      _viewMaxX = center + newRange / 2;
      
      _clampToDataBounds();
      _visibleDuration = newRange;
      
      // Check if we're showing full view
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
    
    final dataMinX = _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
    final dataMaxX = _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
    final currentRange = (_viewMaxX ?? dataMaxX) - (_viewMinX ?? dataMinX);
    
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
      _viewMinX = _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
      _viewMaxX = _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
      _visibleDuration = _viewMaxX! - _viewMinX!;
      _isFullView = true;
    });
  }

  String _getViewTimeRange() {
    if (_viewMinX == null || _viewMaxX == null) return "";
    final startTime = DateTime.fromMillisecondsSinceEpoch(_viewMinX!.toInt());
    final endTime = DateTime.fromMillisecondsSinceEpoch(_viewMaxX!.toInt());
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
            Text(widget.session.deviceName, style: AppTextStyles.regular.copyWith(fontSize: 12, color: Colors.grey[600])),
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
            icon: Icon(Icons.file_download, color: _dataPoints.isNotEmpty ? Colors.green : Colors.grey),
            tooltip: "Export CSV",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dataPoints.isEmpty
              ? Center(child: Text("No data", style: AppTextStyles.bold))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSessionInfo(),
                      _buildStatsCard(),
                      _buildExportButton(),
                      const SizedBox(height: 16),
                      _buildChannelToggles(),
                      const SizedBox(height: 8),
                      
                      // ✅ ZOOM CONTROLS
                      _buildZoomControls(),
                      const SizedBox(height: 8),
                      
                      // ✅ SCROLLABLE CHART
                      _buildChartSection(),
                      
                      // ✅ TIMELINE SCRUBBER
                      // if (_dataPoints.isNotEmpty) _buildTimelineScrubber(),
                      // const SizedBox(height: 8),
                      
                      // _buildScrollHint(),
                      // const SizedBox(height: 16),
                      
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
          // Zoom out
          IconButton(
            onPressed: _zoomOut,
            icon: const Icon(Icons.zoom_out),
            tooltip: "Zoom Out (show more time)",
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[200],
            ),
          ),
          const SizedBox(width: 8),
          
          // Current zoom level / window info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isFullView 
                  ? "Full View" 
                  : "${(_visibleDuration / 1000).toStringAsFixed(0)}s window",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          
          // Zoom in
          IconButton(
            onPressed: _zoomIn,
            icon: const Icon(Icons.zoom_in),
            tooltip: "Zoom In (show less time)",
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[200],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Reset to full view
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

  // Widget _buildTimelineScrubber() {
  //   if (_dataPoints.isEmpty) return const SizedBox.shrink();
    
  //   final dataMinX = _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
  //   final dataMaxX = _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
  //   final totalRange = dataMaxX - dataMinX;
    
  //   if (totalRange <= 0) return const SizedBox.shrink();
    
  //   final viewStart = _viewMinX ?? dataMinX;
  //   final viewEnd = _viewMaxX ?? dataMaxX;
    
  //   final startRatio = ((viewStart - dataMinX) / totalRange).clamp(0.0, 1.0);
  //   final endRatio = ((viewEnd - dataMinX) / totalRange).clamp(0.0, 1.0);
  //   final widthRatio = (endRatio - startRatio).clamp(0.05, 1.0);
    
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16),
  //     child: Column(
  //       children: [
  //         // Timeline bar
  //         Container(
  //           height: 24,
  //           decoration: BoxDecoration(
  //             color: Colors.grey[300],
  //             borderRadius: BorderRadius.circular(4),
  //           ),
  //           child: LayoutBuilder(
  //             builder: (context, constraints) {
  //               return Stack(
  //                 children: [
  //                   // Visible range indicator
  //                   Positioned(
  //                     left: startRatio * constraints.maxWidth,
  //                     width: widthRatio * constraints.maxWidth,
  //                     top: 2,
  //                     bottom: 2,
  //                     child: Container(
  //                       decoration: BoxDecoration(
  //                         color: _isFullView ? Colors.green : MainColors.primaryColor,
  //                         borderRadius: BorderRadius.circular(3),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               );
  //             },
  //           ),
  //         ),
  //         const SizedBox(height: 4),
          
  //         // Time labels
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               DateFormat('HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(dataMinX.toInt())),
  //               style: TextStyle(fontSize: 10, color: Colors.grey[600]),
  //             ),
  //             Text(
  //               "Total: ${((dataMaxX - dataMinX) / 1000).toStringAsFixed(0)}s",
  //               style: TextStyle(fontSize: 10, color: Colors.grey[600]),
  //             ),
  //             Text(
  //               DateFormat('HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(dataMaxX.toInt())),
  //               style: TextStyle(fontSize: 10, color: Colors.grey[600]),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildScrollHint() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     margin: const EdgeInsets.symmetric(horizontal: 16),
  //     decoration: BoxDecoration(
  //       color: Colors.blue.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Icon(Icons.swipe, size: 18, color: Colors.blue[700]),
  //         const SizedBox(width: 8),
  //         Text(
  //           "Swipe to scroll • Pinch to zoom • Use buttons above",
  //           style: TextStyle(fontSize: 11, color: Colors.blue[700]),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
            Text("Recorded: ${dateFormat.format(widget.session.startTime)}", style: AppTextStyles.regular),
          ]),
          if (widget.session.duration != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.timer, size: 18),
              const SizedBox(width: 8),
              Text("Duration: ${_formatDuration(widget.session.duration!)}", style: AppTextStyles.regular),
            ]),
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
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Statistics", style: AppTextStyles.bold),
          const SizedBox(height: 12),
          _buildChannelStats("Channel 1", _channel1Color, 'min_value1', 'max_value1', 'avg_value1'),
          const SizedBox(height: 8),
          _buildChannelStats("Channel 2", _channel2Color, 'min_value2', 'max_value2', 'avg_value2'),
          const SizedBox(height: 8),
          _buildChannelStats("Channel 3", _channel3Color, 'min_value3', 'max_value3', 'avg_value3'),
          const SizedBox(height: 8),
          _buildChannelStats("Channel 4", _channel4Color, 'min_value4', 'max_value4', 'avg_value4'),
        ],
      ),
    );
  }

  Widget _buildChannelStats(String name, Color color, String minKey, String maxKey, String avgKey) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "$name: Min ${_formatStat(_stats[minKey])} | Max ${_formatStat(_stats[maxKey])} | Avg ${_formatStat(_stats[avgKey])}",
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  String _formatStat(dynamic v) => v != null ? (v as num).toStringAsFixed(1) : "N/A";

  Widget _buildExportButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _exportToCSV,
          icon: const Icon(Icons.file_download),
          label: const Text("EXPORT TO CSV"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelToggles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        alignment: WrapAlignment.center,
        children: [
          FilterChip(
            label: const Text("CH 1"),
            selected: _showChannel1,
            onSelected: (v) => setState(() => _showChannel1 = v),
            selectedColor: _channel1Color.withOpacity(0.3),
            checkmarkColor: _channel1Color,
            labelStyle: TextStyle(color: _showChannel1 ? _channel1Color : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          FilterChip(
            label: const Text("CH 2"),
            selected: _showChannel2,
            onSelected: (v) => setState(() => _showChannel2 = v),
            selectedColor: _channel2Color.withOpacity(0.3),
            checkmarkColor: _channel2Color,
            labelStyle: TextStyle(color: _showChannel2 ? _channel2Color : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          FilterChip(
            label: const Text("CH 3"),
            selected: _showChannel3,
            onSelected: (v) => setState(() => _showChannel3 = v),
            selectedColor: _channel3Color.withOpacity(0.3),
            checkmarkColor: _channel3Color,
            labelStyle: TextStyle(color: _showChannel3 ? _channel3Color : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          FilterChip(
            label: const Text("CH 4"),
            selected: _showChannel4,
            onSelected: (v) => setState(() => _showChannel4 = v),
            selectedColor: _channel4Color.withOpacity(0.3),
            checkmarkColor: _channel4Color,
            labelStyle: TextStyle(color: _showChannel4 ? _channel4Color : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
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
          padding: const EdgeInsets.only(top: 24, bottom: 12, right: 20, left: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xfff3f6f9),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Stack(
            children: [
              LineChart(_buildChartData()),
              
              // View indicator
              Positioned(
                top: 8,
                right: 8,
                child: _isFullView
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green, width: 1),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange, width: 1),
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

    // Get visible data points
    List<FlSpot> spots1 = [];
    List<FlSpot> spots2 = [];
    List<FlSpot> spots3 = [];
    List<FlSpot> spots4 = [];

    final minX = _viewMinX ?? (_dataPoints.isNotEmpty ? _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble() : 0);
    final maxX = _viewMaxX ?? (_dataPoints.isNotEmpty ? _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble() : 1);
    final buffer = (maxX - minX) * 0.1;

    for (var p in _dataPoints) {
      final x = p.timestamp.millisecondsSinceEpoch.toDouble();
      if (x >= (minX - buffer) && x <= (maxX + buffer)) {
        spots1.add(FlSpot(x, p.value1));
        spots2.add(FlSpot(x, p.value2));
        spots3.add(FlSpot(x, p.value3));
        spots4.add(FlSpot(x, p.value4));
      }
    }

    // Calculate dynamic symmetric Y-axis from visible data
    double maxAbsValue = 1;
    if (_showChannel1) {
      for (var spot in spots1) {
        if (spot.y.abs() > maxAbsValue) maxAbsValue = spot.y.abs();
      }
    }
    if (_showChannel2) {
      for (var spot in spots2) {
        if (spot.y.abs() > maxAbsValue) maxAbsValue = spot.y.abs();
      }
    }
    if (_showChannel3) {
      for (var spot in spots3) {
        if (spot.y.abs() > maxAbsValue) maxAbsValue = spot.y.abs();
      }
    }
    if (_showChannel4) {
      for (var spot in spots4) {
        if (spot.y.abs() > maxAbsValue) maxAbsValue = spot.y.abs();
      }
    }
    maxAbsValue = maxAbsValue * 1.1;

    if (_showChannel1 && spots1.isNotEmpty) {
      lineBars.add(LineChartBarData(
        spots: spots1,
        isCurved: true,
        color: _channel1Color,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_channel1Color.withOpacity(0.15), _channel1Color.withOpacity(0.0)],
          ),
        ),
      ));
    }
    if (_showChannel2 && spots2.isNotEmpty) {
      lineBars.add(LineChartBarData(
        spots: spots2,
        isCurved: true,
        color: _channel2Color,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_channel2Color.withOpacity(0.15), _channel2Color.withOpacity(0.0)],
          ),
        ),
      ));
    }
    if (_showChannel3 && spots3.isNotEmpty) {
      lineBars.add(LineChartBarData(
        spots: spots3,
        isCurved: true,
        color: _channel3Color,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_channel3Color.withOpacity(0.15), _channel3Color.withOpacity(0.0)],
          ),
        ),
      ));
    }
    if (_showChannel4 && spots4.isNotEmpty) {
      lineBars.add(LineChartBarData(
        spots: spots4,
        isCurved: true,
        color: _channel4Color,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_channel4Color.withOpacity(0.15), _channel4Color.withOpacity(0.0)],
          ),
        ),
      ));
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
            return FlLine(color: Colors.grey[600]!, strokeWidth: 1.5);
          }
          return FlLine(color: Colors.grey[300]!, strokeWidth: 0.8);
        },
        getDrawingVerticalLine: (value) => FlLine(color: Colors.grey[300]!, strokeWidth: 0.8),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value == meta.min || value == meta.max) return const SizedBox.shrink();
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  DateFormat('mm:ss').format(date),
                  style: TextStyle(fontSize: 10, color: Colors.grey[700]),
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
              if (value == meta.max || value == meta.min) return const SizedBox.shrink();
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 10,
                    color: value.abs() < 0.001 ? Colors.grey[800] : Colors.grey[600],
                    fontWeight: value.abs() < 0.001 ? FontWeight.bold : FontWeight.normal,
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
              final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
              final channelInfo = _getChannelInfo(spot.barIndex);
              return LineTooltipItem(
                '${channelInfo.label}: ${spot.y.toStringAsFixed(1)}\n${DateFormat('HH:mm:ss').format(date)}',
                TextStyle(color: channelInfo.color.withOpacity(0.9), fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  ({String label, Color color}) _getChannelInfo(int barIndex) {
    List<({String label, Color color})> visibleChannels = [];
    if (_showChannel1) visibleChannels.add((label: "CH1", color: _channel1Color));
    if (_showChannel2) visibleChannels.add((label: "CH2", color: _channel2Color));
    if (_showChannel3) visibleChannels.add((label: "CH3", color: _channel3Color));
    if (_showChannel4) visibleChannels.add((label: "CH4", color: _channel4Color));
    if (barIndex < visibleChannels.length) return visibleChannels[barIndex];
    return (label: "CH?", color: Colors.grey);
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
                Text("Data Points (${displayPoints.length}/${_dataPoints.length})", style: AppTextStyles.bold),
                Text("Showing first 50", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          const Divider(height: 1),
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(child: Text("#", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700]))),
                Expanded(flex: 2, child: Text("Time", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700]))),
                Expanded(child: Text("CH1", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _channel1Color))),
                Expanded(child: Text("CH2", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _channel2Color))),
                Expanded(child: Text("CH3", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _channel3Color))),
                Expanded(child: Text("CH4", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _channel4Color))),
              ],
            ),
          ),
          ...displayPoints.asMap().entries.map((e) {
            final p = e.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: e.key % 2 == 0 ? Colors.white : Colors.grey[50],
              child: Row(
                children: [
                  Expanded(child: Text("${e.key + 1}", style: const TextStyle(fontSize: 11))),
                  Expanded(flex: 2, child: Text(DateFormat('HH:mm:ss').format(p.timestamp), style: const TextStyle(fontSize: 11))),
                  Expanded(child: Text(p.value1.toStringAsFixed(1), style: const TextStyle(fontSize: 11))),
                  Expanded(child: Text(p.value2.toStringAsFixed(1), style: const TextStyle(fontSize: 11))),
                  Expanded(child: Text(p.value3.toStringAsFixed(1), style: const TextStyle(fontSize: 11))),
                  Expanded(child: Text(p.value4.toStringAsFixed(1), style: const TextStyle(fontSize: 11))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
    if (d.inMinutes > 0) return "${d.inMinutes}m ${d.inSeconds.remainder(60)}s";
    return "${d.inSeconds}s";
  }
}