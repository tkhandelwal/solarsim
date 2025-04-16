// lib/core/solar_position.dart
import 'dart:math' as math;

/// Calculates the solar position for a given date, time and location
class SolarPosition {
  /// Calculate the solar declination angle in radians
  /// This is the angle between the rays of the sun and the equatorial plane of the earth
  static double calculateDeclination(DateTime dateTime) {
    // Day of the year (1-365)
    final dayOfYear = dateTime.difference(DateTime(dateTime.year, 1, 1)).inDays + 1;
    
    // Solar declination angle calculation (in radians)
    return 23.45 * math.pi / 180 * math.sin(2 * math.pi * (284 + dayOfYear) / 365);
  }
  
  /// Calculate the equation of time in minutes
  /// This accounts for the discrepancy between solar time and mean solar time
  static double calculateEquationOfTime(DateTime dateTime) {
    // Day of the year (1-365)
    final dayOfYear = dateTime.difference(DateTime(dateTime.year, 1, 1)).inDays + 1;
    
    // Convert day of year to radians
    final b = 2 * math.pi * (dayOfYear - 81) / 364;
    
    // Calculate equation of time in minutes
    return 9.87 * math.sin(2 * b) - 7.53 * math.cos(b) - 1.5 * math.sin(b);
  }
  
  /// Calculate the solar hour angle in radians
  /// This is the angular displacement of the sun east or west of the local meridian
  static double calculateHourAngle(DateTime dateTime, double longitude, double timeZoneOffset) {
    // Get the equation of time
    final eot = calculateEquationOfTime(dateTime);
    
    // Calculate the time offset from solar noon in minutes
    final solarNoonOffset = 4 * (longitude - (15 * timeZoneOffset)) + eot;
    
    // Calculate the time from solar noon in minutes
    final timeFromSolarNoon = 
        (dateTime.hour * 60 + dateTime.minute + dateTime.second / 60) - (12 * 60 + solarNoonOffset);
    
    // Convert to hour angle in radians (15 degrees per hour)
    return timeFromSolarNoon * 15 / 60 * math.pi / 180;
  }
  
  /// Calculate the solar zenith angle in radians
  /// This is the angle between the vertical and the line to the sun
  static double calculateZenithAngle(double latitude, double declination, double hourAngle) {
    final latRad = latitude * math.pi / 180;
    
    // Calculate the cosine of the zenith angle
    final cosZenith = math.sin(latRad) * math.sin(declination) + 
                      math.cos(latRad) * math.cos(declination) * math.cos(hourAngle);
    
    // Return the zenith angle in radians
    return math.acos(math.max(-1, math.min(1, cosZenith)));
  }
  
  /// Calculate the solar azimuth angle in radians
  /// This is the angle in the horizontal plane from due north in clockwise direction
  static double calculateAzimuthAngle(double latitude, double declination, double hourAngle, double zenithAngle) {
    final latRad = latitude * math.pi / 180;
    
    // Calculate the cosine of the azimuth angle
    final cosAzimuth = (math.sin(declination) * math.cos(latRad) - 
                      math.cos(declination) * math.sin(latRad) * math.cos(hourAngle)) / 
                      math.sin(zenithAngle);
    
    // Calculate basic azimuth (in radians)
    double azimuth = math.acos(math.max(-1, math.min(1, cosAzimuth)));
    
    // Adjust for the afternoon
    if (hourAngle > 0) {
      azimuth = 2 * math.pi - azimuth;
    }
    
    return azimuth;
  }
  
  /// Calculate the solar elevation angle in radians
  /// This is the angle between the horizontal and the line to the sun
  static double calculateElevationAngle(double zenithAngle) {
    return math.pi / 2 - zenithAngle;
  }
  
  /// Calculate the sunrise time for a given date and location
  static DateTime calculateSunriseTime(DateTime date, double latitude, double longitude, double timeZoneOffset) {
    // Day of the year (1-365)
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    
    // Solar declination
    final declination = calculateDeclination(DateTime(date.year, date.month, date.day, 12));
    
    // Hour angle at sunrise (in radians)
    final latRad = latitude * math.pi / 180;
    final sunriseHourAngle = math.acos(-math.tan(latRad) * math.tan(declination));
    
    // Convert hour angle to hours
    final sunriseHourAngleDeg = sunriseHourAngle * 180 / math.pi;
    final sunriseHours = sunriseHourAngleDeg / 15;
    
    // Equation of time
    final eot = calculateEquationOfTime(date);
    
    // Time offset from solar noon in minutes
    final solarNoonOffset = 4 * (longitude - (15 * timeZoneOffset)) + eot;
    
    // Calculate sunrise time in minutes from midnight
    final sunriseMinutes = (12 * 60 - sunriseHours * 60) - solarNoonOffset;
    
    // Convert to hours and minutes
    final sunriseHour = (sunriseMinutes / 60).floor();
    final sunriseMinute = (sunriseMinutes % 60).round();
    
    // Create datetime
    return DateTime(date.year, date.month, date.day, sunriseHour, sunriseMinute);
  }
  
