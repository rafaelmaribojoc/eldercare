import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/moca_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../constants/moca_colors.dart';
import '../models/moca_assessment_model.dart';

class MocaAnalyticsScreen extends StatefulWidget {
  const MocaAnalyticsScreen({super.key});

  @override
  State<MocaAnalyticsScreen> createState() => _MocaAnalyticsScreenState();
}

class _MocaAnalyticsScreenState extends State<MocaAnalyticsScreen> {
  final MocaRepository _repo = MocaRepository();

  int _days = 30;
  bool _loading = true;
  String? _error;

  List<MocaAssessmentModel> _assessments = const [];
  Map<String, String> _clinicianNames = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final from = DateTime.now().subtract(Duration(days: _days));
      final assessments = await _repo.getAssessmentsInRange(from: from);
      final clinicianNames = await _repo.getClinicianNames(unit: 'psych');

      if (!mounted) return;
      setState(() {
        _assessments = assessments;
        _clinicianNames = clinicianNames;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isPsych =
        authState is AuthAuthenticated && authState.user.unit == 'psych';

    if (!isPsych) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('MoCA Analytics'),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
        ),
        body: const Center(
          child: Text('This page is available to Psychological Services only.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MoCA Analytics'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        actions: [
          _RangeChip(
            label: '7D',
            selected: _days == 7,
            onTap: () => _setDays(7),
          ),
          const SizedBox(width: 8),
          _RangeChip(
            label: '30D',
            selected: _days == 30,
            onTap: () => _setDays(30),
          ),
          const SizedBox(width: 8),
          _RangeChip(
            label: '90D',
            selected: _days == 90,
            onTap: () => _setDays(90),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCards(),
                      const SizedBox(height: 16),
                      _buildTrendCard(),
                      const SizedBox(height: 16),
                      _buildRiskDistributionCard(),
                      const SizedBox(height: 16),
                      _buildClinicianWorkloadCard(),
                      const SizedBox(height: 16),
                      _buildRecentLowScores(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  void _setDays(int days) {
    if (_days == days) return;
    setState(() => _days = days);
    _load();
  }

  Widget _buildSummaryCards() {
    final count = _assessments.length;
    final avg = count == 0
        ? 0.0
        : _assessments.map((a) => a.adjustedScore).reduce((a, b) => a + b) /
            count;
    final below = _assessments.where((a) => a.adjustedScore < 26).length;
    final belowPct = count == 0 ? 0 : ((below / count) * 100).round();

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Assessments',
            value: '$count',
            subtitle: 'Last $_days days',
            color: MocaColors.primary,
            icon: LucideIcons.clipboardCheck,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Avg Score',
            value: avg.toStringAsFixed(1),
            subtitle: 'Adjusted (0–30)',
            color: MocaColors.success,
            icon: LucideIcons.chartNoAxesColumnIncreasing,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Below 26',
            value: '$belowPct%',
            subtitle: '$below cases',
            color: MocaColors.warning,
            icon: LucideIcons.triangleAlert,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendCard() {
    final grouped = _groupTrend(_assessments, days: _days);
    final keys = grouped.keys.toList()..sort();
    final points = <FlSpot>[];

    for (var i = 0; i < keys.length; i++) {
      final list = grouped[keys[i]]!;
      final avg = list.isEmpty
          ? 0.0
          : list.map((a) => a.adjustedScore).reduce((a, b) => a + b) /
              list.length;
      points.add(FlSpot(i.toDouble(), avg));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Average adjusted score trend',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 30,
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: 10,
                        getTitlesWidget: (value, meta) =>
                            Text(value.toInt().toString()),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (keys.length <= 4) ? 1 : 2,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= keys.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              keys[idx],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points,
                      isCurved: true,
                      color: MocaColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: MocaColors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskDistributionCard() {
    final counts = <String, int>{};
    for (final a in _assessments) {
      final level = a.riskLevel ?? 'Unknown';
      counts[level] = (counts[level] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Risk level distribution',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (_assessments.isEmpty)
              const Text('No assessments in this range.')
            else
              ...entries.map((e) {
                final pct =
                    _assessments.isEmpty ? 0.0 : e.value / _assessments.length;
                final color = _riskColor(e.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e.key,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text('${e.value}'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 10,
                          backgroundColor: color.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicianWorkloadCard() {
    final counts = <String, int>{};
    for (final a in _assessments) {
      final id = a.clinicianId ?? 'unknown';
      counts[id] = (counts[id] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clinician workload',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Text('No assessments in this range.')
            else
              ...entries.take(6).map((e) {
                final name = _clinicianNames[e.key] ?? e.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(name, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: MocaColors.primaryLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${e.value}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLowScores() {
    final lows = _assessments.where((a) => a.adjustedScore < 26).toList()
      ..sort((a, b) {
        final ad = a.completedAt ?? a.createdAt;
        final bd = b.completedAt ?? b.createdAt;
        return bd.compareTo(ad);
      });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent low scores (<26)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (lows.isEmpty)
              const Text('No low scores in this range.')
            else
              ...lows.take(8).map((a) {
                final when = a.completedAt ?? a.createdAt;
                final clinician = (a.clinicianId != null)
                    ? (_clinicianNames[a.clinicianId!] ?? a.clinicianId!)
                    : 'Unknown';
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(a.residentName ?? 'Unknown Resident'),
                  subtitle: Text(
                    '${when.toLocal().toString().split(".").first} • $clinician',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: MocaColors.warningLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${a.adjustedScore}/30',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Map<String, List<MocaAssessmentModel>> _groupTrend(
    List<MocaAssessmentModel> list, {
    required int days,
  }) {
    final map = <String, List<MocaAssessmentModel>>{};
    for (final a in list) {
      final dt = (a.completedAt ?? a.createdAt).toLocal();
      final key = days <= 7 ? '${dt.month}/${dt.day}' : 'W${_weekKey(dt)}';
      (map[key] ??= <MocaAssessmentModel>[]).add(a);
    }
    return map;
  }

  int _weekKey(DateTime dt) {
    final first = DateTime(dt.year, 1, 1);
    final diff = dt.difference(first).inDays;
    return (diff / 7).floor() + 1;
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'Low Risk':
        return MocaColors.success;
      case 'Low-Moderate Risk':
        return const Color(0xFF8BC34A);
      case 'Moderate Risk':
        return MocaColors.warning;
      case 'High Risk':
        return const Color(0xFFFF5722);
      case 'Very High Risk':
        return MocaColors.error;
      default:
        return MocaColors.textSecondary;
    }
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? MocaColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: MocaColors.primary.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : MocaColors.primary,
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: MocaColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.circleAlert,
                size: 56, color: MocaColors.error),
            const SizedBox(height: 12),
            const Text('Failed to load analytics'),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: MocaColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style:
                  ElevatedButton.styleFrom(backgroundColor: MocaColors.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
