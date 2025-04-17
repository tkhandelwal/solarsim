// lib/core/load_profile.dart
import 'dart:math' as math;

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