  /// Calculate the sunset time for a given date and location
  static DateTime calculateSunsetTime(DateTime date, double latitude, double longitude, double timeZoneOffset) {
    // Day of the year (1-365)
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    
    // Solar declination
    final declination = calculateDeclination(DateTime(date.year, date.month, date.day, 12));
    
    // Hour angle at sunset (in radians)
    final latRad = latitude * math.pi / 180;
    final sunsetHourAngle = math.acos(-math.tan(latRad) * math.tan(declination));
    
    // Convert hour angle to hours
    final sunsetHourAngleDeg = sunsetHourAngle * 180 / math.pi;
    final sunsetHours = sunsetHourAngleDeg / 15;
    
    // Equation of time
    final eot = calculateEquationOfTime(date);
    
    // Time offset from solar noon in minutes
    final solarNoonOffset = 4 * (longitude - (15 * timeZoneOffset)) + eot;
    
    // Calculate sunset time in minutes from midnight
    final sunsetMinutes = (12 * 60 + sunsetHours * 60) - solarNoonOffset;
    
    // Convert to hours and minutes
    final sunsetHour = (sunsetMinutes / 60).floor();
    final sunsetMinute = (sunsetMinutes % 60).round();
    
    // Create datetime
    return DateTime(date.year, date.month, date.day, sunsetHour, sunsetMinute);
  }
  
  /// Calculate complete solar position data for a given date, time and location
  static SolarPositionResult calculate({
    required DateTime dateTime,
    required double latitude,
    required double longitude,
    required double timeZoneOffset,
  }) {
    // Calculate declination angle
    final declination = calculateDeclination(dateTime);
    
    // Calculate the hour angle
    final hourAngle = calculateHourAngle(dateTime, longitude, timeZoneOffset);
    
    // Calculate the zenith angle
    final zenithAngle = calculateZenithAngle(latitude, declination, hourAngle);
    
    // Calculate the azimuth angle
    final azimuthAngle = calculateAzimuthAngle(latitude, declination, hourAngle, zenithAngle);
    
    // Calculate the elevation angle
    final elevationAngle = calculateElevationAngle(zenithAngle);
    
    // Calculate sunrise and sunset times
    final dateMidnight = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final sunrise = calculateSunriseTime(dateMidnight, latitude, longitude, timeZoneOffset);
    final sunset = calculateSunsetTime(dateMidnight, latitude, longitude, timeZoneOffset);
    
    // Return results
    return SolarPositionResult(
      declination: declination,
      hourAngle: hourAngle,
      zenithAngle: zenithAngle,
      azimuthAngle: azimuthAngle,
      elevationAngle: elevationAngle,
      sunriseTime: sunrise,
      sunsetTime: sunset,
    );
  }
}

class SolarPositionResult {
  final double declination;    // radians
  final double hourAngle;      // radians
  final double zenithAngle;    // radians
  final double azimuthAngle;   // radians
  final double elevationAngle; // radians
  final DateTime sunriseTime;
  final DateTime sunsetTime;
  
  SolarPositionResult({
    required this.declination,
    required this.hourAngle,
    required this.zenithAngle,
    required this.azimuthAngle,
    required this.elevationAngle,
    required this.sunriseTime,
    required this.sunsetTime,
  });
  
  // Convert angles to degrees for display
  double get declinationDeg => declination * 180 / math.pi;
  double get hourAngleDeg => hourAngle * 180 / math.pi;
  double get zenithDeg => zenithAngle * 180 / math.pi;
  double get azimuthDeg => azimuthAngle * 180 / math.pi;
  double get elevationDeg => elevationAngle * 180 / math.pi;
  
  // Daylight hours (decimal)
  double get daylightHours {
    final difference = sunsetTime.difference(sunriseTime);
    return difference.inMinutes / 60;
  }
  
  // Check if the sun is up at the given time
  bool get isSunUp => elevationAngle > 0;
  
  @override
  String toString() {
    return 'Solar Position:\n'
      '  Declination: ${declinationDeg.toStringAsFixed(2)}°\n'
      '  Hour angle: ${hourAngleDeg.toStringAsFixed(2)}°\n'
      '  Zenith angle: ${zenithDeg.toStringAsFixed(2)}°\n'
      '  Azimuth angle: ${azimuthDeg.toStringAsFixed(2)}°\n'
      '  Elevation angle: ${elevationDeg.toStringAsFixed(2)}°\n'
      '  Sunrise: ${sunriseTime.hour}:${sunriseTime.minute.toString().padLeft(2, '0')}\n'
      '  Sunset: ${sunsetTime.hour}:${sunsetTime.minute.toString().padLeft(2, '0')}\n'
      '  Daylight hours: ${daylightHours.toStringAsFixed(2)}';
  }
}

// lib/core/irradiance.dart
import 'dart:math' as math;

/// Models for calculating solar irradiance on surfaces
class Irradiance {
  /// Calculate the extraterrestrial radiation in W/m²
  /// This is the solar radiation available outside the Earth's atmosphere
  static double calculateExtraterrestrialIrradiance(DateTime dateTime) {
    // Day of the year (1-365)
    final dayOfYear = dateTime.difference(DateTime(dateTime.year, 1, 1)).inDays + 1;
    
    // Solar constant (W/m²)
    const solarConstant = 1367.0;
    
    // Account for the Earth-Sun distance variation
    final distance = 1 + 0.033 * math.cos(2 * math.pi * dayOfYear / 365);
    
    // Return extraterrestrial irradiance
    return solarConstant * distance;
  }
  
  /// Calculate diffuse fraction using the Erbs correlation
  /// This estimates the ratio of diffuse to global horizontal irradiance
  static double calculateDiffuseFraction(double kt) {
    if (kt <= 0.22) {
      return 1.0 - 0.09 * kt;
    } else if (kt <= 0.80) {
      return 0.9511 - 0.1604 * kt + 4.388 * kt * kt - 
             16.638 * kt * kt * kt + 12.336 * kt * kt * kt * kt;
    } else {
      return 0.165;
    }
  }
  
