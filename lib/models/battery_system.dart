// lib/models/battery_system.dart

/// Battery chemistry types
enum BatteryChemistry {
  lithiumIon,
  lithiumIronPhosphate,
  leadAcid,
  flowBattery,
  sodiumIon,
}

/// Battery operation modes
enum BatteryControlStrategy {
  selfConsumption,   // Maximize self-consumption of PV energy
  timeOfUse,         // Charge/discharge based on electricity price
  peakShaving,       // Reduce grid demand peaks
  backup,            // Prioritize backup power
  gridServices,      // Provide grid services (frequency regulation, etc.)
}

/// Battery system specifications
class BatterySystem {
  final String id;
  final String manufacturer;
  final String model;
  final double capacity;            // kWh - usable capacity
  final double nominalCapacity;     // kWh - nominal capacity before DoD limits
  final double maxChargePower;      // kW
  final double maxDischargePower;   // kW
  final double roundTripEfficiency; // % as decimal (0-1)
  final double maxDepthOfDischarge; // % as decimal (0-1)
  final double selfDischargeRate;   // % per day as decimal
  final int cycleLife;              // number of full equivalent cycles
  final int calendarLifeYears;      // calendar life in years
  final BatteryChemistry chemistry;
  final double costPerKwh;          // $ per kWh
  final double installationCost;    // $ fixed cost
  
  /// Default constructor
  BatterySystem({
    required this.id,
    required this.manufacturer,
    required this.model,
    required this.capacity,
    required this.maxChargePower,
    required this.maxDischargePower,
    required this.roundTripEfficiency,
    required this.maxDepthOfDischarge,
    required this.selfDischargeRate,
    required this.cycleLife,
    required this.calendarLifeYears,
    required this.chemistry,
    required this.costPerKwh,
    required this.installationCost,
    double? nominalCapacity,
  }) : nominalCapacity = nominalCapacity ?? capacity / maxDepthOfDischarge;
  
  /// Total system cost
  double get totalCost => (capacity * costPerKwh) + installationCost;
  
  /// Cost per usable kWh
  double get effectiveCostPerKwh => totalCost / capacity;
  
  /// Create a copy with updated values
  BatterySystem copyWith({
    String? id,
    String? manufacturer,
    String? model,
    double? capacity,
    double? nominalCapacity,
    double? maxChargePower,
    double? maxDischargePower,
    double? roundTripEfficiency,
    double? maxDepthOfDischarge,
    double? selfDischargeRate,
    int? cycleLife,
    int? calendarLifeYears,
    BatteryChemistry? chemistry,
    double? costPerKwh,
    double? installationCost,
  }) {
    return BatterySystem(
      id: id ?? this.id,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      capacity: capacity ?? this.capacity,
      nominalCapacity: nominalCapacity ?? this.nominalCapacity,
      maxChargePower: maxChargePower ?? this.maxChargePower,
      maxDischargePower: maxDischargePower ?? this.maxDischargePower,
      roundTripEfficiency: roundTripEfficiency ?? this.roundTripEfficiency,
      maxDepthOfDischarge: maxDepthOfDischarge ?? this.maxDepthOfDischarge,
      selfDischargeRate: selfDischargeRate ?? this.selfDischargeRate,
      cycleLife: cycleLife ?? this.cycleLife,
      calendarLifeYears: calendarLifeYears ?? this.calendarLifeYears,
      chemistry: chemistry ?? this.chemistry,
      costPerKwh: costPerKwh ?? this.costPerKwh,
      installationCost: installationCost ?? this.installationCost,
    );
  }
  
  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'manufacturer': manufacturer,
      'model': model,
      'capacity': capacity,
      'nominalCapacity': nominalCapacity,
      'maxChargePower': maxChargePower,
      'maxDischargePower': maxDischargePower,
      'roundTripEfficiency': roundTripEfficiency,
      'maxDepthOfDischarge': maxDepthOfDischarge,
      'selfDischargeRate': selfDischargeRate,
      'cycleLife': cycleLife,
      'calendarLifeYears': calendarLifeYears,
      'chemistry': chemistry.toString().split('.').last,
      'costPerKwh': costPerKwh,
      'installationCost': installationCost,
    };
  }
  
  /// From JSON
  factory BatterySystem.fromJson(Map<String, dynamic> json) {
    return BatterySystem(
      id: json['id'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      capacity: json['capacity'],
      nominalCapacity: json['nominalCapacity'],
      maxChargePower: json['maxChargePower'],
      maxDischargePower: json['maxDischargePower'],
      roundTripEfficiency: json['roundTripEfficiency'],
      maxDepthOfDischarge: json['maxDepthOfDischarge'],
      selfDischargeRate: json['selfDischargeRate'],
      cycleLife: json['cycleLife'],
      calendarLifeYears: json['calendarLifeYears'],
      chemistry: BatteryChemistry.values.firstWhere(
        (e) => e.toString().split('.').last == json['chemistry'],
        orElse: () => BatteryChemistry.lithiumIon,
      ),
      costPerKwh: json['costPerKwh'],
      installationCost: json['installationCost'],
    );
  }
  
  /// Default battery systems factory
  static BatterySystem defaultLithiumIon({double capacity = 10.0}) {
    return BatterySystem(
      id: 'default_li_ion_${capacity.toInt()}',
      manufacturer: 'Generic',
      model: 'Lithium Ion ${capacity.toInt()} kWh',
      capacity: capacity,
      maxChargePower: capacity * 0.5, // 0.5C rate
      maxDischargePower: capacity * 0.5, // 0.5C rate
      roundTripEfficiency: 0.92,
      maxDepthOfDischarge: 0.9,
      selfDischargeRate: 0.002, // 0.2% per day
      cycleLife: 4000,
      calendarLifeYears: 10,
      chemistry: BatteryChemistry.lithiumIon,
      costPerKwh: 500,
      installationCost: 1000,
    );
  }
  
  static BatterySystem defaultLFP({double capacity = 10.0}) {
    return BatterySystem(
      id: 'default_lfp_${capacity.toInt()}',
      manufacturer: 'Generic',
      model: 'LiFePO4 ${capacity.toInt()} kWh',
      capacity: capacity,
      maxChargePower: capacity * 0.3, // 0.3C rate
      maxDischargePower: capacity * 0.5, // 0.5C rate
      roundTripEfficiency: 0.94,
      maxDepthOfDischarge: 0.95,
      selfDischargeRate: 0.001, // 0.1% per day
      cycleLife: 6000,
      calendarLifeYears: 15,
      chemistry: BatteryChemistry.lithiumIronPhosphate,
      costPerKwh: 450,
      installationCost: 1000,
    );
  }
}