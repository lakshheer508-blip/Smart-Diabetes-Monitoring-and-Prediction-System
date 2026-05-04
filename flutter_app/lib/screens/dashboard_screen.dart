import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<dynamic> _logs = [];
  Map<String, dynamic>? _predictions;
  Map<String, dynamic>? _report;

  final _glucoseCtrl = TextEditingController();
  final _foodCtrl = TextEditingController();
  final _exerciseCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final logs = await ApiService.getHealthLogs();
    final preds = await ApiService.getPredictions();
    final rep = await ApiService.getReports();
    setState(() {
      _logs = logs;
      _predictions = preds;
      _report = rep;
      _isLoading = false;
    });
  }

  Future<void> _submitData() async {
    if (_glucoseCtrl.text.isEmpty ||
        _foodCtrl.text.isEmpty ||
        _exerciseCtrl.text.isEmpty) return;

    final data = {
      "glucose_level": double.tryParse(_glucoseCtrl.text) ?? 0,
      "food": double.tryParse(_foodCtrl.text) ?? 0,
      "exercise": double.tryParse(_exerciseCtrl.text) ?? 0
    };

    final success = await ApiService.logHealthData(data);
    if (success) {
      _glucoseCtrl.clear();
      _foodCtrl.clear();
      _exerciseCtrl.clear();
      _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log added successfully!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to save log. Please try logging in again.')));
    }
  }

  Widget _buildMetricsCard(String title, dynamic value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('${value ?? '--'}',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionChart() {
    if (_predictions == null || _predictions!['predicted_glucose'] == null)
      return const SizedBox();
    List<dynamic> preds = _predictions!['predicted_glucose'];
    if (preds.isEmpty)
      return const Text("Not enough data for predictions",
          style: TextStyle(color: Colors.grey));

    List<FlSpot> spots = [];
    for (int i = 0; i < preds.length; i++) {
      spots.add(FlSpot(i.toDouble(), (preds[i] as num).toDouble()));
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("72-Hour Glucose Prediction",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                  gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: Colors.white10)),
                  titlesData: FlTitlesData(
                    bottomTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 40)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.purpleAccent,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                          show: true,
                          color: Colors.purpleAccent.withOpacity(0.1)),
                    ),
                  ],
                  extraLinesData: ExtraLinesData(horizontalLines: [
                    HorizontalLine(
                        y: 180,
                        color: Colors.redAccent,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 10))),
                    HorizontalLine(
                        y: 70,
                        color: Colors.orangeAccent,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.bottomRight,
                            style: const TextStyle(
                                color: Colors.orangeAccent, fontSize: 10))),
                  ])),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          )
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.favorite, color: Colors.white, size: 40),
                  SizedBox(height: 10),
                  Text('GlucoSense',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.white),
              title: const Text('72-Hour Prediction',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // close drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range, color: Colors.white),
              title: const Text('7-Day Prediction',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/weekly_prediction');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.white),
              title: const Text('Data Analytics',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/analytics');
              },
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.purpleAccent),
              title: const Text('AI Camera Scan',
                  style: TextStyle(color: Colors.purpleAccent)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/camera_scan');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.restaurant_menu, color: Colors.greenAccent),
              title: const Text('Smart Diet Plan',
                  style: TextStyle(color: Colors.greenAccent)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/diet_plan');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.medical_services, color: Colors.blueAccent),
              title: const Text('Doctor Panel',
                  style: TextStyle(color: Colors.blueAccent)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/doctor_panel');
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.redAccent),
              title: const Text('Emergency SOS',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/sos');
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metrics
                  Row(
                    children: [
                      _buildMetricsCard('Avg Glucose', _report?['avg_glucose'],
                          Colors.blueAccent),
                      const SizedBox(width: 8),
                      _buildMetricsCard('Max (30d)', _report?['max_glucose'],
                          Colors.purpleAccent),
                      const SizedBox(width: 8),
                      _buildMetricsCard('Min (30d)', _report?['min_glucose'],
                          Colors.tealAccent),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Alerts & Recommendations
                  if (_predictions != null &&
                      ((_predictions!['alerts']?.isNotEmpty ?? false) ||
                          (_predictions!['recommendations']?.isNotEmpty ??
                              false)))
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.redAccent.withOpacity(0.3))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Smart Alerts & Insights",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent)),
                          const SizedBox(height: 8),
                          if (_predictions!['alerts'] != null)
                            for (var alert in _predictions!['alerts'])
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('- $alert',
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                          if (_predictions!['recommendations'] != null)
                            for (var rec in _predictions!['recommendations'])
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('- $rec',
                                    style:
                                        const TextStyle(color: Colors.white70)),
                              ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ML Prediction Chart
                  _buildPredictionChart(),
                  const SizedBox(height: 24),

                  // Data Entry Form
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Log New Entry",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextField(
                            controller: _glucoseCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Glucose Level (mg/dL)',
                                filled: true)),
                        const SizedBox(height: 8),
                        TextField(
                            controller: _foodCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Food Intake (calories/g)',
                                filled: true)),
                        const SizedBox(height: 8),
                        TextField(
                            controller: _exerciseCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Exercise (minutes)', filled: true)),
                        const SizedBox(height: 16),
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                                onPressed: _submitData,
                                child: const Text("Save Log")))
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
