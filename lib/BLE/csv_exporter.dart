// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'db.dart';

// class CSVExporter {
//   // Channel name constants for CSV headers
//   static const String _ch1Name = "EEG(Left)";
//   static const String _ch2Name = "EEG(Right)";
//   static const String _ch3Name = "PAL1.5";
//   static const String _ch4Name = "PAR1.5";
//   static const String _ch5Name = "PAR3";
//   static const String _ch6Name = "PBL1.5";
//   static const String _ch7Name = "PBR1.5";
//   static const String _ch8Name = "NoN";

//   static Future<void> exportWithDialog({
//     required BuildContext context,
//     required RecordingSession session,
//     required List<DataPoint> dataPoints,
//     required Map<String, dynamic> stats,
//   }) async {
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
//                 Text("Exporting CSV..."),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );

//     try {
//       final file = await _generateCSV(session, dataPoints, stats);

//       if (context.mounted) {
//         Navigator.pop(context);
//         await Share.shareXFiles(
//           [XFile(file.path)],
//           subject: 'EXG Recording - ${session.deviceName}',
//         );
//       }
//     } catch (e) {
//       if (context.mounted) {
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Error exporting: $e"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   static Future<File> _generateCSV(
//     RecordingSession session,
//     List<DataPoint> dataPoints,
//     Map<String, dynamic> stats,
//   ) async {
//     final dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');
//     final cleanDeviceName = session.deviceName
//         .replaceAll(RegExp(r'[^\w\s-]'), '')
//         .replaceAll(' ', '_');
//     final fileName =
//         'EXG_${cleanDeviceName}_${dateFormat.format(session.startTime)}.csv';

//     final directory = await getTemporaryDirectory();
//     final file = File('${directory.path}/$fileName');

//     final buffer = StringBuffer();

//     // Header info
//     buffer.writeln('EXG Recording Export');
//     buffer.writeln('Device,${session.deviceName}');
//     buffer.writeln(
//         'Start Time,${DateFormat('yyyy-MM-dd HH:mm:ss').format(session.startTime)}');
//     if (session.duration != null) {
//       buffer.writeln('Duration,${_formatDuration(session.duration!)}');
//     }
//     buffer.writeln('Total Points,${dataPoints.length}');
//     buffer.writeln('Channels,8');
//     buffer.writeln(
//         'Channel Names,$_ch1Name,$_ch2Name,$_ch3Name,$_ch4Name,$_ch5Name,$_ch6Name,$_ch7Name,$_ch8Name');
//     buffer.writeln('');

//     // Stats - 8 channels with proper names
//     buffer.writeln('Statistics');
//     buffer.writeln('Channel,Min,Max,Average');
//     buffer.writeln(
//         '$_ch1Name,${_formatValue(stats['min_value1'])},${_formatValue(stats['max_value1'])},${_formatValue(stats['avg_value1'])}');
//     buffer.writeln(
//         '$_ch2Name,${_formatValue(stats['min_value2'])},${_formatValue(stats['max_value2'])},${_formatValue(stats['avg_value2'])}');
//     buffer.writeln(
//         '$_ch3Name,${_formatValue(stats['min_value3'])},${_formatValue(stats['max_value3'])},${_formatValue(stats['avg_value3'])}');
//     buffer.writeln(
//         '$_ch4Name,${_formatValue(stats['min_value4'])},${_formatValue(stats['max_value4'])},${_formatValue(stats['avg_value4'])}');
//     buffer.writeln(
//         '$_ch5Name,${_formatValue(stats['min_value5'])},${_formatValue(stats['max_value5'])},${_formatValue(stats['avg_value5'])}');
//     buffer.writeln(
//         '$_ch6Name,${_formatValue(stats['min_value6'])},${_formatValue(stats['max_value6'])},${_formatValue(stats['avg_value6'])}');
//     buffer.writeln(
//         '$_ch7Name,${_formatValue(stats['min_value7'])},${_formatValue(stats['max_value7'])},${_formatValue(stats['avg_value7'])}');
//     buffer.writeln(
//         '$_ch8Name,${_formatValue(stats['min_value8'])},${_formatValue(stats['max_value8'])},${_formatValue(stats['avg_value8'])}');
//     buffer.writeln('');

