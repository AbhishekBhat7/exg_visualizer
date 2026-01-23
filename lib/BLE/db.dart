// // // lib/Database/db_helper.dart

// // import 'package:fl_chart/fl_chart.dart';
// // import 'package:path/path.dart';
// // import 'package:sqflite/sqflite.dart';

// // class Session {
// //   final int id;
// //   final DateTime createdAt;

// //   Session({required this.id, required this.createdAt});
// // }

// // class DBHelper {
// //   static final DBHelper _instance = DBHelper._internal();
// //   factory DBHelper() => _instance;
// //   DBHelper._internal();

// //   static Database? _database;

// //   Future<Database> get database async {
// //     if (_database != null) return _database!;
// //     _database = await _initDB();
// //     return _database!;
// //   }

// //   Future<Database> _initDB() async {
// //     String path = join(await getDatabasesPath(), 'exg_data.db');
// //     return await openDatabase(
// //       path,
// //       version: 1,
// //       onCreate: _onCreate,
// //     );
// //   }

// //   Future<void> _onCreate(Database db, int version) async {
// //     await db.execute('''
// //       CREATE TABLE sessions(
// //         id INTEGER PRIMARY KEY AUTOINCREMENT,
// //         createdAt TEXT NOT NULL
// //       )
// //     ''');
// //     await db.execute('''
// //       CREATE TABLE data_points(
// //         id INTEGER PRIMARY KEY AUTOINCREMENT,
// //         sessionId INTEGER NOT NULL,
// //         timestamp REAL NOT NULL,
// //         value REAL NOT NULL,
// //         FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
// //       )
// //     ''');
// //   }

// //   Future<void> saveSession(List<FlSpot> points) async {
// //     if (points.isEmpty) return;

// //     final db = await database;

// //     // Use a transaction for efficiency and data integrity
// //     await db.transaction((txn) async {
// //       // 1. Create a new session entry
// //       int sessionId = await txn.insert('sessions', {
// //         'createdAt': DateTime.now().toIso8601String(),
// //       });

// //       // 2. Batch insert all data points for that session
// //       Batch batch = txn.batch();
// //       for (var point in points) {
// //         batch.insert('data_points', {
// //           'sessionId': sessionId,
// //           'timestamp': point.x,
// //           'value': point.y,
// //         });
// //       }
// //       await batch.commit(noResult: true);
// //     });
// //   }

// //   Future<List<Session>> getSessions() async {
// //     final db = await database;
// //     final List<Map<String, dynamic>> maps = await db.query(
// //       'sessions',
// //       orderBy: 'createdAt DESC',
// //     );

// //     return List.generate(maps.length, (i) {
// //       return Session(
// //         id: maps[i]['id'],
// //         createdAt: DateTime.parse(maps[i]['createdAt']),
// //       );
// //     });
// //   }

// //   Future<List<FlSpot>> getDataPointsForSession(int sessionId) async {
// //     final db = await database;
// //     final List<Map<String, dynamic>> maps = await db.query(
// //       'data_points',
// //       where: 'sessionId = ?',
// //       whereArgs: [sessionId],
// //       orderBy: 'timestamp ASC',
// //     );

// //     return List.generate(maps.length, (i) {
// //       return FlSpot(
// //         maps[i]['timestamp'],
// //         maps[i]['value'],
// //       );
// //     });
// //   }
// // }



// // import 'package:sqflite/sqflite.dart';
// // import 'package:path/path.dart';

// // // Data Point Model
// // class ExgDataPoint {
// //   final int? id;
// //   final int sessionId;
// //   final double value;
// //   final int timestamp; // milliseconds since epoch

// //   ExgDataPoint({
// //     this.id,
// //     required this.sessionId,
// //     required this.value,
// //     required this.timestamp,
// //   });

// //   Map<String, dynamic> toMap() {
// //     return {
// //       'id': id,
// //       'session_id': sessionId,
// //       'value': value,
// //       'timestamp': timestamp,
// //     };
// //   }