  /// Calculate global irradiance on a tilted surface using the Perez model
  /// This models the amount of solar radiation reaching a tilted surface
  static double calculateTiltedIrradiance({
    required double globalHorizontal,
    required double diffuseHorizontal,
    required double solarZenith,
    required double solarAzimuth,
    required double tiltAngle,
    required double tiltAzimuth,
    required double albedo,
  }) {
    // Convert to radians
    final zenithRad = solarZenith * math.pi / 180;
    final azimuthRad = solarAzimuth * math.pi / 180;
    final tiltRad = tiltAngle * math.pi / 180;
    final tiltAzimuthRad = tiltAzimuth * math.pi / 180;
    
    // Calculate direct normal irradiance if sun is above horizon
    double beamNormal = 0;
    if (zenithRad < math.pi / 2) {
      // Calculate beam horizontal irradiance
      final beamHorizontal = globalHorizontal - diffuseHorizontal;
      
      // Convert to beam normal
      beamNormal = beamHorizontal / math.cos(zenithRad);
    }
    
    // Calculate incidence angle on the tilted surface
    final cosTiltIncidence = math.cos(zenithRad) * math.cos(tiltRad) + 
                            math.sin(zenithRad) * math.sin(tiltRad) * 
                            math.cos(azimuthRad - tiltAzimuthRad);
    
    // Calculate beam component on the tilted surface
    final beamTilted = beamNormal * math.max(0, cosTiltIncidence);
    
    // Calculate ground-reflected component
    final groundReflected = globalHorizontal * albedo * (1 - math.cos(tiltRad)) / 2;
    
    // Calculate diffuse component on the tilted surface (isotropic model for simplicity)
    final diffuseTilted = diffuseHorizontal * (1 + math.cos(tiltRad)) / 2;
    
    // Return total irradiance on the tilted surface
    return beamTilted + diffuseTilted + groundReflected;
  }
  
  /// Calculate the clearness index (kt)
  /// This is the ratio of global horizontal irradiance to extraterrestrial irradiance
  static double calculateClearnessIndex(
    double globalHorizontal,
    double extraterrestrialHorizontal,
  ) {
    if (extraterrestrialHorizontal > 0) {
      return globalHorizontal / extraterrestrialHorizontal;
    } else {
      return 0.0;
    }
  }
}

// lib/core/pv_module.dart
import 'dart:math' as math;
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
    final voc25 = 40.0; // Example Voc at 25°C
    final vocTempCoeff = -0.0035; // -0.35%/°C
    
    // Voc at minimum temperature
    final vocMin = voc25 * (1 + vocTempCoeff * (minTemp - 25.0));
    final maxVoltageAtMinTemp = vocMin * modulesInSeries;
    
    // Vmp at maximum temperature
    final vmp25 = 33.0; // Example Vmp at 25°C
    final vmpTempCoeff = -0.004; // -0.40%/°C
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
    final voc25 = 40.0; // Example Voc at 25°C
    final vocTempCoeff = -0.0035; // -0.35%/°C
    final vmp25 = 33.0; // Example Vmp at 25°C
    final vmpTempCoeff = -0.004; // -0.40%/°C
    
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

// lib/core/pv_system_simulator.dart
import 'dart:math' as math;
import '../models/project.dart';
import '../models/solar_module.dart';
import '../models/inverter.dart';
import 'solar_position.dart';
import 'irradiance.dart';
import 'pv_module.dart';
import 'pv_array.dart';
import 'inverter_model.dart';

/// Main simulator class for PV systems
class PVSystemSimulator {
  // Project data
  final Project project;
  
  // System components
  final SolarModule module;
  final Inverter inverter;
  final int modulesInSeries;
  final int stringsInParallel;
  
  // System configuration
  final double tiltAngle;        // degrees
  final double azimuthAngle;     // degrees from north (0°) clockwise
  final double groundAlbedo;     // ground reflectivity (0-1)
  
  // Loss factors
  final double soilingLoss;      // Soiling loss (0-1)
  final double shadingLoss;      // Shading loss (0-1)
  final double mismatchLoss;     // Module mismatch loss (0-1)
  final double dcWiringLoss;     // DC wiring loss (0-1)
  final double acWiringLoss;     // AC wiring loss (0-1)
  final double systemAvailability; // System availability (0-1)
  final double annualDegradation; // Annual degradation rate (0-1)
  
  PVSystemSimulator({
    required this.project,
    required this.module,
    required this.inverter,
    required this.modulesInSeries,
    required this.stringsInParallel,
    required this.tiltAngle,
    required this.azimuthAngle,
    this.groundAlbedo = 0.2,
    this.soilingLoss = 0.02,
    this.shadingLoss = 0.03,
    this.mismatchLoss = 0.02,
    this.dcWiringLoss = 0.02,
    this.acWiringLoss = 0.01,
    this.systemAvailability = 0.98,
    this.annualDegradation = 0.005,
  });
  
