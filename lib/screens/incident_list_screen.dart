import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../helpers/database_helper.dart';
import '../models/incident_report.dart';
import 'incident_detail_screen.dart';
import 'incident_form_screen.dart';

class IncidentListScreen extends StatefulWidget {
  // standalone=true เมื่อเปิดจาก HomeScreen (มี AppBar + FAB)
  // standalone=false เมื่อฝังใน BottomNavigationBar (ไม่มี AppBar ซ้อน)
  final bool standalone;
  const IncidentListScreen({super.key, this.standalone = false});

  @override
  State<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends State<IncidentListScreen> {
  final _db = DatabaseHelper();
  List<IncidentReport> _incidents = [];
  String? _filterSeverity;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoading = true);
    final data = await _db.getAllIncidents(filterSeverity: _filterSeverity);
    setState(() {
      _incidents = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'รายการเหตุการณ์',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<String?>(
              value: _filterSeverity,
              dropdownColor: Colors.white,
              underline: const SizedBox(),
              icon: const Icon(Icons.filter_list, color: Colors.white),
              items: [
                const DropdownMenuItem(value: null, child: Text('ทั้งหมด')),
                DropdownMenuItem(
                  value: 'High',
                  child: Row(children: [
                    Icon(Icons.circle, color: AppColors.high, size: 12),
                    const SizedBox(width: 4),
                    const Text('High'),
                  ]),
                ),
                DropdownMenuItem(
                  value: 'Medium',
                  child: Row(children: [
                    Icon(Icons.circle, color: AppColors.medium, size: 12),
                    const SizedBox(width: 4),
                    const Text('Medium'),
                  ]),
                ),
                DropdownMenuItem(
                  value: 'Low',
                  child: Row(children: [
                    Icon(Icons.circle, color: AppColors.low, size: 12),
                    const SizedBox(width: 4),
                    const Text('Low'),
                  ]),
                ),
              ],
              onChanged: (val) {
                setState(() => _filterSeverity = val);
                _loadIncidents();
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _incidents.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('ไม่มีรายการ', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadIncidents,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _incidents.length,
                    itemBuilder: (ctx, i) => _IncidentCard(
                      incident: _incidents[i],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => IncidentDetailScreen(
                              reportId: _incidents[i].reportId!,
                            ),
                          ),
                        );
                        _loadIncidents();
                      },
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const IncidentFormScreen()),
          );
          if (result == true) _loadIncidents();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final IncidentReport incident;
  final VoidCallback onTap;

  const _IncidentCard({required this.incident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = severityColor(incident.severity ?? '');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.stationName ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          incident.typeName ?? '-',
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  // Right: severity badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color, width: 1),
                    ),
                    child: Text(
                      incident.severity ?? '-',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    incident.reporterName,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    incident.timestamp,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
