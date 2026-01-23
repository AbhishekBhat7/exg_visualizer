// // lib/Pages/live_exg_chart_page.dart

// import 'dart:async';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
 

// // --- Placeholder classes for your custom files ---
// class MainColors {
//   static const Color primaryColor = Color(0xFF007AFF);
//   static const Color white = Colors.white;
//   static const Color black = Colors.black;
// }

// class AppTextStyles {
//   static const TextStyle header = TextStyle(fontSize: 22, fontWeight: FontWeight.w600);
//   static const TextStyle regular = TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
// }
// // --------------------------------------------------

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
  
//   final DBHelper _dbHelper = DBHelper();
//   final TransformationController _transformationController = TransformationController();
//   bool _isAutoScrolling = true;
  
//   static const int _visibleDurationInMs = 10000;

//   @override
//   void initState() {
//     super.initState();
//     _startListening();
//   }

//   void _startListening() {
//     _subscription = widget.dataStream.listen((originalValue) {
//       double processedValue = originalValue;
//       switch (_activeFunction) {
//         case ActiveFunction.function1:
//           processedValue = originalValue + 5;
//           break;
//         case ActiveFunction.function2:
//           if (originalValue <= 30) processedValue = originalValue + 10;
//           break;
//         case ActiveFunction.none:
//           break;
//       }

//       if (mounted) {
//         setState(() {
//           final timestamp = DateTime.now().millisecondsSinceEpoch.toDouble();
//           _points.add(FlSpot(timestamp, processedValue));
          
//           if (_isAutoScrolling && _points.isNotEmpty) {
//              _scrollToEnd();
//           }
//         });
//       }
//     });
//   }

//   void _scrollToEnd() {
//     if (_points.isEmpty) return;
    
//     final double latestTimestamp = _points.last.x;
//     final double viewWidth = _visibleDurationInMs.toDouble();

//     final Matrix4 matrix = Matrix4.identity()
//       ..translate(-(latestTimestamp - viewWidth), 0.0);

//     _transformationController.value = matrix;
//   }

//   void _clearChart() {
//     setState(() {
//       _points.clear();
//       _isAutoScrolling = true;
//     });
//   }

//   Future<void> _saveChartData() async {
//     if (_points.isEmpty) {
//       if(mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("No data to save."), backgroundColor: Colors.orange,),
//         );
//       }
//       return;
//     }

//     try {
//       await _dbHelper.saveSession(_points);
//       if(mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Success! Saved ${_points.length} data points."), backgroundColor: Colors.green,),
//         );
//       }
//     } catch (e) {
//       if(mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error saving data: $e"), backgroundColor: Colors.red,),
//         );
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _subscription.cancel();
//     _transformationController.dispose();
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
//           PopupMenuButton<String>(
//             onSelected: (value) {
//               if (value == 'restart') _clearChart();
//               else if (value == 'save') _saveChartData();
//             },
//             itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
//               const PopupMenuItem<String>(value: 'restart', child: Row(children: [Icon(Icons.refresh, color: Colors.blue), SizedBox(width: 8), Text('Restart'),],),),
//               const PopupMenuItem<String>(value: 'save', child: Row(children: [Icon(Icons.save_alt, color: Colors.green), SizedBox(width: 8), Text('Save Data'),],),),
//             ],
//             icon: const Icon(Icons.more_vert, color: MainColors.black),
//           ),
//         ],
//       ),
//       floatingActionButton: !_isAutoScrolling 
//         ? FloatingActionButton.extended(
//             onPressed: () {
//               setState(() => _isAutoScrolling = true);
//               _scrollToEnd();
//             },
//             label: const Text("Go Live"),
//             icon: const Icon(Icons.fast_forward),
//             backgroundColor: MainColors.primaryColor,
//           )
//         : null,
//       body: Column(
//         children: [
//           const SizedBox(height: 24),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Container(
//                 clipBehavior: Clip.hardEdge,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(16),
//                   color: const Color(0xfff3f6f9),
//                   border: Border.all(color: Colors.grey[300]!, width: 1),
//                 ),
//                 child: _points.isEmpty
//                     ? Center(child: Text("Waiting for data...", style: AppTextStyles.regular))
//                     : InteractiveViewer(
//                         transformationController: _transformationController,
//                         maxScale: 10.0,
//                         minScale: 0.1,
//                         constrained: false,
//                         boundaryMargin: const EdgeInsets.symmetric(horizontal: -20),
//                         onInteractionStart: (_) {
//                           if (_isAutoScrolling) {
//                             setState(() => _isAutoScrolling = false);
//                           }
//                         },
//                         child: Padding(
//                           padding: const EdgeInsets.only(top: 24, bottom: 12, right: 20, left: 8),
//                           child: SizedBox(
//                             width: _points.isNotEmpty ? _points.last.x : MediaQuery.of(context).size.width,
//                             child: LineChart(_buildChartData(), duration: Duration.zero),
//                           ),
//                         ),
//                       ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 24),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: _buildFunctionControls(),
//           ),
//           const SizedBox(height: 24),
//         ],
//       ),
//     );
//   }

//   Widget _buildFunctionControls() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         _functionButton(
//           label: 'Function 1 (+5)',
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

//   Widget _functionButton({required String label, required VoidCallback onPressed, required bool isActive}) {
//     final activeStyle = ElevatedButton.styleFrom(
//       backgroundColor: MainColors.primaryColor, foregroundColor: Colors.white,
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//     );

//     final inactiveStyle = OutlinedButton.styleFrom(
//       side: const BorderSide(color: MainColors.primaryColor), foregroundColor: MainColors.primaryColor,
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//     );

//     return isActive
//         ? ElevatedButton(onPressed: onPressed, style: activeStyle, child: Text(label))
//         : OutlinedButton(onPressed: onPressed, style: inactiveStyle, child: Text(label));
//   }

//   LineChartData _buildChartData() {
//     final double minX = _points.isNotEmpty ? _points.first.x : 0;
//     final double maxX = _points.isNotEmpty ? _points.last.x : _visibleDurationInMs.toDouble();

//     return LineChartData(
//       minX: minX, maxX: maxX,
//       clipData: const FlClipData.all(),
//       gridData: FlGridData(
//         show: true, drawVerticalLine: true, horizontalInterval: 20, verticalInterval: 2000,
//         getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[300], strokeWidth: 0.8),
//         getDrawingVerticalLine: (value) => FlLine(color: Colors.grey[300], strokeWidth: 0.8),
//       ),
//       titlesData: FlTitlesData(
//         show: true,
//         rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 2000, getTitlesWidget: (value, meta) {
//           final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
//           return SideTitleWidget(axisSide: meta.axisSide, space: 8.0, child: Text(DateFormat('HH:mm:ss').format(date), style: TextStyle(color: Colors.grey[700], fontSize: 10)),);
//         },),),
//         leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45, getTitlesWidget: (value, meta) {
//           if (value == meta.max || value == meta.min) return Container();
//           return SideTitleWidget(axisSide: meta.axisSide, child: Text(value.toInt().toString(), style: TextStyle(color: Colors.grey[700], fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.left,),);
//         },),),
//       ),
//       borderData: FlBorderData(show: false),
//       lineBarsData: [
//         LineChartBarData(
//           spots: _points, isCurved: true, color: MainColors.primaryColor, barWidth: 3, isStrokeCapRound: true,
//           dotData: const FlDotData(show: false),
//           belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [MainColors.primaryColor.withOpacity(0.3), MainColors.primaryColor.withOpacity(0.0)],),),
//         ),
//       ],
//     );
//   }
// }



