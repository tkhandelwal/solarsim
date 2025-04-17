// lib/core/inverter_model.dart
import '../models/inverter.dart';

/// Models the performance of PV inverters
class InverterModel {
  /// Calculate the AC power output of an inverter
  static double calculateACPowerOutput({
    required Inverter inverter,
    required double dcPowerInput,
    double lowLoadEfficiencyFactor = 0.95, // Efficiency factor for low load conditions
  }) {
    // Calculate the loading ratio
    final loadRatio = dcPowerInput / inverter.ratedPowerAC;
    
    // Apply efficiency based on loading ratio
    double efficiency;
    
    if (loadRatio <= 0.1) {
      // Low load efficiency is typically lower
      efficiency = inverter.efficiency * lowLoadEfficiencyFactor;
    } else if (loadRatio > 1.0) {
      // Inverter is clipping - output is limited to rated AC power
      return inverter.ratedPowerAC;
    } else {
      // Normal operation - use rated efficiency
      efficiency = inverter.efficiency;
    }
    
    // Calculate AC power output
    return dcPowerInput * efficiency;
  }
  
  /// Calculate inverter clipping loss
  static double calculateClippingLoss({
    required Inverter inverter,
    required double dcPowerInput,
  }) {
    if (dcPowerInput > inverter.ratedPowerAC) {
      // Calculate clipping loss (DC power above AC rating)
      return dcPowerInput - inverter.ratedPowerAC;
    } else {
      // No clipping
      return 0.0;
    }
  }
  
  /// Calculate total inverter losses
  static InverterLosses calculateInverterLosses({
    required Inverter inverter,
    required double dcPowerInput,
    double lowLoadEfficiencyFactor = 0.95,
  }) {
    // Calculate AC power output
    final acPowerOutput = calculateACPowerOutput(
      inverter: inverter,
      dcPowerInput: dcPowerInput,
      lowLoadEfficiencyFactor: lowLoadEfficiencyFactor,
    );
    
    // Calculate conversion loss
    final conversionLoss = dcPowerInput - acPowerOutput;
    
    // Calculate clipping loss
    final clippingLoss = calculateClippingLoss(
      inverter: inverter,
      dcPowerInput: dcPowerInput,
    );
    
    // Calculate efficiency at this operating point
    final efficiency = dcPowerInput > 0 ? acPowerOutput / dcPowerInput : 0.0;
    
    return InverterLosses(
      conversionLoss: conversionLoss,
      clippingLoss: clippingLoss,
      totalLoss: conversionLoss + clippingLoss,
      efficiency: efficiency,
    );
  }
}

class InverterLosses {
  final double conversionLoss;
  final double clippingLoss;
  final double totalLoss;
  final double efficiency;
  
  InverterLosses({
    required this.conversionLoss,
    required this.clippingLoss,
    required this.totalLoss,
    required this.efficiency,
  });
  
  @override
  String toString() {
    return 'Inverter Losses:\n'
      '  Conversion loss: ${conversionLoss.toStringAsFixed(2)} W\n'
      '  Clipping loss: ${clippingLoss.toStringAsFixed(2)} W\n'
      '  Total loss: ${totalLoss.toStringAsFixed(2)} W\n'
      '  Efficiency: ${(efficiency * 100).toStringAsFixed(2)} %';
  }
}