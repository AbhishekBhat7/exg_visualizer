import 'package:exg_visualizer/BLE/csv_exporter.dart';
import 'dart:async';
import 'package:exg_visualizer/BLE/db.dart';
import 'package:exg_visualizer/Libraries/Colors/Colors.dart';
import 'package:exg_visualizer/Libraries/Fonts/text_styles.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';

// Data class to hold both values
class DualChannelData {
  final double value1;
  final double value2;
  final DateTime timestamp;

  DualChannelData({
    required this.value1,
    required this.value2,
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
  // ✅ UPDATED UUIDs from nRF Connect
  static const String SERVICE_UUID = "12345678-1234-1234-1234-123456789abc";
  static const String CHARACTERISTIC_UUID = "abcdef12-3456-7890-1234-567890abcdef";

  BluetoothCharacteristic? _characteristic;
  StreamSubscription<List<int>>? _notificationSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  final StreamController<DualChannelData> _graphDataController =
      StreamController<DualChannelData>.broadcast();

  String _displayValue1 = "--";
  String _displayValue2 = "--";
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
        
        // Subscribe to notifications (since your characteristic has NOTIFY property)
        if (_characteristic!.properties.notify) {
          await _subscribeToNotifications();
        }
        
        // Also try to read if available
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

  /// ✅ Parse the comma-separated format: "-402.1,-268.2"
  void _updateValue(List<int> bytes) {
    if (!mounted || bytes.isEmpty) return;

    // Convert bytes to string
    String stringVal = String.fromCharCodes(bytes).trim();
    
    print("📥 Received: $stringVal (${bytes.length} bytes)");
    print("   Raw bytes: $bytes");

    double? val1;
    double? val2;

    // Parse comma-separated values: "-402.1,-268.2"
    if (stringVal.contains(',')) {
      List<String> parts = stringVal.split(',');
      
      if (parts.length >= 2) {
        val1 = double.tryParse(parts[0].trim());
        val2 = double.tryParse(parts[1].trim());
        
        print("   Parsed: val1=$val1, val2=$val2");
      }
    } else {
      // Single value fallback
      val1 = double.tryParse(stringVal);
      val2 = val1;
    }

    // Only process if we have valid values
    if (val1 != null && val2 != null) {
      _graphDataController.add(DualChannelData(
        value1: val1,
        value2: val2,
        timestamp: DateTime.now(),
      ));
    }

    setState(() {
      _rawBytes = bytes;
      _rawString = stringVal;
      _displayValue1 = val1?.toStringAsFixed(1) ?? "--";
      _displayValue2 = val2?.toStringAsFixed(1) ?? "--";
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
            
            // Show error if characteristic not found
            if (_errorMessage.isNotEmpty) ...[
              _buildErrorCard(),
              const SizedBox(height: 20),
            ],
            
            _buildDualValueDisplayCard(),
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
              Text(
                "Error",
                style: AppTextStyles.bold.copyWith(color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: AppTextStyles.regular.copyWith(fontSize: 12),
          ),
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
                    "Receiving data from characteristic",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualValueDisplayCard() {
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
          Text(
            "LIVE VALUES",
            style: AppTextStyles.regular.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Channel 1
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "CH 1",
                        style: AppTextStyles.bold.copyWith(
                          color: Colors.blue[300],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _displayValue1,
                        style: AppTextStyles.header.copyWith(
                          color: Colors.blue[300],
                          fontSize: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                height: 60,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              // Channel 2
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "CH 2",
                        style: AppTextStyles.bold.copyWith(
                          color: Colors.orange[300],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _displayValue2,
                        style: AppTextStyles.header.copyWith(
                          color: Colors.orange[300],
                          fontSize: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            const SizedBox(height: 8),
            _rawDataRow("Hex", _rawBytes.isEmpty 
                ? "--" 
                : _rawBytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join('-')),
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
          child: Text(
            "$label:",
            style: AppTextStyles.bold.copyWith(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.regular.copyWith(
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum ActiveFunction { none, function1, function2 }

class LiveExgChartPage extends StatefulWidget {
  final Stream<DualChannelData> dataStream;
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
  late StreamSubscription<DualChannelData> _subscription;

  // Display points for both channels
  final List<FlSpot> _displayPoints1 = [];
  final List<FlSpot> _displayPoints2 = [];

  // ALL data points stored for saving
  final List<DataPoint> _allDataPoints = [];

  ActiveFunction _activeFunction = ActiveFunction.none;

  // Channel visibility toggles
  bool _showChannel1 = true;
  bool _showChannel2 = true;

  // Scrolling control
  bool _autoScroll = true;
  double? _manualMinX;
  double? _manualMaxX;

  // Recording start time for duration
  DateTime? _recordingStartTime;

  // Latest values for legend
  double _latestValue1 = 0;
  double _latestValue2 = 0;

  static const int _maxDisplayPoints = 500;
  static const double _visibleDurationInMs = 10000;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

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
    _subscription = widget.dataStream.listen((data) {
      final now = data.timestamp;

      // Process values
      double processedValue1 = _processValue(data.value1);
      double processedValue2 = _processValue(data.value2);

      // Store original values with timestamp (for saving)
      _allDataPoints.add(DataPoint(
        value1: data.value1,
        value2: data.value2,
        timestamp: now,
        processedValue1: processedValue1,
        processedValue2: processedValue2,
      ));

      setState(() {
        final timestamp = now.millisecondsSinceEpoch.toDouble();

        _displayPoints1.add(FlSpot(timestamp, processedValue1));
        _displayPoints2.add(FlSpot(timestamp, processedValue2));

        _latestValue1 = processedValue1;
        _latestValue2 = processedValue2;

        // Keep display points manageable
        if (_displayPoints1.length > _maxDisplayPoints) {
          _displayPoints1.removeAt(0);
        }
        if (_displayPoints2.length > _maxDisplayPoints) {
          _displayPoints2.removeAt(0);
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
      _displayPoints1.clear();
      _displayPoints2.clear();
      _allDataPoints.clear();
      _recordingStartTime = DateTime.now();
      _autoScroll = true;
      _manualMinX = null;
      _manualMaxX = null;
      _latestValue1 = 0;
      _latestValue2 = 0;
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
        Navigator.pop(context);
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
    if (_displayPoints1.isEmpty) return;

    setState(() {
      _autoScroll = false;

      final chartWidth = MediaQuery.of(context).size.width - 80;
      final dragRatio = details.delta.dx / chartWidth;
      final timeSpan = _visibleDurationInMs;
      final shift = -dragRatio * timeSpan;

      final currentMaxX = _manualMaxX ?? _displayPoints1.last.x;
      final currentMinX = _manualMinX ?? (currentMaxX - _visibleDurationInMs);

      final dataMinX = _displayPoints1.first.x;
      final dataMaxX = _displayPoints1.last.x;

      double newMinX = currentMinX + shift;
      double newMaxX = currentMaxX + shift;

      if (newMinX < dataMinX) {
        newMinX = dataMinX;
        newMaxX = dataMinX + _visibleDurationInMs;
      }
      if (newMaxX > dataMaxX) {
        newMaxX = dataMaxX;
        newMinX = dataMaxX - _visibleDurationInMs;
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
          _buildStatsBar(),
          const SizedBox(height: 8),
          _buildChannelToggles(),
          const SizedBox(height: 8),
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
                  child: _displayPoints1.isEmpty && _displayPoints2.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.show_chart,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text("Waiting for data...",
                                  style: AppTextStyles.regular),
                              const SizedBox(height: 8),
                              Text(
                                "Make sure BLE device is sending data",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          children: [
                            LineChart(
                              _buildChartData(),
                              duration: Duration.zero,
                            ),
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
          const SizedBox(height: 12),
          _buildLegend(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildFunctionControls(),
          ),
          const SizedBox(height: 12),
          if (_displayPoints1.isNotEmpty || _displayPoints2.isNotEmpty)
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

  Widget _buildChannelToggles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilterChip(
            label: const Text("Channel 1"),
            selected: _showChannel1,
            onSelected: (value) {
              setState(() => _showChannel1 = value);
            },
            selectedColor: Colors.blue.withOpacity(0.3),
            checkmarkColor: Colors.blue,
            labelStyle: TextStyle(
              color: _showChannel1 ? Colors.blue : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          FilterChip(
            label: const Text("Channel 2"),
            selected: _showChannel2,
            onSelected: (value) {
              setState(() => _showChannel2 = value);
            },
            selectedColor: Colors.orange.withOpacity(0.3),
            checkmarkColor: Colors.orange,
            labelStyle: TextStyle(
              color: _showChannel2 ? Colors.orange : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_showChannel1) ...[
            Container(width: 20, height: 3, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              "CH1: ${_latestValue1.toStringAsFixed(1)}",
              style: const TextStyle(
                  color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ],
          if (_showChannel1 && _showChannel2) const SizedBox(width: 24),
          if (_showChannel2) ...[
            Container(width: 20, height: 3, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              "CH2: ${_latestValue2.toStringAsFixed(1)}",
              style: const TextStyle(
                  color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

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
          Container(height: 40, width: 1, color: Colors.grey[300]),
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
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
        ? ElevatedButton(onPressed: onPressed, style: activeStyle, child: Text(label))
        : OutlinedButton(onPressed: onPressed, style: inactiveStyle, child: Text(label));
  }


// LineChartData _buildChartData() {
//   final hasData = _displayPoints1.isNotEmpty || _displayPoints2.isNotEmpty;
//   final referencePoints =
//       _displayPoints1.isNotEmpty ? _displayPoints1 : _displayPoints2;

//   double minX, maxX;

//   if (!hasData) {
//     final now = DateTime.now().millisecondsSinceEpoch.toDouble();
//     minX = now - 1000;
//     maxX = now;
//   } else {
//     final dataMinX = referencePoints.first.x;
//     final dataMaxX = referencePoints.last.x;
//     final dataRange = dataMaxX - dataMinX;

//     if (_autoScroll) {
//       if (dataRange < 1000) {
//         // Very little data - add small padding
//         minX = dataMinX - 500;
//         maxX = dataMaxX + 500;
//       } else if (dataRange < _visibleDurationInMs) {
//         // ✅ Data fills part of window - scale to fit all data
//         // Add 5% padding on each side
//         final padding = dataRange * 0.05;
//         minX = dataMinX - padding;
//         maxX = dataMaxX + padding;
//       } else {
//         // Enough data - show sliding window
//         maxX = dataMaxX;
//         minX = maxX - _visibleDurationInMs;
//       }
//     } else {
//       maxX = _manualMaxX ?? dataMaxX;
//       minX = _manualMinX ?? (maxX - _visibleDurationInMs);
//     }
//   }

//   List<LineChartBarData> lineBars = [];

//   if (_showChannel1 && _displayPoints1.isNotEmpty) {
//     lineBars.add(
//       LineChartBarData(
//         spots: _displayPoints1,
//         isCurved: true,
//         color: Colors.blue,
//         barWidth: 2.5,
//         isStrokeCapRound: true,
//         dotData: const FlDotData(show: false),
//         belowBarData: BarAreaData(
//           show: true,
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Colors.blue.withOpacity(0.2),
//               Colors.blue.withOpacity(0.0),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   if (_showChannel2 && _displayPoints2.isNotEmpty) {
//     lineBars.add(
//       LineChartBarData(
//         spots: _displayPoints2,
//         isCurved: true,
//         color: Colors.orange,
//         barWidth: 2.5,
//         isStrokeCapRound: true,
//         dotData: const FlDotData(show: false),
//         belowBarData: BarAreaData(
//           show: true,
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Colors.orange.withOpacity(0.2),
//               Colors.orange.withOpacity(0.0),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   return LineChartData(
//     minX: minX,
//     maxX: maxX,
//     clipData: const FlClipData.all(),
//     gridData: FlGridData(
//       show: true,
//       drawVerticalLine: true,
//       horizontalInterval: 100,
//       verticalInterval: (maxX - minX) / 5, // Dynamic vertical interval
//       getDrawingHorizontalLine: (value) => FlLine(
//         color: Colors.grey[300],
//         strokeWidth: 0.8,
//       ),
//       getDrawingVerticalLine: (value) => FlLine(
//         color: Colors.grey[300],
//         strokeWidth: 0.8,
//       ),
//     ),
//     titlesData: FlTitlesData(
//       show: true,
//       rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//       topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//       bottomTitles: AxisTitles(
//         sideTitles: SideTitles(
//           showTitles: true,
//           reservedSize: 30,
//           interval: (maxX - minX) / 4, // Dynamic interval for labels
//           getTitlesWidget: (value, meta) {
//             final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
//             return SideTitleWidget(
//               meta: meta,
//               space: 8.0,
//               child: Text(
//                 DateFormat('HH:mm:ss').format(date),
//                 style: TextStyle(color: Colors.grey[700], fontSize: 10),
//               ),
//             );
//           },
//         ),
//       ),
//       leftTitles: AxisTitles(
//         sideTitles: SideTitles(
//           showTitles: true,
//           reservedSize: 50,
//           getTitlesWidget: (value, meta) {
//             if (value == meta.max || value == meta.min) {
//               return Container();
//             }
//             return SideTitleWidget(
//               meta: meta,
//               child: Text(
//                 value.toInt().toString(),
//                 style: TextStyle(
//                     color: Colors.grey[700],
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.left,
//               ),
//             );
//           },
//         ),
//       ),
//     ),
//     borderData: FlBorderData(show: false),
//     lineBarsData: lineBars,
//     lineTouchData: LineTouchData(
//       enabled: true,
//       touchTooltipData: LineTouchTooltipData(
//         getTooltipItems: (touchedSpots) {
//           return touchedSpots.map((spot) {
//             final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
//             final channelLabel = (spot.barIndex == 0 && _showChannel1) ? "CH1" : "CH2";
//             final color = (spot.barIndex == 0 && _showChannel1) ? Colors.blue[100] : Colors.orange[100];
//             return LineTooltipItem(
//               '$channelLabel: ${spot.y.toStringAsFixed(1)}\n${DateFormat('HH:mm:ss').format(date)}',
//               TextStyle(color: color, fontWeight: FontWeight.bold),
//             );
//           }).toList();
//         },
//       ),
//     ),
//   );
// }



LineChartData _buildChartData() {
  final hasData = _displayPoints1.isNotEmpty || _displayPoints2.isNotEmpty;
  final referencePoints =
      _displayPoints1.isNotEmpty ? _displayPoints1 : _displayPoints2;

  double minX, maxX;

  if (!hasData) {
    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    minX = now - 1000;
    maxX = now;
  } else {
    final dataMinX = referencePoints.first.x;
    final dataMaxX = referencePoints.last.x;
    final dataRange = dataMaxX - dataMinX;

    if (_autoScroll) {
      if (dataRange < 1000) {
        minX = dataMinX - 500;
        maxX = dataMaxX + 500;
      } else if (dataRange < _visibleDurationInMs) {
        final padding = dataRange * 0.05;
        minX = dataMinX - padding;
        maxX = dataMaxX + padding;
      } else {
        maxX = dataMaxX;
        minX = maxX - _visibleDurationInMs;
      }
    } else {
      maxX = _manualMaxX ?? dataMaxX;
      minX = _manualMinX ?? (maxX - _visibleDurationInMs);
    }
  }

  // ✅ FIX: Use fixed interval instead of dynamic calculation
  // This prevents the labels from jumping around
  final double xAxisInterval = _calculateFixedInterval(_visibleDurationInMs);
  
  // ✅ FIX: Snap minX to interval boundary for stable labels
  final double snappedMinX = (minX / xAxisInterval).floor() * xAxisInterval;

  List<LineChartBarData> lineBars = [];

  if (_showChannel1 && _displayPoints1.isNotEmpty) {
    lineBars.add(
      LineChartBarData(
        spots: _displayPoints1,
        isCurved: true,
        color: Colors.blue,
        barWidth: 2.5,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.withOpacity(0.2),
              Colors.blue.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }

  if (_showChannel2 && _displayPoints2.isNotEmpty) {
    lineBars.add(
      LineChartBarData(
        spots: _displayPoints2,
        isCurved: true,
        color: Colors.orange,
        barWidth: 2.5,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.withOpacity(0.2),
              Colors.orange.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }

  return LineChartData(
    minX: minX,
    maxX: maxX,
    clipData: const FlClipData.all(),
    gridData: FlGridData(
      show: true,
      drawVerticalLine: true,
      horizontalInterval: 100,
      verticalInterval: xAxisInterval, // ✅ Use fixed interval
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
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: xAxisInterval, // ✅ Use fixed interval
          getTitlesWidget: (value, meta) {
            // ✅ FIX: Only show labels at interval boundaries
            // This prevents label flickering
            final remainder = value % xAxisInterval;
            if (remainder.abs() > 100 && (xAxisInterval - remainder.abs()) > 100) {
              return const SizedBox.shrink();
            }
            
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
          reservedSize: 50,
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
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
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
            final channelLabel = (spot.barIndex == 0 && _showChannel1) ? "CH1" : "CH2";
            final color = (spot.barIndex == 0 && _showChannel1) ? Colors.blue[100] : Colors.orange[100];
            return LineTooltipItem(
              '$channelLabel: ${spot.y.toStringAsFixed(1)}\n${DateFormat('HH:mm:ss').format(date)}',
              TextStyle(color: color, fontWeight: FontWeight.bold),
            );
          }).toList();
        },
      ),
    ),
  );
}

// ✅ Add this helper method to your class
double _calculateFixedInterval(double visibleDuration) {
  // Choose nice round intervals based on visible duration
  if (visibleDuration <= 5000) {
    return 1000; // 1 second intervals
  } else if (visibleDuration <= 15000) {
    return 2000; // 2 second intervals
  } else if (visibleDuration <= 30000) {
    return 5000; // 5 second intervals
  } else if (visibleDuration <= 60000) {
    return 10000; // 10 second intervals
  } else if (visibleDuration <= 120000) {
    return 20000; // 20 second intervals
  } else if (visibleDuration <= 300000) {
    return 30000; // 30 second intervals
  } else {
    return 60000; // 1 minute intervals
  }
}

}

// ============= SAVED RECORDINGS PAGE =============
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
        content: Text("This will permanently delete this recording with ${session.dataCount} data points."),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Recording deleted"), backgroundColor: Colors.green),
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
            MaterialPageRoute(builder: (context) => RecordingDetailPage(session: session)),
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
                    child: Icon(Icons.bluetooth, color: MainColors.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.deviceName, style: AppTextStyles.bold.copyWith(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(dateFormat.format(session.startTime),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
                  _infoItem(icon: Icons.access_time, label: "Start", value: timeFormat.format(session.startTime)),
                  _infoItem(
                    icon: Icons.timer,
                    label: "Duration",
                    value: session.duration != null ? _formatDuration(session.duration!) : "--",
                  ),
                  _infoItem(icon: Icons.data_array, label: "Points", value: session.dataCount.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem({required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) return "${hours}h ${minutes}m";
    if (minutes > 0) return "${minutes}m ${seconds}s";
    return "${seconds}s";
  }
}

// ============= RECORDING DETAIL PAGE =============
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
      final dataPoints = await _dbHelper.getSessionDataPoints(widget.session.id!);
      final stats = await _dbHelper.getSessionStats(widget.session.id!);

      setState(() {
        _dataPoints = dataPoints;
        _stats = stats;
        _isLoading = false;

        if (_dataPoints.isNotEmpty) {
          _visibleMinX = _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
          _visibleMaxX = _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading data: $e"), backgroundColor: Colors.red),
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

  List<FlSpot> _getDisplaySpots1() {
    return _dataPoints.map((p) => FlSpot(p.timestamp.millisecondsSinceEpoch.toDouble(), p.value1)).toList();
  }

  List<FlSpot> _getDisplaySpots2() {
    return _dataPoints.map((p) => FlSpot(p.timestamp.millisecondsSinceEpoch.toDouble(), p.value2)).toList();
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
      final dataMinX = _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
      final dataMaxX = _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
      final dataRange = dataMaxX - dataMinX;
      final currentRange = (_visibleMaxX ?? dataMaxX) - (_visibleMinX ?? dataMinX);
      final center = ((_visibleMaxX ?? dataMaxX) + (_visibleMinX ?? dataMinX)) / 2;
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
      _visibleMinX = _dataPoints.first.timestamp.millisecondsSinceEpoch.toDouble();
      _visibleMaxX = _dataPoints.last.timestamp.millisecondsSinceEpoch.toDouble();
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
            Text(widget.session.deviceName,
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
          IconButton(
            onPressed: _dataPoints.isNotEmpty ? _exportToCSV : null,
            icon: Icon(Icons.file_download, color: _dataPoints.isNotEmpty ? Colors.green : Colors.grey),
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
          Text("No data points found", style: AppTextStyles.bold.copyWith(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildContent(DateFormat dateFormat) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSessionInfoCard(dateFormat),
          _buildStatsCard(),
          _buildExportButton(),
          const SizedBox(height: 16),
          _buildChannelToggles(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Signal Data", style: AppTextStyles.bold),
                Row(
                  children: [
                    IconButton(onPressed: _zoomIn, icon: const Icon(Icons.zoom_in), tooltip: "Zoom In"),
                    IconButton(onPressed: _zoomOut, icon: const Icon(Icons.zoom_out), tooltip: "Zoom Out"),
                    IconButton(onPressed: _resetZoom, icon: const Icon(Icons.fit_screen), tooltip: "Fit All"),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 300,
              padding: const EdgeInsets.only(top: 24, bottom: 12, right: 20, left: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xfff3f6f9),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: LineChart(_buildChartData(), duration: const Duration(milliseconds: 150)),
            ),
          ),
          _buildLegend(),
          _buildDataTable(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildChannelToggles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilterChip(
            label: const Text("Channel 1"),
            selected: _showChannel1,
            onSelected: (v) => setState(() => _showChannel1 = v),
            selectedColor: Colors.blue.withOpacity(0.3),
            checkmarkColor: Colors.blue,
            labelStyle: TextStyle(color: _showChannel1 ? Colors.blue : Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          FilterChip(
            label: const Text("Channel 2"),
            selected: _showChannel2,
            onSelected: (v) => setState(() => _showChannel2 = v),
            selectedColor: Colors.orange.withOpacity(0.3),
            checkmarkColor: Colors.orange,
            labelStyle: TextStyle(color: _showChannel2 ? Colors.orange : Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_showChannel1) ...[
            Container(width: 20, height: 3, color: Colors.blue),
            const SizedBox(width: 8),
            const Text("Channel 1", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ],
          if (_showChannel1 && _showChannel2) const SizedBox(width: 24),
          if (_showChannel2) ...[
            Container(width: 20, height: 3, color: Colors.orange),
            const SizedBox(width: 8),
            const Text("Channel 2", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ],
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
          label: Text("EXPORT TO CSV", style: AppTextStyles.bold.copyWith(fontSize: 15)),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green[600],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          // Channel 1 stats
          Row(children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text("Channel 1:", style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(label: "Min", value: (_stats['min_value1'] as num?)?.toStringAsFixed(1) ?? "0", color: Colors.green),
              _statItem(label: "Max", value: (_stats['max_value1'] as num?)?.toStringAsFixed(1) ?? "0", color: Colors.red),
              _statItem(label: "Avg", value: (_stats['avg_value1'] as num?)?.toStringAsFixed(1) ?? "0", color: Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          // Channel 2 stats
          Row(children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text("Channel 2:", style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(label: "Min", value: (_stats['min_value2'] as num?)?.toStringAsFixed(1) ?? "0", color: Colors.green),
              _statItem(label: "Max", value: (_stats['max_value2'] as num?)?.toStringAsFixed(1) ?? "0", color: Colors.red),
              _statItem(label: "Avg", value: (_stats['avg_value2'] as num?)?.toStringAsFixed(1) ?? "0", color: Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem({required String label, required String value, required Color color}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDataTable() {
    final displayPoints = _dataPoints.take(100).toList();
    final timeFormat = DateFormat('HH:mm:ss.SSS');

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
                Text("Showing ${displayPoints.length} of ${_dataPoints.length}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text("#", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("Time", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("Value 1", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                Expanded(flex: 2, child: Text("Value 2", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))),
              ],
            ),
          ),
          ...displayPoints.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: index % 2 == 0 ? Colors.white : Colors.grey[50]),
              child: Row(
                children: [
                  Expanded(flex: 1, child: Text("${index + 1}", style: TextStyle(color: Colors.grey[600]))),
                  Expanded(flex: 2, child: Text(timeFormat.format(point.timestamp))),
                  Expanded(flex: 2, child: Text(point.value1.toStringAsFixed(1))),
                  Expanded(flex: 2, child: Text(point.value2.toStringAsFixed(1))),
                ],
              ),
            );
          }),
          if (_dataPoints.length > 100)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Text("... and ${_dataPoints.length - 100} more data points",
                  style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    final spots1 = _getDisplaySpots1();
    final spots2 = _getDisplaySpots2();

    List<LineChartBarData> lineBars = [];

    if (_showChannel1 && spots1.isNotEmpty) {
      lineBars.add(LineChartBarData(
        spots: spots1,
        isCurved: true,
        color: Colors.blue,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(show: spots1.length < 50),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.0)],
          ),
        ),
      ));
    }

    if (_showChannel2 && spots2.isNotEmpty) {
      lineBars.add(LineChartBarData(
        spots: spots2,
        isCurved: true,
        color: Colors.orange,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(show: spots2.length < 50),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.withOpacity(0.2), Colors.orange.withOpacity(0.0)],
          ),
        ),
      ));
    }

    return LineChartData(
      minX: _visibleMinX,
      maxX: _visibleMaxX,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 100,
        getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey[300], strokeWidth: 0.8),
        getDrawingVerticalLine: (v) => FlLine(color: Colors.grey[300], strokeWidth: 0.8),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                child: Text(DateFormat('mm:ss').format(date), style: TextStyle(color: Colors.grey[700], fontSize: 10)),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              if (value == meta.max || value == meta.min) return Container();
              return SideTitleWidget(
                meta: meta,
                child: Text(value.toInt().toString(),
                    style: TextStyle(color: Colors.grey[700], fontSize: 10, fontWeight: FontWeight.bold)),
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
              final isChannel1 = spot.barIndex == 0 && _showChannel1;
              return LineTooltipItem(
                '${isChannel1 ? "CH1" : "CH2"}: ${spot.y.toStringAsFixed(1)}\n${DateFormat('HH:mm:ss').format(date)}',
                TextStyle(color: isChannel1 ? Colors.blue[100] : Colors.orange[100], fontWeight: FontWeight.bold),
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
    if (hours > 0) return "${hours}h ${minutes}m ${seconds}s";
    if (minutes > 0) return "${minutes}m ${seconds}s";
    return "${seconds}s";
  }
}