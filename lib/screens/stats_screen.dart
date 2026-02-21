import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../helpers/database_helper.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _db = DatabaseHelper();

  int _totalCount = 0;
  double _avgConfidence = 0.0;
  Map<String, int> _countBySeverity = {};
  List<Map<String, dynamic>> _statsByType = [];
  List<Map<String, dynamic>> _statsByStation = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final total = await _db.getIncidentCount();
    final avg = await _db.getAvgConfidence();
    final bySeverity = await _db.getCountBySeverity();
    final byType = await _db.getStatsPerViolationType();
    final byStation = await _db.getStatsPerStation();
    setState(() {
      _totalCount = total;
      _avgConfidence = avg;
      _countBySeverity = bySeverity;
      _statsByType = byType;
      _statsByStation = byStation;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'สถิติ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'รายงานทั้งหมด',
                          value: '$_totalCount',
                          icon: Icons.report_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'เฉลี่ย AI Confidence',
                          value: '${(_avgConfidence * 100).toStringAsFixed(1)}%',
                          icon: Icons.smart_toy_outlined,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Severity proportion bar
                  _SeverityBar(countBySeverity: _countBySeverity, total: _totalCount),
                  const SizedBox(height: 16),

                  // Stats by violation type
                  _SectionHeader(title: 'แยกตามประเภทความผิด', icon: Icons.gavel_outlined),
                  const SizedBox(height: 8),
                  ..._statsByType.asMap().entries.map((e) {
                    final i = e.key;
                    final row = e.value;
                    return _TypeStatCard(
                      rank: i + 1,
                      typeName: row['type_name'] as String,
                      severity: row['severity'] as String,
                      count: row['count'] as int,
                      total: _totalCount,
                    );
                  }),
                  const SizedBox(height: 16),

                  // Stats by station
                  _SectionHeader(title: 'แยกตามหน่วยเลือกตั้ง (Top 3)', icon: Icons.location_on_outlined),
                  const SizedBox(height: 8),
                  ..._statsByStation.asMap().entries.map((e) {
                    final i = e.key;
                    final row = e.value;
                    return _StationStatCard(
                      rank: i + 1,
                      stationName: row['station_name'] as String,
                      zone: row['zone'] as String,
                      count: row['count'] as int,
                      total: _totalCount,
                      isTop3: i < 3,
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _SeverityBar extends StatelessWidget {
  final Map<String, int> countBySeverity;
  final int total;

  const _SeverityBar({required this.countBySeverity, required this.total});

  @override
  Widget build(BuildContext context) {
    final high = countBySeverity['High'] ?? 0;
    final medium = countBySeverity['Medium'] ?? 0;
    final low = countBySeverity['Low'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'สัดส่วน High / Medium / Low',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            if (total > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    if (high > 0)
                      Expanded(
                        flex: high,
                        child: Container(
                          height: 28,
                          color: AppColors.high,
                          child: Center(
                            child: Text(
                              '$high',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    if (medium > 0)
                      Expanded(
                        flex: medium,
                        child: Container(
                          height: 28,
                          color: AppColors.medium,
                          child: Center(
                            child: Text(
                              '$medium',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    if (low > 0)
                      Expanded(
                        flex: low,
                        child: Container(
                          height: 28,
                          color: AppColors.low,
                          child: Center(
                            child: Text(
                              '$low',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendItem(color: AppColors.high, label: 'High ($high)'),
                _LegendItem(color: AppColors.medium, label: 'Medium ($medium)'),
                _LegendItem(color: AppColors.low, label: 'Low ($low)'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _TypeStatCard extends StatelessWidget {
  final int rank;
  final String typeName;
  final String severity;
  final int count;
  final int total;

  const _TypeStatCard({
    required this.rank,
    required this.typeName,
    required this.severity,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final color = severityColor(severity);
    final pct = total > 0 ? count / total : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#$rank',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(typeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color),
                  ),
                  child: Text(severity, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text('$count รายการ', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationStatCard extends StatelessWidget {
  final int rank;
  final String stationName;
  final String zone;
  final int count;
  final int total;
  final bool isTop3;

  const _StationStatCard({
    required this.rank,
    required this.stationName,
    required this.zone,
    required this.count,
    required this.total,
    required this.isTop3,
  });

  String get _medal {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '#$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    final cardColor = isTop3 ? AppColors.primary.withOpacity(0.05) : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _medal,
                  style: TextStyle(
                    fontSize: isTop3 ? 20 : 14,
                    color: isTop3 ? null : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stationName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(zone, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                Text(
                  '$count รายการ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isTop3 ? AppColors.primary : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isTop3 ? AppColors.primary : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
