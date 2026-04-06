import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_handler.dart';
import '../../../data/repositories/analytics_repository.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsRepository _repo = AnalyticsRepository();

  bool _loading = true;
  String? _error;

  // Data holders
  Map<String, dynamic> _overview = {};
  Map<String, dynamic> _formStats = {};
  Map<String, dynamic> _incidentStats = {};
  Map<String, dynamic> _residentStats = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.getOverview(),
        _repo.getFormStats(),
        _repo.getIncidentStats(),
        _repo.getResidentStats(),
      ]);
      if (!mounted) return;
      setState(() {
        _overview = results[0];
        _formStats = results[1];
        _incidentStats = results[2];
        _residentStats = results[3];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorHandler.getUserFriendlyMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: _loadAll,
                    child: CustomScrollView(
                      slivers: [
                        // Header
                        SliverToBoxAdapter(child: _buildHeader()),
                        // Overview stat cards
                        SliverToBoxAdapter(child: _buildOverviewCards()),
                        // Ward Occupancy
                        SliverToBoxAdapter(child: _buildSection('Ward Occupancy', _buildWardOccupancy())),
                        // Demographics
                        SliverToBoxAdapter(child: _buildSection('Demographics', _buildDemographics())),
                        // Form Statistics
                        SliverToBoxAdapter(child: _buildSection('Form Statistics by Unit', _buildFormsByUnit())),
                        // Turnaround Time
                        SliverToBoxAdapter(child: _buildSection('Avg. Turnaround Time (hours)', _buildTurnaroundChart())),
                        // Monthly Trends
                        SliverToBoxAdapter(child: _buildSection('Monthly Form Submissions', _buildMonthlyTrend())),
                        // Admission / Discharge Trends
                        SliverToBoxAdapter(child: _buildSection('Admission & Discharge Trends', _buildAdmissionTrend())),
                        // Incidents
                        SliverToBoxAdapter(child: _buildSection('Incident Reports', _buildIncidents())),
                        // Case Categories
                        SliverToBoxAdapter(child: _buildSection('Case Categories', _buildCaseCategories())),
                        const SliverToBoxAdapter(child: SizedBox(height: 80)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Unable to load analytics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure the backend server is running.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          if (MediaQuery.of(context).size.width < 1100) ...[
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics & Reports',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Facility performance overview and insights',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh data',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OVERVIEW CARDS
  // ---------------------------------------------------------------------------
  Widget _buildOverviewCards() {
    final res = (_overview['residents'] as Map<String, dynamic>?) ?? {};
    final admitted = res['admitted'] ?? 0;
    final preAdmission = res['pre_admission'] ?? 0;
    final discharged = res['discharged'] ?? 0;
    final avgLos = res['avg_length_of_stay_days'] ?? 0;

    final cards = <_MiniStat>[
      _MiniStat(icon: Icons.people, color: AppColors.primary, label: 'Admitted', value: '$admitted'),
      _MiniStat(icon: Icons.person_add_outlined, color: AppColors.info, label: 'Pre-Admission', value: '$preAdmission'),
      _MiniStat(icon: Icons.exit_to_app, color: AppColors.warning, label: 'Discharged', value: '$discharged'),
      _MiniStat(icon: Icons.schedule, color: AppColors.unitPsych, label: 'Avg. Stay (days)', value: '$avgLos'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossCount = constraints.maxWidth > 900 ? 4 : 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards.map((c) {
              final w = (constraints.maxWidth - (crossCount - 1) * 12) / crossCount;
              return SizedBox(width: w, child: c);
            }).toList(),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WARD OCCUPANCY BAR CHART
  // ---------------------------------------------------------------------------
  Widget _buildWardOccupancy() {
    final wards = (_overview['ward_occupancy'] as List<dynamic>?) ?? [];
    if (wards.isEmpty) return _emptyPlaceholder('No ward data available');

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: wards.fold<double>(
              0, (prev, w) => (w['capacity'] as num? ?? 0).toDouble() > prev ? (w['capacity'] as num).toDouble() : prev) * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final ward = wards[groupIndex];
                return BarTooltipItem(
                  '${ward['name']}\n${rod.toY.toInt()} / ${ward['capacity']}',
                  const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= wards.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      (wards[idx]['name'] as String).replaceAll('Ward ', ''),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          barGroups: List.generate(wards.length, (i) {
            final current = (wards[i]['current'] as num? ?? 0).toDouble();
            final capacity = (wards[i]['capacity'] as num? ?? 0).toDouble();
            final pct = capacity > 0 ? current / capacity : 0;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: current,
                  width: 22,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: LinearGradient(
                    colors: pct > 0.9
                        ? [AppColors.error, AppColors.errorLight]
                        : pct > 0.7
                            ? [AppColors.warning, AppColors.warningLight]
                            : [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: capacity,
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DEMOGRAPHICS (Gender + Age PieCharts)
  // ---------------------------------------------------------------------------
  Widget _buildDemographics() {
    final gender = (_overview['gender_distribution'] as Map<String, dynamic>?) ?? {};
    final age = (_overview['age_distribution'] as Map<String, dynamic>?) ?? {};

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _pieSection('Gender', gender, [AppColors.primary, AppColors.accent, AppColors.unitPsych])),
                  const SizedBox(width: 16),
                  Expanded(child: _pieSection('Age Groups', age, [AppColors.info, AppColors.success, AppColors.warning, AppColors.error])),
                ],
              )
            : Column(
                children: [
                  _pieSection('Gender', gender, [AppColors.primary, AppColors.accent, AppColors.unitPsych]),
                  const SizedBox(height: 16),
                  _pieSection('Age Groups', age, [AppColors.info, AppColors.success, AppColors.warning, AppColors.error]),
                ],
              );
      },
    );
  }

  Widget _pieSection(String label, Map<String, dynamic> data, List<Color> colors) {
    final entries = data.entries.where((e) => (e.value as num) > 0).toList();
    if (entries.isEmpty) return _emptyPlaceholder('No $label data');
    final total = entries.fold<double>(0, (p, e) => p + (e.value as num).toDouble());

    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: List.generate(entries.length, (i) {
                final e = entries[i];
                final value = (e.value as num).toDouble();
                final pct = (value / total * 100).toStringAsFixed(0);
                return PieChartSectionData(
                  value: value,
                  color: colors[i % colors.length],
                  radius: 40,
                  title: '$pct%',
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: List.generate(entries.length, (i) {
            final e = entries[i];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 4),
                Text('${_capitalize(e.key)} (${e.value})', style: Theme.of(context).textTheme.bodySmall),
              ],
            );
          }),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FORMS BY UNIT (horizontal bar)
  // ---------------------------------------------------------------------------
  Widget _buildFormsByUnit() {
    final byUnit = (_formStats['by_unit'] as Map<String, dynamic>?) ?? {};
    if (byUnit.isEmpty) return _emptyPlaceholder('No form data');

    final units = byUnit.entries.toList()..sort((a, b) => (b.value as num).compareTo(a.value as num));
    final maxVal = units.first.value as num;
    final unitColors = {
      'social': AppColors.unitSocial,
      'medical': AppColors.unitMedical,
      'psych': AppColors.unitPsych,
      'homelife': AppColors.unitHomelife,
      'nutrition': AppColors.unitNutrition,
    };

    return Column(
      children: units.map((e) {
        final pct = maxVal > 0 ? (e.value as num) / maxVal : 0.0;
        final color = unitColors[e.key] ?? AppColors.primary;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(_capitalize(e.key), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: pct.toDouble(),
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '${e.value}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // TURNAROUND TIME BAR CHART
  // ---------------------------------------------------------------------------
  Widget _buildTurnaroundChart() {
    final tat = (_formStats['avg_turnaround_hours'] as Map<String, dynamic>?) ?? {};
    if (tat.isEmpty) return _emptyPlaceholder('Not enough approved forms to calculate');

    final entries = tat.entries.toList();
    final maxVal = entries.fold<double>(0, (p, e) => (e.value as num).toDouble() > p ? (e.value as num).toDouble() : p);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.3,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gIdx, rod, rIdx) {
                return BarTooltipItem(
                  '${_capitalize(entries[gIdx].key)}\n${rod.toY.toStringAsFixed(1)}h',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_capitalize(entries[idx].key), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          barGroups: List.generate(entries.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (entries[i].value as num).toDouble(),
                  width: 28,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: LinearGradient(
                    colors: [AppColors.accent, AppColors.accentLight],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MONTHLY SUBMISSION TREND (Line Chart)
  // ---------------------------------------------------------------------------
  Widget _buildMonthlyTrend() {
    final monthly = (_formStats['monthly_submissions'] as Map<String, dynamic>?) ?? {};
    if (monthly.isEmpty) return _emptyPlaceholder('No monthly data');

    return _lineChartFromMap(monthly, AppColors.primary);
  }

  // ---------------------------------------------------------------------------
  // ADMISSION & DISCHARGE TREND
  // ---------------------------------------------------------------------------
  Widget _buildAdmissionTrend() {
    final admissions = (_residentStats['monthly_admissions'] as Map<String, dynamic>?) ?? {};
    final discharges = (_residentStats['monthly_discharges'] as Map<String, dynamic>?) ?? {};
    if (admissions.isEmpty) return _emptyPlaceholder('No admission data');

    final keys = admissions.keys.toList();
    final maxY = [...admissions.values, ...discharges.values].fold<double>(
        0, (p, v) { final n = (v as num).toDouble(); return n > p ? n : p; });

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: (maxY * 1.3).clamp(5, double.infinity),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    final label = s.barIndex == 0 ? 'Admitted' : 'Discharged';
                    return LineTooltipItem('$label: ${s.y.toInt()}', const TextStyle(color: Colors.white, fontSize: 12));
                  }).toList(),
                ),
              ),
              titlesData: _monthlyTitles(keys),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              lineBarsData: [
                _lineBarData(keys.map((k) => (admissions[k] as num? ?? 0).toDouble()).toList(), AppColors.success),
                _lineBarData(keys.map((k) => (discharges[k] as num? ?? 0).toDouble()).toList(), AppColors.error),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot(AppColors.success, 'Admissions'),
            const SizedBox(width: 16),
            _legendDot(AppColors.error, 'Discharges'),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // INCIDENTS
  // ---------------------------------------------------------------------------
  Widget _buildIncidents() {
    final total = _incidentStats['total'] ?? 0;
    final current = _incidentStats['current_month'] ?? 0;
    final prev = _incidentStats['previous_month'] ?? 0;
    final delta = _incidentStats['delta'] ?? 0;
    final monthly = (_incidentStats['monthly_trend'] as Map<String, dynamic>?) ?? {};
    final byWard = (_incidentStats['by_ward'] as Map<String, dynamic>?) ?? {};
    final byType = (_incidentStats['by_type'] as Map<String, dynamic>?) ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary row
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _miniChip('Total', '$total', AppColors.textSecondary),
            _miniChip('This Month', '$current', delta > 0 ? AppColors.error : AppColors.success),
            _miniChip('Last Month', '$prev', AppColors.textSecondary),
            _miniChip(
              delta >= 0 ? '▲ $delta' : '▼ ${delta.abs()}',
              '',
              delta > 0 ? AppColors.error : AppColors.success,
            ),
          ],
        ),
        if (monthly.isNotEmpty) ...[
          const SizedBox(height: 16),
          _lineChartFromMap(monthly, AppColors.error),
        ],
        if (byType.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('By Type', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...byType.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key, style: Theme.of(context).textTheme.bodySmall)),
                    Text('${e.value}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              )),
        ],
        if (byWard.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('By Ward', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...byWard.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key, style: Theme.of(context).textTheme.bodySmall)),
                    Text('${e.value}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CASE CATEGORIES
  // ---------------------------------------------------------------------------
  Widget _buildCaseCategories() {
    final cats = (_residentStats['case_categories'] as Map<String, dynamic>?) ?? {};
    if (cats.isEmpty) return _emptyPlaceholder('No case category data');

    final colorList = [AppColors.unitSocial, AppColors.unitMedical, AppColors.unitPsych, AppColors.unitHomelife, AppColors.accent, AppColors.info];
    return _pieSection('', cats, colorList);
  }

  // ===========================================================================
  // SHARED HELPERS
  // ===========================================================================

  Widget _buildSection(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _lineChartFromMap(Map<String, dynamic> data, Color color) {
    final keys = data.keys.toList();
    final values = keys.map((k) => (data[k] as num? ?? 0).toDouble()).toList();
    final maxY = values.fold<double>(0, (p, v) => v > p ? v : p);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: (maxY * 1.3).clamp(5, double.infinity),
          titlesData: _monthlyTitles(keys),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          lineBarsData: [_lineBarData(values, color)],
        ),
      ),
    );
  }

  LineChartBarData _lineBarData(List<double> values, Color color) {
    return LineChartBarData(
      spots: List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i])),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: values.length < 15),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  FlTitlesData _monthlyTitles(List<String> keys) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: (value, _) {
            final idx = value.toInt();
            if (idx < 0 || idx >= keys.length) return const SizedBox.shrink();
            // Show every other month to prevent overlap
            if (keys.length > 6 && idx % 2 != 0) return const SizedBox.shrink();
            final parts = keys[idx].split('-');
            final month = _monthAbbr(int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(month, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _miniChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        value.isEmpty ? label : '$label: $value',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _emptyPlaceholder(String text) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String _monthAbbr(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return month >= 1 && month <= 12 ? months[month] : '';
  }
}

// =============================================================================
// MINI STAT CARD (reusable)
// =============================================================================

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _MiniStat({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