  /// Simulate PV system performance for a specific hour
  HourlySimulationResult simulateHour({
    required DateTime dateTime,
    required double globalHorizontalIrradiance,
    required double diffuseHorizontalIrradiance,
    required double ambientTemperature,
    required double windSpeed,
  }) {
    // Extract location data
    final latitude = project.location.latitude;
    final longitude = project.location.longitude;
    final timeZoneOffset = 0; // Simplified - in real app get from timeZone string
    
    // Calculate solar position
    final solarPos = SolarPosition.calculate(
      dateTime: dateTime,
      latitude: latitude,
      longitude: longitude,
      timeZoneOffset: timeZoneOffset,
    );
    
    // Check if sun is up
    if (!solarPos.isSunUp) {
      return HourlySimulationResult(
        dateTime: dateTime,
        globalHorizontalIrradiance: 0,
        planeOfArrayIrradiance: 0,
        ambientTemperature: ambientTemperature,
        cellTemperature: ambientTemperature,
        dcPower: 0,
        acPower: 0,
        efficiency: 0,
        performanceRatio: 0,
      );
    }
    
    // Calculate irradiance on tilted surface
    final poaIrradiance = Irradiance.calculateTiltedIrradiance(
      globalHorizontal: globalHorizontalIrradiance,
      diffuseHorizontal: diffuseHorizontalIrradiance,
      solarZenith: solarPos.zenithDeg,
      solarAzimuth: solarPos.azimuthDeg,
      tiltAngle: tiltAngle,
      tiltAzimuth: azimuthAngle,
      albedo: groundAlbedo,
    );
    
    // Calculate PV cell temperature
    final cellTemp = PVModule.calculateCellTemperature(
      ambientTemp: ambientTemperature,
      irradiance: poaIrradiance,
      noct: module.nominalOperatingCellTemp,
      windSpeed: windSpeed,
    );
    
    // Calculate DC power output
    final dcPower = PVArray.calculateDCPowerOutput(
      module: module,
      modulesInSeries: modulesInSeries,
      stringsInParallel: stringsInParallel,
      irradiance: poaIrradiance,
      cellTemp: cellTemp,
      mismatchLoss: mismatchLoss,
      wiringLoss: dcWiringLoss,
      soilingLoss: soilingLoss,
      shadingLoss: shadingLoss,
    );
    
    // Calculate AC power output
    final acPower = InverterModel.calculateACPowerOutput(
      inverter: inverter,
      dcPowerInput: dcPower,
    ) * (1 - acWiringLoss) * systemAvailability;
    
    // Calculate system efficiency
    final totalModuleArea = module.area * modulesInSeries * stringsInParallel;
    final efficiency = poaIrradiance > 0 
        ? acPower / (poaIrradiance * totalModuleArea) 
        : 0;
    
    // Calculate performance ratio
    // (AC output / nominal DC power) / (irradiance / reference irradiance)
    final nominalDCPower = module.powerRating * modulesInSeries * stringsInParallel;
    final performanceRatio = poaIrradiance > 0 
        ? (acPower / nominalDCPower) / (poaIrradiance / 1000) 
        : 0;
    
    return HourlySimulationResult(
      dateTime: dateTime,
      globalHorizontalIrradiance: globalHorizontalIrradiance,
      planeOfArrayIrradiance: poaIrradiance,
      ambientTemperature: ambientTemperature,
      cellTemperature: cellTemp,
      dcPower: dcPower,
      acPower: acPower,
      efficiency: efficiency,
      performanceRatio: performanceRatio,
    );
  }
  
  /// Simulate PV system performance for an entire day
  List<HourlySimulationResult> simulateDay({
    required DateTime date,
    required List<double> hourlyGlobalHorizontalIrradiance,
    required List<double> hourlyDiffuseHorizontalIrradiance,
    required List<double> hourlyAmbientTemperature,
    required List<double> hourlyWindSpeed,
  }) {
    final results = <HourlySimulationResult>[];
    
    // Simulate each hour of the day
    for (int hour = 0; hour < 24; hour++) {
      final dateTime = DateTime(date.year, date.month, date.day, hour);
      
      final result = simulateHour(
        dateTime: dateTime,
        globalHorizontalIrradiance: hourlyGlobalHorizontalIrradiance[hour],
        diffuseHorizontalIrradiance: hourlyDiffuseHorizontalIrradiance[hour],
        ambientTemperature: hourlyAmbientTemperature[hour],
        windSpeed: hourlyWindSpeed[hour],
      );
      
      results.add(result);
    }
    
    return results;
  }
  
  /// Simulate PV system performance for an entire month
  MonthlySimulationResult simulateMonth({
    required int year,
    required int month,
    required List<List<double>> dailyGlobalHorizontalIrradiance,
    required List<List<double>> dailyDiffuseHorizontalIrradiance,
    required List<List<double>> dailyAmbientTemperature,
    required List<List<double>> dailyWindSpeed,
  }) {
    double monthlyEnergyDC = 0;
    double monthlyEnergyAC = 0;
    double monthlyIrradiationGHI = 0;
    double monthlyIrradiationPOA = 0;
    
    final numDays = DateTime(year, month + 1, 0).day; // Last day of month
    
    final allDailyResults = <List<HourlySimulationResult>>[];
    
    // Simulate each day of the month
    for (int day = 1; day <= numDays; day++) {
      final date = DateTime(year, month, day);
      
      final dailyResults = simulateDay(
        date: date,
        hourlyGlobalHorizontalIrradiance: dailyGlobalHorizontalIrradiance[day - 1],
        hourlyDiffuseHorizontalIrradiance: dailyDiffuseHorizontalIrradiance[day - 1],
        hourlyAmbientTemperature: dailyAmbientTemperature[day - 1],
        hourlyWindSpeed: dailyWindSpeed[day - 1],
      );
      
      allDailyResults.add(dailyResults);
      
      // Calculate daily energy and add to monthly total
      double dailyEnergyDC = 0;
      double dailyEnergyAC = 0;
      double dailyIrradiationGHI = 0;
      double dailyIrradiationPOA = 0;
      
      for (final hourly in dailyResults) {
        dailyEnergyDC += hourly.dcPower / 1000; // kWh assuming 1 hour
        dailyEnergyAC += hourly.acPower / 1000; // kWh assuming 1 hour
        dailyIrradiationGHI += hourly.globalHorizontalIrradiance / 1000; // kWh/m² assuming 1 hour
        dailyIrradiationPOA += hourly.planeOfArrayIrradiance / 1000; // kWh/m² assuming 1 hour
      }
      
      monthlyEnergyDC += dailyEnergyDC;
      monthlyEnergyAC += dailyEnergyAC;
      monthlyIrradiationGHI += dailyIrradiationGHI;
      monthlyIrradiationPOA += dailyIrradiationPOA;
    }
    
    // Calculate average values
    final avgAmbientTemp = allDailyResults
        .expand((day) => day)
        .map((hour) => hour.ambientTemperature)
        .reduce((a, b) => a + b) / (numDays * 24);
    
    final avgCellTemp = allDailyResults
        .expand((day) => day)
        .where((hour) => hour.planeOfArrayIrradiance > 0) // Only during daylight
        .map((hour) => hour.cellTemperature)
        .fold<double>(0, (sum, temp) => sum + temp) /
        allDailyResults
            .expand((day) => day)
            .where((hour) => hour.planeOfArrayIrradiance > 0)
            .length;
    
    final avgEfficiency = allDailyResults
        .expand((day) => day)
        .where((hour) => hour.planeOfArrayIrradiance > 50) // Only during significant irradiance
        .map((hour) => hour.efficiency)
        .fold<double>(0, (sum, eff) => sum + eff) /
        allDailyResults
            .expand((day) => day)
            .where((hour) => hour.planeOfArrayIrradiance > 50)
            .length;
    
    final avgPR = allDailyResults
        .expand((day) => day)
        .where((hour) => hour.planeOfArrayIrradiance > 50) // Only during significant irradiance
        .map((hour) => hour.performanceRatio)
        .fold<double>(0, (sum, pr) => sum + pr) /
        allDailyResults
            .expand((day) => day)
            .where((hour) => hour.planeOfArrayIrradiance > 50)
            .length;
    
    final specificYield = monthlyEnergyAC / (module.powerRating * modulesInSeries * stringsInParallel / 1000);
    
    return MonthlySimulationResult(
      year: year,
      month: month,
      energyDC: monthlyEnergyDC,
      energyAC: monthlyEnergyAC,
      irradiationGHI: monthlyIrradiationGHI,
      irradiationPOA: monthlyIrradiationPOA,
      averageAmbientTemperature: avgAmbientTemp,
      averageCellTemperature: avgCellTemp,
      averageEfficiency: avgEfficiency,
      averagePerformanceRatio: avgPR,
      specificYield: specificYield,
    );
  }
  
