// lib/screens/analytics/waste_analytics_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api/analytics_api.dart';
import '../../models/analytics/volume_analytics_model.dart';

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
                      const SizedBox(height: 20),
                      _buildTotalCard(),
                      const SizedBox(height: 20),

                      // 🧩 NEW: Reward Eligibility Card
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

                      const SizedBox(height: 24),
                      _buildInsightsCard(),
                    ],
                  ),
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
  // 🥧 PIE CHART — BY TYPE
  // =====================================================
  Widget _buildPieChartCard() {
    if (_byType.isEmpty) {
      return const Center(child: Text("No waste type data available."));
    }

    final total = _byType.values.fold(0.0, (a, b) => a + b);
    final sections = _byType.entries.map((entry) {
      final percent = (entry.value / total) * 100;
      return PieChartSectionData(
        color: Colors.primaries[
            _byType.keys.toList().indexOf(entry.key) % Colors.primaries.length],
        value: entry.value,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 📊 BAR CHART — BY MONTH
  // =====================================================
  Widget _buildBarChartCard() {
    if (_byMonth.isEmpty) {
      return const Center(child: Text("No monthly data available."));
    }

    final entries = _byMonth.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _chartBoxDecoration(),
      child: Column(
        children: [
          const Text(
            "Monthly Waste Volume (kg)",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        return Transform.rotate(
                          angle: -0.5,
                          child: Text(
                            entries[index].key.split(" ")[0],
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
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
