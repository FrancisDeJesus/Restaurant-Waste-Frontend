// lib/screens/analytics/waste_analytics_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../../services/api/analytics_api.dart';
import 'waste_recommendation_helper.dart';

class WasteAnalyticsDashboardScreen extends StatefulWidget {
  const WasteAnalyticsDashboardScreen({super.key});

  @override
  State<WasteAnalyticsDashboardScreen> createState() =>
      _WasteAnalyticsDashboardScreenState();
}

class _WasteAnalyticsDashboardScreenState
    extends State<WasteAnalyticsDashboardScreen> {
  bool _loading = true;
  String? _error;
  double _totalVolume = 0.0;
  Map<String, double> _byType = {};
  Map<String, double> _byMonth = {};
  String _selectedRange = "This Month"; // 🆕 Dropdown filter state

  static const green = Color(0xFF015704);
  static const double wasteLimit = 500.0; // ⚠️ monthly waste limit threshold

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Later, you can use _selectedRange to call your API differently:
      // final data = await AnalyticsApi.getVolumeAnalytics(range: _selectedRange);
      final data = await AnalyticsApi.getVolumeAnalytics();

      setState(() {
        _totalVolume = data.totalVolume;
        _byType = data.byType;
        _byMonth = data.byMonth;
      });
    } catch (e) {
      setState(() => _error = "Error loading analytics: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final recommendations = WasteRecommendationHelper.buildRecommendations(
      _byType,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Waste Analytics Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: green))
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 5),
                  _buildFilterDropdown(), // 🆕 Filter dropdown added here
                  const SizedBox(height: 5),
                  _buildInsightsCard(),
                  const SizedBox(height: 20),
                  _buildTotalCard(),
                  const SizedBox(height: 20),
                  _buildRewardEligibilityCard(),
                  const SizedBox(height: 24),
                  if (_byType.isNotEmpty && _byMonth.isNotEmpty)
                    isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildPieChartCard()),
                              const SizedBox(width: 20),
                              Expanded(child: _buildBarChartCard()),
                            ],
                          )
                        : Column(
                            children: [
                              _buildPieChartCard(),
                              const SizedBox(height: 20),
                              _buildBarChartCard(),
                            ],
                          )
                  else
                    const Center(
                      child: Text("No analytics data available yet."),
                    ),
                  const SizedBox(height: 20),
                  _buildRecommendationsSection(recommendations),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // =====================================================
  // ♻️ WASTE REDUCTION RECOMMENDATIONS
  // =====================================================
  Widget _buildRecommendationsSection(
    List<WasteRecommendation> recommendations,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _chartBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with icon
          Row(
            children: const [
              Icon(Icons.lightbulb_outline_rounded, color: green, size: 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  "Waste Reduction Recommendations",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // One card per recommendation
          ...recommendations.map(
            (rec) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: green.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(rec.icon, size: 20, color: green),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec.title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: green,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          rec.message,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 🧭 DASHBOARD HEADER
  // =====================================================
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "♻️ Waste Volume Overview",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: green,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "Track and visualize your waste collection trends",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  // =====================================================
  // 🧮 FILTER DROPDOWN (🆕)
  // =====================================================
  Widget _buildFilterDropdown() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: green.withOpacity(0.3)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedRange,
            items: const [
              DropdownMenuItem(value: "This Month", child: Text("This Month")),
              DropdownMenuItem(
                value: "Last 3 Months",
                child: Text("Last 3 Months"),
              ),
              DropdownMenuItem(value: "All Time", child: Text("All Time")),
            ],
            onChanged: (value) {
              setState(() => _selectedRange = value!);
              _loadAnalytics(); // refresh data when range changes
            },
            icon: const Icon(Icons.arrow_drop_down, color: green),
            dropdownColor: Colors.white,
            style: const TextStyle(color: green, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // 🧠 INSIGHTS CARD
  // =====================================================
  Widget _buildInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _chartBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "📈 Insights & Trends",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            "• Monitor which waste type your restaurant generates most.\n"
            "• Compare monthly waste trends to identify improvement.\n"
            "• Reduce biodegradable waste to increase reward points and efficiency.",
            style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 💧 TOTAL VOLUME CARD
  // =====================================================
  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [green, Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Total Waste Collected",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${_totalVolume.toStringAsFixed(2)} kg",
            style: const TextStyle(
              fontSize: 34,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 🚫 REWARD ELIGIBILITY CARD
  // =====================================================
  Widget _buildRewardEligibilityCard() {
    final exceeded = _totalVolume > wasteLimit;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: exceeded ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: exceeded ? Colors.redAccent : green,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            exceeded ? Icons.block : Icons.emoji_events_outlined,
            color: exceeded ? Colors.redAccent : green,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              exceeded
                  ? "⚠️ You have exceeded ${wasteLimit.toStringAsFixed(0)} kg this month.\nReward redemption is locked until next month."
                  : "🎉 You're within the waste limit.\nYou are eligible to redeem rewards this month!",
              style: TextStyle(
                color: exceeded ? Colors.red[800] : green,
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 🥧 PIE CHART — BY TYPE (Tappable)
  // =====================================================
  Widget _buildPieChartCard() {
    if (_byType.isEmpty) {
      return const Center(child: Text("No waste type data available."));
    }

    final safeByType = _sanitizeEntries(_byType.entries.toList());
    if (safeByType.isEmpty) {
      return const Center(child: Text("No valid waste type data available."));
    }

    final total = safeByType.fold(0.0, (a, e) => a + e.value);
    final safeTotal = total > 0 ? total : 1.0;

    final sections = safeByType.asMap().entries.map((indexed) {
      final index = indexed.key;
      final entry = indexed.value;
      final percent = (entry.value / safeTotal) * 100;

      return PieChartSectionData(
        color: Colors.primaries[index % Colors.primaries.length],
        value: entry.value < 0 ? 0 : entry.value,
        radius: 70,
        title: "${entry.key}\n${percent.toStringAsFixed(1)}%",
        titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _chartBoxDecoration(),
      child: Column(
        children: [
          const Text(
            "Waste Breakdown by Type",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                borderData: FlBorderData(show: false),
                pieTouchData: PieTouchData(enabled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 📊 BAR CHART — BY DAY / WEEK / MONTH (Enhanced)
  // =====================================================
  String _barChartView = "Monthly"; // 🆕 Default chart view

  Widget _buildBarChartCard() {
    if (_byMonth.isEmpty) {
      return const Center(child: Text("No waste data available."));
    }

    // 🧩 Simulated transformations (for frontend filtering)
    // In real use, fetch _byDay / _byWeek data from backend
    final entries = _sanitizeEntries(_filterChartData());
    if (entries.isEmpty) {
      return const Center(child: Text("No valid waste data available."));
    }

    final maxY = _computeNiceMaxY(entries);
    final yInterval = _computeNiceInterval(maxY);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _chartBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with dropdown filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$_barChartView Waste Volume (kg)",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _barChartView,
                  items: const [
                    DropdownMenuItem(value: "Daily", child: Text("Daily")),
                    DropdownMenuItem(value: "Weekly", child: Text("Weekly")),
                    DropdownMenuItem(value: "Monthly", child: Text("Monthly")),
                  ],
                  onChanged: (value) {
                    setState(() => _barChartView = value!);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                minY: 0,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: false),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= entries.length) {
                          return const SizedBox.shrink();
                        }

                        final label = entries[index].key;
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8,
                          child: Transform.rotate(
                            angle: -0.45,
                            child: SizedBox(
                              width: 52,
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 6,
                        child: Text(
                          _formatCompactKg(value, interval: yInterval),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barGroups: List.generate(entries.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: entries[i].value,
                        width: 18,
                        color: Colors.teal.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 🧩 Helper — Filter data for Day / Week / Month
  // =====================================================
  List<MapEntry<String, double>> _filterChartData() {
    final rawEntries = _byMonth.entries.toList();

    if (_barChartView == "Monthly") {
      return rawEntries;
    }

    // Simulated finer granularity (frontend-only demo)
    // You can later replace this logic with real API filters.
    if (_barChartView == "Weekly") {
      // Combine data into weekly bins
      final weekMap = <String, double>{};
      for (int i = 0; i < rawEntries.length; i++) {
        final weekLabel = "Week ${i + 1}";
        weekMap[weekLabel] = (rawEntries[i].value / 4);
      }
      return weekMap.entries.toList();
    }

    if (_barChartView == "Daily") {
      // Generate 7-day view for preview purposes
      final dayMap = <String, double>{};
      for (int i = 1; i <= 7; i++) {
        dayMap["Day $i"] = (rawEntries.last.value / 7) + (i * 2);
      }
      return dayMap.entries.toList();
    }

    return rawEntries;
  }

  double _computeNiceMaxY(List<MapEntry<String, double>> entries) {
    if (entries.isEmpty) return 10;

    final maxValue = entries
        .map((e) => e.value)
        .fold<double>(0, (prev, v) => v > prev ? v : prev);

    if (maxValue <= 0) return 1;

    // Keep some headroom so bars/labels remain readable for tiny values.
    final targetMax = maxValue * 1.2;

    final exponent = (math.log(targetMax) / math.ln10).floor();
    final magnitude = math.pow(10, exponent).toDouble();
    final normalized = targetMax / magnitude;

    double niceNormalized;
    if (normalized <= 1) {
      niceNormalized = 1;
    } else if (normalized <= 2) {
      niceNormalized = 2;
    } else if (normalized <= 5) {
      niceNormalized = 5;
    } else {
      niceNormalized = 10;
    }

    return niceNormalized * magnitude;
  }

  double _computeNiceInterval(double maxY) {
    if (maxY <= 0) return 1;

    final roughStep = maxY / 5;
    final exponent = (math.log(roughStep) / math.ln10).floor();
    final magnitude = math.pow(10, exponent).toDouble();
    final normalized = roughStep / magnitude;

    double niceNormalized;
    if (normalized <= 1) {
      niceNormalized = 1;
    } else if (normalized <= 2) {
      niceNormalized = 2;
    } else if (normalized <= 5) {
      niceNormalized = 5;
    } else {
      niceNormalized = 10;
    }

    return niceNormalized * magnitude;
  }

  String _formatCompactKg(double value, {double? interval}) {
    if (value >= 1000) {
      final compact = value / 1000;
      if (compact % 1 == 0) {
        return '${compact.toStringAsFixed(0)}k';
      }
      return '${compact.toStringAsFixed(1)}k';
    }

    final activeInterval = interval ?? 1;
    if (activeInterval < 1) {
      final decimals = _decimalsForStep(activeInterval);
      return _trimTrailingZeros(value.toStringAsFixed(decimals));
    }

    return value.toStringAsFixed(0);
  }

  int _decimalsForStep(double step) {
    if (step >= 1) return 0;
    final raw = (-math.log(step) / math.ln10).ceil();
    return raw.clamp(1, 4);
  }

  List<MapEntry<String, double>> _sanitizeEntries(
    List<MapEntry<String, double>> entries,
  ) {
    return entries
        .where((e) => e.value.isFinite)
        .map((e) => MapEntry(e.key, e.value < 0 ? 0.0 : e.value))
        .where((e) => e.value > 0)
        .toList();
  }

  String _trimTrailingZeros(String input) {
    if (!input.contains('.')) return input;
    return input
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  // =====================================================
  // ✨ Shared Chart Style
  // =====================================================
  BoxDecoration _chartBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6,
          spreadRadius: 1,
        ),
      ],
    );
  }
}
