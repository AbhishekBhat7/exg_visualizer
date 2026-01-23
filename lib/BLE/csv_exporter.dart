// import 'dart:io';
// import 'package:exg_visualizer/BLE/db.dart';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:open_filex/open_filex.dart';
// import 'package:intl/intl.dart'; 

// class CSVExporter {
  
//   /// Request storage permission
//   static Future<bool> _requestPermission() async {
//     if (Platform.isAndroid) {
//       // For Android 13+ (API 33+)
//       if (await Permission.manageExternalStorage.isGranted) {
//         return true;
//       }
      
//       // Try requesting storage permission
//       var status = await Permission.storage.request();
//       if (status.isGranted) {
//         return true;
//       }
      
//       // For Android 11+ try manage external storage
//       status = await Permission.manageExternalStorage.request();
//       return status.isGranted;
//     }
//     return true; // iOS doesn't need explicit permission for app documents
//   }

//   /// Get the best directory for saving files
//   static Future<Directory> _getExportDirectory() async {
//     if (Platform.isAndroid) {
//       // Try to get Downloads directory
//       Directory? directory = Directory('/storage/emulated/0/Download');
//       if (await directory.exists()) {
//         return directory;
//       }
      
//       // Fallback to external storage
//       directory = await getExternalStorageDirectory();
//       if (directory != null) {
//         return directory;
//       }
//     }
    
//     // Fallback for iOS and other cases
//     return await getApplicationDocumentsDirectory();
//   }

//   /// Generate CSV content from data points
//   // static String generateCSVContent({
//   //   required RecordingSession session,
//   //   required List<DataPoint> dataPoints,
//   //   required Map<String, dynamic> stats,
//   // }) {
//   //   final StringBuffer buffer = StringBuffer();

//   //   // Add metadata as comments
//   //   buffer.writeln('# EXG Recording Export');
//   //   buffer.writeln('# Device: ${session.deviceName}');
//   //   buffer.writeln('# Start Time: ${session.startTime.toIso8601String()}');
//   //   if (session.endTime != null) {
//   //     buffer.writeln('# End Time: ${session.endTime!.toIso8601String()}');
//   //   }
//   //   buffer.writeln('# Total Points: ${dataPoints.length}');
//   //   buffer.writeln('# Min Value: ${stats['min_value'] ?? 'N/A'}');
//   //   buffer.writeln('# Max Value: ${stats['max_value'] ?? 'N/A'}');
//   //   buffer.writeln('# Avg Value: ${(stats['avg_value'] as num?)?.toStringAsFixed(2) ?? 'N/A'}');
//   //   buffer.writeln('#');

//   //   // Add CSV header
//   //   buffer.writeln('Index,Timestamp_ms,DateTime,Value,Processed_Value');

//   //   // Add data rows
//   //   for (int i = 0; i < dataPoints.length; i++) {
//   //     final point = dataPoints[i];
//   //     final dateTimeStr = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(point.timestamp);
//   //     final timestampMs = point.timestamp.millisecondsSinceEpoch;
      
//   //     buffer.writeln(
//   //       '${i + 1},$timestampMs,$dateTimeStr,${point.value},${point.processedValue ?? point.value}'
//   //     );
//   //   }

//   //   return buffer.toString();
//   // }

// /// Generate CSV content from data points
// static String generateCSVContent({
//   required RecordingSession session,
//   required List<DataPoint> dataPoints,
//   required Map<String, dynamic> stats,
// }) {
//   final StringBuffer buffer = StringBuffer();

//   // Add metadata as comments
//   buffer.writeln('# EXG Recording Export');
//   buffer.writeln('# Device: ${session.deviceName}');
//   buffer.writeln('# Start Time: ${session.startTime.toIso8601String()}');
//   if (session.endTime != null) {
//     buffer.writeln('# End Time: ${session.endTime!.toIso8601String()}');
//   }
//   buffer.writeln('# Total Points: ${dataPoints.length}');
//   buffer.writeln('# Min Value: ${stats['min_value'] ?? 'N/A'}');
//   buffer.writeln('# Max Value: ${stats['max_value'] ?? 'N/A'}');
//   buffer.writeln('# Avg Value: ${(stats['avg_value'] as num?)?.toStringAsFixed(2) ?? 'N/A'}');
//   buffer.writeln('#');