  /// Simulate PV system performance for a full year
  AnnualSimulationResult simulateYear({
    required int year,
    // Weather data for each month and day would be provided here
  }) {
    // This is a placeholder implementation
    // In a real implementation, you would load weather data for all days of the year
    // and call simulateMonth for each month
    
    final monthlyResults = <MonthlySimulationResult>[];
    double annualEnergyAC = 0;
    double annualEnergyDC = 0;
    
    // Placeholder for demonstration
    for (int month = 1; month <= 12; month++) {
      // Create random sample data for demonstration
      final numDays = DateTime(year, month + 1, 0).day;
      
      final dailyGHI = List.generate(
        numDays, 
        (_) => List.generate(24, (hour) => math.Random().nextDouble() * 1000 * math.sin(math.pi * hour / 24)),
      );
      
      final dailyDHI = List.generate(
        numDays, 
        (day) => List.generate(24, (hour) => dailyGHI[day][hour] * 0.3),
      );
      
      final dailyTemp = List.generate(
        numDays, 
        (_) => List.generate(24, (hour) => 15 + 10 * math.sin(math.pi * (hour - 3) / 24)),
      );
      
      final dailyWind = List.generate(
        numDays, 
        (_) => List.generate(24, (_) => 1 + math.Random().nextDouble() * 4),
      );
      
      final monthResult = simulateMonth(
        year: year,
        month: month,
        dailyGlobalHorizontalIrradiance: dailyGHI,
        dailyDiffuseHorizontalIrradiance: dailyDHI,
        dailyAmbientTemperature: dailyTemp,
        dailyWindSpeed: dailyWind,
      );
      
      monthlyResults.add(monthResult);
      annualEnergyAC += monthResult.energyAC;
      annualEnergyDC += monthResult.energyDC;
    }
    
    // Calculate annual performance metrics
    final averagePR = monthlyResults
        .map((month) => month.averagePerformanceRatio)
        .reduce((a, b) => a + b) / 12;
    
    final specificYield = annualEnergyAC / (module.powerRating * modulesInSeries * stringsInParallel / 1000);
    
    return AnnualSimulationResult(
      year: year,
      monthlyResults: monthlyResults,
      energyAC: annualEnergyAC,
      energyDC: annualEnergyDC,
      averagePerformanceRatio: averagePR,
      specificYield: specificYield,
    );
  }
}

class HourlySimulationResult {
  final DateTime dateTime;
  final double globalHorizontalIrradiance; // W/m²
  final double planeOfArrayIrradiance;     // W/m²
  final double ambientTemperature;         // °C
  final double cellTemperature;            // °C
  final double dcPower;                    // W
  final double acPower;                    // W
  final double efficiency;                 // Fraction (0-1)
  final double performanceRatio;           // Fraction (0-1)
  
  HourlySimulationResult({
    required this.dateTime,
    required this.globalHorizontalIrradiance,
    required this.planeOfArrayIrradiance,
    required this.ambientTemperature,
    required this.cellTemperature,
    required this.dcPower,
    required this.acPower,
    required this.efficiency,
    required this.performanceRatio,
  });
}

class MonthlySimulationResult {
  final int year;
  final int month;
  final double energyDC;                   // kWh
  final double energyAC;                   // kWh
  final double irradiationGHI;             // kWh/m²
  final double irradiationPOA;             // kWh/m²
  final double averageAmbientTemperature;  // °C
  final double averageCellTemperature;     // °C
  final double averageEfficiency;          // Fraction (0-1)
  final double averagePerformanceRatio;    // Fraction (0-1)
  final double specificYield;              // kWh/kWp
  
