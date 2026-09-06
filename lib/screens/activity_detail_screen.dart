import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../providers/theme_provider.dart';
import '../providers/activity_sleep_provider.dart';
import '../providers/telemetry_provider.dart';

class ActivityDetailScreen extends ConsumerStatefulWidget {
  const ActivityDetailScreen({super.key});

  @override
  ConsumerState<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  final List<FlSpot> _historicalData24h = [];
  final List<FlSpot> _historicalData7d = [];
  bool _is24h = true;

  @override
  void initState() {
    super.initState();
    _generateMockHistoricalData();
  }

  void _generateMockHistoricalData() {
    // Generate 24 hours of mock data
    final random = Random();
    for (int i = 0; i < 24; i++) {
      double intensity = 0;
      if (i > 8 && i < 20) {
        intensity = random.nextDouble() * 3 + 1; // 1 to 4
        if (i == 17 || i == 18) {
          intensity = 4.5 + random.nextDouble();
        }
      } else {
        intensity = random.nextDouble() * 0.5;
      }
      _historicalData24h.add(FlSpot(i.toDouble(), intensity));
    }
    
    // Generate 7 days of mock data
    for (int i = 0; i < 7; i++) {
      // average intensity between 1 and 4
      double avgIntensity = random.nextDouble() * 2 + 1.5;
      _historicalData7d.add(FlSpot(i.toDouble(), avgIntensity));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final activityState = ref.watch(activitySleepProvider);
    final telemetry = ref.watch(currentTelemetryProvider);

    // Merge live data into the graph seamlessly
    List<FlSpot> displayData = _is24h ? List.from(_historicalData24h) : List.from(_historicalData7d);
    
    if (telemetry != null && _is24h) {
      final double currentHour = DateTime.now().hour + DateTime.now().minute / 60.0;
      double currentIntensity = 0;
      if (activityState.activityLevel == 'Exercise') currentIntensity = 5.0;
      else if (activityState.activityLevel == 'Running') currentIntensity = 4.0;
      else if (activityState.activityLevel == 'Walking') currentIntensity = 2.0;
      else currentIntensity = 0.5;
      
      bool found = false;
      for (int i = 0; i < displayData.length; i++) {
        if ((displayData[i].x - currentHour).abs() < 0.5) {
          displayData[i] = FlSpot(currentHour, currentIntensity);
          found = true;
          break;
        }
      }
      if (!found) {
        displayData.add(FlSpot(currentHour, currentIntensity));
        displayData.sort((a, b) => a.x.compareTo(b.x));
      }
    } else if (telemetry != null && !_is24h) {
      // Add a slight bump to today's 7d average based on current activity
      double currentIntensity = 0;
      if (activityState.activityLevel == 'Exercise') currentIntensity = 1.0;
      else if (activityState.activityLevel == 'Running') currentIntensity = 0.5;
      else if (activityState.activityLevel == 'Walking') currentIntensity = 0.2;
      
      displayData[6] = FlSpot(6, (displayData[6].y + currentIntensity).clamp(0, 5.0));
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        title: Text(
          "Activity & Steps",
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              glowColor: Colors.lightGreen,
              child: Column(
                children: [
                  Text("Current Status", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                  const SizedBox(height: 8),
                  Text(
                    activityState.activityLevel,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricBox("Steps", "${activityState.steps}", isDark),
                      _buildMetricBox("Active kCal", "${activityState.activeCalories}", isDark),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _is24h ? "24-HOUR ACTIVITY INTENSITY" : "7-DAY ACTIVITY TREND",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8E8E93),
                    letterSpacing: 0.8,
                  ),
                ),
                _buildToggle(isDark),
              ],
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: _is24h ? 6 : 1,
                          getTitlesWidget: (value, meta) {
                            if (_is24h) {
                              return Text("${value.toInt()}h", style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54));
                            } else {
                              final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
                              int index = value.toInt() % 7;
                              return Text(days[index], style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54));
                            }
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: displayData,
                        isCurved: true,
                        color: Colors.lightGreen,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.lightGreen.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
      ],
    );
  }

  Widget _buildToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton("24H", true, isDark),
          _buildToggleButton("7D", false, isDark),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool is24hToggle, bool isDark) {
    final isSelected = _is24h == is24hToggle;
    return GestureDetector(
      onTap: () => setState(() => _is24h = is24hToggle),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? Colors.white.withValues(alpha: 0.2) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected && !isDark ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white54 : Colors.black54),
          ),
        ),
      ),
    );
  }
}