// //   factory ExgDataPoint.fromMap(Map<String, dynamic> map) {
// //     return ExgDataPoint(
// //       id: map['id'],
// //       sessionId: map['session_id'],
// //       value: map['value'],
// //       timestamp: map['timestamp'],
// //     );
// //   }
// // }

// // // Session Model
// // class ExgSession {
// //   final int? id;
// //   final String deviceName;
// //   final String sessionName;
// //   final int startTime;
// //   final int endTime;
// //   final int dataPointCount;

// //   ExgSession({
// //     this.id,
// //     required this.deviceName,
// //     required this.sessionName,
// //     required this.startTime,
// //     required this.endTime,
// //     required this.dataPointCount,
// //   });

// //   Map<String, dynamic> toMap() {
// //     return {
// //       'id': id,
// //       'device_name': deviceName,
// //       'session_name': sessionName,
// //       'start_time': startTime,
// //       'end_time': endTime,
// //       'data_point_count': dataPointCount,
// //     };
// //   }

// //   factory ExgSession.fromMap(Map<String, dynamic> map) {
// //     return ExgSession(
// //       id: map['id'],
// //       deviceName: map['device_name'],
// //       sessionName: map['session_name'],
// //       startTime: map['start_time'],
// //       endTime: map['end_time'],
// //       dataPointCount: map['data_point_count'],
// //     );
// //   }

// //   String get formattedStartTime {
// //     final date = DateTime.fromMillisecondsSinceEpoch(startTime);
// //     return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
// //   }

// //   String get duration {
// //     final durationMs = endTime - startTime;
// //     final seconds = (durationMs / 1000).round();
// //     if (seconds < 60) {
// //       return '${seconds}s';
// //     }
// //     final minutes = seconds ~/ 60;
// //     final remainingSeconds = seconds % 60;
// //     if (minutes < 60) {
// //       return '${minutes}m ${remainingSeconds}s';
// //     }
// //     final hours = minutes ~/ 60;
// //     final remainingMinutes = minutes % 60;
// //     return '${hours}h ${remainingMinutes}m';
// //   }
// // }

// // // Database Helper Singleton
// // class DatabaseHelper {
// //   static final DatabaseHelper instance = DatabaseHelper._init();
// //   static Database? _database;

// //   DatabaseHelper._init();

// //   Future<Database> get database async {
// //     if (_database != null) return _database!;
// //     _database = await _initDB('exg_data.db');
// //     return _database!;
// //   }

// //   Future<Database> _initDB(String filePath) async {
// //     final dbPath = await getDatabasesPath();
// //     final path = join(dbPath, filePath);

// //     return await openDatabase(
// //       path,
// //       version: 1,
// //       onCreate: _createDB,
// //     );
// //   }

// //   Future<void> _createDB(Database db, int version) async {
// //     // Create sessions table
// //     await db.execute('''
// //       CREATE TABLE sessions (
// //         id INTEGER PRIMARY KEY AUTOINCREMENT,
// //         device_name TEXT NOT NULL,
// //         session_name TEXT NOT NULL,
// //         start_time INTEGER NOT NULL,
// //         end_time INTEGER NOT NULL,
// //         data_point_count INTEGER NOT NULL
// //       )
// //     ''');

// //     // Create data_points table
// //     await db.execute('''
// //       CREATE TABLE data_points (
// //         id INTEGER PRIMARY KEY AUTOINCREMENT,
// //         session_id INTEGER NOT NULL,
// //         value REAL NOT NULL,
// //         timestamp INTEGER NOT NULL,
// //         FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
// //       )
// //     ''');

// //     // Create index for faster queries
// //     await db.execute('''
// //       CREATE INDEX idx_data_points_session_id ON data_points (session_id)
// //     ''');

