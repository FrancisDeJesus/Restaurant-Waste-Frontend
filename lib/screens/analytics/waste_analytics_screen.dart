import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api/analytics_api.dart'; // ✅ Use this
import '../../models/analytics/volume_analytics_model.dart'; // ✅ if you have it

class WasteAnalyticsScreen extends StatefulWidget {
  const WasteAnalyticsScreen({super.key});

  @override
  State<WasteAnalyticsScreen> createState() => _WasteAnalyticsScreenState();
}

class _WasteAnalyticsScreenState extends State<WasteAnalyticsScreen> {
  bool _loading = true;
  String? _error;
  double _totalVolume = 0.0;
  Map<String, double> _byType = {};
  Map<String, double> _byMonth = {};

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
      // ✅ Fetch using your AnalyticsApi class
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
    return Scaffold(
      appBar: AppBar(title: const Text("Waste Volume Analytics")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 24),
                      _buildPieChartCard(),
                      const SizedBox(height: 24),
                      _buildBarChartCard(),
                    ],
                  ),
                ),
    );
  }

  // ==========================
  // 🔹 TOTAL SUMMARY CARD
  // ==========================
  Widget _buildSummaryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.green.shade50,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Total Waste Collected",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "${_totalVolume.toStringAsFixed(2)} kg",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================
  // 🥧 PIE CHART (BY TYPE)
  // ==========================
  Widget _buildPieChartCard() {
    if (_byType.isEmpty) {
      return const Center(child: Text("No waste type data available."));
    }

    final total = _byType.values.fold(0.0, (a, b) => a + b);
    final List<PieChartSectionData> sections = _byType.entries.map((entry) {
      final percent = (entry.value / total) * 100;
      return PieChartSectionData(
        title: "${entry.key}\n${percent.toStringAsFixed(1)}%",
        color: Colors.primaries[
            _byType.keys.toList().indexOf(entry.key) % Colors.primaries.length],
        value: entry.value,
        radius: 70,
        titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
      );
    }).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Waste Type Breakdown",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: PieChart(PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
              )),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================
  // 📊 BAR CHART (BY MONTH)
  // ==========================
  Widget _buildBarChartCard() {
    if (_byMonth.isEmpty) {
      return const Center(child: Text("No monthly data available."));
    }

    final entries = _byMonth.entries.toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                          final monthIndex = value.toInt();
                          if (monthIndex < 0 || monthIndex >= entries.length) {
                            return const SizedBox.shrink();
                          }
                          return Transform.rotate(
                            angle: -0.5,
                            child: Text(
                              entries[monthIndex].key.split(" ")[0],
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
                          color: Colors.teal,
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
      ),
    );
  }
}
