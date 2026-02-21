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
INSERT OR IGNORE INTO violation_type VALUES (1, 'ซื้อสิทธิ์ขายเสียง (Buying Votes)',          'High');
INSERT OR IGNORE INTO violation_type VALUES (2, 'ขนคนไปลงคะแนน (Transportation)',              'High');
INSERT OR IGNORE INTO violation_type VALUES (3, 'หาเสียงเกินเวลา (Overtime Campaign)',          'Medium');
INSERT OR IGNORE INTO violation_type VALUES (4, 'ทำลายป้ายหาเสียง (Vandalism)',                'Low');
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
