# REQUIREMENT.md
# ระบบรายงานการทุจริตการเลือกตั้ง (Election Violation Reporter)
## วิชา Mobile — ข้อสอบปลายภาค 2/2568 — มหาวิทยาลัยวลัยลักษณ์

---

## 🎯 ภาพรวมแอปพลิเคชัน

แอปพลิเคชัน Flutter สำหรับรายงาน ติดตาม และจัดการข้อมูลการทุจริตการเลือกตั้ง ทำงานบนอุปกรณ์พกพา (Android/iOS) เชื่อมต่อกับ SQLite local database

---

## 🗂️ โครงสร้างโปรเจค

```
FinalXXXXXXX/
├── lib/
│   ├── main.dart
│   ├── constants/
│   │   └── app_constants.dart       # สีหลัก, ข้อความคงที่
│   ├── models/
│   │   ├── polling_station.dart
│   │   ├── violation_type.dart
│   │   └── incident_report.dart
│   ├── helpers/
│   │   └── database_helper.dart     # SQLite CRUD ทั้งหมด
│   └── screens/
│       ├── home_screen.dart         # หน้าหลัก / Dashboard
│       ├── incident_list_screen.dart # รายการเหตุการณ์
│       ├── incident_detail_screen.dart # รายละเอียดเหตุการณ์
│       ├── incident_form_screen.dart  # เพิ่ม/แก้ไขรายงาน
│       └── stats_screen.dart         # สถิติและรายงาน
└── web/
    ├── database_init.sql            # SQL สร้างตาราง
    └── sample_data.sql              # ข้อมูลตัวอย่าง
```

---

## 📱 หน้าจอที่ต้องทำ (5 หน้าจอ × 4 คะแนน = 20 คะแนน)

---

### หน้าจอที่ 1 — Home / Dashboard (ง่าย)
**ไฟล์:** `lib/screens/home_screen.dart`

**แสดงผล:**
- AppBar ชื่อแอป "Election Watch"
- Card สรุปจำนวนรายงานทั้งหมด
- Card แยกตาม Severity: 🔴 High / 🟡 Medium / 🟢 Low
- ปุ่ม "ดูรายการทั้งหมด" → ไป incident_list_screen
- ปุ่ม "เพิ่มรายงาน" (FloatingActionButton) → ไป incident_form_screen
- BottomNavigationBar: Home | รายการ | สถิติ

**Logic:**
- ดึงข้อมูลจาก `DatabaseHelper.getIncidentCount()` และ `getCountBySeverity()`
- แสดงเป็น StatCard widget

---

### หน้าจอที่ 2 — รายการเหตุการณ์ (ปานกลาง)
**ไฟล์:** `lib/screens/incident_list_screen.dart`

**แสดงผล:**
- ListView ของ incident_report ทั้งหมด
- แต่ละ item แสดง:
  - ชื่อหน่วยเลือกตั้ง (station_name)
  - ประเภทความผิด (type_name)
  - Badge สี severity (High=แดง, Medium=เหลือง, Low=เขียว)
  - วันเวลา (timestamp)
  - ชื่อผู้แจ้ง (reporter_name)
- กดที่ item → ไป incident_detail_screen
- Dropdown Filter ตาม severity หรือ zone

**Logic:**
- Query JOIN 3 ตาราง: `incident_report JOIN polling_station JOIN violation_type`
- Refresh หลังจากเพิ่ม/แก้ไขรายงาน

---

### หน้าจอที่ 3 — เพิ่มรายงานเหตุการณ์ (ปานกลาง)
**ไฟล์:** `lib/screens/incident_form_screen.dart`

**ฟอร์ม:**
- Dropdown เลือกหน่วยเลือกตั้ง (polling_station)
- Dropdown เลือกประเภทความผิด (violation_type)
- TextFormField: ชื่อผู้แจ้ง (reporter_name)
- TextFormField: รายละเอียด (description)
- ปุ่มถ่ายรูป (Icon camera) → บันทึก path ลง evidence_photo
- timestamp: บันทึกอัตโนมัติ ณ เวลาที่กด Submit
- ปุ่ม "บันทึก" → validate → insert → กลับ

**Validation:**
- reporter_name ต้องไม่ว่าง
- ต้องเลือก station และ violation type

---

### หน้าจอที่ 4 — รายละเอียดเหตุการณ์ (ปานกลาง-ยาก)
**ไฟล์:** `lib/screens/incident_detail_screen.dart`

**แสดงผล:**
- ข้อมูลครบทุก field ของ incident_report
- แสดงรูปภาพ evidence_photo (ถ้ามี path → Image.file, ถ้าไม่มี → placeholder icon)
- AI Result Card:
  - ai_result (เช่น "Money", "Crowd")
  - ai_confidence แสดงเป็น % พร้อม LinearProgressIndicator
  - ถ้า confidence ≥ 0.8 → แสดง ✅ "น่าเชื่อถือ", < 0.5 → ⚠️ "ความมั่นใจต่ำ"
- ปุ่มแก้ไข → ไป incident_form_screen (mode: edit)
- ปุ่มลบ → ยืนยัน Dialog → ลบ → กลับ

---

### หน้าจอที่ 5 — สถิติ (ยาก)
**ไฟล์:** `lib/screens/stats_screen.dart`

**แสดงผล:**
- สรุปรวม: จำนวนรายงานทั้งหมด, เฉลี่ย ai_confidence
- ตาราง/รายการ: จำนวนรายงานแยกตามประเภทความผิด
- ตาราง/รายการ: จำนวนรายงานแยกตามหน่วยเลือกตั้ง
- Top 3 หน่วยที่มีรายงานมากที่สุด
- แสดงสัดส่วน High/Medium/Low (อาจใช้ Stack+Container แทน chart library)

**Logic:**
- `DatabaseHelper.getStatsPerViolationType()`
- `DatabaseHelper.getStatsPerStation()`

---

## 🗄️ Database Schema (SQLite)

### ตาราง polling_station
```sql
CREATE TABLE polling_station (
  station_id   INTEGER PRIMARY KEY,
  station_name TEXT NOT NULL,
  zone         TEXT NOT NULL,
  province     TEXT NOT NULL
);
```

### ตาราง violation_type
```sql
CREATE TABLE violation_type (
  type_id   INTEGER PRIMARY KEY AUTOINCREMENT,
  type_name TEXT NOT NULL,
  severity  TEXT NOT NULL CHECK(severity IN ('High','Medium','Low'))
);
```

### ตาราง incident_report
```sql
CREATE TABLE incident_report (
  report_id     INTEGER PRIMARY KEY AUTOINCREMENT,
  station_id    INTEGER NOT NULL REFERENCES polling_station(station_id),
  type_id       INTEGER NOT NULL REFERENCES violation_type(type_id),
  reporter_name TEXT NOT NULL,
  description   TEXT,
  evidence_photo TEXT,
  timestamp     TEXT NOT NULL,
  ai_result     TEXT,
  ai_confidence REAL DEFAULT 0.0
);
```

---

## 📦 Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path: ^1.9.0
  image_picker: ^1.0.7
  intl: ^0.19.0
```

---

## 🚫 ข้อห้าม (ตามข้อสอบ)

- ห้ามใช้ AI ช่วยเขียนโปรแกรมหรือคิดข้อมูล
- ต้องใช้โครงสร้าง lib/ และ web/ ตามที่เรียน
- ชื่อโปรเจค: Final + รหัสนักศึกษา (เช่น Final66124419)