//     // Data header with channel names
//     buffer.writeln(
//         'Index,Timestamp,Time (ms),$_ch1Name,$_ch2Name,$_ch3Name,$_ch4Name,$_ch5Name,$_ch6Name,$_ch7Name,$_ch8Name');

//     // Data rows
//     final startMs = dataPoints.isNotEmpty
//         ? dataPoints.first.timestamp.millisecondsSinceEpoch
//         : 0;

//     for (int i = 0; i < dataPoints.length; i++) {
//       final point = dataPoints[i];
//       final relativeMs = point.timestamp.millisecondsSinceEpoch - startMs;
//       final timeStr = DateFormat('HH:mm:ss.SSS').format(point.timestamp);

//       buffer.writeln(
//         '${i + 1},'
//         '$timeStr,'
//         '$relativeMs,'
//         '${point.value1.toStringAsFixed(3)},'
//         '${point.value2.toStringAsFixed(3)},'
//         '${point.value3.toStringAsFixed(3)},'
//         '${point.value4.toStringAsFixed(3)},'
//         '${point.value5.toStringAsFixed(3)},'
//         '${point.value6.toStringAsFixed(3)},'
//         '${point.value7.toStringAsFixed(3)},'
//         '${point.value8.toStringAsFixed(3)}',
//       );
//     }

//     await file.writeAsString(buffer.toString());
//     return file;
//   }

//   static String _formatValue(dynamic value) {
//     if (value == null) return "N/A";
//     if (value is num) return value.toStringAsFixed(3);
//     return value.toString();
//   }

//   static String _formatDuration(Duration duration) {
//     final hours = duration.inHours;
//     final minutes = duration.inMinutes.remainder(60);
//     final seconds = duration.inSeconds.remainder(60);

//     if (hours > 0) {
//       return '${hours}h ${minutes}m ${seconds}s';
//     } else if (minutes > 0) {
//       return '${minutes}m ${seconds}s';
//     } else {
//       return '${seconds}s';
//     }
//   }
// }



import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'db.dart';

class CSVExporter {
  // Channel name constants for CSV headers
  static const String _ch1Name = "EEG(Left)";
  static const String _ch2Name = "EEG(Right)";
  static const String _ch3Name = "PAL1.5";
  static const String _ch4Name = "PAR1.5";
  static const String _ch5Name = "PAR3";
  static const String _ch6Name = "PBL1.5";
  static const String _ch7Name = "PBR1.5";
  static const String _ch8Name = "NoN";
  static const String _pal3Name = "PAL3";  

