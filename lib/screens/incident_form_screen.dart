import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_constants.dart';
import '../helpers/database_helper.dart';
import '../models/incident_report.dart';
import '../models/polling_station.dart';
import '../models/violation_type.dart';

class IncidentFormScreen extends StatefulWidget {
  final IncidentReport? incident; // null = add mode, non-null = edit mode
  const IncidentFormScreen({super.key, this.incident});

  @override
  State<IncidentFormScreen> createState() => _IncidentFormScreenState();
}

class _IncidentFormScreenState extends State<IncidentFormScreen> {
  final _db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  final _reporterController = TextEditingController();
  final _descController = TextEditingController();

  List<PollingStation> _stations = [];
  List<ViolationType> _violationTypes = [];

  PollingStation? _selectedStation;
  ViolationType? _selectedType;
  String? _evidencePhotoPath;
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isEditMode => widget.incident != null;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    final stations = await _db.getAllStations();
    final types = await _db.getAllViolationTypes();
    setState(() {
      _stations = stations;
      _violationTypes = types;
      _isLoading = false;
    });

    // Pre-fill if edit mode
    if (_isEditMode) {
      final inc = widget.incident!;
      _reporterController.text = inc.reporterName;
      _descController.text = inc.description ?? '';
      _evidencePhotoPath = inc.evidencePhoto;
      _selectedStation = _stations.firstWhere(
        (s) => s.stationId == inc.stationId,
        orElse: () => _stations.first,
      );
      _selectedType = _violationTypes.firstWhere(
        (t) => t.typeId == inc.typeId,
        orElse: () => _violationTypes.first,
      );
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (picked != null) {
        setState(() => _evidencePhotoPath = picked.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเปิดกล้องได้: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final timestamp = DateTime.now().toString().substring(0, 19);
    final incident = IncidentReport(
      reportId:      _isEditMode ? widget.incident!.reportId : null,
      stationId:     _selectedStation!.stationId,
      typeId:        _selectedType!.typeId,
      reporterName:  _reporterController.text.trim(),
      description:   _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      evidencePhoto: _evidencePhotoPath,
      timestamp:     _isEditMode ? widget.incident!.timestamp : timestamp,
      aiResult:      _isEditMode ? widget.incident!.aiResult : null,
      aiConfidence:  _isEditMode ? widget.incident!.aiConfidence : 0.0,
    );

    if (_isEditMode) {
      await _db.updateIncident(incident);
    } else {
      await _db.insertIncident(incident);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _reporterController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'แก้ไขรายงาน' : 'เพิ่มรายงาน',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dropdown: หน่วยเลือกตั้ง
                    _buildSectionLabel('หน่วยเลือกตั้ง *'),
                    DropdownButtonFormField<PollingStation>(
                      value: _selectedStation,
                      decoration: _inputDecoration('เลือกหน่วยเลือกตั้ง'),
                      items: _stations.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s.stationId} — ${s.stationName}', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedStation = val),
                      validator: (val) => val == null ? 'กรุณาเลือกหน่วยเลือกตั้ง' : null,
                    ),
                    const SizedBox(height: 16),

                    // Dropdown: ประเภทความผิด
                    _buildSectionLabel('ประเภทความผิด *'),
                    DropdownButtonFormField<ViolationType>(
                      value: _selectedType,
                      decoration: _inputDecoration('เลือกประเภทความผิด'),
                      items: _violationTypes.map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.typeName, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedType = val),
                      validator: (val) => val == null ? 'กรุณาเลือกประเภทความผิด' : null,
                    ),
                    const SizedBox(height: 16),

                    // ชื่อผู้แจ้ง
                    _buildSectionLabel('ชื่อผู้แจ้ง *'),
                    TextFormField(
                      controller: _reporterController,
                      decoration: _inputDecoration('ระบุชื่อผู้แจ้ง'),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'กรุณาระบุชื่อผู้แจ้ง' : null,
                    ),
                    const SizedBox(height: 16),

                    // รายละเอียด
                    _buildSectionLabel('รายละเอียด'),
                    TextFormField(
                      controller: _descController,
                      decoration: _inputDecoration('อธิบายเหตุการณ์ที่พบ (ไม่บังคับ)'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    // หลักฐานภาพ
                    _buildSectionLabel('หลักฐานภาพ'),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('ถ่ายรูป'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_evidencePhotoPath != null)
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_evidencePhotoPath!),
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60),
                              ),
                            ),
                          )
                        else
                          const Text('ยังไม่มีรูป', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ปุ่มบันทึก
                    ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('บันทึก'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}
