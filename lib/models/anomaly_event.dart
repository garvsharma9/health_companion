enum RiskType {
  heatStroke,
  respiratory,
  cardiac,
  fallDetected,
  environmentalSpike,
  normal
}

enum AnomalySeverity { low, medium, high, critical }

class AnomalyEvent {
  final String id;
  final String title;
  final String description;
  final RiskType riskType;
  final AnomalySeverity severity;
  final String recommendation;
  final DateTime timestamp;
  bool isAcknowledged;

  AnomalyEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.riskType,
    required this.severity,
    required this.recommendation,
    required this.timestamp,
    this.isAcknowledged = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'riskType': riskType.name,
        'severity': severity.name,
        'recommendation': recommendation,
        'timestamp': timestamp.toIso8601String(),
        'isAcknowledged': isAcknowledged,
      };

  factory AnomalyEvent.fromJson(Map<String, dynamic> json) {
    return AnomalyEvent(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'Alert',
      description: json['description'] ?? '',
      riskType: RiskType.values.firstWhere(
        (e) => e.name == json['riskType'],
        orElse: () => RiskType.normal,
      ),
      severity: AnomalySeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AnomalySeverity.medium,
      ),
      recommendation: json['recommendation'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isAcknowledged: json['isAcknowledged'] ?? false,
    );
  }
}