  static Future<void> exportWithDialog({
    required BuildContext context,
    required RecordingSession session,
    required List<DataPoint> dataPoints,
    required Map<String, dynamic> stats,
  }) async {
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
        Navigator.pop(context);
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'EXG Recording - ${session.deviceName}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
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
    final cleanDeviceName = session.deviceName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(' ', '_');
    final fileName =
        'EXG_${cleanDeviceName}_${dateFormat.format(session.startTime)}.csv';

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');

    final buffer = StringBuffer();

    // Header info
    buffer.writeln('EXG Recording Export');
    buffer.writeln('Device,${session.deviceName}');
    buffer.writeln(
        'Start Time,${DateFormat('yyyy-MM-dd HH:mm:ss').format(session.startTime)}');
    if (session.duration != null) {
      buffer.writeln('Duration,${_formatDuration(session.duration!)}');
    }
    buffer.writeln('Total Points,${dataPoints.length}');
    buffer.writeln('Channels,9'); // UPDATED: 8 channels + PAL3
    buffer.writeln(
        'Channel Names,$_ch1Name,$_ch2Name,$_ch3Name,$_ch4Name,$_ch5Name,$_ch6Name,$_ch7Name,$_ch8Name,$_pal3Name'); // UPDATED
    buffer.writeln('');

    // Stats - 8 channels + PAL3 with proper names
    buffer.writeln('Statistics');
    buffer.writeln('Channel,Min,Max,Average');
    buffer.writeln(
        '$_ch1Name,${_formatValue(stats['min_value1'])},${_formatValue(stats['max_value1'])},${_formatValue(stats['avg_value1'])}');
    buffer.writeln(
        '$_ch2Name,${_formatValue(stats['min_value2'])},${_formatValue(stats['max_value2'])},${_formatValue(stats['avg_value2'])}');
    buffer.writeln(
        '$_ch3Name,${_formatValue(stats['min_value3'])},${_formatValue(stats['max_value3'])},${_formatValue(stats['avg_value3'])}');
    buffer.writeln(
        '$_ch4Name,${_formatValue(stats['min_value4'])},${_formatValue(stats['max_value4'])},${_formatValue(stats['avg_value4'])}');
    buffer.writeln(
        '$_ch5Name,${_formatValue(stats['min_value5'])},${_formatValue(stats['max_value5'])},${_formatValue(stats['avg_value5'])}');
    buffer.writeln(
        '$_ch6Name,${_formatValue(stats['min_value6'])},${_formatValue(stats['max_value6'])},${_formatValue(stats['avg_value6'])}');
    buffer.writeln(
        '$_ch7Name,${_formatValue(stats['min_value7'])},${_formatValue(stats['max_value7'])},${_formatValue(stats['avg_value7'])}');
    buffer.writeln(
        '$_ch8Name,${_formatValue(stats['min_value8'])},${_formatValue(stats['max_value8'])},${_formatValue(stats['avg_value8'])}');
    // NEW: PAL3 statistics
    buffer.writeln(
        '$_pal3Name,${_formatValue(stats['min_pal3'])},${_formatValue(stats['max_pal3'])},${_formatValue(stats['avg_pal3'])}');
    buffer.writeln('');

    // Data header with channel names (8 + PAL3)
    buffer.writeln(
        'Index,Timestamp,Time (ms),$_ch1Name,$_ch2Name,$_ch3Name,$_ch4Name,$_ch5Name,$_ch6Name,$_ch7Name,$_ch8Name,$_pal3Name'); // UPDATED

    // Data rows
    final startMs = dataPoints.isNotEmpty
        ? dataPoints.first.timestamp.millisecondsSinceEpoch
        : 0;

    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      final relativeMs = point.timestamp.millisecondsSinceEpoch - startMs;
      final timeStr = DateFormat('HH:mm:ss.SSS').format(point.timestamp);

      // NEW: Include PAL3 value in the data row
      buffer.writeln(
        '${i + 1},'
        '$timeStr,'
        '$relativeMs,'
        '${point.value1.toStringAsFixed(3)},'
        '${point.value2.toStringAsFixed(3)},'
        '${point.value3.toStringAsFixed(3)},'
        '${point.value4.toStringAsFixed(3)},'
        '${point.value5.toStringAsFixed(3)},'
        '${point.value6.toStringAsFixed(3)},'
        '${point.value7.toStringAsFixed(3)},'
        '${point.value8.toStringAsFixed(3)},'
        '${_formatPAL3Value(point.pal3)}', // NEW: Add PAL3 value
      );
    }

    await file.writeAsString(buffer.toString());
    return file;
  }

  static String _formatValue(dynamic value) {
    if (value == null) return "N/A";
    if (value is num) return value.toStringAsFixed(3);
    return value.toString();
  }

  /// NEW: Format PAL3 value with fallback for null
  static String _formatPAL3Value(double? value) {
    if (value == null) return "N/A";
    return value.toStringAsFixed(3);
  }

  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}