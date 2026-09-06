import '../models/telemetry_data.dart';
import '../providers/activity_sleep_provider.dart';

class LocalAIEngine {
  /// Generates a dynamic natural language response based on user query and local telemetry context.
  static String generateResponse(
    String userQuery,
    TelemetryData telemetry,
    ActivitySleepState activitySleepState,
  ) {
    final query = userQuery.toLowerCase();

    // 1. Heart Rate Intent
    if (query.contains('hr') || query.contains('heart') || query.contains('spike') || query.contains('bpm')) {
      if (telemetry.heartRate > 100) {
        return "I noticed your heart rate is currently elevated at ${telemetry.heartRate.toInt()} BPM. Since you are in a '${activitySleepState.activityLevel}' state, this is expected. Remember to breathe and stay hydrated!";
      } else if (telemetry.heartRate < 60) {
        return "Your heart rate is beautifully resting at ${telemetry.heartRate.toInt()} BPM. This indicates excellent cardiovascular recovery.";
      } else {
        return "Your current heart rate is ${telemetry.heartRate.toInt()} BPM, which is perfectly within normal resting limits. Your heart is functioning efficiently today!";
      }
    }

    // 2. SpO2 / Oxygen Intent
    if (query.contains('spo2') || query.contains('oxygen') || query.contains('breathe')) {
      if (telemetry.spO2 < 95) {
        return "Your blood oxygen is slightly low at ${telemetry.spO2.toInt()}%. I recommend taking a few deep breaths and ensuring your room is well-ventilated.";
      } else {
        return "Your SpO2 is fantastic at ${telemetry.spO2.toInt()}%. Oxygen delivery to your muscles and brain is optimal right now.";
      }
    }

    // 3. Sleep Intent
    if (query.contains('sleep') || query.contains('night') || query.contains('rest')) {
      final hours = activitySleepState.sleepDurationMinutes ~/ 60;
      final mins = activitySleepState.sleepDurationMinutes % 60;
      if (activitySleepState.sleepScore > 85) {
        return "You had an excellent night's rest! You slept for $hours hours and $mins minutes with a Sleep Score of ${activitySleepState.sleepScore}. You should feel highly energized today.";
      } else {
        return "Your sleep score was ${activitySleepState.sleepScore} over $hours hours and $mins minutes. To improve this tonight, try to keep your room temperature around 19°C and avoid screens 1 hour before bed.";
      }
    }

    // 4. Activity / Steps Intent
    if (query.contains('step') || query.contains('walk') || query.contains('activity') || query.contains('calorie')) {
      if (activitySleepState.steps > 8000) {
        return "You've crushed it today with ${activitySleepState.steps} steps and ${activitySleepState.activeCalories} active calories burned! You are currently ${activitySleepState.activityLevel}. Keep up the great momentum!";
      } else {
        return "You are currently ${activitySleepState.activityLevel} with ${activitySleepState.steps} steps logged so far. A brisk 15-minute walk right now would give you a great energy boost!";
      }
    }

    // 5. Environment / AQI Intent
    if (query.contains('aqi') || query.contains('environment') || query.contains('temp')) {
      return "Current ambient temperature around you is ${telemetry.bodyTemp.toStringAsFixed(1)}°C. With a stable HR of ${telemetry.heartRate.toInt()} BPM, your body is thermoregulating perfectly in this environment.";
    }

    // Default Fallback Response
    return "Based on your real-time telemetry, your overall health parameters are stable. Your HR is ${telemetry.heartRate.toInt()} BPM, SpO2 is ${telemetry.spO2.toInt()}%, and you've taken ${activitySleepState.steps} steps. Is there a specific metric you'd like me to analyze further?";
  }
}
