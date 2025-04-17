// lib/services/weather_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/weather_data.dart';
import '../models/location.dart';

/// Service for fetching weather data from external APIs
class WeatherApiService {
  // API keys for different providers - store these securely in a production app
  // You would need to sign up for these services to get valid API keys
  static const String _openWeatherMapApiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
  static const String _solarRadiationApiKey = 'YOUR_SOLCAST_API_KEY';
  static const String _nrelApiKey = 'YOUR_NREL_API_KEY';
  
  /// Fetch current weather data for a location
  Future<Map<String, dynamic>> fetchCurrentWeather(Location location) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?'
      'lat=${location.latitude}&lon=${location.longitude}'
      '&units=metric&appid=$_openWeatherMapApiKey'
    );
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather data: ${response.statusCode}');
    }
  }
  
  /// Fetch historical weather data for the past year
  Future<Map<String, dynamic>> fetchHistoricalWeather(Location location) async {
    // Using OpenWeatherMap's One Call API for historical data
    // Note: OpenWeatherMap limits free tier to 5 days of historical data
    // In a real app, you might need to use a different provider or paid plan
    final now = DateTime.now();
    final fiveDaysAgo = now.subtract(const Duration(days: 5));
    final timestamp = fiveDaysAgo.millisecondsSinceEpoch ~/ 1000;
    
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/onecall/timemachine?'
      'lat=${location.latitude}&lon=${location.longitude}'
      '&dt=$timestamp&units=metric&appid=$_openWeatherMapApiKey'
    );
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load historical weather data: ${response.statusCode}');
    }
  }
  
  /// Fetch solar radiation data for a location (TMY data)
  Future<Map<String, dynamic>> fetchSolarRadiationData(Location location) async {
    // Using NREL's Solar Resource Data API
    // This provides Typical Meteorological Year (TMY) data
    final url = Uri.parse(
      'https://developer.nrel.gov/api/solar/solar_resource/v1.json?'
      'api_key=$_nrelApiKey&lat=${location.latitude}&lon=${location.longitude}'
    );
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load solar radiation data: ${response.statusCode}');
    }
  }
  
  /// Fetch detailed irradiance forecast for the next few days
  Future<Map<String, dynamic>> fetchIrradianceForecast(Location location) async {
    // Using Solcast's Solar Radiation API for forecasting
    final url = Uri.parse(
      'https://api.solcast.com.au/radiation/forecasts?'
      'latitude=${location.latitude}&longitude=${location.longitude}'
      '&hours=168&format=json&api_key=$_solarRadiationApiKey'
    );
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load irradiance forecast data: ${response.statusCode}');
    }
  }
  
  /// Convert raw API data to WeatherData object
  Future<WeatherData> getWeatherData(Location location) async {
    try {
      // Fetch solar radiation data (TMY)
      final solarData = await fetchSolarRadiationData(location);
      
      // Process TMY data into monthly averages
      final monthlyData = <int, MonthlyWeatherData>{};
      
      // Example of parsing NREL's TMY data format
      // In a real implementation, you'd need to parse the specific format returned by the API
      final annualData = solarData['outputs']['tmy_hourly'] as List<dynamic>;
      
      // Group by month
      final hoursByMonth = <int, List<Map<String, dynamic>>>{};
      
      for (var hourData in annualData) {
        final month = _parseMonth(hourData['month'].toString());
        hoursByMonth.putIfAbsent(month, () => []);
        hoursByMonth[month]!.add(hourData);
      }
      
      // Process each month
      for (final entry in hoursByMonth.entries) {
        final month = entry.key;
        final hourlyData = entry.value;
        
        // Group by day
        final dayCount = DateTime(DateTime.now().year, month + 1, 0).day;
        final daysInMonth = List.generate(dayCount, (i) => i + 1);
        
        // Create daily weather data (simplified - in a real app, you'd process actual hourly data)
        final dailyData = daysInMonth.map((day) {
          return _createDailyWeatherData(
            DateTime(DateTime.now().year, month, day),
            hourlyData,
          );
        }).toList();
        
        monthlyData[month] = MonthlyWeatherData(
          year: DateTime.now().year,
          month: month,
          dailyData: dailyData,
        );
      }
      
      return WeatherData(
        latitude: location.latitude,
        longitude: location.longitude,
        location: location.address,
        monthlyData: monthlyData,
      );
    } catch (e) {
      print('Error fetching weather data: $e');
      // Fall back to synthetic data if API fails
      return WeatherData.testData(
        latitude: location.latitude,
        longitude: location.longitude,
        location: location.address,
      );
    }
  }
  
  /// Parse month string to int (1-12)
  int _parseMonth(String monthStr) {
    try {
      return int.parse(monthStr);
    } catch (e) {
      // If parsing fails, default to current month
      return DateTime.now().month;
    }
  }
  
  /// Create daily weather data from hourly data (simplified)
  DailyWeatherData _createDailyWeatherData(
    DateTime date,
    List<Map<String, dynamic>> hourlyData,
  ) {
    // Filter to get only the hours for this day of month
    // In a real implementation, you'd match the actual day
    final day = date.day;
    final dayHours = hourlyData.where((h) => 
      int.tryParse(h['day'].toString()) == day
    ).toList();
    
    // Default to 24 hours of data if no matching data found
    final hourCount = dayHours.isEmpty ? 24 : dayHours.length;
    
    // Parse hourly values (simplified example)
    final hourlyGHI = List.generate(24, (hour) {
      if (hour < hourCount && dayHours.isNotEmpty) {
        return double.tryParse(dayHours[hour]['ghi'].toString()) ?? 0.0;
      } else {
        return 0.0;
      }
    });
    
    final hourlyDHI = List.generate(24, (hour) {
      if (hour < hourCount && dayHours.isNotEmpty) {
        return double.tryParse(dayHours[hour]['dhi'].toString()) ?? 0.0;
      } else {
        return 0.0;
      }
    });
    
    final hourlyTemp = List.generate(24, (hour) {
      if (hour < hourCount && dayHours.isNotEmpty) {
        return double.tryParse(dayHours[hour]['temp'].toString()) ?? 20.0;
      } else {
        return 20.0;
      }
    });
    
    final hourlyWind = List.generate(24, (hour) {
      if (hour < hourCount && dayHours.isNotEmpty) {
        return double.tryParse(dayHours[hour]['wind_speed'].toString()) ?? 1.0;
      } else {
        return 1.0;
      }
    });
    
    final hourlyHumidity = List.generate(24, (hour) {
      if (hour < hourCount && dayHours.isNotEmpty) {
        return double.tryParse(dayHours[hour]['relative_humidity'].toString()) ?? 50.0;
      } else {
        return 50.0;
      }
    });
    
    return DailyWeatherData(
      date: date,
      hourlyGlobalHorizontalIrradiance: hourlyGHI,
      hourlyDiffuseHorizontalIrradiance: hourlyDHI,
      hourlyTemperature: hourlyTemp,
      hourlyWindSpeed: hourlyWind,
      hourlyHumidity: hourlyHumidity,
    );
  }
  
  /// Import weather data from a TMY3 file
  Future<WeatherData> importTMY3Data(String filePath, Location location) async {
    // In a real implementation, you would parse the TMY3 file format
    // This is just a placeholder that returns synthetic data
    return WeatherData.testData(
      latitude: location.latitude,
      longitude: location.longitude,
      location: location.address,
    );
  }
  
  /// Import weather data from a CSV file
  Future<WeatherData> importCSVData(String filePath, Location location) async {
    // In a real implementation, you would parse the CSV file
    // This is just a placeholder that returns synthetic data
    return WeatherData.testData(
      latitude: location.latitude,
      longitude: location.longitude,
      location: location.address,
    );
  }
}