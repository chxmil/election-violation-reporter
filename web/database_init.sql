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
