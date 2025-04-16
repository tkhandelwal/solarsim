// lib/models/simulation_result.dart
class SimulationResult {
  final String id;
  final String projectId;
  final DateTime createdAt;
  final Map<String, double> monthlyEnergy;
  final double annualEnergy;
  final double performanceRatio;
  final Map<String, double> losses;
  final Map<String, double> financialMetrics;
  
  SimulationResult({
    required this.id,
    required this.projectId,
    required this.createdAt,
    required this.monthlyEnergy,
    required this.annualEnergy,
    required this.performanceRatio,
    required this.losses,
    required this.financialMetrics,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'createdAt': createdAt.toIso8601String(),
      'monthlyEnergy': monthlyEnergy,
      'annualEnergy': annualEnergy,
      'performanceRatio': performanceRatio,
      'losses': losses,
      'financialMetrics': financialMetrics,
    };
  }
  
  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    return SimulationResult(
      id: json['id'],
      projectId: json['projectId'],
      createdAt: DateTime.parse(json['createdAt']),
      monthlyEnergy: Map<String, double>.from(json['monthlyEnergy']),
      annualEnergy: json['annualEnergy'],
      performanceRatio: json['performanceRatio'],
      losses: Map<String, double>.from(json['losses']),
      financialMetrics: Map<String, double>.from(json['financialMetrics']),
    );
  }
}