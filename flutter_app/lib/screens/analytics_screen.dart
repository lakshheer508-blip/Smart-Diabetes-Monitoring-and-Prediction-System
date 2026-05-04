import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  List<dynamic> _logs = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final logs = await ApiService.getHealthLogs();
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  Widget _buildCombinedChart() {
    if (_logs.isEmpty) return const SizedBox();

    List<FlSpot> glucoseSpots = [];
    List<FlSpot> foodSpots = [];
    List<FlSpot> exerciseSpots = [];

    for (int i = 0; i < _logs.length; i++) {
        // Safe mapping
      try {
        final g = double.tryParse(_logs[i]['glucose_level'].toString()) ?? 0;
        final f = double.tryParse(_logs[i]['food'].toString()) ?? 0;
        final e = double.tryParse(_logs[i]['exercise'].toString()) ?? 0;

        glucoseSpots.add(FlSpot(i.toDouble(), g));
        foodSpots.add(FlSpot(i.toDouble(), f));
        exerciseSpots.add(FlSpot(i.toDouble(), e));
      } catch (e) {
          // Skip invalid data
      }
    }

    return _buildChartContainer(
      "Combined Overlap Analysis",
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          _createLine(glucoseSpots, Colors.blueAccent),
          _createLine(foodSpots, Colors.orangeAccent),
          _createLine(exerciseSpots, Colors.tealAccent),
        ],
      ),
      legend: _buildLegend([
          {"color": Colors.blueAccent, "label": "Glucose"},
          {"color": Colors.orangeAccent, "label": "Food"},
          {"color": Colors.tealAccent, "label": "Exercise"},
      ])
    );
  }

  Widget _buildSingleChart(String title, String dataKey, Color color) {
    if (_logs.isEmpty) return const SizedBox();

    List<FlSpot> spots = [];
    for (int i = 0; i < _logs.length; i++) {
      try {
        final val = double.tryParse(_logs[i][dataKey].toString()) ?? 0;
        spots.add(FlSpot(i.toDouble(), val));
      } catch (e) {}
    }

    return _buildChartContainer(
      title,
      LineChartData(
        gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: Colors.white10)),
        titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  LineChartBarData _createLine(List<FlSpot> spots, Color color) {
      return LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: FlDotData(show: false),
      );
  }

  Widget _buildLegend(List<Map<String, dynamic>> items) {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: items.map((i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                    children: [
                        Container(width: 12, height: 12, color: i['color'] as Color),
                        const SizedBox(width: 4),
                        Text(i['label'] as String, style: const TextStyle(fontSize: 12)),
                    ]
                )
            )).toList(),
        ),
      );
  }

  Widget _buildChartContainer(String title, LineChartData data, {Widget? legend}) {
    return Container(
      height: 300,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(child: LineChart(data)),
          if (legend != null) legend
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _logs.isEmpty 
          ? const Center(child: Text("No health logs recorded yet.", style: TextStyle(color: Colors.grey)))
          : RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCombinedChart(),
              _buildSingleChart("Isolated Glucose History", "glucose_level", Colors.blueAccent),
              _buildSingleChart("Isolated Food History", "food", Colors.orangeAccent),
              _buildSingleChart("Isolated Exercise History", "exercise", Colors.tealAccent),
            ],
          ),
        ),
      ),
    );
  }
}
