import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'diet_plan_screen.dart';

class WeeklyPredictionScreen extends StatefulWidget {
  const WeeklyPredictionScreen({super.key});

  @override
  State<WeeklyPredictionScreen> createState() => _WeeklyPredictionScreenState();
}

class _WeeklyPredictionScreenState extends State<WeeklyPredictionScreen> {
  bool _isLoading = true;
  bool _isDietLoading = true;
  Map<String, dynamic>? _predictions;
  Map<String, dynamic>? _dietPlanResponse;
  String? _dietPlanError;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _isDietLoading = true;
      _dietPlanError = null;
    });

    final predictions = await ApiService.getWeeklyPredictions();
    final dietPlan = await ApiService.getDietPlan();

    if (!mounted) {
      return;
    }

    setState(() {
      _predictions = predictions;
      _isLoading = false;
      _isDietLoading = false;

      if (dietPlan['success'] == true) {
        _dietPlanResponse = dietPlan;
        _dietPlanError = null;
      } else {
        _dietPlanResponse = null;
        _dietPlanError = dietPlan['error'] as String?;
      }
    });
  }

  void _openDietPlan() {
    if (_dietPlanResponse == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DietPlanScreen(initialDietPlanResponse: _dietPlanResponse),
      ),
    );
  }

  Widget _buildPredictionChart() {
    if (_predictions == null || _predictions!['predicted_glucose'] == null) {
      return const SizedBox();
    }

    final preds = (_predictions!['predicted_glucose'] as List<dynamic>);
    if (preds.isEmpty) {
      return const Text(
        'Not enough data for predictions',
        style: TextStyle(color: Colors.grey),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < preds.length; i++) {
      spots.add(FlSpot(i.toDouble(), (preds[i] as num).toDouble()));
    }

    return Container(
      height: 350,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1-Week (7-Day) Glucose Forecast',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.white10),
                ),
                titlesData: FlTitlesData(
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blueAccent.withOpacity(0.1),
                    ),
                  ),
                ],
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 180,
                      color: Colors.redAccent,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                    HorizontalLine(
                      y: 70,
                      color: Colors.orangeAccent,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Each interval represents 6 hours over 7 days (28 points).',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDietPlanPanel() {
    final hasDietPlan = _dietPlanResponse != null &&
        _dietPlanResponse!['diet_plan'] is List &&
        (_dietPlanResponse!['diet_plan'] as List).isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.restaurant_menu, color: Colors.greenAccent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI Diet Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Your personalized 7-day Indian diet chart is generated after prediction and ready to open here.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (_isDietLoading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 10),
            const Text(
              'Generating diet plan...',
              style: TextStyle(color: Colors.white70),
            ),
          ] else if (hasDietPlan) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openDietPlan,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Open 7-Day Diet Plan'),
              ),
            ),
          ] else ...[
            Text(
              _dietPlanError ?? 'Diet plan is not available yet.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final alerts = (_predictions?['alerts'] as List<dynamic>?) ?? const [];
    final recommendations =
        (_predictions?['recommendations'] as List<dynamic>?) ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('7-Day Machine Learning Forecast'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (alerts.isNotEmpty || recommendations.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orangeAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1-Week Smart Insights',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final alert in alerts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '- $alert',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      for (final recommendation in recommendations)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '- $recommendation',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              _buildPredictionChart(),
              const SizedBox(height: 24),
              _buildDietPlanPanel(),
            ],
          ),
        ),
      ),
    );
  }
}
