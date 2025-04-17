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
    //final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    
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
    //final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    
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














