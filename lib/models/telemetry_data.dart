import 'dart:math';

/// Live sensor telemetry payload from ESP32 or Hardware Simulator
class TelemetryData {
  final double heartRate; // BPM (60 - 160)
  final double spO2; // % (85 - 100)
  final double bodyTemp; // °C (35.5 - 41.0)
  final double ambientTemp; // °C (20 - 48)
  final double humidity; // % (20 - 95)
  final double aqi; // Air Quality Index (0 - 500)
  final double accelX; // Accelerometer X (m/s²)
  final double accelY; // Accelerometer Y (m/s²)
  final double accelZ; // Accelerometer Z (m/s²)
  final int batteryLevel; // ESP32 Battery % (0 - 100)
  final DateTime timestamp;
  final bool isSimulated;

  TelemetryData({
    required this.heartRate,
    required this.spO2,
    required this.bodyTemp,
    required this.ambientTemp,
    required this.humidity,
    required this.aqi,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.batteryLevel,
    required this.timestamp,
    this.isSimulated = false,
  });

  /// Default baseline healthy vitals
  factory TelemetryData.initial() {
    return TelemetryData(
      heartRate: 72.0,
      spO2: 98.5,
      bodyTemp: 36.8,
      ambientTemp: 31.0,
      humidity: 52.0,
      aqi: 65.0,
      accelX: 0.12,
      accelY: 0.08,
      accelZ: 9.81,
      batteryLevel: 92,
      timestamp: DateTime.now(),
      isSimulated: true,
    );
  }

  /// Calculates total magnitude of acceleration vector (g-force)
  double get accelerationMagnitude =>
      sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);

  Map<String, dynamic> toJson() => {
        'heartRate': heartRate,
        'spO2': spO2,
        'bodyTemp': bodyTemp,
        'ambientTemp': ambientTemp,
        'humidity': humidity,
        'aqi': aqi,
        'accelX': accelX,
        'accelY': accelY,
        'accelZ': accelZ,
        'batteryLevel': batteryLevel,
        'timestamp': timestamp.toIso8601String(),
        'isSimulated': isSimulated,
      };

  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    return TelemetryData(
      heartRate: (json['heartRate'] ?? 72.0).toDouble(),
      spO2: (json['spO2'] ?? 98.0).toDouble(),
      bodyTemp: (json['bodyTemp'] ?? 36.8).toDouble(),
      ambientTemp: (json['ambientTemp'] ?? 30.0).toDouble(),
      humidity: (json['humidity'] ?? 50.0).toDouble(),
      aqi: (json['aqi'] ?? 60.0).toDouble(),
      accelX: (json['accelX'] ?? 0.0).toDouble(),
      accelY: (json['accelY'] ?? 0.0).toDouble(),
      accelZ: (json['accelZ'] ?? 9.81).toDouble(),
      batteryLevel: (json['batteryLevel'] ?? 100).toInt(),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isSimulated: json['isSimulated'] ?? false,
    );
  }

  /// Helper to generate slightly noisy live data for simulation
  TelemetryData copyWithFluctuations({
    double? customHr,
    double? customSpO2,
    double? customBodyTemp,
    double? customAmbientTemp,
    double? customAqi,
    double? customAccelZ,
    bool? customSim,
  }) {
    final random = Random();
    // Minor realistic noise
    final hrDelta = (random.nextDouble() * 1.6) - 0.8;
    final spO2Delta = (random.nextDouble() * 0.4) - 0.2;
    final tempDelta = (random.nextDouble() * 0.1) - 0.05;

    return TelemetryData(
      heartRate: customHr ?? (heartRate + hrDelta).clamp(40.0, 180.0),
      spO2: customSpO2 ?? (spO2 + spO2Delta).clamp(80.0, 100.0),
      bodyTemp: customBodyTemp ?? (bodyTemp + tempDelta).clamp(34.0, 42.0),
      ambientTemp: customAmbientTemp ?? ambientTemp,
      humidity: humidity,
      aqi: customAqi ?? aqi,
      accelX: accelX,
      accelY: accelY,
      accelZ: customAccelZ ?? accelZ,
      batteryLevel: batteryLevel,
      timestamp: DateTime.now(),
      isSimulated: customSim ?? isSimulated,
    );
  }
}
