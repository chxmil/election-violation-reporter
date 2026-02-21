import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../helpers/database_helper.dart';
import '../models/incident_report.dart';
import 'incident_form_screen.dart';

class IncidentDetailScreen extends StatefulWidget {
  final int reportId;
  const IncidentDetailScreen({super.key, required this.reportId});

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  final _db = DatabaseHelper();
  IncidentReport? _incident;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncident();
  }

  Future<void> _loadIncident() async {
    setState(() => _isLoading = true);
    final incident = await _db.getIncidentById(widget.reportId);
    setState(() {
      _incident = incident;
      _isLoading = false;
    });
  }

  Future<void> _deleteIncident() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบรายงานนี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.high, foregroundColor: Colors.white),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteIncident(widget.reportId);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'รายละเอียด',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_incident != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'แก้ไข',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IncidentFormScreen(incident: _incident),
                  ),
                );
                if (result == true) _loadIncident();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'ลบ',
              onPressed: _deleteIncident,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _incident == null
              ? const Center(child: Text('ไม่พบข้อมูล'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Severity badge
                      _SeverityBadge(severity: _incident!.severity ?? ''),
                      const SizedBox(height: 12),

                      // Info card
                      _InfoCard(incident: _incident!),
                      const SizedBox(height: 12),

                      // Evidence photo
                      _PhotoCard(path: _incident!.evidencePhoto),
                      const SizedBox(height: 12),

                      // AI Result card
                      _AiResultCard(incident: _incident!),
                    ],
                  ),
                ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_rounded, color: color),
          const SizedBox(width: 8),
          Text(
            'ระดับความรุนแรง: $severity',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IncidentReport incident;
  const _InfoCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ข้อมูลเหตุการณ์', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            _InfoRow(icon: Icons.location_on_outlined, label: 'หน่วยเลือกตั้ง', value: incident.stationName ?? '-'),
            _InfoRow(icon: Icons.map_outlined, label: 'เขต', value: incident.stationName != null ? 'เขต' : '-'),
            _InfoRow(icon: Icons.gavel_outlined, label: 'ประเภทความผิด', value: incident.typeName ?? '-'),
            _InfoRow(icon: Icons.person_outline, label: 'ผู้แจ้ง', value: incident.reporterName),
            _InfoRow(icon: Icons.access_time, label: 'วันเวลา', value: incident.timestamp),
            if (incident.description != null && incident.description!.isNotEmpty)
              _InfoRow(icon: Icons.description_outlined, label: 'รายละเอียด', value: incident.description!),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final String? path;
  const _PhotoCard({required this.path});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('หลักฐานภาพ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            const SizedBox(height: 8),
            if (path != null && path!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(path!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _NoPhotoPlaceholder(),
                ),
              )
            else
              const _NoPhotoPlaceholder(),
          ],
        ),
      ),
    );
  }
}

class _NoPhotoPlaceholder extends StatelessWidget {
  const _NoPhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text('ไม่มีรูปหลักฐาน', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _AiResultCard extends StatelessWidget {
  final IncidentReport incident;
  const _AiResultCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    final hasAi = incident.aiResult != null && incident.aiResult!.isNotEmpty;
    final confidence = incident.aiConfidence;

    String confidenceLabel;
    Color confidenceColor;
    IconData confidenceIcon;

    if (confidence >= 0.8) {
      confidenceLabel = 'น่าเชื่อถือ';
      confidenceColor = AppColors.low;
      confidenceIcon = Icons.check_circle;
    } else if (confidence >= 0.5) {
      confidenceLabel = 'ความมั่นใจปานกลาง';
      confidenceColor = AppColors.medium;
      confidenceIcon = Icons.info;
    } else {
      confidenceLabel = 'ความมั่นใจต่ำ';
      confidenceColor = AppColors.high;
      confidenceIcon = Icons.warning_amber_rounded;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.smart_toy_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text('AI Result', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            if (!hasAi)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('ไม่มีผลการวิเคราะห์ AI', style: TextStyle(color: Colors.grey)),
              )
            else ...[
              Row(
                children: [
                  const Text('ผล: ', style: TextStyle(color: Colors.grey)),
                  Text(
                    incident.aiResult!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ความมั่นใจ', style: TextStyle(color: Colors.grey)),
                  Text(
                    '${(confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontWeight: FontWeight.bold, color: confidenceColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: confidence,
                  minHeight: 10,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(confidenceIcon, color: confidenceColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    confidenceLabel,
                    style: TextStyle(color: confidenceColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
