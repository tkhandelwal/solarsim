// lib/models/inverter.dart
class Inverter {
  final String id;
  final String manufacturer;
  final String model;
  final double ratedPowerAC;
  final double maxDCPower;
  final double efficiency;
  final double minMPPVoltage;
  final double maxMPPVoltage;
  final int numberOfMPPTrackers;
  final InverterType type;
  
  Inverter({
    required this.id,
    required this.manufacturer,
    required this.model,
    required this.ratedPowerAC,
    required this.maxDCPower,
    required this.efficiency,
    required this.minMPPVoltage,
    required this.maxMPPVoltage,
    required this.numberOfMPPTrackers,
    required this.type,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'manufacturer': manufacturer,
      'model': model,
      'ratedPowerAC': ratedPowerAC,
      'maxDCPower': maxDCPower,
      'efficiency': efficiency,
      'minMPPVoltage': minMPPVoltage,
      'maxMPPVoltage': maxMPPVoltage,
      'numberOfMPPTrackers': numberOfMPPTrackers,
      'type': type.toString().split('.').last,
    };
  }
  
  factory Inverter.fromJson(Map<String, dynamic> json) {
    return Inverter(
      id: json['id'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      ratedPowerAC: json['ratedPowerAC'],
      maxDCPower: json['maxDCPower'],
      efficiency: json['efficiency'],
      minMPPVoltage: json['minMPPVoltage'],
      maxMPPVoltage: json['maxMPPVoltage'],
      numberOfMPPTrackers: json['numberOfMPPTrackers'],
      type: InverterType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
    );
  }
}

enum InverterType {
  string,
  central,
  microinverter,
  hybrid,
}