import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../providers/theme_provider.dart';
import '../providers/activity_sleep_provider.dart';
import '../providers/telemetry_provider.dart';

class SleepDetailScreen extends ConsumerStatefulWidget {
  const SleepDetailScreen({super.key});

  @override
  ConsumerState<SleepDetailScreen> createState() => _SleepDetailScreenState();
}

class _SleepDetailScreenState extends ConsumerState<SleepDetailScreen> {
  final List<FlSpot> _historicalData24h = [];
  final List<FlSpot> _historicalData7d = [];
  bool _is24h = true;

  @override
  void initState() {
    super.initState();
    _generateMockHistoricalData();
  }

  void _generateMockHistoricalData() {
    // Generate 8 hours of sleep stages: 3 (Awake), 2 (Light), 1 (Deep)
    final random = Random();
    for (int i = 0; i < 8 * 4; i++) { // Every 15 mins
      double time = i / 4.0;
      double stage = 2; // Light
      if (time > 1.5 && time < 4.0 && random.nextDouble() > 0.3) {
        stage = 1; // Deep sleep cycles
      } else if (time > 5.5 && time < 7.0 && random.nextDouble() > 0.4) {
        stage = 1;
      }
      if (random.nextDouble() > 0.95) {
        stage = 3; // Brief awakening
      }
      _historicalData24h.add(FlSpot(time, stage));
    }

    // Generate 7 days of sleep scores (0-4 scale mapping to Deep/Light)
    for (int i = 0; i < 7; i++) {
      double score = random.nextDouble() * 1.5 + 1.2; // 1.2 to 2.7 average score
      _historicalData7d.add(FlSpot(i.toDouble(), score));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final sleepState = ref.watch(activitySleepProvider);
    final telemetry = ref.watch(currentTelemetryProvider);

    List<FlSpot> displayData = _is24h ? List.from(_historicalData24h) : List.from(_historicalData7d);
    
    if (telemetry != null && _is24h) {
      double currentStage = 3.0; // Awake
      if (sleepState.sleepState == 'Deep Sleep') currentStage = 1.0;
      else if (sleepState.sleepState == 'Light Sleep') currentStage = 2.0;

      // Add live data to the end of the chart (hour 8.0)
      displayData.add(FlSpot(8.0, currentStage));
    } else if (telemetry != null && !_is24h) {
      double currentStage = 3.0;
      if (sleepState.sleepState == 'Deep Sleep') currentStage = -0.5;
      else if (sleepState.sleepState == 'Light Sleep') currentStage = -0.2;
      
      displayData[6] = FlSpot(6, (displayData[6].y + currentStage).clamp(1.0, 3.0));
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        title: Text(
          "Sleep Quality",
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
              glowColor: Colors.indigoAccent,
              child: Column(
                children: [
                  Text("Current Status", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                  const SizedBox(height: 8),
                  Text(
                    sleepState.sleepState,
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
                      _buildMetricBox("Duration", "${sleepState.sleepDurationMinutes ~/ 60}h ${sleepState.sleepDurationMinutes % 60}m", isDark),
                      _buildMetricBox("Quality Score", "${sleepState.sleepScore}", isDark),
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
                  _is24h ? "LAST NIGHT'S SLEEP STAGES" : "7-DAY SLEEP TREND",
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
                    minY: 0,
                    maxY: 4,
                    titlesData: FlTitlesData(
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: _is24h ? 2 : 1,
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
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (!_is24h) return const Text(""); // Hide left titles in 7D mode for cleaner look
                            switch (value.toInt()) {
                              case 1:
                                return Text("Deep", style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54));
                              case 2:
                                return Text("Light", style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54));
                              case 3:
                                return Text("Awake", style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54));
                              default:
                                return const Text("");
                            }
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: displayData,
                        isCurved: !_is24h,
                        color: Colors.indigoAccent,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.indigoAccent.withValues(alpha: 0.2),
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
