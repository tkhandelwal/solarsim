// lib/core/pv_array.dart
import '../models/solar_module.dart';
import '../models/inverter.dart';
import 'pv_module.dart';

/// Models the performance of a PV array (multiple modules connected together)
class PVArray {
  /// Calculate the DC power output of a PV array
  static double calculateDCPowerOutput({
    required SolarModule module,
    required int modulesInSeries,
    required int stringsInParallel,
    required double irradiance,
    required double cellTemp,
    double mismatchLoss = 0.02, // 2% loss due to module mismatch
    double wiringLoss = 0.02,    // 2% loss due to DC wiring
    double soilingLoss = 0.03,   // 3% loss due to soiling
    double shadingLoss = 0.0,    // Shading loss (0% by default)
  }) {
    // Calculate power output of a single module
    final modulePower = PVModule.calculatePowerOutput(
      module: module,
      irradiance: irradiance,
      cellTemp: cellTemp,
    );
    
    // Calculate array DC power (before losses)
    final arrayDCPower = modulePower * modulesInSeries * stringsInParallel;
    
    // Apply DC losses
    final arrayDCPowerWithLosses = arrayDCPower * 
      (1 - mismatchLoss) * 
      (1 - wiringLoss) * 
      (1 - soilingLoss) * 
      (1 - shadingLoss);
    
    return arrayDCPowerWithLosses;
  }
  
  /// Check if the array configuration is compatible with the inverter
  static ArraySizingResult checkInverterCompatibility({
    required SolarModule module,
    required Inverter inverter,
    required int modulesInSeries,
    required int stringsInParallel,
    double minTemp = -10.0, // °C
    double maxTemp = 75.0,  // °C
  }) {
    // Calculate array parameters
    final totalModules = modulesInSeries * stringsInParallel;
    final arrayDCPower = module.powerRating * totalModules;
    
    // Calculate minimum and maximum voltage at extreme temperatures
    // Assume a temperature coefficient of -0.35%/°C for Voc
    const voc25 = 40.0; // Example Voc at 25°C
    const vocTempCoeff = -0.0035; // -0.35%/°C
    
    // Voc at minimum temperature
    final vocMin = voc25 * (1 + vocTempCoeff * (minTemp - 25.0));
    final maxVoltageAtMinTemp = vocMin * modulesInSeries;
    
    // Vmp at maximum temperature
    const vmp25 = 33.0; // Example Vmp at 25°C
    const vmpTempCoeff = -0.004; // -0.40%/°C
    final vmpMax = vmp25 * (1 + vmpTempCoeff * (maxTemp - 25.0));
    final minVoltageAtMaxTemp = vmpMax * modulesInSeries;
    
    // Check inverter voltage limits
    final isVoltageInRange = minVoltageAtMaxTemp >= inverter.minMPPVoltage &&
                             maxVoltageAtMinTemp <= inverter.maxMPPVoltage;
    
    // Check inverter power
    final dcToAcRatio = arrayDCPower / inverter.ratedPowerAC;
    final isPowerInRange = arrayDCPower <= inverter.maxDCPower;
    
    // Return sizing result
    return ArraySizingResult(
      modulesInSeries: modulesInSeries,
      stringsInParallel: stringsInParallel,
      totalModules: totalModules,
      arrayDCPower: arrayDCPower,
      maxArrayVoltage: maxVoltageAtMinTemp,
      minArrayVoltage: minVoltageAtMaxTemp,
      dcToAcRatio: dcToAcRatio,
      isVoltageInRange: isVoltageInRange,
      isPowerInRange: isPowerInRange,
      isValid: isVoltageInRange && isPowerInRange,
    );
  }
  
  /// Calculate the optimal number of modules in series for an inverter
  static int calculateOptimalModulesInSeries({
    required SolarModule module,
    required Inverter inverter,
    double minTemp = -10.0, // °C
    double maxTemp = 75.0,  // °C
  }) {
    // Assume standard module parameters for demonstration
    const voc25 = 40.0; // Example Voc at 25°C
    const vocTempCoeff = -0.0035; // -0.35%/°C
    const vmp25 = 33.0; // Example Vmp at 25°C
    const vmpTempCoeff = -0.004; // -0.40%/°C
    
    // Voc at minimum temperature
    final vocMin = voc25 * (1 + vocTempCoeff * (minTemp - 25.0));
    
    // Vmp at maximum temperature
    final vmpMax = vmp25 * (1 + vmpTempCoeff * (maxTemp - 25.0));
    
    // Calculate maximum modules in series based on max voltage
    final maxModulesVoc = (inverter.maxMPPVoltage / vocMin).floor();
    
    // Calculate minimum modules in series based on min voltage
    final minModulesVmp = (inverter.minMPPVoltage / vmpMax).ceil();
    
    // Return optimal value within range
    if (minModulesVmp <= maxModulesVoc) {
      // Choose a value midway between min and max
      return ((minModulesVmp + maxModulesVoc) / 2).round();
    } else {
      // No valid configuration
      return -1;
    }
  }
  
  /// Calculate the optimal number of strings in parallel for an inverter
  static int calculateOptimalStringsInParallel({
    required SolarModule module,
    required Inverter inverter,
    required int modulesInSeries,
  }) {
    // Calculate optimal strings to match inverter power
    final modulePower = module.powerRating;
    final stringPower = modulePower * modulesInSeries;
    
    // Target a DC/AC ratio of 1.2
    final targetDCPower = inverter.ratedPowerAC * 1.2;
    
    // Calculate optimal number of strings
    final optimalStrings = (targetDCPower / stringPower).round();
    
    // Check not to exceed inverter max DC power
    final maxStrings = (inverter.maxDCPower / stringPower).floor();
    
    return optimalStrings < maxStrings ? optimalStrings : maxStrings;
  }
}

class ArraySizingResult {
  final int modulesInSeries;
  final int stringsInParallel;
  final int totalModules;
  final double arrayDCPower;
  final double maxArrayVoltage;
  final double minArrayVoltage;
  final double dcToAcRatio;
  final bool isVoltageInRange;
  final bool isPowerInRange;
  final bool isValid;
  
  ArraySizingResult({
    required this.modulesInSeries,
    required this.stringsInParallel,
    required this.totalModules,
    required this.arrayDCPower,
    required this.maxArrayVoltage,
    required this.minArrayVoltage,
    required this.dcToAcRatio,
    required this.isVoltageInRange,
    required this.isPowerInRange,
    required this.isValid,
  });
  
  @override
  String toString() {
    return 'Array Sizing Result:\n'
      '  Modules in series: $modulesInSeries\n'
      '  Strings in parallel: $stringsInParallel\n'
      '  Total modules: $totalModules\n'
      '  Array DC power: ${arrayDCPower.toStringAsFixed(2)} W\n'
      '  Max array voltage: ${maxArrayVoltage.toStringAsFixed(2)} V\n'
      '  Min array voltage: ${minArrayVoltage.toStringAsFixed(2)} V\n'
      '  DC/AC ratio: ${dcToAcRatio.toStringAsFixed(2)}\n'
      '  Voltage in range: $isVoltageInRange\n'
      '  Power in range: $isPowerInRange\n'
      '  Valid configuration: $isValid';
  }
}