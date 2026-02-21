import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/polling_station.dart';
import '../models/violation_type.dart';
import '../models/incident_report.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'election_watch.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // สร้างตาราง
    await db.execute('''
      CREATE TABLE polling_station (
        station_id   INTEGER PRIMARY KEY,
        station_name TEXT NOT NULL,
        zone         TEXT NOT NULL,
        province     TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE violation_type (
        type_id   INTEGER PRIMARY KEY AUTOINCREMENT,
        type_name TEXT NOT NULL,
        severity  TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE incident_report (
        report_id      INTEGER PRIMARY KEY AUTOINCREMENT,
        station_id     INTEGER NOT NULL,
        type_id        INTEGER NOT NULL,
        reporter_name  TEXT NOT NULL,
        description    TEXT,
        evidence_photo TEXT,
        timestamp      TEXT NOT NULL,
        ai_result      TEXT,
        ai_confidence  REAL DEFAULT 0.0,
        FOREIGN KEY (station_id) REFERENCES polling_station(station_id),
        FOREIGN KEY (type_id)    REFERENCES violation_type(type_id)
      )
    ''');

    // Insert ข้อมูลตัวอย่าง
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    // polling_station
    final stations = [
      {'station_id': 101, 'station_name': 'โรงเรียนวัดพระมหาธาตุ', 'zone': 'เขต 1', 'province': 'นครศรีธรรมราช'},
      {'station_id': 102, 'station_name': 'เต็นท์หน้าตลาดท่าวัง',  'zone': 'เขต 1', 'province': 'นครศรีธรรมราช'},
      {'station_id': 103, 'station_name': 'ศาลากลางหมู่บ้านคีรีวง','zone': 'เขต 2', 'province': 'นครศรีธรรมราช'},
      {'station_id': 104, 'station_name': 'หอประชุมอำเภอทุ่งสง',   'zone': 'เขต 3', 'province': 'นครศรีธรรมราช'},
      {'station_id': 105, 'station_name': 'โรงเรียนเบญจมราชูทิศ',  'zone': 'เขต 1', 'province': 'นครศรีธรรมราช'},
      {'station_id': 106, 'station_name': 'วัดพระธาตุน้อย',         'zone': 'เขต 2', 'province': 'นครศรีธรรมราช'},
    ];
    for (final s in stations) {
      await db.insert('polling_station', s, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // violation_type
    final violations = [
      {'type_id': 1, 'type_name': 'ซื้อสิทธิ์ขายเสียง (Buying Votes)',          'severity': 'High'},
      {'type_id': 2, 'type_name': 'ขนคนไปลงคะแนน (Transportation)',              'severity': 'High'},
      {'type_id': 3, 'type_name': 'หาเสียงเกินเวลา (Overtime Campaign)',          'severity': 'Medium'},
      {'type_id': 4, 'type_name': 'ทำลายป้ายหาเสียง (Vandalism)',                'severity': 'Low'},
      {'type_id': 5, 'type_name': 'เจ้าหน้าที่วางตัวไม่เป็นกลาง (Bias Official)', 'severity': 'High'},
    ];
    for (final v in violations) {
      await db.insert('violation_type', v, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // incident_report
    final incidents = [
      {'station_id': 101, 'type_id': 1, 'reporter_name': 'พลเมืองดี 01', 'description': 'พบเห็นการแจกเงินบริเวณหน้าหน่วย',  'evidence_photo': null, 'timestamp': '2026-02-08 09:30:00', 'ai_result': 'Money',  'ai_confidence': 0.95},
      {'station_id': 102, 'type_id': 3, 'reporter_name': 'สมชาย ใจกล้า', 'description': 'มีการเปิดรถแห่เสียงดังรบกวน',       'evidence_photo': null, 'timestamp': '2026-02-08 10:15:00', 'ai_result': 'Crowd',  'ai_confidence': 0.75},
      {'station_id': 103, 'type_id': 5, 'reporter_name': 'Anonymous',     'description': 'เจ้าหน้าที่พูดจาชี้นำผู้ลงคะแนน',  'evidence_photo': null, 'timestamp': '2026-02-08 11:00:00', 'ai_result': null,     'ai_confidence': 0.0},
      {'station_id': 104, 'type_id': 2, 'reporter_name': 'วิภา รักชาติ', 'description': 'พบรถหลายคันรับส่งผู้มาใช้สิทธิ์',  'evidence_photo': null, 'timestamp': '2026-02-08 11:45:00', 'ai_result': 'Car',    'ai_confidence': 0.88},
      {'station_id': 101, 'type_id': 4, 'reporter_name': 'ประชา มั่นใจ', 'description': 'ป้ายหาเสียงถูกฉีกทำลาย',            'evidence_photo': null, 'timestamp': '2026-02-08 12:30:00', 'ai_result': 'Poster', 'ai_confidence': 0.62},
      {'station_id': 105, 'type_id': 1, 'reporter_name': 'นิรนาม',       'description': 'มีคนแจกซองบริเวณด้านหลังหน่วย',     'evidence_photo': null, 'timestamp': '2026-02-08 13:00:00', 'ai_result': 'Money',  'ai_confidence': 0.91},
      {'station_id': 106, 'type_id': 3, 'reporter_name': 'สุชาติ ดีงาม', 'description': 'รถหาเสียงวนซ้ำหลายรอบ',             'evidence_photo': null, 'timestamp': '2026-02-08 14:00:00', 'ai_result': 'Crowd',  'ai_confidence': 0.55},
    ];
    for (final i in incidents) {
      await db.insert('incident_report', i);
    }
  }

  // ─── polling_station ───────────────────────────────────────
  Future<List<PollingStation>> getAllStations() async {
    final db = await database;
    final maps = await db.query('polling_station', orderBy: 'station_id');
    return maps.map(PollingStation.fromMap).toList();
  }

  // ─── violation_type ────────────────────────────────────────
  Future<List<ViolationType>> getAllViolationTypes() async {
    final db = await database;
    final maps = await db.query('violation_type', orderBy: 'type_id');
    return maps.map(ViolationType.fromMap).toList();
  }

  // ─── incident_report ───────────────────────────────────────
  Future<List<IncidentReport>> getAllIncidents({String? filterSeverity}) async {
    final db = await database;
    String sql = '''
      SELECT ir.*, ps.station_name, ps.zone, vt.type_name, vt.severity
      FROM incident_report ir
      JOIN polling_station ps ON ir.station_id = ps.station_id
      JOIN violation_type  vt ON ir.type_id    = vt.type_id
    ''';
    List<dynamic> args = [];
    if (filterSeverity != null) {
      sql += ' WHERE vt.severity = ?';
      args.add(filterSeverity);
    }
    sql += ' ORDER BY ir.timestamp DESC';
    final maps = await db.rawQuery(sql, args);
    return maps.map(IncidentReport.fromMap).toList();
  }

  Future<IncidentReport?> getIncidentById(int reportId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT ir.*, ps.station_name, ps.zone, vt.type_name, vt.severity
      FROM incident_report ir
      JOIN polling_station ps ON ir.station_id = ps.station_id
      JOIN violation_type  vt ON ir.type_id    = vt.type_id
      WHERE ir.report_id = ?
    ''', [reportId]);
    if (maps.isEmpty) return null;
    return IncidentReport.fromMap(maps.first);
  }

  Future<int> insertIncident(IncidentReport incident) async {
    final db = await database;
    return db.insert('incident_report', incident.toMap());
  }

  Future<int> updateIncident(IncidentReport incident) async {
    final db = await database;
    return db.update(
      'incident_report',
      incident.toMap(),
      where: 'report_id = ?',
      whereArgs: [incident.reportId],
    );
  }

  Future<int> deleteIncident(int reportId) async {
    final db = await database;
    return db.delete('incident_report', where: 'report_id = ?', whereArgs: [reportId]);
  }

  // ─── Stats ──────────────────────────────────────────────────
  Future<int> getIncidentCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM incident_report');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> getCountBySeverity() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT vt.severity, COUNT(*) as count
      FROM incident_report ir
      JOIN violation_type vt ON ir.type_id = vt.type_id
      GROUP BY vt.severity
    ''');
    return {for (final m in maps) m['severity'] as String: m['count'] as int};
  }

  Future<List<Map<String, dynamic>>> getStatsPerViolationType() async {
    final db = await database;
    return db.rawQuery('''
      SELECT vt.type_name, vt.severity, COUNT(*) as count
      FROM incident_report ir
      JOIN violation_type vt ON ir.type_id = vt.type_id
      GROUP BY vt.type_id
      ORDER BY count DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getStatsPerStation() async {
    final db = await database;
    return db.rawQuery('''
      SELECT ps.station_name, ps.zone, COUNT(*) as count
      FROM incident_report ir
      JOIN polling_station ps ON ir.station_id = ps.station_id
      GROUP BY ps.station_id
      ORDER BY count DESC
    ''');
  }

  Future<double> getAvgConfidence() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT AVG(ai_confidence) as avg FROM incident_report WHERE ai_confidence > 0'
    );
    return (result.first['avg'] as num?)?.toDouble() ?? 0.0;
  }
}
