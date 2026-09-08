import '../providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:health_companion/widgets/glass_card.dart';
import '../providers/health_trends_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class HealthChartCard extends ConsumerWidget {
  final String title;
  final String currentValue;
  final String unit;
  final Color accentColor;
  final Widget chart;

  const HealthChartCard({
    super.key,
    required this.title,
    required this.currentValue,
    required this.unit,
    required this.accentColor,
    required this.chart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF1C1C1E);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassCard(
        padding: const EdgeInsets.all(18.0),
        glowColor: accentColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ref.tr(title),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentValue,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        unit,
                        style: TextStyle(
                          color: accentColor.withValues(alpha: 0.85),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 170, // Height for clear chart visibility
              child: chart,
            ),
          ],
        ),
      ),
    );
  }
}

class LineChartHelper {
  static Widget buildLineChart(
    BuildContext context,
    List<FlSpot> spots,
    Color color,
    double minY,
    double maxY,
    TimeFrame timeFrame,
    String unit, {
    double? yInterval,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final is24h = timeFrame == TimeFrame.hours24;
    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // High contrast axis text colors for light and dark mode
    final axisTextColor = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : const Color(0xFF2C2C2E);

    final gridLineColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.10);

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => isDark ? const Color(0xFF1E1E26) : Colors.white,
            tooltipBorder: BorderSide(color: color.withValues(alpha: 0.8), width: 1.5),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final xVal = spot.x.toInt();
                final timeLabel = is24h
                    ? "${xVal.toString().padLeft(2, '0')}:00"
                    : (xVal < daysOfWeek.length ? daysOfWeek[xVal] : "Day ${xVal + 1}");
                return LineTooltipItem(
                  "$timeLabel\n",
                  TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: "${spot.y.toStringAsFixed(1)} $unit",
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 3,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: gridLineColor,
              strokeWidth: 1,
              dashArray: [4, 4],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: is24h ? 4 : 1,
              getTitlesWidget: (value, meta) {
                final int idx = value.toInt();
                String text = '';
                if (is24h) {
                  if (idx % 4 == 0 && idx <= 24) {
                    text = "${idx.toString().padLeft(2, '0')}:00";
                  }
                } else {
                  if (idx >= 0 && idx < daysOfWeek.length) {
                    text = daysOfWeek[idx];
                  }
                }
                if (text.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: axisTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: yInterval ?? ((maxY - minY) / 3),
              getTitlesWidget: (value, meta) {
                // Hide min/max to prevent overlapping if they are too close to intervals
                if (value == minY || value == maxY) return const SizedBox.shrink();
                return Text(
                  value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
                  style: TextStyle(
                    color: axisTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: color,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: color,
                  strokeWidth: 1.5,
                  strokeColor: isDark ? Colors.white : Colors.black87,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: isDark ? 0.40 : 0.25),
                  color.withValues(alpha: 0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