  MonthlySimulationResult({
    required this.year,
    required this.month,
    required this.energyDC,
    required this.energyAC,
    required this.irradiationGHI,
    required this.irradiationPOA,
    required this.averageAmbientTemperature,
    required this.averageCellTemperature,
    required this.averageEfficiency,
    required this.averagePerformanceRatio,
    required this.specificYield,
  });
  
  String get monthName {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }
}

class AnnualSimulationResult {
  final int year;
  final List<MonthlySimulationResult> monthlyResults;
  final double energyAC;                   // kWh
  final double energyDC;                   // kWh
  final double averagePerformanceRatio;    // Fraction (0-1)
  final double specificYield;              // kWh/kWp
  
  AnnualSimulationResult({
    required this.year,
    required this.monthlyResults,
    required this.energyAC,
    required this.energyDC,
    required this.averagePerformanceRatio,
    required this.specificYield,
  });
}

// lib/core/financial_model.dart
/// Models the financial aspects of PV systems
class FinancialModel {
  /// Calculate levelized cost of energy (LCOE)
  static double calculateLCOE({
    required double initialInvestment,
    required double annualOperationAndMaintenance,
    required double annualEnergy,
    required double discountRate,
    required int projectLifetime,
  }) {
    double totalDiscountedCosts = initialInvestment;
    double totalDiscountedEnergy = 0;
    
    for (int year = 1; year <= projectLifetime; year++) {
      // Calculate discounted O&M costs
      final discountedOMCost = annualOperationAndMaintenance / math.pow(1 + discountRate, year);
      totalDiscountedCosts += discountedOMCost;
      
      // Calculate discounted energy
      final discountedEnergy = annualEnergy / math.pow(1 + discountRate, year);
      totalDiscountedEnergy += discountedEnergy;
    }
    
    // Calculate LCOE
    return totalDiscountedCosts / totalDiscountedEnergy;
  }
  
  /// Calculate net present value (NPV)
  static double calculateNPV({
    required double initialInvestment,
    required double annualEnergySavings,
    required double annualOperationAndMaintenance,
    required double discountRate,
    required int projectLifetime,
  }) {
    double npv = -initialInvestment;
    
    for (int year = 1; year <= projectLifetime; year++) {
      // Calculate net cash flow for the year
      final netCashFlow = annualEnergySavings - annualOperationAndMaintenance;
      
      // Calculate discounted cash flow
      final discountedCashFlow = netCashFlow / math.pow(1 + discountRate, year);
      
      // Add to NPV
      npv += discountedCashFlow;
    }
    
    return npv;
  }
  
  /// Calculate payback period
  static double calculatePaybackPeriod({
    required double initialInvestment,
    required double annualEnergySavings,
    required double annualOperationAndMaintenance,
  }) {
    // Calculate annual net savings
    final annualNetSavings = annualEnergySavings - annualOperationAndMaintenance;
    
    // Check if project is profitable
    if (annualNetSavings <= 0) {
      return double.infinity; // Never pays back
    }
    
    // Calculate simple payback period
    return initialInvestment / annualNetSavings;
  }
  
  /// Calculate internal rate of return (IRR)
  /// Uses a simple iterative approach
  static double calculateIRR({
    required double initialInvestment,
    required double annualEnergySavings,
    required double annualOperationAndMaintenance,
    required int projectLifetime,
  }) {
    // Start with a guess for IRR
    double irr = 0.1; // 10%
    double step = 0.01;
    int maxIterations = 100;
    double tolerance = 0.0001;
    
    for (int i = 0; i < maxIterations; i++) {
      // Calculate NPV with current IRR guess
      double npv = -initialInvestment;
      
      for (int year = 1; year <= projectLifetime; year++) {
        // Calculate net cash flow for the year
        final netCashFlow = annualEnergySavings - annualOperationAndMaintenance;
        
        // Calculate discounted cash flow
        final discountedCashFlow = netCashFlow / math.pow(1 + irr, year);
        
        // Add to NPV
        npv += discountedCashFlow;
      }
      
      // Check if NPV is close enough to zero
      if (npv.abs() < tolerance) {
        return irr;
      }
      
      // Adjust IRR based on NPV
      if (npv > 0) {
        irr += step;
      } else {
        irr -= step;
        step /= 2; // Reduce step size
      }
    }
    
    // Return best estimate after max iterations
    return irr;
  }
}

// lib/core/load_profile.dart
/// Models electricity load profiles for energy consumption
class LoadProfile {
  final List<double> hourlyLoad; // kW for each hour of the day
  
  LoadProfile({required this.hourlyLoad});
  
  /// Create a typical residential load profile
  factory LoadProfile.typicalResidential() {
    return LoadProfile(
      hourlyLoad: [
        0.3, 0.2, 0.2, 0.2, 0.2, 0.3, // 0:00 - 5:59
        0.5, 0.7, 0.9, 0.7, 0.6, 0.6, // 6:00 - 11:59
        0.7, 0.7, 0.6, 0.6, 0.7, 1.0, // 12:00 - 17:59
        1.2, 1.0, 0.8, 0.6, 0.4, 0.3, // 18:00 - 23:59
      ],
    );
  }
  
  /// Create a typical commercial load profile
  factory LoadProfile.typicalCommercial() {
    return LoadProfile(
      hourlyLoad: [
        0.3, 0.3, 0.3, 0.3, 0.3, 0.4, // 0:00 - 5:59
        0.5, 1.0, 1.5, 1.8, 1.9, 2.0, // 6:00 - 11:59
        2.0, 2.0, 1.9, 1.8, 1.7, 1.5, // 12:00 - 17:59
        1.0, 0.8, 0.6, 0.5, 0.4, 0.3, // 18:00 - 23:59
      ],
    );
  }
  
