import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/telemetry_data.dart';
import 'telemetry_provider.dart';

class ActivitySleepState {
  final String activityLevel;
  final int steps;
  final int activeCalories;
  final String sleepState;
  final int sleepDurationMinutes;
  final int sleepScore;

  ActivitySleepState({
    required this.activityLevel,
    required this.steps,
    required this.activeCalories,
    required this.sleepState,
    required this.sleepDurationMinutes,
    required this.sleepScore,
  });

  factory ActivitySleepState.initial() {
    return ActivitySleepState(
      activityLevel: 'Resting',
      steps: 4302, // Mocked base steps for demo
      activeCalories: 340,
      sleepState: 'Awake',
      sleepDurationMinutes: 432, // 7 hours 12 mins
      sleepScore: 88,
    );
  }

  ActivitySleepState copyWith({
    String? activityLevel,
    int? steps,
    int? activeCalories,
    String? sleepState,
    int? sleepDurationMinutes,
    int? sleepScore,
  }) {
    return ActivitySleepState(
      activityLevel: activityLevel ?? this.activityLevel,
      steps: steps ?? this.steps,
      activeCalories: activeCalories ?? this.activeCalories,
      sleepState: sleepState ?? this.sleepState,
      sleepDurationMinutes: sleepDurationMinutes ?? this.sleepDurationMinutes,
      sleepScore: sleepScore ?? this.sleepScore,
    );
  }
}

final activitySleepProvider =
    StateNotifierProvider<ActivitySleepNotifier, ActivitySleepState>((ref) {
  return ActivitySleepNotifier(ref);
});

class ActivitySleepNotifier extends StateNotifier<ActivitySleepState> {
  final Ref ref;
  
  ActivitySleepNotifier(this.ref) : super(ActivitySleepState.initial()) {
    ref.listen(currentTelemetryProvider, (previous, current) {
      if (current != null) {
        _processTelemetry(current);
      }
    });
  }

  void _processTelemetry(TelemetryData telemetry) {
    final magnitude = telemetry.accelerationMagnitude;
    
    // --- Activity Level Logic (IMU classification) ---
    String newActivityLevel = 'Resting';
    int newSteps = state.steps;
    int newCalories = state.activeCalories;

    if (magnitude > 15.0) {
      newActivityLevel = 'Exercise';
      newSteps += 2;
      newCalories += 1;
    } else if (magnitude > 11.0) {
      newActivityLevel = 'Walking';
      newSteps += 1;
    } else {
      newActivityLevel = 'Resting';
    }

    // --- Sleep Quality Logic (Motion + HR) ---
    String newSleepState = 'Awake';
    int newSleepScore = state.sleepScore;
    
    // Near 1g (9.81 m/s^2) means very little motion. Low HR means sleep.
    if (magnitude > 9.7 && magnitude < 9.9 && telemetry.heartRate < 60) {
      newSleepState = 'Deep Sleep';
      newSleepScore = min(100, newSleepScore + 1);
    } else if (magnitude > 9.5 && magnitude < 10.1 && telemetry.heartRate < 72) {
      newSleepState = 'Light Sleep';
    } else {
      newSleepState = 'Awake';
    }

    state = state.copyWith(
      activityLevel: newActivityLevel,
      steps: newSteps,
      activeCalories: newCalories,
      sleepState: newSleepState,
      sleepScore: newSleepScore,
    );
  }
}
