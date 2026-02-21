# DATA.md
# ข้อมูลฐานข้อมูล SQLite — Election Violation Reporter

---

## 📁 web/database_init.sql

```sql
-- ===========================
-- สร้างตาราง polling_station
-- ===========================
CREATE TABLE IF NOT EXISTS polling_station (
  station_id   INTEGER PRIMARY KEY,
  station_name TEXT NOT NULL,
  zone         TEXT NOT NULL,
  province     TEXT NOT NULL
);

-- ===========================
-- สร้างตาราง violation_type
-- ===========================
CREATE TABLE IF NOT EXISTS violation_type (
  type_id   INTEGER PRIMARY KEY AUTOINCREMENT,
  type_name TEXT NOT NULL,
  severity  TEXT NOT NULL CHECK(severity IN ('High','Medium','Low'))
);

-- ===========================
-- สร้างตาราง incident_report
-- ===========================
CREATE TABLE IF NOT EXISTS incident_report (
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
);
```

---

## 📁 web/sample_data.sql

```sql
-- ===========================
-- ข้อมูลหน่วยเลือกตั้ง
-- ===========================
INSERT OR IGNORE INTO polling_station VALUES (101, 'โรงเรียนวัดพระมหาธาตุ', 'เขต 1', 'นครศรีธรรมราช');
INSERT OR IGNORE INTO polling_station VALUES (102, 'เต็นท์หน้าตลาดท่าวัง',  'เขต 1', 'นครศรีธรรมราช');
INSERT OR IGNORE INTO polling_station VALUES (103, 'ศาลากลางหมู่บ้านคีรีวง','เขต 2', 'นครศรีธรรมราช');
INSERT OR IGNORE INTO polling_station VALUES (104, 'หอประชุมอำเภอทุ่งสง',   'เขต 3', 'นครศรีธรรมราช');
INSERT OR IGNORE INTO polling_station VALUES (105, 'โรงเรียนเบญจมราชูทิศ',   'เขต 1', 'นครศรีธรรมราช');
INSERT OR IGNORE INTO polling_station VALUES (106, 'วัดพระธาตุน้อย',          'เขต 2', 'นครศรีธรรมราช');

-- ===========================
-- ข้อมูลประเภทความผิด
-- ===========================
INSERT OR IGNORE INTO violation_type VALUES (1, 'ซื้อสิทธิ์ขายเสียง (Buying Votes)',         'High');
INSERT OR IGNORE INTO violation_type VALUES (2, 'ขนคนไปลงคะแนน (Transportation)',             'High');
INSERT OR IGNORE INTO violation_type VALUES (3, 'หาเสียงเกินเวลา (Overtime Campaign)',         'Medium');
INSERT OR IGNORE INTO violation_type VALUES (4, 'ทำลายป้ายหาเสียง (Vandalism)',               'Low');
INSERT OR IGNORE INTO violation_type VALUES (5, 'เจ้าหน้าที่วางตัวไม่เป็นกลาง (Bias Official)', 'High');

-- ===========================
-- ข้อมูลรายงานเหตุการณ์
-- ===========================
INSERT OR IGNORE INTO incident_report VALUES
  (1, 101, 1, 'พลเมืองดี 01', 'พบเห็นการแจกเงินบริเวณหน้าหน่วย',   NULL, '2026-02-08 09:30:00', 'Money',  0.95);

INSERT OR IGNORE INTO incident_report VALUES
  (2, 102, 3, 'สมชาย ใจกล้า', 'มีการเปิดรถแห่เสียงดังรบกวน',        NULL, '2026-02-08 10:15:00', 'Crowd',  0.75);

INSERT OR IGNORE INTO incident_report VALUES
  (3, 103, 5, 'Anonymous',    'เจ้าหน้าที่พูดจาชี้นำผู้ลงคะแนน',    NULL, '2026-02-08 11:00:00', NULL,     0.0);

INSERT OR IGNORE INTO incident_report VALUES
  (4, 104, 2, 'วิภา รักชาติ', 'พบรถหลายคันรับส่งผู้มาใช้สิทธิ์',   NULL, '2026-02-08 11:45:00', 'Car',    0.88);

INSERT OR IGNORE INTO incident_report VALUES
  (5, 101, 4, 'ประชา มั่นใจ', 'ป้ายหาเสียงถูกฉีกทำลาย',             NULL, '2026-02-08 12:30:00', 'Poster', 0.62);

INSERT OR IGNORE INTO incident_report VALUES
  (6, 105, 1, 'นิรนาม',       'มีคนแจกซองบริเวณด้านหลังหน่วย',      NULL, '2026-02-08 13:00:00', 'Money',  0.91);

INSERT OR IGNORE INTO incident_report VALUES
  (7, 106, 3, 'สุชาติ ดีงาม', 'รถหาเสียงวนซ้ำหลายรอบ',              NULL, '2026-02-08 14:00:00', 'Crowd',  0.55);
```

---

## 🗺️ ER Diagram (Text)

```
polling_station          incident_report          violation_type
───────────────          ───────────────          ──────────────
station_id (PK) ◄──── station_id (FK)        ┌── type_id (PK)
station_name            report_id (PK)         │   type_name
zone                    type_id (FK) ──────────┘   severity
province                reporter_name
                        description
                        evidence_photo
                        timestamp
                        ai_result
                        ai_confidence
```

---

## 🔍 ตัวอย่าง Query ที่ใช้บ่อย

### ดึงรายการพร้อม JOIN
```sql
SELECT
  ir.report_id,
  ps.station_name,
  ps.zone,
  vt.type_name,
  vt.severity,
  ir.reporter_name,
  ir.description,
  ir.evidence_photo,
  ir.timestamp,
  ir.ai_result,
  ir.ai_confidence
FROM incident_report ir
JOIN polling_station ps ON ir.station_id = ps.station_id
JOIN violation_type vt  ON ir.type_id    = vt.type_id
ORDER BY ir.timestamp DESC;
```

### นับตาม severity
```sql
SELECT vt.severity, COUNT(*) as count
FROM incident_report ir
JOIN violation_type vt ON ir.type_id = vt.type_id
GROUP BY vt.severity;
```

### สถิติต่อประเภทความผิด
```sql
SELECT vt.type_name, vt.severity, COUNT(*) as count
FROM incident_report ir
JOIN violation_type vt ON ir.type_id = vt.type_id
GROUP BY vt.type_id
ORDER BY count DESC;
```

### สถิติต่อหน่วยเลือกตั้ง
```sql
SELECT ps.station_name, ps.zone, COUNT(*) as count
FROM incident_report ir
JOIN polling_station ps ON ir.station_id = ps.station_id
GROUP BY ps.station_id
ORDER BY count DESC;
```

### ค่าเฉลี่ย ai_confidence
```sql
SELECT ROUND(AVG(ai_confidence), 2) as avg_confidence
FROM incident_report
WHERE ai_confidence > 0;
```

### กรองตาม severity
```sql
SELECT ir.*, ps.station_name, vt.type_name, vt.severity
FROM incident_report ir
JOIN polling_station ps ON ir.station_id = ps.station_id
JOIN violation_type vt  ON ir.type_id    = vt.type_id
WHERE vt.severity = 'High'
ORDER BY ir.timestamp DESC;
```
