import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class FallRiskPanel extends StatelessWidget {
  const FallRiskPanel({
    super.key,
    required this.riskScore,            // 0..100
    required this.doubleSupportPct,     // %
    required this.loadAsymmetryPct,     // % difference L vs R (absolute)
    required this.forefootHeelRatio,    // unitless ratio (F/H)
    required this.stepWidthVarPct,      // % variability
    required this.toeClearanceProxyPct, // % of stance dominated by forefoot
    this.lastUpdated,                   // optional timestamp string
  });

  final double riskScore;
  final double doubleSupportPct;
  final double loadAsymmetryPct;
  final double forefootHeelRatio;
  final double stepWidthVarPct;
  final double toeClearanceProxyPct;
  final String? lastUpdated;

  Color get _ringColor => _riskColor(riskScore);
  String get _riskLabel => _riskBand(riskScore);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Fall Risk",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (lastUpdated != null)
                  Text("Updated: $lastUpdated",
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),

            // Score ring + traffic light label
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Center(
                    child: CircularPercentIndicator(
                      radius: 48,
                      lineWidth: 10,
                      percent: (riskScore.clamp(0, 100)) / 100.0,
                      animation: true,
                      animateFromLastPercent: true,
                      circularStrokeCap: CircularStrokeCap.round,
                      backgroundColor: Colors.grey.shade200,
                      progressColor: _ringColor,
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("${riskScore.toStringAsFixed(0)}",
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: _ringColor,
                              )),
                          Text(_riskLabel,
                              style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Traffic-light chip
                Expanded(
                  flex: 6,
                  child: _TrafficLightLegend(score: riskScore),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),

            // Sub-metrics grid
            const SizedBox(height: 12),
            _SubMetricGrid(
              items: [
                _SubMetric(
                  label: "Double Support",
                  valueText: "${doubleSupportPct.toStringAsFixed(1)}%",
                  icon: Icons.timer_outlined,
                  color: _metricColorTargetLowerBetter(doubleSupportPct, goodMax: 24, warnMax: 32),
                  hint: "Lower is better; high = cautious gait",
                ),
                _SubMetric(
                  label: "Load Asymmetry",
                  valueText: "${loadAsymmetryPct.toStringAsFixed(1)}%",
                  icon: Icons.compare_arrows_outlined,
                  color: _metricColorTargetLowerBetter(loadAsymmetryPct, goodMax: 8, warnMax: 15),
                  hint: "L/R imbalance; lower is better",
                ),
                _SubMetric(
                  label: "Forefoot/Heel",
                  valueText: forefootHeelRatio.toStringAsFixed(2),
                  icon: Icons.stacked_line_chart,
                  color: _metricColorTargetRange(
                    forefootHeelRatio,
                    goodMin: 0.8, goodMax: 1.4,
                    warnMin: 0.6, warnMax: 1.7,
                  ),
                  hint: "Load sequencing; extremes ↑ risk",
                ),
                _SubMetric(
                  label: "Step-Width Var",
                  valueText: "${stepWidthVarPct.toStringAsFixed(1)}%",
                  icon: Icons.swap_horiz_outlined,
                  color: _metricColorTargetLowerBetter(stepWidthVarPct, goodMax: 12, warnMax: 18),
                  hint: "Consistency side-to-side; lower better",
                ),
                _SubMetric(
                  label: "Toe-Clearance",
                  valueText: "${toeClearanceProxyPct.toStringAsFixed(0)}%",
                  icon: Icons.directions_walk_outlined,
                  color: _metricColorTargetHigherBetter(toeClearanceProxyPct, goodMin: 45, warnMin: 35),
                  hint: "Forefoot-dominant late stance; higher better",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ----- helpers -----
  static Color _riskColor(double score) {
    if (score >= 70) return const Color(0xFFE53935); // high risk - red
    if (score >= 40) return const Color(0xFFFFB300); // medium - amber
    return const Color(0xFF43A047);                  // low - green
  }

  static String _riskBand(double score) {
    if (score >= 70) return "High";
    if (score >= 40) return "Moderate";
    return "Low";
  }

  static Color _metricColorTargetLowerBetter(double v, {required double goodMax, required double warnMax}) {
    if (v <= goodMax) return const Color(0xFF43A047);
    if (v <= warnMax) return const Color(0xFFFFB300);
    return const Color(0xFFE53935);
  }

  static Color _metricColorTargetHigherBetter(double v, {required double goodMin, required double warnMin}) {
    if (v >= goodMin) return const Color(0xFF43A047);
    if (v >= warnMin) return const Color(0xFFFFB300);
    return const Color(0xFFE53935);
  }

  static Color _metricColorTargetRange(double v, {
    required double goodMin, required double goodMax,
    required double warnMin, required double warnMax,
  }) {
    if (v >= goodMin && v <= goodMax) return const Color(0xFF43A047);
    if (v >= warnMin && v <= warnMax) return const Color(0xFFFFB300);
    return const Color(0xFFE53935);
  }
}

// ====================== sub-widgets ======================

class _TrafficLightLegend extends StatelessWidget {
  const _TrafficLightLegend({required this.score});
  final double score;

  @override
  Widget build(BuildContext context) {
    Color cLow = const Color(0xFF43A047);
    Color cMed = const Color(0xFFFFB300);
    Color cHigh = const Color(0xFFE53935);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _trafficRow("Low", cLow, active: score < 40),
        const SizedBox(height: 6),
        _trafficRow("Moderate", cMed, active: score >= 40 && score < 70),
        const SizedBox(height: 6),
        _trafficRow("High", cHigh, active: score >= 70),
      ],
    );
  }

  Widget _trafficRow(String label, Color color, {required bool active}) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: active ? color : color.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? Colors.black : Colors.black54,
        )),
      ],
    );
  }
}

class _SubMetricGrid extends StatelessWidget {
  const _SubMetricGrid({required this.items});
  final List<_SubMetric> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((m) {
        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 150, maxWidth: 240),
          child: _SubMetricTile(metric: m),
        );
      }).toList(),
    );
  }
}

class _SubMetric {
  final String label;
  final String valueText;
  final IconData icon;
  final Color color;
  final String? hint;
  const _SubMetric({
    required this.label,
    required this.valueText,
    required this.icon,
    required this.color,
    this.hint,
  });
}

class _SubMetricTile extends StatelessWidget {
  const _SubMetricTile({required this.metric});
  final _SubMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: metric.color.withOpacity(0.15),
            child: Icon(metric.icon, size: 20, color: metric.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(metric.label,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (metric.hint != null)
                  Text(metric.hint!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(metric.valueText,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: metric.color,
              )),
        ],
      ),
    );
  }
}
