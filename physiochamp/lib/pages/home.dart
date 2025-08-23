import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../session_manager.dart';
import 'champ.dart';

const String _kApiBase = 'http://10.171.28.60:5000';

class HomePage extends StatefulWidget {
  final String? apiBase;

  const HomePage({super.key, this.apiBase});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SessionManager sessionManager = SessionManager();

  int steps = 1250;
  double distanceKm = 0.9;
  int calories = 45;
  int todaySessions = 0;

  Map<String, dynamic> metrics = {
    'posture_score': 85,
    'gait_symmetry_score': 92,
    'balance_score': 78,
    'contact_time_s': 0.22,
    'cadence_spm': 120.0,
    'swing_stance_ratio': 0.82,
  };

  String get _base => widget.apiBase ?? _kApiBase;

  int? _lastStartedSid;
  Timer? _timer; // ⏱ to tick the UI timer

  @override
  void initState() {
    super.initState();
    try {
      (sessionManager as dynamic).apiBase = _base;
    } catch (e) {}
    try {
      (sessionManager as dynamic).setApiBase(_base);
    } catch (e) {}

    sessionManager.attachListener(_onSessionChanged);
    _loadLastSessionAtLaunch();
  }

  @override
  void dispose() {
    sessionManager.detachListener(_onSessionChanged);
    _timer?.cancel();
    super.dispose();
  }

  void _onSessionChanged() {
    setState(() {});
  }

