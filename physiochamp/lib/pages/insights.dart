// lib/screens/insights.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:physiochamp/pages/widgets/foot_heatmap.dart';

// ✅ use only the new widgets you made
import 'package:physiochamp/widgets/foot_heatmap.dart';   // FootHeatmapPainter40
import 'package:physiochamp/widgets/foot_layouts.dart';   // insoleLayout40Left, mirrorX

import '../../session_manager.dart';
import 'champ.dart';   // ✅ import champ page

// Your backend IP
const String _kApiBase = 'http://10.171.28.60:5000';

class InsightsPage extends StatefulWidget {
  final String? sessionId;                // optional (Live uses SessionManager if null)
  final String? userId;                   // for last_completed (defaults to "1")
  final String? apiBase;                  // optional override
  final String? aggregation;              // p95 | mean | peak
  final Map<String, dynamic>? sessionData;

  const InsightsPage({
    super.key,
    this.sessionId,
    this.userId,
    this.apiBase,
    this.aggregation,
    this.sessionData,
  });

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  final SessionManager _manager = SessionManager();

  Map<String, dynamic>? sessionData;
  String selectedPhase = "Live";
  final List<String> gaitPhases = ["Live", "Heel Strike", "Midstance", "Toe Off"];

  String get _basePref => widget.apiBase ?? _kApiBase;

  @override
  void initState() {
    super.initState();
    sessionData = widget.sessionData ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // 🔑 Rebuild the panel state whenever phase/base/session changes
    final panelKey = ValueKey<String>(
      "phase=$selectedPhase|base=$_basePref|sid=${widget.sessionId ?? _manager.currentSessionId}",
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Insights",
          style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Phase dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonFormField<String>(
                  value: selectedPhase,
                  decoration: const InputDecoration(
                    labelText: "Select Gait Phase",
                    border: OutlineInputBorder(),
                  ),
                  items: gaitPhases
                      .map((phase) =>
                      DropdownMenuItem(value: phase, child: Text(phase)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedPhase = v!),
                ),
              ),

              const SizedBox(height: 16),

              // Heatmaps
              const Text(
                "Foot Pressure Heatmap",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              SizedBox(
                height: size.height * 0.44,
                child: _PhaseHeatmapPanel(
                  key: panelKey,
                  sessionId: selectedPhase == "Live"
                      ? (widget.sessionId ??
                      _manager.currentSessionId?.toString() ??
                      '')
                      : null,
                  userId: widget.userId ?? "1",
                  apiBasePreferred: _basePref,
                  aggregation: widget.aggregation ?? "p95",
                  phaseLabel: selectedPhase,
                ),
              ),

              const SizedBox(height: 24),

              // INSIGHTS
              const Text("Insights",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              _bullet("Good balance"),
              _bullet("Slight asymmetry detected"),
              _bullet("Pressure more on right foot"),

              const SizedBox(height: 16),

              // RECOMMENDATIONS
              const Text("Recommendations",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              _bullet("Balance drills (single-leg stance)"),
              _bullet("Strength training (calf raises)"),
              _bullet("Posture correction exercises"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bullet(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8),
    child: Row(children: [
      const Icon(Icons.check_circle, color: Colors.cyan, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Text(text)),
    ]),
  );
}

/// Fetches + paints:
///   • Live → requires active SessionManager().currentSessionId, polls /latest40?max=400
///   • Heel/Mid/Toe → uses /sessions/last_completed then /heatmap40 (RAW, norm=none)
class _PhaseHeatmapPanel extends StatefulWidget {
  final String? sessionId;        // active session for Live ('' or null → none)
  final String userId;            // for /sessions/last_completed
  final String apiBasePreferred;  // starting hint
  final String phaseLabel;        // Live | Heel Strike | Midstance | Toe Off
  final String aggregation;       // p95 | mean | peak

  const _PhaseHeatmapPanel({
    super.key,
    required this.sessionId,
    required this.userId,
    required this.apiBasePreferred,
    required this.phaseLabel,
    required this.aggregation,
  });

  @override
  State<_PhaseHeatmapPanel> createState() => _PhaseHeatmapPanelState();
}

class _PhaseHeatmapPanelState extends State<_PhaseHeatmapPanel> {
  @override
  Widget build(BuildContext context) {
    // 🔥 Replace placeholder with an image
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Image.asset(
          "assets/footprint.jpg",  // <-- replace with your image path
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