// //     await db.execute('''
// //       CREATE INDEX idx_data_points_timestamp ON data_points (timestamp)
// //     ''');
// //   }

// //   // ==================== SESSION OPERATIONS ====================

// //   Future<int> createSession(ExgSession session) async {
// //     final db = await database;
// //     return await db.insert('sessions', session.toMap());
// //   }

// //   Future<List<ExgSession>> getAllSessions() async {
// //     final db = await database;
// //     final result = await db.query('sessions', orderBy: 'start_time DESC');
// //     return result.map((map) => ExgSession.fromMap(map)).toList();
// //   }

// //   Future<ExgSession?> getSession(int id) async {
// //     final db = await database;
// //     final result = await db.query('sessions', where: 'id = ?', whereArgs: [id]);
// //     if (result.isEmpty) return null;
// //     return ExgSession.fromMap(result.first);
// //   }

// //   Future<int> updateSession(ExgSession session) async {
// //     final db = await database;
// //     return await db.update(
// //       'sessions',
// //       session.toMap(),
// //       where: 'id = ?',
// //       whereArgs: [session.id],
// //     );
// //   }

// //   Future<int> deleteSession(int id) async {
// //     final db = await database;
// //     // First delete all data points for this session
// //     await db.delete('data_points', where: 'session_id = ?', whereArgs: [id]);
// //     // Then delete the session
// //     return await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
// //   }

// //   Future<int> deleteAllSessions() async {
// //     final db = await database;
// //     await db.delete('data_points');
// //     return await db.delete('sessions');
// //   }

// //   // ==================== DATA POINT OPERATIONS ====================

// //   Future<void> insertDataPoints(int sessionId, List<ExgDataPoint> points) async {
// //     final db = await database;
// //     final batch = db.batch();

// //     for (final point in points) {
// //       batch.insert('data_points', {
// //         'session_id': sessionId,
// //         'value': point.value,
// //         'timestamp': point.timestamp,
// //       });
// //     }

// //     await batch.commit(noResult: true);
// //   }

// //   Future<List<ExgDataPoint>> getDataPointsForSession(int sessionId) async {
// //     final db = await database;
// //     final result = await db.query(
// //       'data_points',
// //       where: 'session_id = ?',
// //       whereArgs: [sessionId],
// //       orderBy: 'timestamp ASC',
// //     );
// //     return result.map((map) => ExgDataPoint.fromMap(map)).toList();
// //   }

// //   Future<List<ExgDataPoint>> getDataPointsInRange(
// //     int sessionId,
// //     int startTimestamp,
// //     int endTimestamp,
// //   ) async {
// //     final db = await database;
// //     final result = await db.query(
// //       'data_points',
// //       where: 'session_id = ? AND timestamp >= ? AND timestamp <= ?',
// //       whereArgs: [sessionId, startTimestamp, endTimestamp],
// //       orderBy: 'timestamp ASC',
// //     );
// //     return result.map((map) => ExgDataPoint.fromMap(map)).toList();
// //   }

// //   // ==================== STATISTICS ====================

// //   Future<Map<String, double>> getSessionStatistics(int sessionId) async {
// //     final db = await database;
// //     final result = await db.rawQuery('''
// //       SELECT 
// //         MIN(value) as min_value,
// //         MAX(value) as max_value,
// //         AVG(value) as avg_value,
// //         COUNT(*) as count
// //       FROM data_points
// //       WHERE session_id = ?
// //     ''', [sessionId]);

// //     if (result.isEmpty) {
// //       return {'min': 0, 'max': 0, 'avg': 0, 'count': 0};
// //     }

// //     final row = result.first;
// //     return {
// //       'min': (row['min_value'] as num?)?.toDouble() ?? 0,
// //       'max': (row['max_value'] as num?)?.toDouble() ?? 0,
// //       'avg': (row['avg_value'] as num?)?.toDouble() ?? 0,
// //       'count': (row['count'] as num?)?.toDouble() ?? 0,
// //     };
// //   }

