// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

// class DataPoint {
//   final double value1;
//   final double value2;
//   final double value3;
//   final double value4;
//   final DateTime timestamp;
//   final double? processedValue1;
//   final double? processedValue2;
//   final double? processedValue3;
//   final double? processedValue4;

//   DataPoint({
//     required this.value1,
//     required this.value2,
//     required this.value3,
//     required this.value4,
//     required this.timestamp,
//     this.processedValue1,
//     this.processedValue2,
//     this.processedValue3,
//     this.processedValue4,
//   });

//   Map<String, dynamic> toMap(int sessionId) {
//     return {
//       'session_id': sessionId,
//       'value1': value1,
//       'value2': value2,
//       'value3': value3,
//       'value4': value4,
//       'processed_value1': processedValue1 ?? value1,
//       'processed_value2': processedValue2 ?? value2,
//       'processed_value3': processedValue3 ?? value3,
//       'processed_value4': processedValue4 ?? value4,
//       'timestamp': timestamp.millisecondsSinceEpoch,
//     };
//   }

//   factory DataPoint.fromMap(Map<String, dynamic> map) {
//     return DataPoint(
//       value1: (map['value1'] as num).toDouble(),
//       value2: (map['value2'] as num).toDouble(),
//       value3: (map['value3'] as num?)?.toDouble() ?? 0.0,
//       value4: (map['value4'] as num?)?.toDouble() ?? 0.0,
//       timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
//       processedValue1: (map['processed_value1'] as num?)?.toDouble(),
//       processedValue2: (map['processed_value2'] as num?)?.toDouble(),
//       processedValue3: (map['processed_value3'] as num?)?.toDouble(),
//       processedValue4: (map['processed_value4'] as num?)?.toDouble(),
//     );
//   }
// }

// class RecordingSession {
//   final int? id;
//   final String deviceName;
//   final DateTime startTime;
//   final Duration? duration;
//   final int dataCount;

//   RecordingSession({
//     this.id,
//     required this.deviceName,
//     required this.startTime,
//     this.duration,
//     this.dataCount = 0,
//   });

//   factory RecordingSession.fromMap(Map<String, dynamic> map) {
//     return RecordingSession(
//       id: map['id'] as int?,
//       deviceName: map['device_name'] as String,
//       startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
//       duration: map['duration_ms'] != null
//           ? Duration(milliseconds: map['duration_ms'] as int)
//           : null,
//       dataCount: map['data_count'] as int? ?? 0,
//     );
//   }
// }

// class DatabaseHelper {
//   static final DatabaseHelper instance = DatabaseHelper._init();
//   static Database? _database;

//   DatabaseHelper._init();

//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await _initDB('exg_data.db');
//     return _database!;
//   }

//   Future<Database> _initDB(String filePath) async {
//     final dbPath = await getDatabasesPath();
//     final path = join(dbPath, filePath);

//     return await openDatabase(
//       path,
//       version: 2, // Incremented version for migration
//       onCreate: _createDB,
//       onUpgrade: _onUpgrade,
//     );
//   }

//   Future<void> _createDB(Database db, int version) async {
//     await db.execute('''
//       CREATE TABLE sessions (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         device_name TEXT NOT NULL,
//         start_time INTEGER NOT NULL,
//         duration_ms INTEGER
//       )
//     ''');

//     await db.execute('''
//       CREATE TABLE data_points (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         session_id INTEGER NOT NULL,
//         value1 REAL NOT NULL,
//         value2 REAL NOT NULL,
//         value3 REAL NOT NULL DEFAULT 0,
//         value4 REAL NOT NULL DEFAULT 0,
//         processed_value1 REAL,
//         processed_value2 REAL,
//         processed_value3 REAL,
//         processed_value4 REAL,
//         timestamp INTEGER NOT NULL,
//         FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
//       )
//     ''');

//     await db.execute(
//         'CREATE INDEX idx_data_points_session ON data_points (session_id)');
//   }

//   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
//     if (oldVersion < 2) {
//       // Add new columns for 4-channel support
//       await db.execute('ALTER TABLE data_points ADD COLUMN value3 REAL NOT NULL DEFAULT 0');
//       await db.execute('ALTER TABLE data_points ADD COLUMN value4 REAL NOT NULL DEFAULT 0');
//       await db.execute('ALTER TABLE data_points ADD COLUMN processed_value3 REAL');
//       await db.execute('ALTER TABLE data_points ADD COLUMN processed_value4 REAL');
//     }
//   }

//   Future<int> createSession(String deviceName) async {
//     final db = await database;
//     final now = DateTime.now().millisecondsSinceEpoch;

//     return await db.insert('sessions', {
//       'device_name': deviceName,
//       'start_time': now,
//     });
//   }

//   Future<void> saveDataPoints(int sessionId, List<DataPoint> dataPoints) async {
//     final db = await database;
//     final batch = db.batch();

//     for (final point in dataPoints) {
//       batch.insert('data_points', point.toMap(sessionId));
//     }

//     await batch.commit(noResult: true);

//     // Update session duration
//     if (dataPoints.isNotEmpty) {
//       final duration = dataPoints.last.timestamp
//           .difference(dataPoints.first.timestamp)
//           .inMilliseconds;
//       await db.update(
//         'sessions',
//         {'duration_ms': duration},
//         where: 'id = ?',
//         whereArgs: [sessionId],
//       );
//     }
//   }

//   Future<List<RecordingSession>> getAllSessions() async {
//     final db = await database;