  Future<void> _loadLastSessionAtLaunch() async {
    try {
      final res =
      await http.get(Uri.parse("$_base/sessions/last_completed?user_id=1"));
      if (res.statusCode == 200) {
        final map = Map<String, dynamic>.from(json.decode(res.body));
        final sid =
        map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}');
        if (sid != null) {
          await _fetchMetrics(sid);
        }
      }
    } catch (e) {}
  }

  Future<void> _fetchMetrics(int sessionId) async {
    try {
      final res = await http.get(Uri.parse("$_base/metrics/$sessionId"));
      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        if (decoded is Map && !decoded.containsKey('error')) {
          setState(() {
            metrics = Map<String, dynamic>.from(decoded);
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _startSessionBackend() async {
    try {
      final res = await http.post(Uri.parse("$_base/start_session"));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final sid = (body is Map && body['session_id'] != null)
            ? (body['session_id'] as num).toInt()
            : null;

        if (sid != null) {
          _lastStartedSid = sid;

          try {
            (sessionManager as dynamic).currentSessionId = sid;
          } catch (e) {}
          try {
            (sessionManager as dynamic).setCurrentSessionId(sid);
          } catch (e) {}

          try {
            sessionManager.startSession();
          } catch (e) {}

          // 🔹 Start ticking local timer every second
          _timer?.cancel();
          _timer = Timer.periodic(const Duration(seconds: 1), (_) {
            setState(() {
              sessionManager.sessionSeconds++;
            });
          });

          setState(() {
            todaySessions++;
            steps = 0;
            distanceKm = 0.0;
            calories = 0;
          });

          _showSnack("Session #$sid started.");
        } else {
          _showSnack("Start returned no session_id.");
        }
      } else {
        _showSnack("Failed to start session (HTTP ${res.statusCode}).");
      }
    } catch (e) {
      _showSnack("Start error: $e");
    }
  }

  Future<void> _stopSessionBackend() async {
    final sid = sessionManager.currentSessionId ?? _lastStartedSid;
    if (sid == null) {
      _showSnack("No active session id to stop.");
      return;
    }

    try {
      final res = await http.post(
        Uri.parse("$_base/stop_session"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'session_id': sid}),
      );
      if (res.statusCode == 200) {
        try {
          sessionManager.stopSession();
        } catch (e) {}

        _timer?.cancel(); // ⏹ stop ticking
        await _fetchMetrics(sid);
        _showSnack("Session #$sid stopped.");
      } else {
        _showSnack("Failed to stop (HTTP ${res.statusCode}).");
      }
    } catch (e) {
      _showSnack("Stop error: $e");
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String formatTime(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  Widget sessionCard() {
    final String today = DateFormat('dd MMM yyyy').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: sessionManager.isSessionActive
              ? [Colors.greenAccent.shade400, Colors.green.shade700] // ✅ Active
              : [Colors.blueAccent.shade200, Colors.blue.shade700], // ✅ Idle
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Date row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(today,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              Text("Sessions: ${todaySessions}x",
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),

          // Loader
          Column(
            children: [
              SizedBox(
                height: 70,
                width: 70,
                child: CircularProgressIndicator(
                  value: sessionManager.isSessionActive
                      ? null // ✅ infinite spinner while active
                      : 0.0,
                  strokeWidth: 6,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 6),
              const Text("Hey Pritesh",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 8),

          // Buttons & Timer
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: sessionManager.isSessionActive
                        ? null
                        : () async {
                      await _startSessionBackend();
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Start"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    // ✅ Stop button enabled when session is active
                    onPressed: sessionManager.isSessionActive
                        ? () async {
                      await _stopSessionBackend();
                    }
                        : null,
                    icon: const Icon(Icons.stop),
                    label: const Text("Stop"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text("⏱ Timer: ${formatTime(sessionManager.sessionSeconds)}",
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white)),
            ],
          ),

          const SizedBox(height: 8),

          // Image + Stats
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Image.asset("assets/animations/man_running.gif",
                      fit: BoxFit.contain),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.directions_walk,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text("$steps steps",
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.route,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text("${distanceKm.toStringAsFixed(2)} km",
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white70, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_fire_department,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text("$calories cal",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget metricsGrid() {
    final double contactS = (metrics['contact_time_s'] is num)
        ? (metrics['contact_time_s'] as num).toDouble()
        : 0.0;
    final String contactMs = "${(contactS * 1000).toStringAsFixed(0)} ms";

    final double cadence = (metrics['cadence_spm'] is num)
        ? (metrics['cadence_spm'] as num).toDouble()
        : 0.0;
    final String cadenceStr = "${cadence.toStringAsFixed(0)} spm";

    double ssr = (metrics['swing_stance_ratio'] is num)
        ? (metrics['swing_stance_ratio'] as num).toDouble()
        : 0.0;
    if (ssr.isNaN || !ssr.isFinite || ssr <= 0) ssr = 0.82;
    final double standPct = (100.0 / (1.0 + ssr));
    final double swingPct = 100.0 - standPct;
    final String swingStand =
        "${swingPct.toStringAsFixed(0)}/${standPct.toStringAsFixed(0)}%";

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _metricCard("Posture", "${metrics['posture_score']}%",
                Icons.accessibility_new, Colors.blue,
                description:
                "Posture Score indicates how upright and aligned your body is while walking."),
            _metricCard("Gait", "${metrics['gait_symmetry_score']}%",
                Icons.directions_walk, Colors.green,
                description:
                "Gait Symmetry measures how evenly both sides of your body move during walking."),
            _metricCard("Balance", "${metrics['balance_score']}%",
                Icons.accessibility, Colors.orange,
                description:
                "Balance Score reflects your stability and control while standing or moving."),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _metricCard("Contact Time", contactMs, Icons.timer, Colors.purple,
                description:
                "Contact Time is the average time your foot stays in contact with the ground per step."),
            _metricCard("Cadence", cadenceStr, Icons.directions_run, Colors.red,
                description:
                "Cadence is the number of steps you take per minute while walking or running."),
            _metricCard("Swing/Stand", swingStand, Icons.swap_vert, Colors.teal,
                description:
                "Swing/Stance Ratio shows the balance between time your foot is in the air (swing) vs on the ground (stance)."),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color,
      {required String description}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(title),
              content: Text(description),
              actions: [
                TextButton(
                  child: const Text("OK"),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          );
        },
        child: Card(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.25)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 6),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "PHYSIOCHAMP",
          style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChampPage()),
                );
              },
              child: const Center(
                child: Text(
                  "Champ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(flex: 11, child: sessionCard()),
            const SizedBox(height: 8),
            Expanded(flex: 6, child: metricsGrid()),
          ],
        ),
      ),
    );
  }
}
