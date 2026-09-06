import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

enum TimeFrame { hours24, days7 }

class HealthTrendsState {
  final TimeFrame selectedTimeFrame;
  final List<FlSpot> heartRateData;
  final List<FlSpot> spO2Data;
  final List<FlSpot> temperatureData;
  final List<BarChartGroupData> stepsData;

  HealthTrendsState({
    required this.selectedTimeFrame,
    required this.heartRateData,
    required this.spO2Data,
    required this.temperatureData,
    required this.stepsData,
  });

  HealthTrendsState copyWith({
    TimeFrame? selectedTimeFrame,
    List<FlSpot>? heartRateData,
    List<FlSpot>? spO2Data,
    List<FlSpot>? temperatureData,
    List<BarChartGroupData>? stepsData,
  }) {
    return HealthTrendsState(
      selectedTimeFrame: selectedTimeFrame ?? this.selectedTimeFrame,
      heartRateData: heartRateData ?? this.heartRateData,
      spO2Data: spO2Data ?? this.spO2Data,
      temperatureData: temperatureData ?? this.temperatureData,
      stepsData: stepsData ?? this.stepsData,
    );
  }
}

class HealthTrendsNotifier extends StateNotifier<HealthTrendsState> {
  HealthTrendsNotifier() : super(_generateDummyData(TimeFrame.hours24));

  void setTimeFrame(TimeFrame timeFrame) {
    state = _generateDummyData(timeFrame);
  }

  static HealthTrendsState _generateDummyData(TimeFrame timeFrame) {
    final random = Random();
    final is24h = timeFrame == TimeFrame.hours24;
    final dataPointsCount = is24h ? 24 : 7;
    
    // Heart Rate (BPM)
    List<FlSpot> hrData = [];
    double currentHr = 75.0;
    for (int i = 0; i < dataPointsCount; i++) {
      currentHr += (random.nextDouble() * 10) - 5;
      currentHr = currentHr.clamp(60.0, 120.0);
      hrData.add(FlSpot(i.toDouble(), currentHr));
    }

    // SpO2 (%)
    List<FlSpot> spO2Data = [];
    for (int i = 0; i < dataPointsCount; i++) {
      double val = 95.0 + random.nextDouble() * 5.0; // 95 - 100
      spO2Data.add(FlSpot(i.toDouble(), val));
    }

    // Temperature (°C)
    List<FlSpot> tempData = [];
    double currentTemp = 36.5;
    for (int i = 0; i < dataPointsCount; i++) {
      currentTemp += (random.nextDouble() * 0.4) - 0.2;
      currentTemp = currentTemp.clamp(36.0, 38.0);
      tempData.add(FlSpot(i.toDouble(), currentTemp));
    }

    // Steps
    List<BarChartGroupData> stepsData = [];
    for (int i = 0; i < dataPointsCount; i++) {
      double steps = is24h ? random.nextDouble() * 1000 : random.nextDouble() * 12000;
      stepsData.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: steps,
              width: is24h ? 6 : 14,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return HealthTrendsState(
      selectedTimeFrame: timeFrame,
      heartRateData: hrData,
      spO2Data: spO2Data,
      temperatureData: tempData,
      stepsData: stepsData,
    );
  }
}

final healthTrendsProvider = StateNotifierProvider<HealthTrendsNotifier, HealthTrendsState>((ref) {
  return HealthTrendsNotifier();
});