//   // Add CSV header (removed Processed_Value)
//   buffer.writeln('Index,DateTime,Value');

//   // Add data rows (removed processed value)
//   for (int i = 0; i < dataPoints.length; i++) {
//     final point = dataPoints[i];
//     final dateTimeStr = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(point.timestamp);
//     // final timestampMs = point.timestamp.millisecondsSinceEpoch;
    
//     buffer.writeln(
//       '${i + 1},$dateTimeStr,${point.value}'
//     );
//   }

//   return buffer.toString();
// }

//   /// Generate file name
//   static String generateFileName(RecordingSession session) {
//     final dateStr = DateFormat('yyyyMMdd_HHmmss').format(session.startTime);
//     final deviceName = session.deviceName.replaceAll(RegExp(r'[^\w]'), '_');
//     return 'EXG_${deviceName}_$dateStr.csv';
//   }

//   /// Export and show options dialog
//   static Future<void> exportWithDialog({
//     required BuildContext context,
//     required RecordingSession session,
//     required List<DataPoint> dataPoints,
//     required Map<String, dynamic> stats,
//   }) async {
//     if (dataPoints.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("No data to export!"),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     // Show loading
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
//                 Text("Preparing CSV..."),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );

//     try {
//       // Request permission
//       final hasPermission = await _requestPermission();
      
//       // Generate CSV content
//       final csvContent = generateCSVContent(
//         session: session,
//         dataPoints: dataPoints,
//         stats: stats,
//       );

//       // Generate file name
//       final fileName = generateFileName(session);

//       // Get directory and save file
//       final directory = await _getExportDirectory();
//       final filePath = '${directory.path}/$fileName';
//       final file = File(filePath);
//       await file.writeAsString(csvContent);

//       // Close loading dialog
//       Navigator.pop(context);

//       // Show success dialog with options
//       _showExportSuccessDialog(
//         context: context,
//         filePath: filePath,
//         fileName: fileName,
//         dataCount: dataPoints.length,
//         hasStoragePermission: hasPermission,
//       );

//     } catch (e) {
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error exporting: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   /// Show success dialog with multiple options
//   static void _showExportSuccessDialog({
//     required BuildContext context,
//     required String filePath,
//     required String fileName,
//     required int dataCount,
//     required bool hasStoragePermission,
//   }) {
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
//             const Expanded(
//               child: Text("Export Successful", style: TextStyle(fontSize: 18)),
//             ),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // File info
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       const Icon(Icons.insert_drive_file, color: Colors.green, size: 20),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           fileName,
//                           style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     "$dataCount data points",
//                     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Location info
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.blue.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.folder, color: Colors.blue, size: 18),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       hasStoragePermission 
//                         ? "Saved to Downloads folder"
//                         : "Saved to app storage",
//                       style: const TextStyle(fontSize: 12),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
            
//             const SizedBox(height: 20),
//             const Text(
//               "What would you like to do?",
//               style: TextStyle(fontWeight: FontWeight.w500),
//             ),
//           ],
//         ),
//         actionsAlignment: MainAxisAlignment.center,
//         actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//         actions: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Share button
//               ElevatedButton.icon(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   _shareFile(context, filePath);
//                 },
//                 icon: const Icon(Icons.share, size: 20),
//                 label: const Text("Share File"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
              
//               // Open button
//               OutlinedButton.icon(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   _openFile(context, filePath);
//                 },
//                 icon: const Icon(Icons.open_in_new, size: 20),
//                 label: const Text("Open File"),
//                 style: OutlinedButton.styleFrom(
//                   foregroundColor: Colors.green,
//                   side: const BorderSide(color: Colors.green),
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
              
//               // Close button
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("Done"),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   /// Share file using share_plus
//   static Future<void> _shareFile(BuildContext context, String filePath) async {
//     try {
//       final file = XFile(filePath);
      
//       final result = await Share.shareXFiles(
//         [file],
//         subject: 'EXG Recording Data',
//         text: 'EXG recording data exported on ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
//       );

