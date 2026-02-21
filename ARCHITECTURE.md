# ARCHITECTURE.md — Election Watch

อธิบายสถาปัตยกรรมโค้ดและ code pattern สำคัญทุกตัวในโปรเจคนี้

---

## สารบัญ

1. [Layer Architecture ภาพรวม](#1-layer-architecture-ภาพรวม)
2. [Pattern ที่ 1 — Singleton (DatabaseHelper)](#2-pattern-ที่-1--singleton-databasehelper)
3. [Pattern ที่ 2 — Model: fromMap / toMap](#3-pattern-ที่-2--model-frommap--tomap)
4. [Pattern ที่ 3 — StatefulWidget Lifecycle](#4-pattern-ที่-3--statefulwidget-lifecycle)
5. [Pattern ที่ 4 — async / await / Future](#5-pattern-ที่-4--async--await--future)
6. [Pattern ที่ 5 — Navigator.push + รับค่ากลับ](#6-pattern-ที่-5--navigatorpush--รับค่ากลับ)
7. [Pattern ที่ 6 — Form Validation](#7-pattern-ที่-6--form-validation)
8. [Pattern ที่ 7 — Null Safety](#8-pattern-ที่-7--null-safety)
9. [Pattern ที่ 8 — Private Widget Decomposition](#9-pattern-ที่-8--private-widget-decomposition)
10. [Workflow แต่ละ Screen](#10-workflow-แต่ละ-screen)

---

## 1. Layer Architecture ภาพรวม

```
┌─────────────────────────────────────────────────────┐
│                  UI Layer (Screens)                  │
│  home_screen  list_screen  form_screen  detail stats │
│                  ↕  setState / Navigator             │
├─────────────────────────────────────────────────────┤
│              Business Logic Layer                    │
│              (อยู่ใน Screen State class)             │
│         initState() → load → setState → build()     │
├─────────────────────────────────────────────────────┤
│              Data Layer (DatabaseHelper)             │
│    getAllIncidents / insertIncident / getStats ...    │
│              ↕  Future<T>  async/await               │
├─────────────────────────────────────────────────────┤
│              Model Layer                             │
│    PollingStation / ViolationType / IncidentReport   │
│              fromMap() ←→ toMap()                    │
├─────────────────────────────────────────────────────┤
│              SQLite (sqflite package)                │
│         election_watch.db บน device storage         │
└─────────────────────────────────────────────────────┘
```

**กฎหลัก:** Screen ไม่คุยกับ SQLite โดยตรง — ต้องผ่าน `DatabaseHelper` เสมอ

---

## 2. Pattern ที่ 1 — Singleton (DatabaseHelper)

**ไฟล์:** `lib/helpers/database_helper.dart` บรรทัด 7–17

```dart
class DatabaseHelper {
  // [1] สร้าง instance เดียวของตัวเองเก็บไว้เป็น static
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  // [2] factory constructor — ทุกครั้งที่ DatabaseHelper() ถูกเรียก
  //     จะ return _instance เดิมเสมอ ไม่สร้างใหม่
  factory DatabaseHelper() => _instance;

  // [3] constructor ที่แท้จริง — เป็น private (ขึ้นต้น _)
  //     เรียกได้เฉพาะตอนสร้าง _instance ครั้งแรก
  DatabaseHelper._internal();

  // [4] Database object เก็บแบบ static — มีแค่ตัวเดียวตลอด app lifecycle
  static Database? _db;

  // [5] getter แบบ lazy init — ถ้า _db ยังไม่มี ค่อยสร้าง
  //     ??= หมายถึง "ถ้าเป็น null ให้ assign ค่าใหม่"
  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }
}
```

**ทำไมต้องใช้ Singleton?**
- เปิด database connection ครั้งเดียว ประหยัด resource
- ทุก Screen ใช้ `DatabaseHelper()` แล้วได้ object เดิม — ข้อมูลสอดคล้องกัน
- ป้องกัน database file ถูกเปิดหลายครั้งพร้อมกัน

---

## 3. Pattern ที่ 2 — Model: fromMap / toMap

**ไฟล์:** `lib/models/incident_report.dart`

SQLite ส่งข้อมูลกลับมาเป็น `Map<String, dynamic>` (key=column name, value=ค่า)
ต้องแปลงไปมาระหว่าง Map กับ Dart class

```dart
class IncidentReport {
  final int? reportId;       // ? = nullable (อาจเป็น null ได้)
  final int stationId;       // ไม่มี ? = non-null (ต้องมีค่าเสมอ)
  final String reporterName;

  // ─── fromMap: Map → Object ───────────────────────────────
  // ใช้ตอน: อ่านข้อมูลจาก DB → แปลงเป็น Dart Object
  factory IncidentReport.fromMap(Map<String, dynamic> map) => IncidentReport(
    reportId:     map['report_id'],       // key ตรงกับชื่อ column ใน DB
    stationId:    map['station_id'],
    reporterName: map['reporter_name'],
    // .toDouble() — DB เก็บ REAL แต่ Dart อาจได้เป็น int จึงต้องแปลง
    aiConfidence: (map['ai_confidence'] ?? 0.0).toDouble(),
    // field จาก JOIN — มีเฉพาะตอน query ด้วย rawQuery
    stationName:  map['station_name'],    // มาจาก JOIN polling_station
    typeName:     map['type_name'],       // มาจาก JOIN violation_type
    severity:     map['severity'],
  );

  // ─── toMap: Object → Map ───────────────────────────────
  // ใช้ตอน: INSERT หรือ UPDATE ข้อมูลลง DB
  Map<String, dynamic> toMap() => {
    // if ใน collection literal — ใส่ report_id เฉพาะตอน edit (ไม่ใช่ add)
    // ถ้า add ใหม่ ไม่ใส่ report_id → DB จะ AUTOINCREMENT เอง
    if (reportId != null) 'report_id': reportId,
    'station_id':    stationId,
    'reporter_name': reporterName,
    // ไม่มี stationName / typeName ใน toMap เพราะเป็น JOIN field
    // ไม่ต้องบันทึกลง DB
  };
}
```

**Flow การใช้งาน:**
```
DB rawQuery() → List<Map<String,dynamic>>
    → .map(IncidentReport.fromMap).toList()
    → List<IncidentReport>  ← Screen ใช้งาน

Screen สร้าง IncidentReport(...)
    → .toMap()
    → db.insert('incident_report', map)  ← บันทึกลง DB
```

---

## 4. Pattern ที่ 3 — StatefulWidget Lifecycle

**ทุก Screen ใช้ pattern เดียวกัน** — ตัวอย่างจาก `home_screen.dart`

```dart
// [A] แยก Widget (ไม่มี state) กับ State (มี state) ออกจากกัน
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // createState() — Flutter เรียกครั้งเดียวตอนสร้าง widget
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// [B] State class — เก็บตัวแปรที่เปลี่ยนแปลงได้
class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper();   // สร้าง db helper
  int _totalCount = 0;            // state variables
  bool _isLoading = true;         // ตัวแปรควบคุม UI

  // [C] initState — เรียกครั้งเดียวหลัง widget ถูกสร้าง
  //     ใช้โหลดข้อมูลครั้งแรก
  @override
  void initState() {
    super.initState();   // ต้องเรียก super ก่อนเสมอ
    _loadData();         // เริ่มโหลดข้อมูลจาก DB
  }

  Future<void> _loadData() async {
    // [D] setState(fn) — บอก Flutter ว่า state เปลี่ยน → rebuild UI
    //     ทุกครั้งที่ต้องการให้ UI อัปเดต ต้องเรียก setState
    setState(() => _isLoading = true);          // แสดง loading spinner

    final total = await _db.getIncidentCount(); // รอ DB
    setState(() {
      _totalCount = total;
      _isLoading = false;                       // ซ่อน spinner, แสดงข้อมูล
    });
  }

  // [E] build() — เรียกทุกครั้งที่ setState() ถูกเรียก
  //     return Widget tree ที่จะแสดงบนหน้าจอ
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading                          // ดู state ตัดสินใจว่าแสดงอะไร
          ? const CircularProgressIndicator()  // กำลังโหลด
          : Text('$_totalCount'),              // โหลดเสร็จ
    );
  }
}
```

**Lifecycle ตามลำดับ:**
```
Flutter สร้าง Widget
    → createState()
    → initState()      ← โหลดข้อมูล, subscribe ต่างๆ
    → build()          ← แสดง UI ครั้งแรก (อาจเห็น loading)
    → setState()       ← เมื่อข้อมูลพร้อม
    → build()          ← แสดง UI ใหม่พร้อมข้อมูล
    ...
    → dispose()        ← Widget ถูกทำลาย, cleanup (TextEditingController, etc.)
```

---

## 5. Pattern ที่ 4 — async / await / Future

**แนวคิด:** การอ่าน DB ใช้เวลา → ต้องไม่บล็อก UI thread → ใช้ async

```dart
// Future<T> = "สัญญาว่าจะส่ง T กลับมาในอนาคต"
// async = "function นี้ทำงานแบบ asynchronous"
// await = "หยุดรอจนกว่าจะได้ค่า แต่ไม่บล็อก UI"

// ตัวอย่างจาก database_helper.dart
Future<List<IncidentReport>> getAllIncidents({String? filterSeverity}) async {
  // [1] await database — รอให้ connection พร้อม
  final db = await database;

  // [2] สร้าง SQL แบบ dynamic ตาม filter
  String sql = '''
    SELECT ir.*, ps.station_name, vt.type_name, vt.severity
    FROM incident_report ir
    JOIN polling_station ps ON ir.station_id = ps.station_id
    JOIN violation_type  vt ON ir.type_id    = vt.type_id
  ''';
  List<dynamic> args = [];
  if (filterSeverity != null) {
    sql += ' WHERE vt.severity = ?';  // ? = placeholder ป้องกัน SQL injection
    args.add(filterSeverity);
  }
  sql += ' ORDER BY ir.timestamp DESC';

  // [3] await rawQuery — รอผล query (List<Map<String,dynamic>>)
  final maps = await db.rawQuery(sql, args);

  // [4] แปลง Map → IncidentReport object ทีละตัว
  return maps.map(IncidentReport.fromMap).toList();
}

// ตัวอย่างการเรียกใช้ใน Screen
Future<void> _loadIncidents() async {
  setState(() => _isLoading = true);
  // await รอให้ getAllIncidents() เสร็จก่อนไปบรรทัดถัดไป
  final data = await _db.getAllIncidents(filterSeverity: _filterSeverity);
  setState(() {
    _incidents = data;
    _isLoading = false;
  });
}
```

**query() vs rawQuery():**

| method | ใช้เมื่อ | ตัวอย่าง |
|--------|---------|---------|
| `db.query('table')` | query ตารางเดียว ไม่มี JOIN | `getAllStations()` |
| `db.rawQuery(sql)` | query ซับซ้อน มี JOIN / GROUP BY | `getAllIncidents()`, `getStats()` |
| `db.insert(table, map)` | INSERT ข้อมูลใหม่ | `insertIncident()` |
| `db.update(table, map, where:)` | UPDATE ข้อมูล | `updateIncident()` |
| `db.delete(table, where:)` | DELETE ข้อมูล | `deleteIncident()` |

---

## 6. Pattern ที่ 5 — Navigator.push + รับค่ากลับ

**ปัญหา:** เมื่อเพิ่มรายงานแล้วกลับ Home → Home ต้องรู้ว่ามีข้อมูลใหม่เพื่อ reload

**วิธีแก้:** `Navigator.push` คืน `Future` — รอจนกว่า screen ปลายทางจะ pop กลับ

```dart
// ─── ฝั่ง Screen ที่เปิด (Home / List) ─────────────────────

// push และรอผลที่ส่งกลับมา
final result = await Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const IncidentFormScreen()),
);
// result = ค่าที่ IncidentFormScreen ส่งกลับผ่าน Navigator.pop(context, value)
if (result == true) {
  _loadData();  // มีการเพิ่ม/แก้ไข → reload ข้อมูล
}


// ─── ฝั่ง Screen ปลายทาง (Form / Detail) ───────────────────

// เมื่อบันทึกสำเร็จ
Navigator.pop(context, true);   // pop กลับ พร้อมส่งค่า true

// เมื่อกด Cancel หรือ Back button ปกติ
Navigator.pop(context);          // pop กลับ ไม่ส่งค่า (result = null)
```

**Navigation Map ของโปรเจคนี้:**
```
MainNavigation (BottomNav)
├── [0] HomeScreen
│       → push → IncidentListScreen (standalone)
│       → push → IncidentFormScreen (add mode)
│
├── [1] IncidentListScreen
│       → push → IncidentDetailScreen(reportId)
│                   → push → IncidentFormScreen (edit mode)
│       → push → IncidentFormScreen (add mode)
│
└── [2] StatsScreen
```

**`mounted` check — สำคัญมาก:**
```dart
if (mounted) {
  Navigator.pop(context, true);
}
```
ป้องกัน error "setState called after dispose" — ถ้า user กด back ระหว่างบันทึก widget อาจถูก dispose ไปแล้ว `mounted` ช่วยตรวจสอบว่า widget ยังอยู่บน tree ไหม

---

## 7. Pattern ที่ 6 — Form Validation

**ไฟล์:** `lib/screens/incident_form_screen.dart`

```dart
// [1] GlobalKey เชื่อม Form widget กับ State
//     ใช้เรียก .validate() และ .save() จากภายนอก Form widget
final _formKey = GlobalKey<FormState>();

// [2] TextEditingController — ดึงค่าจาก TextField
final _reporterController = TextEditingController();

// [3] Form widget ห่อ input ทั้งหมด
Form(
  key: _formKey,   // ผูก key
  child: Column(
    children: [

      // [4] TextFormField — มี validator
      TextFormField(
        controller: _reporterController,
        validator: (val) {
          // validator คืน null = valid, คืน String = error message
          if (val == null || val.trim().isEmpty) {
            return 'กรุณาระบุชื่อผู้แจ้ง';
          }
          return null;  // valid
        },
      ),

      // [5] DropdownButtonFormField — validator แบบ null check
      DropdownButtonFormField<PollingStation>(
        value: _selectedStation,
        items: _stations.map((s) => DropdownMenuItem(
          value: s,
          child: Text(s.stationName),
        )).toList(),
        onChanged: (val) => setState(() => _selectedStation = val),
        validator: (val) => val == null ? 'กรุณาเลือกหน่วยเลือกตั้ง' : null,
      ),
    ],
  ),
)

// [6] เรียก validate() ตอนกด Submit
Future<void> _submit() async {
  // validate() วิ่งทุก validator ใน Form
  // คืน true ถ้าทุก field valid, false ถ้ามีอย่างน้อย 1 field ไม่ valid
  if (!_formKey.currentState!.validate()) return;  // หยุดถ้า invalid

  // ดึงค่าจาก controller
  final name = _reporterController.text.trim();
  ...
}

// [7] ต้อง dispose controller ตอน widget ถูกทำลาย
//     ป้องกัน memory leak
@override
void dispose() {
  _reporterController.dispose();
  _descController.dispose();
  super.dispose();
}
```

---

## 8. Pattern ที่ 7 — Null Safety

Dart บังคับให้ประกาศชัดว่า variable เป็น null ได้หรือไม่

```dart
// ─── การประกาศ ───────────────────────────────────────────
String  name;      // non-nullable — ต้องมีค่าเสมอ ใส่ null ไม่ได้
String? name;      // nullable    — อาจเป็น null ได้

// ─── การใช้งาน ───────────────────────────────────────────

// ?? — "null coalescing" ถ้า null ให้ใช้ค่า default แทน
final count = _countBySeverity['High'] ?? 0;
//                                          ↑ ถ้า key ไม่มี คืน 0

// ?. — "null-safe access" เรียก method เฉพาะถ้าไม่ใช่ null
final name = incident.stationName?.toUpperCase();
//                                ↑ ถ้า stationName == null → คืน null ไม่ crash

// ! — "null assertion" บอก Dart ว่า "แน่ใจว่าไม่ null"
//     ถ้าจริงๆ เป็น null จะ throw exception ตอน runtime
return _db!;
_formKey.currentState!.validate();

// if-null check ก่อนใช้
if (_incident != null) {
  // ในบล็อกนี้ Dart รู้ว่า _incident ไม่ใช่ null → ใช้ได้เลย
  _SeverityBadge(severity: _incident!.severity ?? '')
}

// ตัวอย่างจากโปรเจค — pattern ที่ใช้บ่อย
final hasAi = incident.aiResult != null && incident.aiResult!.isNotEmpty;
//                                    ↑ ตรวจก่อน          ↑ ค่อย !
```

---

## 9. Pattern ที่ 8 — Private Widget Decomposition

**ปัญหา:** ถ้าใส่ทุกอย่างใน `build()` เดียว — อ่านยาก, ยาวมาก

**วิธีแก้:** แยกเป็น class ย่อยที่ขึ้นต้นด้วย `_` (private ใช้ได้แค่ในไฟล์เดียวกัน)

```dart
// ─── ใน home_screen.dart ───────────────────────────────────

// build() อ่านง่าย — เห็นโครงสร้าง UI ชัดเจน
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        _TotalCard(count: _totalCount),           // widget แยก
        _StatCard(label: 'สูง', count: 4, ...),   // widget แยก พร้อม props
      ],
    ),
  );
}

// ─── Private widget class ─────────────────────────────────
// _TotalCard รับ count มาแสดงผล — ไม่มี state (StatelessWidget)
class _TotalCard extends StatelessWidget {
  final int count;                          // รับ data ผ่าน constructor
  const _TotalCard({required this.count}); // required = ต้องส่งค่ามาเสมอ

  @override
  Widget build(BuildContext context) {
    return Card(child: Text('$count'));
  }
}

// _StatCard — reusable widget รับ props ต่างกันได้
class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });
  ...
}
```

**กฎการเลือก StatelessWidget vs StatefulWidget:**

| Widget | ใช้เมื่อ | ตัวอย่าง |
|--------|---------|---------|
| `StatelessWidget` | แสดงผลอย่างเดียว ไม่มี state ภายใน | `_TotalCard`, `_StatCard`, `_InfoRow` |
| `StatefulWidget` | มีการโหลดข้อมูล, มี input, state เปลี่ยน | `HomeScreen`, `IncidentFormScreen` |

---

## 10. Workflow แต่ละ Screen

### A. App Startup

```
main() → runApp(ElectionWatchApp)
    → MaterialApp → MainNavigation
    → BottomNavBar สร้าง [HomeScreen, IncidentListScreen, StatsScreen]
    → HomeScreen.initState() เรียกแรก
        → DatabaseHelper() — lazy init สร้าง DB ครั้งแรก
        → _onCreate() — CREATE TABLE + INSERT sample data
        → getIncidentCount() → setState → build() แสดงข้อมูล
```

### B. Database Init (ครั้งแรกเท่านั้น)

```dart
// database_helper.dart — _initDatabase()
return openDatabase(
  path,            // /data/data/com.example.final66123217/databases/election_watch.db
  version: 1,
  onCreate: _onCreate,   // เรียกเฉพาะตอนไฟล์ DB ยังไม่มี (ครั้งแรก)
);
// ครั้งต่อไป — DB มีอยู่แล้ว → onCreate ไม่ถูกเรียก → ข้อมูลเดิมยังอยู่
```

### C. Add Incident Flow

```
HomeScreen FAB กด "เพิ่มรายงาน"
    → Navigator.push(IncidentFormScreen())    ← ไม่ส่ง incident (add mode)

IncidentFormScreen.initState()
    → getAllStations()   → query polling_station
    → getAllViolationTypes() → query violation_type
    → setState() → build() แสดง dropdowns

User กรอกข้อมูล + กด "บันทึก"
    → _submit()
    → _formKey.validate() → ตรวจทุก field
    → สร้าง IncidentReport(reportId: null, timestamp: now, ...)
    → insertIncident(incident)
        → db.insert('incident_report', incident.toMap())
        → DB สร้าง report_id ให้อัตโนมัติ (AUTOINCREMENT)
    → Navigator.pop(context, true)   ← ส่ง true กลับ

HomeScreen ได้รับ result = true
    → _loadData()   ← reload ข้อมูลใหม่
    → setState() → build() แสดงจำนวนรายงานเพิ่มขึ้น
```

### D. Edit Incident Flow

```
IncidentDetailScreen AppBar กด "แก้ไข"
    → Navigator.push(IncidentFormScreen(incident: _incident))  ← ส่ง incident

IncidentFormScreen — _isEditMode = true
    → initState() → loadDropdownData() → pre-fill ข้อมูลเดิม
    → _selectedStation = stations.firstWhere(id == incident.stationId)
    → _reporterController.text = incident.reporterName

User แก้ไข + กด "บันทึก"
    → สร้าง IncidentReport(reportId: incident.reportId, ...)  ← ใส่ reportId
    → updateIncident(incident)
        → db.update('incident_report', map, where: 'report_id = ?')
    → Navigator.pop(context, true)

IncidentDetailScreen ได้ result = true
    → _loadIncident()  ← โหลดข้อมูลใหม่ของ report นี้
```

### E. Delete Incident Flow

```
IncidentDetailScreen กด "ลบ"
    → _deleteIncident()
    → showDialog(AlertDialog ยืนยัน?)
        → กด "ยกเลิก" → Navigator.pop(ctx, false) → confirm = false → หยุด
        → กด "ลบ"     → Navigator.pop(ctx, true)  → confirm = true → ดำเนินการ

    → deleteIncident(widget.reportId)
        → db.delete('incident_report', where: 'report_id = ?')
    → Navigator.pop(context, true)   ← กลับ List screen

IncidentListScreen ได้ result = true → _loadIncidents()
```

### F. Filter Flow (List Screen)

```dart
// incident_list_screen.dart
DropdownButton onChanged: (val) {
  setState(() => _filterSeverity = val);  // val = 'High' | 'Medium' | 'Low' | null
  _loadIncidents();                        // reload ด้วย filter ใหม่
}

// database_helper.dart — getAllIncidents
String sql = 'SELECT ... FROM incident_report ir JOIN ...';
if (filterSeverity != null) {
  sql += ' WHERE vt.severity = ?';   // เพิ่ม WHERE clause
  args.add(filterSeverity);
}
// ถ้า filterSeverity == null → ไม่มี WHERE → ดึงทั้งหมด
```

### G. Stats Screen — Aggregation

```dart
// database_helper.dart — getCountBySeverity
final maps = await db.rawQuery('''
  SELECT vt.severity, COUNT(*) as count
  FROM incident_report ir
  JOIN violation_type vt ON ir.type_id = vt.type_id
  GROUP BY vt.severity
''');
// ผลลัพธ์: [{'severity': 'High', 'count': 4}, {'severity': 'Medium', 'count': 2}, ...]

// แปลงเป็น Map<String, int> ด้วย collection for
return {for (final m in maps) m['severity'] as String: m['count'] as int};
// ผลลัพธ์: {'High': 4, 'Medium': 2, 'Low': 1}

// stats_screen.dart ใช้ค่าเพื่อวาด Severity Bar
Row(children: [
  Expanded(flex: high,   child: Container(color: AppColors.high)),   // สัดส่วนตาม flex
  Expanded(flex: medium, child: Container(color: AppColors.medium)),
  Expanded(flex: low,    child: Container(color: AppColors.low)),
])
// Expanded(flex: N) — ใช้พื้นที่ N ส่วน เทียบกับ flex รวม
```

---

## สรุป Code Pattern ที่ต้องจำ

| Pattern | คำหลัก | ใช้ทำอะไร |
|---------|--------|----------|
| Singleton | `factory`, `static final` | Database connection เดียว |
| fromMap / toMap | `factory ClassName.fromMap` | แปลง DB row ↔ Dart object |
| Lifecycle | `initState`, `setState`, `dispose` | โหลดข้อมูล, อัปเดต UI, cleanup |
| Async | `async`, `await`, `Future<T>` | ทำงาน background ไม่บล็อก UI |
| Navigator | `await Navigator.push`, `Navigator.pop(ctx, val)` | เปิดหน้าใหม่และรับผลกลับ |
| Form | `GlobalKey<FormState>`, `validator`, `validate()` | ตรวจสอบ input |
| Null Safety | `?`, `!`, `??`, `?.` | จัดการค่า null อย่างปลอดภัย |
| Widget Decomposition | `_PrivateWidget extends StatelessWidget` | แยก UI ให้อ่านง่าย reusable |
