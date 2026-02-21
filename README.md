# Election Watch — Final66123217

ระบบรายงานการทุจริตการเลือกตั้ง
วิชา Mobile — ข้อสอบปลายภาค 2/2568 — มหาวิทยาลัยวลัยลักษณ์

---

## สารบัญ

1. [Tech Stack](#tech-stack)
2. [วิธีการรัน](#วิธีการรัน)
3. [โครงสร้างไฟล์และที่มาของแต่ละไฟล์](#โครงสร้างไฟล์และที่มาของแต่ละไฟล์)
4. [Dataflow](#dataflow)
5. [ถ้าต้องแก้ไข ต้องแก้ไฟล์ไหน](#ถ้าต้องแก้ไข-ต้องแก้ไฟล์ไหน)
6. [คำสั่งที่ต้องรู้ (เริ่มใหม่หรือแก้ไข)](#คำสั่งที่ต้องรู้)

---

## Tech Stack

| เทคโนโลยี | เวอร์ชัน | ใช้ทำอะไร |
|-----------|---------|-----------|
| Flutter | ≥3.0.0 | Framework หลัก |
| Dart | ≥3.0.0 | ภาษาโปรแกรม |
| sqflite | ^2.3.0 | SQLite local database |
| path | ^1.9.0 | จัดการ path ของไฟล์ database |
| image_picker | ^1.0.7 | ถ่ายรูปหลักฐาน |
| intl | ^0.19.0 | จัดรูปแบบวันที่/เวลา |

---

## วิธีการรัน

### ความต้องการเบื้องต้น
- ติดตั้ง Flutter SDK แล้ว (`flutter --version` ต้องไม่ error)
- มี Android Studio หรือ VS Code
- มี Android emulator หรือ device จริง

### ขั้นตอน (ครั้งแรก)

```bash
# 1. เข้าไปที่ folder โปรเจค
cd Z:/Teacher/AJ.Bank/Final66123217

# 2. สร้าง Flutter project structure (android/, ios/, web/ ฯลฯ)
flutter create .

# 3. ติดตั้ง packages ตาม pubspec.yaml
flutter pub get

# 4. ตรวจดู devices ที่เชื่อมต่อ
flutter devices

# 5. เปิด Android emulator (ถ้ายังไม่เปิด)
flutter emulators --launch Pixel_9_Pro

# 6. รัน app
flutter run -d emulator-5554
```

### ขั้นตอน (ครั้งต่อไป — emulator เปิดอยู่แล้ว)

```bash
cd Z:/Teacher/AJ.Bank/Final66123217
flutter run -d emulator-5554
```

### คำสั่งระหว่างรัน (กดใน terminal)

| ปุ่ม | ทำอะไร |
|-----|--------|
| `r` | Hot reload — โหลดโค้ดใหม่เร็ว ไม่ล้าง state |
| `R` | Hot restart — รีสตาร์ท app ล้าง state ทั้งหมด |
| `q` | ออกจาก flutter run |
| `d` | Detach — หยุด session แต่ app ยังรันบน emulator |

---

## โครงสร้างไฟล์และที่มาของแต่ละไฟล์

```
Final66123217/
│
├── pubspec.yaml                        ← [WRITE] กำหนด dependencies ทั้งหมด
├── README.md                           ← [WRITE] เอกสารนี้
│
├── lib/                                ← โค้ด Dart ทั้งหมด (เขียนเอง)
│   ├── main.dart                       ← [WRITE] Entry point + NavigationBar 3 แท็บ
│   │
│   ├── constants/
│   │   └── app_constants.dart          ← [WRITE] สี, ชื่อแอป, severityColor()
│   │
│   ├── models/                         ← [WRITE] Data class แต่ละตาราง
│   │   ├── polling_station.dart        ← Model: หน่วยเลือกตั้ง
│   │   ├── violation_type.dart         ← Model: ประเภทความผิด
│   │   └── incident_report.dart        ← Model: รายงานเหตุการณ์ (+ JOIN fields)
│   │
│   ├── helpers/
│   │   └── database_helper.dart        ← [WRITE] SQLite: สร้างตาราง, CRUD, Stats
│   │
│   └── screens/                        ← [WRITE] หน้าจอทั้ง 5
│       ├── home_screen.dart            ← หน้าหลัก/Dashboard
│       ├── incident_list_screen.dart   ← รายการเหตุการณ์ + Filter
│       ├── incident_form_screen.dart   ← ฟอร์มเพิ่ม/แก้ไข
│       ├── incident_detail_screen.dart ← รายละเอียด + AI badge + ลบ
│       └── stats_screen.dart           ← สถิติ + กราฟ
│
├── web/                                ← SQL reference files
│   ├── database_init.sql               ← [WRITE] SQL สร้างตาราง (reference เท่านั้น)
│   └── sample_data.sql                 ← [WRITE] SQL ข้อมูลตัวอย่าง (reference เท่านั้น)
│
├── android/                            ← [BUILD] สร้างโดย `flutter create .`
│   └── app/src/main/AndroidManifest.xml ← [WRITE] เพิ่ม CAMERA permission
│
├── ios/                                ← [BUILD] สร้างโดย `flutter create .`
├── windows/                            ← [BUILD] สร้างโดย `flutter create .`
├── linux/                              ← [BUILD] สร้างโดย `flutter create .`
├── macos/                              ← [BUILD] สร้างโดย `flutter create .`
│
├── build/                              ← [BUILD AUTO] สร้างโดย `flutter build` / `flutter run`
│   └── app/outputs/flutter-apk/
│       └── app-debug.apk               ← APK ที่ติดตั้งบน device
│
├── .dart_tool/                         ← [BUILD AUTO] Flutter internal tools
├── pubspec.lock                        ← [BUILD AUTO] lock versions จาก `flutter pub get`
└── test/
    └── widget_test.dart                ← [BUILD] สร้างโดย `flutter create .`
```

### ตำนาน (Legend)

| ป้าย | ความหมาย |
|-----|---------|
| `[WRITE]` | เขียนขึ้นมาเอง / แก้ไขเอง |
| `[BUILD]` | สร้างโดย `flutter create .` อัตโนมัติ |
| `[BUILD AUTO]` | สร้างโดย Flutter ทุกครั้งที่ build/run — **ห้ามแก้ไข** |

---

## Dataflow

### ภาพรวม

```
User Action
    │
    ▼
Screen (StatefulWidget)
    │  setState() เมื่อข้อมูลเปลี่ยน
    │
    ▼
DatabaseHelper (Singleton)
    │  Future<T> — async/await
    │
    ▼
sqflite (SQLite)
    │  election_watch.db บน device
    │
    ▼
Model Class (fromMap / toMap)
    │
    ▼
Screen อัปเดต UI
```

### Dataflow แต่ละ Screen

#### Home Screen
```
initState()
  → getIncidentCount()        → SELECT COUNT(*) FROM incident_report
  → getCountBySeverity()      → GROUP BY vt.severity
  → setState(_totalCount, _countBySeverity)
  → build() แสดง StatCard

FAB กด "เพิ่มรายงาน"
  → push IncidentFormScreen
  → รอ result (true/false)
  → ถ้า true → _loadData() โหลดใหม่
```

#### Incident List Screen
```
initState()
  → getAllIncidents(filterSeverity?)
      → SELECT ir.*, ps.*, vt.*
        FROM incident_report ir
        JOIN polling_station ps ...
        JOIN violation_type vt ...
        [WHERE vt.severity = ?]
        ORDER BY timestamp DESC
  → setState(_incidents)

Dropdown filter เปลี่ยน
  → _filterSeverity = val
  → _loadIncidents() โหลดใหม่

กด item
  → push IncidentDetailScreen(reportId)
  → รอ return → _loadIncidents()
```

#### Incident Form Screen (Add/Edit)
```
initState()
  → getAllStations()     → SELECT * FROM polling_station
  → getAllViolationTypes() → SELECT * FROM violation_type
  → ถ้า edit mode: pre-fill จาก widget.incident

กด "ถ่ายรูป"
  → ImagePicker.pickImage(camera)
  → setState(_evidencePhotoPath)

กด "บันทึก"
  → _formKey.validate()
  → สร้าง IncidentReport object
  → timestamp = DateTime.now().toString()
  → ถ้า add: insertIncident() → INSERT INTO incident_report
  → ถ้า edit: updateIncident() → UPDATE incident_report SET ...
  → Navigator.pop(context, true)
```

#### Incident Detail Screen
```
initState()
  → getIncidentById(reportId)
      → SELECT ir.*, ps.*, vt.*
        FROM incident_report ir
        JOIN ... WHERE ir.report_id = ?
  → setState(_incident)

กด "แก้ไข"
  → push IncidentFormScreen(incident: _incident)
  → รอ result → _loadIncident() โหลดใหม่

กด "ลบ"
  → showDialog(ยืนยัน?)
  → deleteIncident(reportId) → DELETE FROM incident_report
  → Navigator.pop(context, true)
```

#### Stats Screen
```
initState()
  → getIncidentCount()
  → getAvgConfidence()          → AVG(ai_confidence)
  → getCountBySeverity()        → GROUP BY severity
  → getStatsPerViolationType()  → GROUP BY type_id ORDER BY count DESC
  → getStatsPerStation()        → GROUP BY station_id ORDER BY count DESC
  → setState(ข้อมูลทั้งหมด)
  → build() แสดง bar chart + tables
```

### Database Schema

```
polling_station          incident_report              violation_type
────────────────         ───────────────              ──────────────
station_id (PK) ◄──── station_id (FK)           ┌── type_id (PK)
station_name            report_id (PK AUTOINCR)  │   type_name
zone                    type_id (FK) ─────────────┘   severity
province                reporter_name
                        description
                        evidence_photo (path)
                        timestamp (TEXT)
                        ai_result (TEXT)
                        ai_confidence (REAL 0.0-1.0)
```

---

## ถ้าต้องแก้ไข ต้องแก้ไฟล์ไหน

### แก้สี / ชื่อแอป
```
lib/constants/app_constants.dart
  → AppColors.primary / high / medium / low
  → AppStrings.appName
```

### แก้โครงสร้าง Database / เพิ่มตาราง
```
lib/helpers/database_helper.dart
  → _onCreate()       ← แก้ CREATE TABLE
  → _insertSampleData() ← แก้ข้อมูลตัวอย่าง
  → เพิ่ม method ใหม่ถ้าต้องการ query ใหม่

lib/models/          ← แก้ model ให้ตรงกับตาราง
web/database_init.sql ← แก้ SQL reference ให้ตรงกัน
web/sample_data.sql   ← แก้ข้อมูลตัวอย่าง reference
```

> **หมายเหตุ:** ถ้าแก้ schema หลังจาก app รันแล้ว database จะไม่อัปเดตเอง
> ต้องลบแอปออกจาก emulator/device แล้วรันใหม่ หรือเพิ่ม version + onUpgrade

### แก้ UI หน้าจอ
```
lib/screens/home_screen.dart          ← หน้าหลัก, StatCard
lib/screens/incident_list_screen.dart ← รายการ, filter
lib/screens/incident_form_screen.dart ← ฟอร์มเพิ่ม/แก้ไข
lib/screens/incident_detail_screen.dart ← รายละเอียด, AI badge
lib/screens/stats_screen.dart         ← สถิติ, กราฟ
```

### แก้ Navigation (เพิ่ม/ลดแท็บ)
```
lib/main.dart
  → _screens list
  → NavigationBar destinations
```

### เพิ่ม Package ใหม่
```
pubspec.yaml
  → เพิ่มใต้ dependencies:
  → รัน: flutter pub get
```

### แก้ Permission Android
```
android/app/src/main/AndroidManifest.xml
  → เพิ่ม <uses-permission ... />
```

---

## คำสั่งที่ต้องรู้

### คำสั่งพื้นฐาน Flutter

```bash
# ตรวจสอบ Flutter environment ว่าพร้อมไหม
flutter doctor

# ดู Flutter version
flutter --version

# ดู devices ที่เชื่อมต่ออยู่
flutter devices

# ดู emulators ที่มี
flutter emulators

# เปิด emulator
flutter emulators --launch <emulator_id>
# ตัวอย่าง:
flutter emulators --launch Pixel_9_Pro
```

### คำสั่ง Project

```bash
# สร้าง Flutter project structure ใน folder ปัจจุบัน
# ใช้ครั้งแรก หรือเมื่อต้องการสร้าง project ใหม่
# ไม่ overwrite ไฟล์ที่มีอยู่แล้ว (lib/, pubspec.yaml)
flutter create .

# ติดตั้ง/อัปเดต packages ตาม pubspec.yaml
# รันทุกครั้งที่เพิ่ม/แก้ dependency ใน pubspec.yaml
flutter pub get

# ตรวจสอบ packages ที่มี version ใหม่
flutter pub outdated

# อัปเดต packages ทั้งหมด
flutter pub upgrade
```

### คำสั่ง Run & Build

```bash
# รัน app ใน debug mode บน device ที่เลือก
flutter run -d emulator-5554

# รัน app บน device แรกที่พบ (ถ้ามี device เดียว)
flutter run

# รัน app แบบ release mode (เร็วกว่า debug)
flutter run --release -d emulator-5554

# Build APK สำหรับ Android
flutter build apk

# Build APK แบบ release (สำหรับแจกจ่าย)
flutter build apk --release

# ตำแหน่ง APK ที่ build แล้ว:
# build/app/outputs/flutter-apk/app-release.apk
```

### คำสั่งแก้ปัญหา (Reset / เริ่มใหม่)

```bash
# ล้าง build cache ทั้งหมด (ใช้เมื่อเกิด build error แปลกๆ)
flutter clean

# หลังจาก flutter clean ต้อง pub get ใหม่เสมอ
flutter clean && flutter pub get

# ลบ database บน emulator และรีเซ็ตข้อมูล:
# วิธีที่ 1: ลบแอปออกจาก emulator แล้วรันใหม่
# วิธีที่ 2: ใน Android Studio → Device Explorer → data/data/com.example.final66123217/databases/

# ถ้า Gradle error ให้ลองล้าง Gradle cache
cd android && ./gradlew clean && cd ..
flutter run

# ถ้า packages มีปัญหา
flutter pub cache clean
flutter pub get
```

### คำสั่ง Analyze & Format

```bash
# ตรวจหา error และ warning ใน code ทั้งหมด
flutter analyze

# จัด format code ให้ตรง Dart standard
dart format lib/

# รัน unit tests
flutter test
```

### สรุปลำดับเมื่อต้องเริ่มใหม่ทั้งหมด

```bash
# 1. ล้าง cache
flutter clean

# 2. ติดตั้ง packages ใหม่
flutter pub get

# 3. เปิด emulator
flutter emulators --launch Pixel_9_Pro

# 4. รอ emulator boot แล้วรัน
flutter run -d emulator-5554
```

---

## ข้อควรระวัง

- **ห้ามแก้ไขไฟล์ใน `build/`** — สร้างใหม่อัตโนมัติทุกครั้ง
- **ห้ามแก้ไขไฟล์ใน `.dart_tool/`** — Flutter internal
- **`pubspec.lock`** — ไม่ต้องแก้เอง สร้างจาก `flutter pub get`
- **แก้ schema DB หลัง app รันแล้ว** — ต้องลบแอปออกจาก device แล้วรันใหม่ เพราะ `onCreate` จะไม่รันซ้ำ
- **`sqflite` ไม่รองรับ Windows/Web** — ต้องรันบน Android/iOS เท่านั้น
