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
    const timeZoneOffset = 0; // Simplified - in real app get from timeZone string
    
    // Calculate solar position
    final solarPos = SolarPosition.calculate(
      dateTime: dateTime,
      latitude: latitude,
      longitude: longitude,
      timeZoneOffset: timeZoneOffset.toDouble(),
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
      efficiency: efficiency.toDouble(),
      performanceRatio: performanceRatio.toDouble(),
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