// //   Future<int> getTotalDataPointsCount() async {
// //     final db = await database;
// //     final result = await db.rawQuery('SELECT COUNT(*) as count FROM data_points');
// //     return (result.first['count'] as int?) ?? 0;
// //   }

// //   Future<int> getTotalSessionsCount() async {
// //     final db = await database;
// //     final result = await db.rawQuery('SELECT COUNT(*) as count FROM sessions');
// //     return (result.first['count'] as int?) ?? 0;
// //   }

// //   // ==================== DATABASE MANAGEMENT ====================

// //   Future<void> close() async {
// //     final db = await database;
// //     await db.close();
// //     _database = null;
// //   }

// //   Future<void> deleteDatabase() async {
// //     final dbPath = await getDatabasesPath();
// //     final path = join(dbPath, 'exg_data.db');
// //     await databaseFactory.deleteDatabase(path);
// //     _database = null;
// //   }
// // }




// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

// // --------------------------------------------------------------------------
// // DATA MODELS
// // --------------------------------------------------------------------------

// class DataPoint {
//   final int? id;
//   final double value;
//   final DateTime timestamp;
//   final double? processedValue;

//   DataPoint({
//     this.id,
//     required this.value,
//     required this.timestamp,
//     this.processedValue,
//   });

//   factory DataPoint.fromJson(Map<String, dynamic> json) {
//     return DataPoint(
//       id: json['id'] as int?,
//       value: json['value'] as double,
//       timestamp: DateTime.parse(json['timestamp'] as String),
//       processedValue: json['processed_value'] as double?,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'value': value,
//       'timestamp': timestamp.toIso8601String(),
//       'processed_value': processedValue,
//     };
//   }
// }

// class RecordingSession {
//   final int? id;
//   final String deviceName;
//   final DateTime startTime;
//   final DateTime? endTime;
//   final int dataCount;
//   final String? notes;

//   RecordingSession({
//     this.id,
//     required this.deviceName,
//     required this.startTime,
//     this.endTime,
//     required this.dataCount,
//     this.notes,
//   });

//   factory RecordingSession.fromJson(Map<String, dynamic> json) {
//     return RecordingSession(
//       id: json['id'] as int?,
//       deviceName: json['device_name'] as String,
//       startTime: DateTime.parse(json['start_time'] as String),
//       endTime: json['end_time'] != null
//           ? DateTime.parse(json['end_time'] as String)
//           : null,
//       dataCount: json['data_count'] as int? ?? 0,
//       notes: json['notes'] as String?,
//     );
//   }

//   Duration? get duration {
//     if (endTime == null) return null;
//     return endTime!.difference(startTime);
//   }
// }

// // --------------------------------------------------------------------------
// // DATABASE HELPER
// // --------------------------------------------------------------------------

// class DatabaseHelper {
//   static final DatabaseHelper instance = DatabaseHelper._init();
//   static Database? _database;

//   DatabaseHelper._init();

//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await _initDB('exg_recordings.db');
//     return _database!;
//   }

//   Future<Database> _initDB(String filePath) async {
//     final dbPath = await getDatabasesPath();
//     final path = join(dbPath, filePath);

//     return await openDatabase(
//       path,
//       version: 1,
//       onCreate: _createDB,
//     );
//   }

//   Future<void> _createDB(Database db, int version) async {
//     // Sessions table
//     await db.execute('''
//       CREATE TABLE sessions (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         device_name TEXT NOT NULL,
//         start_time TEXT NOT NULL,
//         end_time TEXT,
//         data_count INTEGER DEFAULT 0,
//         notes TEXT
//       )
//     ''');

//     // Data points table
//     await db.execute('''
//       CREATE TABLE data_points (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         session_id INTEGER NOT NULL,
//         value REAL NOT NULL,
//         processed_value REAL,
//         timestamp TEXT NOT NULL,
//         FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
//       )
//     ''');