  /// Create a typical industrial load profile
  factory LoadProfile.typicalIndustrial() {
    return LoadProfile(
      hourlyLoad: [
        0.6, 0.6, 0.6, 0.6, 0.6, 0.8, // 0:00 - 5:59
        1.5, 2.0, 2.2, 2.2, 2.2, 2.2, // 6:00 - 11:59
        2.2, 2.2, 2.2, 2.2, 2.0, 1.5, // 12:00 - 17:59
        1.0, 0.8, 0.7, 0.7, 0.6, 0.6, // 18:00 - 23:59
      ],
    );
  }
  
  /// Calculate daily energy consumption in kWh
  double get dailyEnergy {
    return hourlyLoad.reduce((sum, load) => sum + load);
  }
  
  /// Calculate monthly energy consumption in kWh
  double calculateMonthlyEnergy(int month, int year) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return dailyEnergy * daysInMonth;
  }
  
  /// Calculate annual energy consumption in kWh
  double calculateAnnualEnergy(int year) {
    double annualEnergy = 0;
    
    // Sum energy for each month
    for (int month = 1; month <= 12; month++) {
      annualEnergy += calculateMonthlyEnergy(month, year);
    }
    
    return annualEnergy;
  }
  
  /// Calculate self-consumption ratio based on PV production
  double calculateSelfConsumptionRatio({
    required List<double> hourlyPVProduction, // kWh for each hour of the day
  }) {
    double selfConsumed = 0;
    double totalProduction = 0;
    
    for (int hour = 0; hour < 24; hour++) {
      final consumption = hourlyLoad[hour];
      final production = hourlyPVProduction[hour];
      
      // Calculate self-consumed energy (minimum of production and consumption)
      selfConsumed += math.min(consumption, production);
      
      // Sum total production
      totalProduction += production;
    }
    
    // Calculate self-consumption ratio
    return totalProduction > 0 ? selfConsumed / totalProduction : 0;
  }
  
  /// Calculate self-sufficiency ratio based on PV production
  double calculateSelfSufficiencyRatio({
    required List<double> hourlyPVProduction, // kWh for each hour of the day
  }) {
    double selfConsumed = 0;
    double totalConsumption = 0;
    
    for (int hour = 0; hour < 24; hour++) {
      final consumption = hourlyLoad[hour];
      final production = hourlyPVProduction[hour];
      
      // Calculate self-consumed energy (minimum of production and consumption)
      selfConsumed += math.min(consumption, production);
      
      // Sum total consumption
      totalConsumption += consumption;
    }
    
    // Calculate self-sufficiency ratio
    return totalConsumption > 0 ? selfConsumed / totalConsumption : 0;
  }
}

// lib/core/weather_data.dart
/// Models weather data for PV system simulations
class WeatherData {
  final double latitude;
  final double longitude;
  final String location;
  final Map<int, MonthlyWeatherData> monthlyData; // Key is month (1-12)
  
  WeatherData({
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.monthlyData,
  });
  
  /// Create test weather data for a location (for demonstration purposes)
  factory WeatherData.testData({
    required double latitude,
    required double longitude,
    required String location,
  }) {
    final monthlyData = <int, MonthlyWeatherData>{};
    
    // Generate test data for each month
    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateTime(2025, month + 1, 0).day;
      
      // Generate daily weather data
      final dailyData = List.generate(
        daysInMonth, 
        (day) => DailyWeatherData(
          date: DateTime(2025, month, day + 1),
          hourlyGlobalHorizontalIrradiance: _generateHourlyIrradiance(month, latitude),
          hourlyDiffuseHorizontalIrradiance: _generateHourlyDiffuseIrradiance(month, latitude),
          hourlyTemperature: _generateHourlyTemperature(month, latitude),
          hourlyWindSpeed: _generateHourlyWindSpeed(month),
          hourlyHumidity: _generateHourlyHumidity(month),
        ),
      );
      
      monthlyData[month] = MonthlyWeatherData(
        year: 2025,
        month: month,
        dailyData: dailyData,
      );
    }
    
