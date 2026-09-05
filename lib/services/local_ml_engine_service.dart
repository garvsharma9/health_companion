import 'dart:math';
import '../models/telemetry_data.dart';
import '../models/anomaly_event.dart';

class MlInferenceResult {
  final double riskScore; // 0.0 to 100.0%
  final AnomalySeverity overallSeverity;
  final List<AnomalyEvent> activeAnomalies;
  final String primaryRecommendation;
  final int inferenceTimeMs;
  final String modelName;

  MlInferenceResult({
    required this.riskScore,
    required this.overallSeverity,
    required this.activeAnomalies,
    required this.primaryRecommendation,
    required this.inferenceTimeMs,
    this.modelName = "OnDevice_MultiFactor_Heuristic_v1",
  });
}

class LocalMlEngineService {
  /// Executes local on-device AI inference & multi-factor heuristic risk scoring.
  /// Runs 100% offline with zero cloud network calls.
  static MlInferenceResult processTelemetry(TelemetryData telemetry) {
    final stopwatch = Stopwatch()..start();
    final anomalies = <AnomalyEvent>[];
    double riskScoreAcc = 0.0;

    // --- 1. Heat Stroke Risk Model (Qualcomm SIH Feature 3) ---
    // Multi-factor formula: Body Temp + Ambient Temp + Humidity + Heart Rate
    if (telemetry.bodyTemp >= 38.2 ||
        (telemetry.ambientTemp >= 38.0 && telemetry.humidity >= 55.0)) {
      final heatIndex = telemetry.ambientTemp +
          (0.55 * (telemetry.humidity / 100.0) * (telemetry.ambientTemp - 14.5));
      if (telemetry.bodyTemp >= 38.8 || heatIndex >= 42.0) {
        riskScoreAcc += 45.0;
        anomalies.add(AnomalyEvent(
          id: 'heat_${DateTime.now().millisecondsSinceEpoch}',
          title: 'HEAT STROKE RISK DETECTED',
          description:
              'Body Temp ${telemetry.bodyTemp.toStringAsFixed(1)}°C with Ambient Heat Index ${heatIndex.toStringAsFixed(0)}°C. High heat stroke risk.',
          riskType: RiskType.heatStroke,
          severity: AnomalySeverity.critical,
          recommendation:
              'Immediately move to shade, sip cold water, and apply wet cloths to neck.',
          timestamp: DateTime.now(),
        ));
      } else if (telemetry.ambientTemp >= 36.0) {
        riskScoreAcc += 20.0;
        anomalies.add(AnomalyEvent(
          id: 'heat_warn_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Elevated Thermal Stress',
          description:
              'High ambient temperature (${telemetry.ambientTemp.toStringAsFixed(1)}°C). Stay hydrated.',
          riskType: RiskType.heatStroke,
          severity: AnomalySeverity.medium,
          recommendation: 'Seek shade and drink water frequently.',
          timestamp: DateTime.now(),
        ));
      }
    }

    // --- 2. Respiratory & Pollution Hazard (Qualcomm SIH Feature 4) ---
    if (telemetry.aqi > 200 || telemetry.spO2 < 93.0) {
      if (telemetry.aqi >= 250 && telemetry.spO2 <= 92.0) {
        riskScoreAcc += 40.0;
        anomalies.add(AnomalyEvent(
          id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
          title: 'CRITICAL RESPIRATORY HAZARD',
          description:
              'Severe AQI (${telemetry.aqi.toStringAsFixed(0)}) combined with low SpO2 blood oxygen (${telemetry.spO2.toStringAsFixed(1)}%).',
          riskType: RiskType.respiratory,
          severity: AnomalySeverity.high,
          recommendation:
              'Wear N95 mask immediately, move indoors, and use prescribed asthma inhaler if applicable.',
          timestamp: DateTime.now(),
        ));
      } else if (telemetry.aqi > 150) {
        riskScoreAcc += 15.0;
        anomalies.add(AnomalyEvent(
          id: 'aqi_warn_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Unhealthy Air Quality (AQI ${telemetry.aqi.toStringAsFixed(0)})',
          description: 'Air pollution spike detected in surrounding area.',
          riskType: RiskType.environmentalSpike,
          severity: AnomalySeverity.medium,
          recommendation: 'Limit strenuous outdoor activity.',
          timestamp: DateTime.now(),
        ));
      }
    }

    // --- 3. Cardiac Anomaly Model ---
    if (telemetry.heartRate > 125.0 || telemetry.heartRate < 48.0) {
      if (telemetry.heartRate > 145.0) {
        riskScoreAcc += 35.0;
        anomalies.add(AnomalyEvent(
          id: 'cardiac_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Severe Tachycardia Alert',
          description:
              'Abnormal Heart Rate spike: ${telemetry.heartRate.toStringAsFixed(0)} BPM while resting.',
          riskType: RiskType.cardiac,
          severity: AnomalySeverity.high,
          recommendation:
              'Sit down, practice slow deep breathing, and notify caregiver if symptoms persist.',
          timestamp: DateTime.now(),
        ));
      } else if (telemetry.heartRate < 48.0) {
        riskScoreAcc += 25.0;
        anomalies.add(AnomalyEvent(
          id: 'brady_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Bradycardia Warning',
          description:
              'Low Resting Heart Rate: ${telemetry.heartRate.toStringAsFixed(0)} BPM.',
          riskType: RiskType.cardiac,
          severity: AnomalySeverity.medium,
          recommendation: 'Monitor vitals and rest.',
          timestamp: DateTime.now(),
        ));
      }
    }

    // --- 4. Fall Detection (Qualcomm SIH Feature 6) ---
    final accelVector = telemetry.accelerationMagnitude;
    if (accelVector > 22.0) {
      riskScoreAcc += 50.0;
      anomalies.add(AnomalyEvent(
        id: 'fall_${DateTime.now().millisecondsSinceEpoch}',
        title: 'FALL EVENT DETECTED!',
        description:
            'Sudden impact vector of ${accelVector.toStringAsFixed(1)} m/s² detected by wrist sensors.',
        riskType: RiskType.fallDetected,
        severity: AnomalySeverity.critical,
        recommendation:
            'Emergency SOS countdown initiated. Tap cancel if you are uninjured.',
        timestamp: DateTime.now(),
      ));
    }

    stopwatch.stop();

    // Determine final risk tier
    final finalRiskScore = riskScoreAcc.clamp(5.0, 99.0);
    AnomalySeverity severity = AnomalySeverity.low;
    String recommendation = "Vitals and environment are within safe parameters.";

    if (finalRiskScore >= 70.0 ||
        anomalies.any((e) => e.severity == AnomalySeverity.critical)) {
      severity = AnomalySeverity.critical;
      recommendation = anomalies.isNotEmpty
          ? anomalies.first.recommendation
          : "Critical risk detected! Take emergency precautions.";
    } else if (finalRiskScore >= 40.0) {
      severity = AnomalySeverity.high;
      recommendation = anomalies.isNotEmpty
          ? anomalies.first.recommendation
          : "Elevated health risk. Take rest and monitor vitals.";
    } else if (finalRiskScore >= 20.0) {
      severity = AnomalySeverity.medium;
      recommendation = "Minor vital deviations noted. Stay hydrated and calm.";
    }

    return MlInferenceResult(
      riskScore: finalRiskScore,
      overallSeverity: severity,
      activeAnomalies: anomalies,
      primaryRecommendation: recommendation,
      inferenceTimeMs: max(1, stopwatch.elapsedMilliseconds),
    );
  }
}