//     // Index for faster queries
//     await db.execute('''
//       CREATE INDEX idx_data_points_session ON data_points (session_id)
//     ''');
//   }

//   // --------------------------------------------------------------------------
//   // SESSION OPERATIONS
//   // --------------------------------------------------------------------------

//   Future<int> createSession(String deviceName) async {
//     final db = await database;
//     return await db.insert('sessions', {
//       'device_name': deviceName,
//       'start_time': DateTime.now().toIso8601String(),
//       'data_count': 0,
//     });
//   }

//   Future<void> updateSession({
//     required int sessionId,
//     DateTime? endTime,
//     int? dataCount,
//     String? notes,
//   }) async {
//     final db = await database;
//     final Map<String, dynamic> updates = {};

//     if (endTime != null) updates['end_time'] = endTime.toIso8601String();
//     if (dataCount != null) updates['data_count'] = dataCount;
//     if (notes != null) updates['notes'] = notes;

//     if (updates.isNotEmpty) {
//       await db.update(
//         'sessions',
//         updates,
//         where: 'id = ?',
//         whereArgs: [sessionId],
//       );
//     }
//   }

//   Future<List<RecordingSession>> getAllSessions() async {
//     final db = await database;
//     final result = await db.query(
//       'sessions',
//       orderBy: 'start_time DESC',
//     );
//     return result.map((json) => RecordingSession.fromJson(json)).toList();
//   }

//   Future<RecordingSession?> getSession(int sessionId) async {
//     final db = await database;
//     final result = await db.query(
//       'sessions',
//       where: 'id = ?',
//       whereArgs: [sessionId],
//       limit: 1,
//     );
//     if (result.isEmpty) return null;
//     return RecordingSession.fromJson(result.first);
//   }

//   Future<void> deleteSession(int sessionId) async {
//     final db = await database;
//     // Delete data points first (or use CASCADE)
//     await db.delete(
//       'data_points',
//       where: 'session_id = ?',
//       whereArgs: [sessionId],
//     );
//     await db.delete(
//       'sessions',
//       where: 'id = ?',
//       whereArgs: [sessionId],
//     );
//   }

//   // --------------------------------------------------------------------------
//   // DATA POINT OPERATIONS
//   // --------------------------------------------------------------------------

//   Future<void> saveDataPoints(int sessionId, List<DataPoint> points) async {
//     if (points.isEmpty) return;

//     final db = await database;
//     final batch = db.batch();

//     for (var point in points) {
//       batch.insert('data_points', {
//         'session_id': sessionId,
//         'value': point.value,
//         'processed_value': point.processedValue,
//         'timestamp': point.timestamp.toIso8601String(),
//       });
//     }

//     await batch.commit(noResult: true);

//     // Update session with data count
//     await updateSession(
//       sessionId: sessionId,
//       endTime: DateTime.now(),
//       dataCount: points.length,
//     );
//   }

//   Future<List<DataPoint>> getSessionDataPoints(int sessionId) async {
//     final db = await database;
//     final result = await db.query(
//       'data_points',
//       where: 'session_id = ?',
//       whereArgs: [sessionId],
//       orderBy: 'timestamp ASC',
//     );
//     return result.map((json) => DataPoint.fromJson(json)).toList();
//   }

//   Future<Map<String, dynamic>> getSessionStats(int sessionId) async {
//     final db = await database;
//     final result = await db.rawQuery('''
//       SELECT 
//         COUNT(*) as count,
//         MIN(value) as min_value,
//         MAX(value) as max_value,
//         AVG(value) as avg_value
//       FROM data_points 
//       WHERE session_id = ?
//     ''', [sessionId]);

//     if (result.isEmpty) {
//       return {'count': 0, 'min_value': 0, 'max_value': 0, 'avg_value': 0};
//     }
//     return result.first;
//   }

