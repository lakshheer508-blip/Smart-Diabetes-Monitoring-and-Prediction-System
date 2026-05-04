import 'package:flutter/material.dart';

import '../services/api_service.dart';

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key, this.initialDietPlanResponse});

  final Map<String, dynamic>? initialDietPlanResponse;

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _dietPlanResponse;

  @override
  void initState() {
    super.initState();

    if (_extractDietPlan(widget.initialDietPlanResponse).isNotEmpty) {
      _dietPlanResponse = widget.initialDietPlanResponse;
      _isLoading = false;
    } else {
      _loadDietPlan();
    }
  }

  Future<void> _loadDietPlan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiService.getDietPlan();
    if (!mounted) {
      return;
    }

    setState(() {
      if (response['success'] == true) {
        _dietPlanResponse = response;
        _errorMessage = null;
      } else {
        _dietPlanResponse = null;
        _errorMessage =
            response['error'] as String? ?? 'Unable to load diet plan.';
      }
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _extractDietPlan(Map<String, dynamic>? response) {
    final rawPlan = response?['diet_plan'];
    if (rawPlan is! List) {
      return [];
    }

    return rawPlan
        .whereType<Map>()
        .map((dayPlan) => Map<String, dynamic>.from(dayPlan))
        .toList();
  }

  String _mealValue(Map<String, dynamic> dayPlan, String key) {
    final value = dayPlan[key];
    if (value == null) {
      return 'Not available';
    }

    final normalized = value.toString().trim();
    return normalized.isEmpty ? 'Not available' : normalized;
  }

  Widget _buildMealRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final status = (_dietPlanResponse?['status'] ?? 'Personalized').toString();
    final goal = (_dietPlanResponse?['goal'] ?? 'balanced').toString();
    final summary = (_dietPlanResponse?['summary'] ??
            'AI-generated 7-day Indian diet plan.')
        .toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102038), Color(0xFF153E35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Generated 7-Day Indian Diet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: const TextStyle(
                fontSize: 14, color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.health_and_safety_outlined,
                label: 'Status: $status',
              ),
              _InfoChip(
                icon: Icons.tune,
                label: 'Goal: ${goal.replaceAll('_', ' ')}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateView({
    required IconData icon,
    required String title,
    required String message,
    bool showRetry = false,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Icon(icon, color: Colors.white54, size: 72),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style:
              const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
        ),
        if (showRetry) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadDietPlan,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dietPlan = _extractDietPlan(_dietPlanResponse);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Diet Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDietPlan,
              child: _errorMessage != null
                  ? _buildStateView(
                      icon: Icons.error_outline,
                      title: 'Diet plan unavailable',
                      message: _errorMessage!,
                      showRetry: true,
                    )
                  : dietPlan.isEmpty
                      ? _buildStateView(
                          icon: Icons.restaurant_menu_outlined,
                          title: 'No diet plan available',
                          message:
                              'We could not find a 7-day diet chart yet. Pull to refresh or try again after prediction.',
                          showRetry: true,
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: dietPlan.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildHeaderCard(),
                              );
                            }

                            final dayPlan = dietPlan[index - 1];
                            final dayNumber = dayPlan['day'] is num
                                ? (dayPlan['day'] as num).toInt()
                                : index;

                            return Card(
                              color: const Color(0xFF1E293B),
                              margin: const EdgeInsets.only(bottom: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                    color: Colors.white.withOpacity(0.06)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.blueAccent
                                                .withOpacity(0.14),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            'Day $dayNumber',
                                            style: const TextStyle(
                                              color: Colors.blueAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    _buildMealRow(
                                      icon: Icons.wb_sunny_outlined,
                                      label: 'Breakfast',
                                      value: _mealValue(dayPlan, 'breakfast'),
                                      color: Colors.amberAccent,
                                    ),
                                    _buildMealRow(
                                      icon: Icons.lunch_dining_outlined,
                                      label: 'Lunch',
                                      value: _mealValue(dayPlan, 'lunch'),
                                      color: Colors.orangeAccent,
                                    ),
                                    _buildMealRow(
                                      icon: Icons.dinner_dining_outlined,
                                      label: 'Dinner',
                                      value: _mealValue(dayPlan, 'dinner'),
                                      color: Colors.greenAccent,
                                    ),
                                    _buildMealRow(
                                      icon: Icons.local_cafe_outlined,
                                      label: 'Snacks',
                                      value: _mealValue(dayPlan, 'snacks'),
                                      color: Colors.purpleAccent,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
