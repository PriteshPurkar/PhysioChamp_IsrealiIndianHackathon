// lib/pages/progress.dart
import 'dart:async';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:physiochamp/pages/session_history.dart';
import '../../session_manager.dart';

/// Change this to your backend base if needed
const String _kApiBase = 'http://10.171.28.60:5000';

class ProgressPage extends StatefulWidget {
  final String? apiBase;
  const ProgressPage({super.key, this.apiBase});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final SessionManager _sm = SessionManager();

  String get _base => widget.apiBase ?? _kApiBase;

  // Data for the 3 charts (kept same visual as your original)
  // 1) Posture (Mon..Sun) line
  final List<double> _postureByWeekday = List<double>.filled(7, 0.0);

  // 2) Balance (last 4 weeks) bars
  final List<double> _balanceByWeek = List<double>.filled(4, 0.0);
  // Track ISO week starts for aligning live updates
  final List<String> _weekStartsIso = List<String>.filled(4, '');

  // 3) Pressure distribution (Mon..Sun) line
  final List<double> _pressureByWeekday = List<double>.filled(7, 0.0);

  // Tip
  String _tipText = "—";

  // History table rows
  // [{"date":"YYYY-MM-DD","posture":78,"balance":85,"notes":"Good progress"}, ...]
  List<Map<String, dynamic>> _historyRows = const [];

  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _sm.attachListener(_onSmChange);
    _seedWeekStarts();
    _fetchAll();