//   // Close database
//   Future<void> close() async {
//     final db = await database;
//     db.close();
//     _database = null;
//   }
// }


import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// --------------------------------------------------------------------------
// DATA MODELS
// --------------------------------------------------------------------------

class DataPoint {
  final int? id;
  final double value1;
  final double value2;
  final DateTime timestamp;
  final double? processedValue1;
  final double? processedValue2;

  DataPoint({
    this.id,
    required this.value1,
    required this.value2,
    required this.timestamp,
    this.processedValue1,
    this.processedValue2,
  });

  Map<String, dynamic> toMap(int sessionId) {
    return {
      'session_id': sessionId,
      'value1': value1,
      'value2': value2,
      'processed_value1': processedValue1,
      'processed_value2': processedValue2,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory DataPoint.fromMap(Map<String, dynamic> map) {
    return DataPoint(
      id: map['id'] as int?,
      value1: (map['value1'] as num?)?.toDouble() ?? 0.0,
      value2: (map['value2'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      processedValue1: (map['processed_value1'] as num?)?.toDouble(),
      processedValue2: (map['processed_value2'] as num?)?.toDouble(),
    );
  }
}

class RecordingSession {
  final int? id;
  final String deviceName;
  final DateTime startTime;
  final Duration? duration;
  final int dataCount;
  final String? notes;

  RecordingSession({
    this.id,
    required this.deviceName,
    required this.startTime,
    this.duration,
    this.dataCount = 0,
    this.notes,
  });

  factory RecordingSession.fromMap(Map<String, dynamic> map) {
    return RecordingSession(
      id: map['id'] as int?,
      deviceName: map['device_name'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      duration: map['duration_ms'] != null
          ? Duration(milliseconds: map['duration_ms'] as int)
          : null,
      dataCount: (map['data_count'] as int?) ?? 0,
      notes: map['notes'] as String?,
    );
  }
}

// --------------------------------------------------------------------------
// DATABASE HELPER
// --------------------------------------------------------------------------

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('exg_recordings.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // ⚠️ DELETE OLD DATABASE - Remove this line after first run!
    await deleteDatabase(path);
    print('Database reset - remove deleteDatabase() call after first run!');

    return await openDatabase(
      path,
      version: 3, // Increment version
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    print('Creating database with version $version');
    
    // Sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_name TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        duration_ms INTEGER,
        data_count INTEGER DEFAULT 0,
        notes TEXT
      )
    ''');

    // Data points table with dual values
    await db.execute('''
      CREATE TABLE data_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        value1 REAL NOT NULL,
        value2 REAL NOT NULL,
        processed_value1 REAL,
        processed_value2 REAL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    // Index for faster queries
    await db.execute(
        'CREATE INDEX idx_data_points_session ON data_points (session_id)');
    
    print('Database tables created successfully');
  }

  // --------------------------------------------------------------------------
  // SESSION OPERATIONS
  // --------------------------------------------------------------------------

  Future<int> createSession(String deviceName) async {
    final db = await database;
    final id = await db.insert('sessions', {
      'device_name': deviceName,
      'start_time': DateTime.now().millisecondsSinceEpoch,
      'data_count': 0,
    });
    print('Created session with id: $id');
    return id;
  }

  Future<void> updateSession({
    required int sessionId,
    Duration? duration,
    int? dataCount,
    String? notes,
  }) async {
    final db = await database;
    final Map<String, dynamic> updates = {};

    if (duration != null) updates['duration_ms'] = duration.inMilliseconds;
    if (dataCount != null) updates['data_count'] = dataCount;
    if (notes != null) updates['notes'] = notes;

    if (updates.isNotEmpty) {
      await db.update(
        'sessions',
        updates,
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    }
  }

  Future<List<RecordingSession>> getAllSessions() async {
    final db = await database;
    
    // First, let's check what columns exist
    final tableInfo = await db.rawQuery('PRAGMA table_info(sessions)');
    print('Sessions table columns: ${tableInfo.map((c) => c['name']).toList()}');
    
    final result = await db.rawQuery('''
      SELECT 
        s.id,
        s.device_name,
        s.start_time,
        s.duration_ms,
        s.notes,
        COALESCE(s.data_count, COUNT(d.id)) as data_count
      FROM sessions s
      LEFT JOIN data_points d ON s.id = d.session_id
      GROUP BY s.id
      ORDER BY s.start_time DESC
    ''');

    return result.map((map) => RecordingSession.fromMap(map)).toList();
  }

  Future<RecordingSession?> getSession(int sessionId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        s.id,
        s.device_name,
        s.start_time,
        s.duration_ms,
        s.notes,
        COALESCE(s.data_count, COUNT(d.id)) as data_count
      FROM sessions s
      LEFT JOIN data_points d ON s.id = d.session_id
      WHERE s.id = ?
      GROUP BY s.id
    ''', [sessionId]);

    if (result.isEmpty) return null;
    return RecordingSession.fromMap(result.first);
  }

  // --------------------------------------------------------------------------
  // DATA POINT OPERATIONS
  // --------------------------------------------------------------------------

  Future<void> saveDataPoints(int sessionId, List<DataPoint> dataPoints) async {
    if (dataPoints.isEmpty) return;

    final db = await database;
    final batch = db.batch();

    for (var point in dataPoints) {
      batch.insert('data_points', point.toMap(sessionId));
    }

    await batch.commit(noResult: true);

    // Update session with duration and data count
    final firstTime = dataPoints.first.timestamp;
    final lastTime = dataPoints.last.timestamp;
    final duration = lastTime.difference(firstTime);

    // Get total count for this session
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM data_points WHERE session_id = ?',
      [sessionId],
    );
    final totalCount = countResult.first['count'] as int;

    await updateSession(
      sessionId: sessionId,
      duration: duration,
      dataCount: totalCount,
    );
    
    print('Saved ${dataPoints.length} data points to session $sessionId');
  }

  Future<List<DataPoint>> getSessionDataPoints(int sessionId) async {
    final db = await database;
    final result = await db.query(
      'data_points',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return result.map((map) => DataPoint.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getSessionStats(int sessionId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as count,
        MIN(value1) as min_value1,
        MAX(value1) as max_value1,
        AVG(value1) as avg_value1,
        MIN(value2) as min_value2,
        MAX(value2) as max_value2,
        AVG(value2) as avg_value2
      FROM data_points
      WHERE session_id = ?
    ''', [sessionId]);

    if (result.isEmpty) {
      return {
        'count': 0,
        'min_value1': 0.0,
        'max_value1': 0.0,
        'avg_value1': 0.0,
        'min_value2': 0.0,
        'max_value2': 0.0,
        'avg_value2': 0.0,
      };
    }
    return result.first;
  }

  Future<void> deleteSession(int sessionId) async {
    final db = await database;
    await db.delete(
      'data_points',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // --------------------------------------------------------------------------
  // UTILITY METHODS
  // --------------------------------------------------------------------------

  /// Call this to completely reset the database
  Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'exg_recordings.db');
    await deleteDatabase(path);
    print('Database has been reset');
    
    // Reinitialize
    _database = await _initDB('exg_recordings.db');
  }

  /// Debug method to check table structure
  Future<void> debugPrintSchema() async {
    final db = await database;
    
    print('=== DATABASE SCHEMA ===');
    
    final sessions = await db.rawQuery('PRAGMA table_info(sessions)');
    print('Sessions columns:');
    for (var col in sessions) {
      print('  - ${col['name']} (${col['type']})');
    }
    
    final dataPoints = await db.rawQuery('PRAGMA table_info(data_points)');
    print('Data Points columns:');
    for (var col in dataPoints) {
      print('  - ${col['name']} (${col['type']})');
    }
    
    print('=======================');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}