//     final List<Map<String, dynamic>> maps = await db.rawQuery('''
//       SELECT s.*, COUNT(d.id) as data_count
//       FROM sessions s
//       LEFT JOIN data_points d ON s.id = d.session_id
//       GROUP BY s.id
//       ORDER BY s.start_time DESC
//     ''');

//     return maps.map((map) => RecordingSession.fromMap(map)).toList();
//   }

//   Future<List<DataPoint>> getSessionDataPoints(int sessionId) async {
//     final db = await database;

//     final List<Map<String, dynamic>> maps = await db.query(
//       'data_points',
//       where: 'session_id = ?',
//       whereArgs: [sessionId],
//       orderBy: 'timestamp ASC',
//     );

//     return maps.map((map) => DataPoint.fromMap(map)).toList();
//   }

//   Future<Map<String, dynamic>> getSessionStats(int sessionId) async {
//     final db = await database;

//     final result = await db.rawQuery('''
//       SELECT 
//         MIN(value1) as min_value1,
//         MAX(value1) as max_value1,
//         AVG(value1) as avg_value1,
//         MIN(value2) as min_value2,
//         MAX(value2) as max_value2,
//         AVG(value2) as avg_value2,
//         MIN(value3) as min_value3,
//         MAX(value3) as max_value3,
//         AVG(value3) as avg_value3,
//         MIN(value4) as min_value4,
//         MAX(value4) as max_value4,
//         AVG(value4) as avg_value4,
//         COUNT(*) as count
//       FROM data_points
//       WHERE session_id = ?
//     ''', [sessionId]);

//     return result.first;
//   }

//   Future<void> deleteSession(int sessionId) async {
//     final db = await database;
//     await db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
//   }
// }

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// --------------------------------------------------------------------------
// DATA MODELS - Updated for 4 Channels
// --------------------------------------------------------------------------

class DataPoint {
  final int? id;
  final double value1;
  final double value2;
  final double value3;
  final double value4;
  final DateTime timestamp;
  final double? processedValue1;
  final double? processedValue2;
  final double? processedValue3;
  final double? processedValue4;

  DataPoint({
    this.id,
    required this.value1,
    required this.value2,
    required this.value3,
    required this.value4,
    required this.timestamp,
    this.processedValue1,
    this.processedValue2,
    this.processedValue3,
    this.processedValue4,
  });

  Map<String, dynamic> toMap(int sessionId) {
    return {
      'session_id': sessionId,
      'value1': value1,
      'value2': value2,
      'value3': value3,
      'value4': value4,
      'processed_value1': processedValue1,
      'processed_value2': processedValue2,
      'processed_value3': processedValue3,
      'processed_value4': processedValue4,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory DataPoint.fromMap(Map<String, dynamic> map) {
    return DataPoint(
      id: map['id'] as int?,
      value1: (map['value1'] as num?)?.toDouble() ?? 0.0,
      value2: (map['value2'] as num?)?.toDouble() ?? 0.0,
      value3: (map['value3'] as num?)?.toDouble() ?? 0.0,
      value4: (map['value4'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      processedValue1: (map['processed_value1'] as num?)?.toDouble(),
      processedValue2: (map['processed_value2'] as num?)?.toDouble(),
      processedValue3: (map['processed_value3'] as num?)?.toDouble(),
      processedValue4: (map['processed_value4'] as num?)?.toDouble(),
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
// DATABASE HELPER - Updated for 4 Channels
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

    // ⚠️ UNCOMMENT THIS LINE ONCE to reset database, then comment it back
    // await deleteDatabase(path);
    // print('Database reset - comment out deleteDatabase() after first run!');

    return await openDatabase(
      path,
      version: 4, // Increment version for 4-channel migration
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
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

    // Data points table with 4 channel values
    await db.execute('''
      CREATE TABLE data_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        value1 REAL NOT NULL,
        value2 REAL NOT NULL,
        value3 REAL NOT NULL DEFAULT 0,
        value4 REAL NOT NULL DEFAULT 0,
        processed_value1 REAL,
        processed_value2 REAL,
        processed_value3 REAL,
        processed_value4 REAL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    // Index for faster queries
    await db.execute(
        'CREATE INDEX idx_data_points_session ON data_points (session_id)');
    
    print('Database tables created successfully with 4-channel support');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 4) {
      // Check if columns exist before adding
      final tableInfo = await db.rawQuery('PRAGMA table_info(data_points)');
      final existingColumns = tableInfo.map((c) => c['name'] as String).toSet();
      
      if (!existingColumns.contains('value3')) {
        await db.execute('ALTER TABLE data_points ADD COLUMN value3 REAL NOT NULL DEFAULT 0');
        print('Added value3 column');
      }
      if (!existingColumns.contains('value4')) {
        await db.execute('ALTER TABLE data_points ADD COLUMN value4 REAL NOT NULL DEFAULT 0');
        print('Added value4 column');
      }
      if (!existingColumns.contains('processed_value3')) {
        await db.execute('ALTER TABLE data_points ADD COLUMN processed_value3 REAL');
        print('Added processed_value3 column');
      }
      if (!existingColumns.contains('processed_value4')) {
        await db.execute('ALTER TABLE data_points ADD COLUMN processed_value4 REAL');
        print('Added processed_value4 column');
      }
    }
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
        AVG(value2) as avg_value2,
        MIN(value3) as min_value3,
        MAX(value3) as max_value3,
        AVG(value3) as avg_value3,
        MIN(value4) as min_value4,
        MAX(value4) as max_value4,
        AVG(value4) as avg_value4
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
        'min_value3': 0.0,
        'max_value3': 0.0,
        'avg_value3': 0.0,
        'min_value4': 0.0,
        'max_value4': 0.0,
        'avg_value4': 0.0,
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