//       if (result.status == ShareResultStatus.success) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("File shared successfully!"),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error sharing file: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   /// Open file with default app
//   static Future<void> _openFile(BuildContext context, String filePath) async {
//     try {
//       final result = await OpenFilex.open(filePath);
      
//       if (result.type != ResultType.done) {
//         // If no app can open CSV, offer to share instead
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text("No app found to open CSV files"),
//             backgroundColor: Colors.orange,
//             action: SnackBarAction(
//               label: "Share Instead",
//               textColor: Colors.white,
//               onPressed: () => _shareFile(context, filePath),
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error opening file: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   /// Quick export and share (used from list view)
//   static Future<void> quickExportAndShare({
//     required BuildContext context,
//     required RecordingSession session,
//     required DatabaseHelper dbHelper,
//   }) async {
//     // Show loading
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
//                 Text("Preparing export..."),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );

//     try {
//       // Get data
//       final dataPoints = await dbHelper.getSessionDataPoints(session.id!);
//       final stats = await dbHelper.getSessionStats(session.id!);

//       if (dataPoints.isEmpty) {
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("No data to export!"),
//             backgroundColor: Colors.orange,
//           ),
//         );
//         return;
//       }

//       // Request permission
//       await _requestPermission();

//       // Generate and save CSV
//       final csvContent = generateCSVContent(
//         session: session,
//         dataPoints: dataPoints,
//         stats: stats,
//       );
//       final fileName = generateFileName(session);
//       final directory = await _getExportDirectory();
//       final filePath = '${directory.path}/$fileName';
//       final file = File(filePath);
//       await file.writeAsString(csvContent);

//       Navigator.pop(context);

//       // Share directly
//       await _shareFile(context, filePath);

//     } catch (e) {
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error exporting: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
// }



// csv_exporter.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'db.dart';

class CSVExporter {
  static Future<void> exportWithDialog({
    required BuildContext context,
    required RecordingSession session,
    required List<DataPoint> dataPoints,
    required Map<String, dynamic> stats,
  }) async {
    // Show loading dialog
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
                Text("Exporting CSV..."),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final file = await _generateCSV(session, dataPoints, stats);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'EXG Recording - ${session.deviceName}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error exporting: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<File> _generateCSV(
    RecordingSession session,
    List<DataPoint> dataPoints,
    Map<String, dynamic> stats,
  ) async {
    final dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');
    final fileName = 'EXG_${session.deviceName}_${dateFormat.format(session.startTime)}.csv';

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');

    final buffer = StringBuffer();

    // Header info
    buffer.writeln('EXG Recording Export');
    buffer.writeln('Device,${session.deviceName}');
    buffer.writeln('Start Time,${DateFormat('yyyy-MM-dd HH:mm:ss').format(session.startTime)}');
    if (session.duration != null) {
      buffer.writeln('Duration,${session.duration!.inSeconds} seconds');
    }
    buffer.writeln('Total Points,${dataPoints.length}');
    buffer.writeln('');
    
    // Stats
    buffer.writeln('Statistics');
    buffer.writeln('Channel,Min,Max,Average');
    buffer.writeln('Channel 1,${stats['min_value1']},${stats['max_value1']},${(stats['avg_value1'] as num?)?.toStringAsFixed(2) ?? "N/A"}');
    buffer.writeln('Channel 2,${stats['min_value2']},${stats['max_value2']},${(stats['avg_value2'] as num?)?.toStringAsFixed(2) ?? "N/A"}');
    buffer.writeln('');

    // Data header
    buffer.writeln('Index,Timestamp,Time (ms),Value 1,Value 2,Processed Value 1,Processed Value 2');

    // Data rows
    final startMs = dataPoints.isNotEmpty
        ? dataPoints.first.timestamp.millisecondsSinceEpoch
        : 0;

    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      final relativeMs = point.timestamp.millisecondsSinceEpoch - startMs;
      final timeStr = DateFormat('HH:mm:ss.SSS').format(point.timestamp);

      buffer.writeln(
        '${i + 1},$timeStr,$relativeMs,${point.value1},${point.value2},${point.processedValue1 ?? ""},${point.processedValue2 ?? ""}',
      );
    }

    await file.writeAsString(buffer.toString());
    return file;
  }
}