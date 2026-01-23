import 'dart:async';
import 'package:exg_visualizer/Libraries/Colors/Colors.dart'; // Keep your imports
import 'package:exg_visualizer/Libraries/Fonts/text_styles.dart'; // Keep your imports
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  // Store data points
  final List<FlSpot> _allPoints = [];
  
  // Viewport management
  final int _visibleWindowMs = 5000; // Show 5 seconds of data at a time
  double _minX = 0;
  double _maxX = 5000;
  
  // State
  bool _isPaused = false;
  double _lastValue = 0.0;
  late StreamSubscription<double> _subscription;
  
  // For precise formatting
  final DateFormat _timeFormatter = DateFormat('HH:mm:ss.SSS');

  @override
  void initState() {
    super.initState();
    double startTimestamp = DateTime.now().millisecondsSinceEpoch.toDouble();
    _minX = startTimestamp;
    _maxX = startTimestamp + _visibleWindowMs;
    
    _startListening();
  }

  void _startListening() {
    _subscription = widget.dataStream.listen((value) {
      if (!_isPaused) {
        setState(() {
          double currentTimestamp = DateTime.now().millisecondsSinceEpoch.toDouble();
          
          _allPoints.add(FlSpot(currentTimestamp, value));
          _lastValue = value;

          // Keep the list size manageable (e.g., keep last 1000 points for history scrolling)
          // If you want truly infinite history, remove this if block, but app may crash after hours.
          if (_allPoints.length > 2000) {
             _allPoints.removeAt(0);
          }

          // Auto-scroll logic: Move the window to follow the latest point
          _maxX = currentTimestamp; 
          _minX = currentTimestamp - _visibleWindowMs;
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _resetGraph() {
    setState(() {
      _allPoints.clear();
      double now = DateTime.now().millisecondsSinceEpoch.toDouble();
      _minX = now;
      _maxX = now + _visibleWindowMs;
      _lastValue = 0.0;
      _isPaused = false;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Detect screen type for responsiveness
    bool isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark background for "Monitor" look
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.deviceName, style: const TextStyle(color: Colors.white, fontSize: 18)),
            Text(
              _isPaused ? "PAUSED - Drag to scroll history" : "LIVE MONITORING", 
              style: TextStyle(
                color: _isPaused ? Colors.orange : Colors.greenAccent, 
                fontSize: 10, 
                letterSpacing: 1.5
              )
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Current Value Header
            _buildReadoutPanel(isTablet),

            // 2. The Chart Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black, // Deep black for contrast
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                  boxShadow: [
                     BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))
                  ]
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 24.0, top: 24.0, bottom: 12.0, left: 8.0),
                  child: LineChart(
                    _buildChartData(isTablet),
                    duration: const Duration(milliseconds: 0), // Disable animation for performance
                  ),
                ),
              ),
            ),

            // 3. Controls
            _buildControlPanel(isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildReadoutPanel(bool isTablet) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: Colors.grey[850],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("AMPLITUDE", style: TextStyle(color: Colors.grey[400], fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _lastValue.toStringAsFixed(2),
                    style: TextStyle(
                      color: _lastValue >= 0 ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace'
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6.0),
                    child: Text("µV", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
          // Time display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _timeFormatter.format(DateTime.now()),
              style: const TextStyle(color: Colors.white70, fontFamily: 'monospace'),
            ),
          )
        ],
      ),
    );
  }

  LineChartData _buildChartData(bool isTablet) {
    return LineChartData(
      // 1. Touch Behavior (Allows scrolling when paused)
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          // tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
           getTooltipItems: (touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final date = DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt());
              return LineTooltipItem(
                '${touchedSpot.y}\n${_timeFormatter.format(date)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
      ),
      
      // 2. Grid styling
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 10, // Adjust based on your data range
        getDrawingHorizontalLine: (value) {
          // Highlight the Zero line
          if (value == 0) {
            return FlLine(color: Colors.white38, strokeWidth: 1);
          }
          return FlLine(color: Colors.white10, strokeWidth: 1);
        },
        getDrawingVerticalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
      ),

      // 3. Axis Titles (The tricky part)
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        
        // Y-AXIS
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40, // Space for Y labels to prevent overflow
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              );
            },
          ),
        ),

        // X-AXIS (Time)
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32, // Space for X labels
            interval: 1000, // Draw a label every 1000ms (1 second)
            getTitlesWidget: (value, meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              // We split the formatting to prevent text collision
              // If it's the start of a minute, show full time, else show sec:ms
              // But user asked for hr:min:sec:ms. 
              // To fit that, we need to rotate or only show it occasionally.
              // Here is the responsive solution:
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('HH:mm:ss').format(date), // Dropped MS for axis readability, visible in Tooltip
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              );
            },
          ),
        ),
      ),

      // 4. Borders
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey[800]!),
      ),

      // 5. Scroll / Scale Logic
      // If paused, allow user to scroll (don't set min/max strictly).
      // If live, lock min/max to the moving window.
      minX: _isPaused ? null : _minX,
      maxX: _isPaused ? null : _maxX,
      
      // Ensure we see 0 and negative numbers
      baselineX: 0, 

      // 6. The Line Itself
      lineBarsData: [
        LineChartBarData(
          spots: _allPoints,
          isCurved: true,
          curveSmoothness: 0.2, // Sharper curves for medical data
          color: MainColors.primaryColor, // Or Colors.cyanAccent
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false), // No dots, just line
          belowBarData: BarAreaData(
            show: true,
            // Gradient fading to bottom
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                MainColors.primaryColor.withOpacity(0.2),
                MainColors.primaryColor.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel(bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[900],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Stop/Reset
          _buildCircleButton(
            icon: Icons.stop,
            color: Colors.redAccent,
            onTap: _resetGraph,
          ),
          const SizedBox(width: 24),
          
          // Play/Pause Big Button
          SizedBox(
            height: 60,
            width: 120,
            child: ElevatedButton(
              onPressed: _togglePause,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPaused ? Colors.green : Colors.amber[800],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Screenshot or other action (Placeholder)
          _buildCircleButton(
            icon: Icons.camera_alt,
            color: Colors.blueGrey,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Snapshot feature coming soon")),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}