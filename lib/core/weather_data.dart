// lib/core/weather_data.dart
import 'dart:math' as math;

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
    baseTemp -= (math.min(latitude.abs(), 60) / 60) * 10;
    
    // Generate hourly temperatures with diurnal variation
    return List.generate(24, (hour) {
      // Diurnal variation: coolest around 5am, warmest around 2pm
      final hourFactor = math.sin((hour - 5) / 24 * 2 * math.pi);
      
      // Diurnal range depends on season and latitude
      final diurnalRange = 5 + 5 * math.cos((latitude.abs() / 90) * math.pi/2);
      
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