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