    // ✅ Timer.periodic callback must accept a Timer argument
    _poll = Timer.periodic(const Duration(seconds: 5), (Timer _) async {
      await _fetchAll();
    });
  }

  @override
  void dispose() {
    _sm.detachListener(_onSmChange);
    _poll?.cancel();
    super.dispose();
  }

  void _onSmChange() {
    // Re-run fetches when session on/off switches
    _fetchAll();
    setState(() {}); // rebuild to reflect live status if needed
  }

  // Build the 4 week-start ISO dates for the bar chart, oldest..newest
  void _seedWeekStarts() {
    final now = DateTime.now();
    final mondayThisWeek = now.subtract(Duration(days: now.weekday - 1));
    final weeks = List<DateTime>.generate(
      4,
          (i) => DateTime(
        mondayThisWeek.year,
        mondayThisWeek.month,
        mondayThisWeek.day,
      ).subtract(Duration(days: (3 - i) * 7)),
    );
    for (int i = 0; i < 4; i++) {
      _weekStartsIso[i] = weeks[i].toIso8601String().substring(0, 10);
    }
  }

  // Generate Monday..Sunday ISO for the current week for aligning daily charts
  List<String> _currentWeekDatesIso() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List<String>.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      return d.toIso8601String().substring(0, 10);
    });
  }

  Future<void> _fetchAll() async {
    await Future.wait([
      _fetchPostureOverTime(),
      _fetchBalanceWeekly(),
      _fetchPressureDistribution(),
      _fetchHistory(),
      _fetchTip(),
      if (_sm.isSessionActive == true && _sm.currentSessionId != null)
        _fetchLiveOverlays(),
    ]);

    if (mounted) setState(() {});
  }

  Future<void> _fetchPostureOverTime() async {
    try {
      final uri =
      Uri.parse("$_base/progress/posture_over_time?user_id=1&days=7");
      final r = await http.get(uri).timeout(const Duration(seconds: 4));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        final series = (data['series'] as List?) ?? [];
        // Align to current Mon..Sun
        final weekDays = _currentWeekDatesIso();
        final map = <String, double>{};
        for (final e in series) {
          final d = (e['date'] ?? '').toString();
          final s =
          (e['score'] is num) ? (e['score'] as num).toDouble() : 0.0;
          map[d] = s;
        }
        for (int i = 0; i < 7; i++) {
          _postureByWeekday[i] = map[weekDays[i]] ?? 0.0;
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchBalanceWeekly() async {
    try {
      final uri =
      Uri.parse("$_base/progress/balance_weekly?user_id=1&weeks=4");
      final r = await http.get(uri).timeout(const Duration(seconds: 4));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        final series = (data['series'] as List?) ?? [];
        // Build a map from week_start -> balance
        final map = <String, double>{};
        for (final e in series) {
          final d = (e['week_start'] ?? '').toString();
          final v =
          (e['balance'] is num) ? (e['balance'] as num).toDouble() : 0.0;
          map[d] = v;
        }
        // Fill bars oldest..newest using our precomputed weekStarts
        for (int i = 0; i < 4; i++) {
          _balanceByWeek[i] = map[_weekStartsIso[i]] ?? 0.0;
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchPressureDistribution() async {
    try {
      final uri = Uri.parse(
          "$_base/progress/pressure_distribution?user_id=1&days=7");
      final r = await http.get(uri).timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        final series = (data['series'] as List?) ?? [];
        final map = <String, double>{};
        for (final e in series) {
          final d = (e['date'] ?? '').toString();
          final v = (e['pressure'] is num)
              ? (e['pressure'] as num).toDouble()
              : 0.0;
          map[d] = v;
        }
        final weekDays = _currentWeekDatesIso();
        for (int i = 0; i < 7; i++) {
          _pressureByWeekday[i] = map[weekDays[i]] ?? 0.0;
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchHistory() async {
    try {
      final uri = Uri.parse("$_base/progress/history?user_id=1&limit=10");
      final r = await http.get(uri).timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        final rows = (data['rows'] as List?) ?? [];
        _historyRows = List<Map<String, dynamic>>.from(rows);
      }
    } catch (_) {}
  }

  Future<void> _fetchTip() async {
    try {
      final uri = Uri.parse("$_base/progress/summary_tip?user_id=1");
      final r = await http.get(uri).timeout(const Duration(seconds: 4));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        _tipText = (data['text'] ?? '—').toString();
      }
    } catch (_) {}
  }

  Future<void> _fetchLiveOverlays() async {
    final sid = _sm.currentSessionId;
    if (sid == null) return;

    // 1) Live posture today -> overwrite today's weekday in posture chart
    try {
      final uri =
      Uri.parse("$_base/progress/live_posture_today?session_id=$sid");
      final r = await http.get(uri).timeout(const Duration(seconds: 3));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        final score =
        (data['score'] is num) ? (data['score'] as num).toDouble() : null;
        if (score != null) {
          final idxToday = DateTime.now().weekday - 1; // 0..6
          _postureByWeekday[idxToday] = score;
        }
      }
    } catch (_) {}

    // 2) Live balance this week -> overwrite newest bar if the week_start matches
    try {
      final uri =
      Uri.parse("$_base/progress/live_balance_this_week?session_id=$sid");
      final r = await http.get(uri).timeout(const Duration(seconds: 3));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        final ws = (data['week_start'] ?? '').toString();
        final bal =
        (data['balance'] is num) ? (data['balance'] as num).toDouble() : null;
        if (bal != null) {
          final pos = _weekStartsIso.indexOf(ws);
          if (pos != -1) _balanceByWeek[pos] = bal;
        }
      }
    } catch (_) {}

    // 3) Live pressure series -> average and overwrite today's point
    try {
      final uri = Uri.parse(
          "$_base/progress/live_pressure_series?session_id=$sid&seconds=20");
      final r = await http.get(uri).timeout(const Duration(seconds: 3));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        final series = (data['series'] as List?) ?? [];
        if (series.isNotEmpty) {
          double acc = 0.0;
          int n = 0;
          for (final e in series) {
            final v = (e['pressure'] is num)
                ? (e['pressure'] as num).toDouble()
                : null;
            if (v != null) {
              acc += v;
              n++;
            }
          }
          if (n > 0) {
            final idxToday = DateTime.now().weekday - 1;
            _pressureByWeekday[idxToday] = acc / n;
          }
        }
      }
    } catch (_) {}
  }

  // -------------------- UI (unchanged layout) --------------------

  Widget _buildLineChart(List<double> ys) {
    // 7 points -> Mon..Sun at x=0..6
    final spots = <FlSpot>[
      for (int i = 0; i < 7; i++) FlSpot(i.toDouble(), ys[i].toDouble()),
    ];
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return const Text("Mon");
                    case 1:
                      return const Text("Tue");
                    case 2:
                      return const Text("Wed");
                    case 3:
                      return const Text("Thu");
                    case 4:
                      return const Text("Fri");
                    case 5:
                      return const Text("Sat");
                    case 6:
                      return const Text("Sun");
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 35),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.teal,
              barWidth: 4,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<double> ys) {
    // 4 bars -> W1..W4 (oldest..newest)
    final groups = <BarChartGroupData>[
      for (int i = 0; i < 4; i++)
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: ys[i].toDouble(), color: Colors.teal)],
        )
    ];
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return const Text("W1");
                    case 1:
                      return const Text("W2");
                    case 2:
                      return const Text("W3");
                    case 3:
                      return const Text("W4");
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 35),
            ),
          ),
          barGroups: groups,
        ),
      ),
    );
  }

  Widget _buildTrendCard(String title, Widget chart) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            chart,
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneCard(String text) {
    return Card(
      color: Colors.green[100],
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHistoryTable(BuildContext context) {
    // If no data yet, show the original placeholder structure
    final rows = _historyRows.isEmpty
        ? const [
      TableRow(children: [
        Padding(
            padding: EdgeInsets.all(8), child: Text("2025-07-15")),
        Padding(padding: EdgeInsets.all(8), child: Text("78")),
        Padding(padding: EdgeInsets.all(8), child: Text("85")),
        Padding(
            padding: EdgeInsets.all(8), child: Text("Good progress")),
      ]),
      TableRow(children: [
        Padding(
            padding: EdgeInsets.all(8), child: Text("2025-07-08")),
        Padding(padding: EdgeInsets.all(8), child: Text("70")),
        Padding(padding: EdgeInsets.all(8), child: Text("79")),
        Padding(padding: EdgeInsets.all(8), child: Text("Needs work")),
      ]),
    ]
        : _historyRows.map((m) {
      final d = (m['date'] ?? '').toString();
      final p = (m['posture']?.toString() ?? '—');
      final b = (m['balance']?.toString() ?? '—');
      final n = (m['notes'] ?? '—').toString();
      return TableRow(children: [
        Padding(padding: const EdgeInsets.all(8), child: Text(d)),
        Padding(padding: const EdgeInsets.all(8), child: Text(p)),
        Padding(padding: const EdgeInsets.all(8), child: Text(b)),
        Padding(padding: const EdgeInsets.all(8), child: Text(n)),
      ]);
    }).toList();

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SessionHistoryPage()),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        elevation: 4,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              const ListTile(
                title: Text("📅 History Table",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(3),
                },
                children: [
                  const TableRow(children: [
                    Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Date",
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(
                        padding: EdgeInsets.all(8), child: Text("Posture")),
                    Padding(
                        padding: EdgeInsets.all(8), child: Text("Balance")),
                    Padding(
                        padding: EdgeInsets.all(8), child: Text("Notes")),
                  ]),
                  ...rows,
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: () {}, // keep as-is (UI unchanged)
          icon: const Icon(Icons.download),
          label: const Text("Export All Progress"),
          style: ElevatedButton.styleFrom(
            padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  // -------------------- Build --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text(
          "Progress Tracker",
          style:
          TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTrendCard("Posture Symmetry Over Time",
                _buildLineChart(_postureByWeekday)),
            _buildTrendCard(
                "Balance Index (Weekly)", _buildBarChart(_balanceByWeek)),
            _buildTrendCard("Pressure Distribution Chart",
                _buildLineChart(_pressureByWeekday)),
            _buildMilestoneCard(_tipText == "—"
                ? "🎉 Keep walking sessions to unlock insights!"
                : "🎉 $_tipText"),
            _buildHistoryTable(context),
            _buildExportButton(),
          ],
        ),
      ),
    );
  }
}