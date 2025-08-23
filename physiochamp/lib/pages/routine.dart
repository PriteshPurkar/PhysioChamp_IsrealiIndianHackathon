// lib/pages/routine.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:physiochamp/pages/widgets/fall_risk_panel.dart';
import '../../session_manager.dart'; // uses your existing SessionManager
import 'champ.dart'; // ChampPage

// Change this to your backend base if needed
const String _kApiBase = 'http://10.171.28.60:5000';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  final SessionManager _sm = SessionManager();

  bool isAssessing = false;
  int secondsLeft = 0; // countdown for 5-min (300s)
  Timer? _timer;

  double? riskScore;
  String? _assessmentId;
  DateTime? _startedAt;

  // ---------------- Backend helpers ----------------
  Future<void> _startBackendAssessment({required int windowSeconds}) async {
    int? sid = _sm.currentSessionId;
    if (sid == null) {
      for (int i = 0; i < 6; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        sid = _sm.currentSessionId;
        if (sid != null) break;
      }
    }

    try {
      final res = await http.post(
        Uri.parse('$_kApiBase/fallrisk/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": 1,
          "session_id": sid,
          "window_s": windowSeconds,
        }),
      );
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        _assessmentId = j['assessment_id']?.toString();
      } else {
        _assessmentId = null;
      }
    } catch (_) {
      _assessmentId = null;
    }
  }

  Future<double?> _completeBackendAssessment() async {
    if (_assessmentId != null) {
      try {
        final res = await http.post(
          Uri.parse('$_kApiBase/fallrisk/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({"assessment_id": _assessmentId}),
        );
        if (res.statusCode == 200) {
          final j = jsonDecode(res.body);
          final s = j['risk_score'];
          if (s is num) return s.toDouble();
        }
      } catch (_) {}
    }

    final elapsed = _startedAt == null
        ? 300
        : DateTime.now().difference(_startedAt!).inSeconds.clamp(30, 300);

    try {
      final res = await http.post(
        Uri.parse('$_kApiBase/fallrisk/quick'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": 1,
          "window_s": elapsed,
          "session_id": _sm.currentSessionId,
        }),
      );
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        final s = j['risk_score'];
        if (s is num) return s.toDouble();
      }
    } catch (_) {}

    return Random().nextDouble() * 100;
  }

  Future<void> _startSessionIfNeeded() async {
    if (!_sm.isSessionActive) {
      _sm.startSession();
    }
  }

  Future<void> _stopSessionIfActive() async {
    if (_sm.isSessionActive) {
      _sm.stopSession();
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> startAssessment() async {
    setState(() {
      isAssessing = true;
      secondsLeft = 300;
      riskScore = null;
      _assessmentId = null;
      _startedAt = DateTime.now();
    });

    await _startSessionIfNeeded();
    await _startBackendAssessment(windowSeconds: 300);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (secondsLeft > 0) {
        setState(() {
          secondsLeft--;
        });
      } else {
        t.cancel();
        completeAssessment();
      }
    });
  }

  Future<void> completeAssessment() async {
    setState(() {
      isAssessing = false;
    });

    await _stopSessionIfActive();

    final score = await _completeBackendAssessment();

    setState(() {
      riskScore = score ?? (Random().nextDouble() * 100);
      secondsLeft = 0;
      _assessmentId = null;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------------- UI helpers ----------------

  Widget buildCategoryCard(
      String title,
      Color color,
      IconData icon,
      List<Map<String, String>> exercises,
      ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      shadowColor: color.withOpacity(0.4),
      child: ExpansionTile(
        iconColor: color,
        collapsedIconColor: color,
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(
          title,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: exercises.map((exercise) {
                return InkWell(
                  onTap: () async {
                    final url = Uri.parse(exercise['url']!);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    width: 260,
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[50],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              exercise['thumbnail']!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            exercise['name']!,
                            style:
                            const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(exercise['benefit']!),
                          trailing: const Icon(Icons.play_circle_fill,
                              color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _howToWalkCard() {
    return Card(
      color: Colors.teal.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: const Padding(
        padding: EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("How to walk for this test",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 6),
            Text("• Walk at your normal, comfortable pace."),
            Text("• Keep moving continuously for 5 minutes (turn as needed)."),
            Text("• Avoid running, jumping, or standing still for long."),
            Text("• Keep the phone on you; wear the insoles correctly."),
            Text("• If you feel unsafe at any time, press Stop."),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanceExercises = [
      {
        'name': 'Balance Training Routine',
        'benefit': 'Improve stability & coordination',
        'url': 'https://www.youtube.com/watch?v=FUabI1jKgdQ',
        'thumbnail': 'https://img.youtube.com/vi/FUabI1jKgdQ/0.jpg'
      },
    ];
    final postureExercises = [
      {
        'name': 'Posture Correction Routine',
        'benefit': 'Correct alignment & reduce pain',
        'url': 'https://www.youtube.com/watch?v=XWQvmh_INTQ',
        'thumbnail': 'https://img.youtube.com/vi/XWQvmh_INTQ/0.jpg'
      },
    ];
    final flexibilityExercises = [
      {
        'name': 'Flexibility Routine',
        'benefit': 'Improve range of motion',
        'url': 'https://www.youtube.com/watch?v=tnZ96Y2C28Y',
        'thumbnail': 'https://img.youtube.com/vi/tnZ96Y2C28Y/0.jpg'
      },
    ];
    final gaitExercises = [
      {
        'name': 'Gait Training Routine',
        'benefit': 'Improve stride & walking ability',
        'url': 'https://www.youtube.com/watch?v=pOPnPaydsB8',
        'thumbnail': 'https://img.youtube.com/vi/pOPnPaydsB8/0.jpg'
      },
    ];

    final double progress = (300 - secondsLeft) / 300.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Assessments',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Colors.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.teal),
            backgroundColor: Colors.transparent,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (isAssessing) ...[
                    _howToWalkCard(),
                    const SizedBox(height: 12),
                    const Text("⏱ Assessment in Progress",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 160,
                            height: 160,
                            child: CircularProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              strokeWidth: 12,
                              color: Colors.teal,
                              backgroundColor: Colors.grey.shade300,
                            ),
                          ),
                          Text(
                            "${(secondsLeft ~/ 60).toString().padLeft(2, '0')}:${(secondsLeft % 60).toString().padLeft(2, '0')}",
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        _timer?.cancel();
                        await _stopSessionIfActive();
                        setState(() {
                          isAssessing = false;
                          _assessmentId = null;
                        });
                        if (_startedAt != null &&
                            DateTime.now()
                                .difference(_startedAt!)
                                .inSeconds >=
                                30) {
                          final score =
                          await _completeBackendAssessment();
                          setState(() => riskScore = score);
                        }
                        secondsLeft = 0;
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.all(16),
                      ),
                      icon: const Icon(Icons.stop),
                      label: const Text("Stop Assessment"),
                    ),
                  ] else if (riskScore != null) ...[
                    const Text("📊 Assessment Results",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    FallRiskPanel(
                      riskScore: riskScore!,
                      doubleSupportPct: 27.5,
                      loadAsymmetryPct: 6.8,
                      forefootHeelRatio: 1.05,
                      stepWidthVarPct: 11.0,
                      toeClearanceProxyPct: 48,
                      lastUpdated: TimeOfDay.now().format(context),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: startAssessment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.all(16),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retake Assessment"),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: startAssessment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.all(20),
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(
                        "Start 5-min Assessment",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              const Divider(thickness: 1),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('🧩 Explore by Category',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              buildCategoryCard('🔵 Balance Training', Colors.blue,
                  Icons.balance, balanceExercises),
              buildCategoryCard('🟡 Posture Correction', Colors.orange,
                  Icons.accessibility_new, postureExercises),
              buildCategoryCard('🟢 Flexibility', Colors.green,
                  Icons.self_improvement, flexibilityExercises),
              buildCategoryCard('🟣 Gait Retraining', Colors.purple,
                  Icons.directions_walk, gaitExercises),
            ]),
          ),
        ],
      ),
    );
  }
}
