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
    // Clean device name for filename (remove special characters)
    final cleanDeviceName = session.deviceName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final fileName = 'EXG_${cleanDeviceName}_${dateFormat.format(session.startTime)}.csv';

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');

    final buffer = StringBuffer();

    // Header info
    buffer.writeln('EXG Recording Export');
    buffer.writeln('Device,${session.deviceName}');
    buffer.writeln('Start Time,${DateFormat('yyyy-MM-dd HH:mm:ss').format(session.startTime)}');
    if (session.duration != null) {
      buffer.writeln('Duration,${_formatDuration(session.duration!)}');
    }
    buffer.writeln('Total Points,${dataPoints.length}');
    buffer.writeln('Channels,4');
    buffer.writeln('');
    
    // Stats - Updated for 4 channels
    buffer.writeln('Statistics');
    buffer.writeln('Channel,Min,Max,Average');
    buffer.writeln('Channel 1,${_formatValue(stats['min_value1'])},${_formatValue(stats['max_value1'])},${_formatValue(stats['avg_value1'])}');
    buffer.writeln('Channel 2,${_formatValue(stats['min_value2'])},${_formatValue(stats['max_value2'])},${_formatValue(stats['avg_value2'])}');
    buffer.writeln('Channel 3,${_formatValue(stats['min_value3'])},${_formatValue(stats['max_value3'])},${_formatValue(stats['avg_value3'])}');
    buffer.writeln('Channel 4,${_formatValue(stats['min_value4'])},${_formatValue(stats['max_value4'])},${_formatValue(stats['avg_value4'])}');
    buffer.writeln('');

    // Data header - Updated for 4 channels
    // buffer.writeln('Index,Timestamp,Time (ms),Value 1,Value 2,Value 3,Value 4,Processed Value 1,Processed Value 2,Processed Value 3,Processed Value 4');
    buffer.writeln('Index,Timestamp,Time (ms),Value 1,Value 2,Value 3,Value 4');
    // Data rows
    final startMs = dataPoints.isNotEmpty
        ? dataPoints.first.timestamp.millisecondsSinceEpoch
        : 0;

    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      final relativeMs = point.timestamp.millisecondsSinceEpoch - startMs;
      final timeStr = DateFormat('HH:mm:ss.SSS').format(point.timestamp);

      buffer.writeln(
        '${i + 1},'
        '$timeStr,'
        '$relativeMs,'
        '${point.value1.toStringAsFixed(3)},'
        '${point.value2.toStringAsFixed(3)},'
        '${point.value3.toStringAsFixed(3)},'
        '${point.value4.toStringAsFixed(3)},'
        // '${_formatProcessedValue(point.processedValue1)},'
        // '${_formatProcessedValue(point.processedValue2)},'
        // '${_formatProcessedValue(point.processedValue3)},'
        // '${_formatProcessedValue(point.processedValue4)}',
      );
    }

    await file.writeAsString(buffer.toString());
    return file;
  }

  /// Format a stat value for CSV
  static String _formatValue(dynamic value) {
    if (value == null) return "N/A";
    if (value is num) return value.toStringAsFixed(3);
    return value.toString();
  }

  /// Format processed value (can be null)
  // static String _formatProcessedValue(double? value) {
  //   if (value == null) return "";
  //   return value.toStringAsFixed(3);
  // }

  /// Format duration nicely
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