    return WeatherData(
      latitude: latitude,
      longitude: longitude,
      location: location,
      monthlyData: monthlyData,
    );
  }
  
  /// Generate synthetic hourly irradiance data
  static List<double> _generateHourlyIrradiance(int month, double latitude) {
    final isNorthernHemisphere = latitude > 0;
    
    // Determine season factor (0-1 scale)
    double seasonFactor;
    if (isNorthernHemisphere) {
      // Northern hemisphere: summer around June-August
      seasonFactor = 0.5 + 0.5 * math.cos((month - 7) / 12 * 2 * math.pi);
    } else {
      // Southern hemisphere: summer around December-February
      seasonFactor = 0.5 + 0.5 * math.cos((month - 1) / 12 * 2 * math.pi);
    }
    
    // Day length factor based on month and latitude
    final dayLengthFactor = 0.5 + 0.45 * math.sin((math.pi * latitude / 180) * math.cos((month - 6) / 6 * math.pi));
    
    // Peak irradiance based on season (W/m²)
    final peakIrradiance = 600 + 400 * seasonFactor;
    
    // Generate hourly values
    return List.generate(24, (hour) {
      // Determine if it's daylight
      final hourNormalized = (hour - 12) / 12; // -1 to 1
      final dayWindow = dayLengthFactor * 12; // hours of daylight
      
      if (hour >= 12 - dayWindow / 2 && hour <= 12 + dayWindow / 2) {
        // Daylight hours: bell curve distribution
        final position = (hour - 12) / (dayWindow / 2); // -1 to 1 during daylight
        return peakIrradiance * math.exp(-4 * position * position);
      } else {
        // Night hours
        return 0.0;
      }
    });
  }
  
  /// Generate synthetic hourly diffuse irradiance data
  static List<double> _generateHourlyDiffuseIrradiance(int month, double latitude) {
    // Get global horizontal irradiance
    final ghi = _generateHourlyIrradiance(month, latitude);
    
    // Determine diffuse fraction based on month
    // Winter months have higher diffuse fraction
    final isNorthernHemisphere = latitude > 0;
    double diffuseFraction;
    
    if (isNorthernHemisphere) {
      // Northern hemisphere
      diffuseFraction = month >= 5 && month <= 9 ? 0.3 : 0.5;
    } else {
      // Southern hemisphere
      diffuseFraction = month >= 11 || month <= 3 ? 0.3 : 0.5;
    }
    
    // Generate diffuse component
    return ghi.map((value) => value * diffuseFraction).toList();
  }
  
  /// Generate synthetic hourly temperature data
  static List<double> _generateHourlyTemperature(int month, double latitude) {
    final isNorthernHemisphere = latitude > 0;
    
    // Base temperature based on month and hemisphere
    double baseTemp;
    if (isNorthernHemisphere) {
      // Northern hemisphere
      baseTemp = 15 + 15 * math.sin((month - 1) / 12 * 2 * math.pi - math.pi/2);
    } else {
      // Southern hemisphere
      baseTemp = 15 + 15 * math.sin((month - 7) / 12 * 2 * math.pi - math.pi/2);
    }
    
    // Adjust based on latitude (cooler at higher latitudes)
    baseTemp -= (math.min(math.abs(latitude), 60) / 60) * 10;
    
    // Generate hourly temperatures with diurnal variation
    return List.generate(24, (hour) {
      // Diurnal variation: coolest around 5am, warmest around 2pm
      final hourFactor = math.sin((hour - 5) / 24 * 2 * math.pi);
      
      // Diurnal range depends on season and latitude
      final diurnalRange = 5 + 5 * math.cos((math.abs(latitude) / 90) * math.pi/2);
      
      return baseTemp + hourFactor * diurnalRange;
    });
  }
  
  /// Generate synthetic hourly wind speed data
  static List<double> _generateHourlyWindSpeed(int month) {
    // Base wind speed (slightly higher in winter/spring)
    final baseWind = 2.0 + 1.0 * math.sin((month - 3) / 12 * 2 * math.pi);
    
    // Generate hourly wind speeds
    return List.generate(24, (hour) {
      // Wind tends to be stronger in afternoon
      final hourFactor = 1.0 + 0.5 * math.sin((hour - 2) / 24 * 2 * math.pi);
      
      // Add some randomness
      final random = math.Random();
      return baseWind * hourFactor * (0.8 + 0.4 * random.nextDouble());
    });
  }
  
  /// Generate synthetic hourly humidity data
  static List<double> _generateHourlyHumidity(int month) {
    // Base humidity (higher in winter)
    final baseHumidity = 50 + 20 * math.cos((month - 1) / 12 * 2 * math.pi);
    
    // Generate hourly humidity values
    return List.generate(24, (hour) {
      // Humidity tends to be higher at night/morning
      final hourFactor = 1.0 + 0.3 * math.cos((hour - 3) / 24 * 2 * math.pi);
      
      // Add some randomness
      final random = math.Random();
      return math.min(100, baseHumidity * hourFactor * (0.9 + 0.2 * random.nextDouble()));
    });
  }
}

class MonthlyWeatherData {
  final int year;
  final int month;
  final List<DailyWeatherData> dailyData;
  
  MonthlyWeatherData({
    required this.year,
    required this.month,
    required this.dailyData,
  });
  
  /// Calculate monthly averages
  Map<String, double> get monthlyAverages {
    // Calculate daily averages first
    final dailyAvgTemp = dailyData
        .map((day) => day.hourlyTemperature.reduce((a, b) => a + b) / 24)
        .toList();
    
    final dailyAvgGHI = dailyData
        .map((day) => day.hourlyGlobalHorizontalIrradiance.reduce((a, b) => a + b) / 24)
        .toList();
    
    final dailyAvgWind = dailyData
        .map((day) => day.hourlyWindSpeed.reduce((a, b) => a + b) / 24)
        .toList();
    
    final dailyAvgHumidity = dailyData
        .map((day) => day.hourlyHumidity.reduce((a, b) => a + b) / 24)
        .toList();
    
    // Calculate monthly averages
    return {
      'temperature': dailyAvgTemp.reduce((a, b) => a + b) / dailyAvgTemp.length,
      'ghi': dailyAvgGHI.reduce((a, b) => a + b) / dailyAvgGHI.length,
      'windSpeed': dailyAvgWind.reduce((a, b) => a + b) / dailyAvgWind.length,
      'humidity': dailyAvgHumidity.reduce((a, b) => a + b) / dailyAvgHumidity.length,
    };
  }
}

class DailyWeatherData {
  final DateTime date;
  final List<double> hourlyGlobalHorizontalIrradiance; // W/m²
  final List<double> hourlyDiffuseHorizontalIrradiance; // W/m²
  final List<double> hourlyTemperature; // °C
  final List<double> hourlyWindSpeed; // m/s
  final List<double> hourlyHumidity; // %
  
  DailyWeatherData({
    required this.date,
    required this.hourlyGlobalHorizontalIrradiance,
    required this.hourlyDiffuseHorizontalIrradiance,
    required this.hourlyTemperature,
    required this.hourlyWindSpeed,
    required this.hourlyHumidity,
  });
}