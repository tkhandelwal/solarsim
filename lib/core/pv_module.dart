// lib/core/pv_module.dart
// import 'dart:math' as math;
import '../models/solar_module.dart';

/// Models the performance of PV modules
class PVModule {
  /// Calculate the cell temperature based on ambient temperature and irradiance
  /// using the NOCT (Nominal Operating Cell Temperature) model
  static double calculateCellTemperature({
    required double ambientTemp,
    required double irradiance,
    required double noct,
    double windSpeed = 1.0,
  }) {
    // Standard conditions for NOCT
    const standardIrradiance = 800.0; // W/m²
    const standardAmbient = 20.0; // °C
    const standardWindSpeed = 1.0; // m/s
    
    // Calculate temperature difference between cell and ambient
    final tempDiff = (noct - standardAmbient) * (irradiance / standardIrradiance) * 
                    (standardWindSpeed / windSpeed) * 0.6;
    
    // Return cell temperature
    return ambientTemp + tempDiff;
  }
  
  /// Calculate the maximum power output of a PV module based on irradiance and temperature
  static double calculatePowerOutput({
    required SolarModule module,
    required double irradiance,
    required double cellTemp,
    double standardIrradiance = 1000.0, // W/m²
    double standardTemp = 25.0, // °C
  }) {
    // Irradiance ratio
    final irradianceRatio = irradiance / standardIrradiance;
    
    // Temperature difference from standard test conditions
    final tempDiff = cellTemp - standardTemp;
    
    // Temperature correction factor
    final tempCorrectionFactor = 1 + module.temperatureCoefficient / 100 * tempDiff;
    
    // Calculate power output
    return module.powerRating * irradianceRatio * tempCorrectionFactor;
  }
  
  /// Calculate module efficiency based on temperature
  static double calculateEfficiency({
    required SolarModule module, 
    required double cellTemp,
    double standardTemp = 25.0, // °C
  }) {
    // Temperature difference from standard test conditions
    final tempDiff = cellTemp - standardTemp;
    
    // Calculate efficiency with temperature correction
    return module.efficiency * (1 + module.temperatureCoefficient / 100 * tempDiff);
  }
  
  /// Calculate the I-V curve parameters based on temperature and irradiance
  static IVCurveParameters calculateIVCurveParameters({
    required SolarModule module,
    required double irradiance,
    required double cellTemp,
    double standardIrradiance = 1000.0, // W/m²
    double standardTemp = 25.0, // °C
  }) {
    // Irradiance ratio
    final irradianceRatio = irradiance / standardIrradiance;
    
    // Temperature difference from standard test conditions
    final tempDiff = cellTemp - standardTemp;
    
    // Assume standard parameters for demonstration
    // In a real implementation, these would be derived from the module datasheet
    final voc = 40.0 * (1 - 0.0035 * tempDiff);
    final isc = 10.0 * irradianceRatio * (1 + 0.0005 * tempDiff);
    final vmp = 33.0 * (1 - 0.004 * tempDiff);
    final imp = 9.5 * irradianceRatio * (1 + 0.0003 * tempDiff);
    
    return IVCurveParameters(
      voc: voc,
      isc: isc,
      vmp: vmp,
      imp: imp,
      pmp: vmp * imp,
      ff: (vmp * imp) / (voc * isc),
    );
  }
}

class IVCurveParameters {
  final double voc;  // Open-circuit voltage
  final double isc;  // Short-circuit current
  final double vmp;  // Voltage at maximum power
  final double imp;  // Current at maximum power
  final double pmp;  // Maximum power
  final double ff;   // Fill factor
  
  IVCurveParameters({
    required this.voc,
    required this.isc,
    required this.vmp,
    required this.imp,
    required this.pmp,
    required this.ff,
  });
  
  @override
  String toString() {
    return 'I-V Curve Parameters:\n'
      '  Voc: ${voc.toStringAsFixed(2)} V\n'
      '  Isc: ${isc.toStringAsFixed(2)} A\n'
      '  Vmp: ${vmp.toStringAsFixed(2)} V\n'
      '  Imp: ${imp.toStringAsFixed(2)} A\n'
      '  Pmp: ${pmp.toStringAsFixed(2)} W\n'
      '  FF: ${(ff * 100).toStringAsFixed(2)} %';
  }
}