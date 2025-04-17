// lib/core/battery_optimizer.dart
import 'dart:math' as math;
import '../models/battery_system.dart';
import 'battery_simulator.dart';

/// Type definition for custom battery control strategy
typedef CustomTimeOfUseStrategy = Map<String, bool> Function(int hour, double batteryStateOfCharge, double maxCapacity);

/// Advanced optimizer for battery operation strategies
class BatteryOptimizer {
  final BatterySystem batterySystem;
  final BatterySimulator simulator;
  
  // Control parameters
  final double _learningRate = 0.05;
  final int _maxIterations = 100;
  
  BatteryOptimizer({
    required this.batterySystem,
    required this.simulator,
  });
  
  /// Optimize time-of-use strategy
  /// Returns optimized charge/discharge thresholds
  Map<String, double> optimizeTimeOfUseStrategy({
    required List<TimeOfUseRate> timeOfUseRates,
    required List<double> typicalLoad,
    required List<double> typicalProduction,
  }) {
    // Calculate average rate
    double averageRate = 0;
    int totalHours = 0;
    
    for (final rate in timeOfUseRates) {
      final hours = rate.endHour - rate.startHour;
      averageRate += rate.rate * hours;
      totalHours += hours;
    }
    
    averageRate = totalHours > 0 ? averageRate / totalHours : 0.15;
    
    // Initial thresholds
    double chargeThreshold = averageRate * 0.9; // Charge when price below 90% of average
    double dischargeThreshold = averageRate * 1.1; // Discharge when price above 110% of average
    
    double bestSavings = 0;
    Map<String, double> bestThresholds = {
      'chargeThreshold': chargeThreshold,
      'dischargeThreshold': dischargeThreshold,
    };
    
    // Define optimization search space
    final double minChargeThreshold = _findMinRate(timeOfUseRates);
    final double maxChargeThreshold = averageRate;
    final double minDischargeThreshold = averageRate;
    final double maxDischargeThreshold = _findMaxRate(timeOfUseRates);
    
    // Iterative optimization
    for (int iteration = 0; iteration < _maxIterations; iteration++) {
      // Test current thresholds
      final savings = _evaluateTimeOfUseThresholds(
        chargeThreshold: chargeThreshold,
        dischargeThreshold: dischargeThreshold,
        timeOfUseRates: timeOfUseRates,
        typicalLoad: typicalLoad,
        typicalProduction: typicalProduction,
      );
      
      // Update best result if better
      if (savings > bestSavings) {
        bestSavings = savings;
        bestThresholds = {
          'chargeThreshold': chargeThreshold,
          'dischargeThreshold': dischargeThreshold,
        };
      }
      
      // Apply gradient step (simplified approach)
      final stepSize = _learningRate * (1 - iteration / _maxIterations);
      
      // Test step directions
      final savingsUp = _evaluateTimeOfUseThresholds(
        chargeThreshold: chargeThreshold + stepSize,
        dischargeThreshold: dischargeThreshold + stepSize,
        timeOfUseRates: timeOfUseRates,
        typicalLoad: typicalLoad,
        typicalProduction: typicalProduction,
      );
      
      final savingsDown = _evaluateTimeOfUseThresholds(
        chargeThreshold: chargeThreshold - stepSize,
        dischargeThreshold: dischargeThreshold - stepSize,
        timeOfUseRates: timeOfUseRates,
        typicalLoad: typicalLoad,
        typicalProduction: typicalProduction,
      );
      
      // Apply step in best direction
      if (savingsUp > savings && savingsUp > savingsDown) {
        chargeThreshold = math.min(chargeThreshold + stepSize, maxChargeThreshold);
        dischargeThreshold = math.min(dischargeThreshold + stepSize, maxDischargeThreshold);
      } else if (savingsDown > savings) {
        chargeThreshold = math.max(chargeThreshold - stepSize, minChargeThreshold);
        dischargeThreshold = math.max(dischargeThreshold - stepSize, minDischargeThreshold);
      }
    }
    
    return bestThresholds;
  }
  
  /// Optimize peak shaving strategy
  /// Returns optimized discharge power threshold
  double optimizePeakShavingThreshold({
    required List<double> typicalLoad,
    required List<double> typicalProduction,
    required double demandChargeRate, // $ per kW of peak demand
  }) {
    // Find base peak without battery
    double basePeak = 0;
    for (int hour = 0; hour < math.min(typicalLoad.length, typicalProduction.length); hour++) {
      final netLoad = typicalLoad[hour] - typicalProduction[hour];
      if (netLoad > basePeak) {
        basePeak = netLoad;
      }
    }
    
    // Initial threshold at 80% of peak
    double threshold = basePeak * 0.8;
    double bestThreshold = threshold;
    double bestSavings = 0;
    
    // Search space
    final double minThreshold = basePeak * 0.5;
    final double maxThreshold = basePeak * 0.95;
    final double step = (maxThreshold - minThreshold) / 20;
    
    // Grid search for optimal threshold
    for (double testThreshold = minThreshold; testThreshold <= maxThreshold; testThreshold += step) {
      final savings = _evaluatePeakShavingThreshold(
        threshold: testThreshold,
        typicalLoad: typicalLoad,
        typicalProduction: typicalProduction,
        demandChargeRate: demandChargeRate,
      );
      
      if (savings > bestSavings) {
        bestSavings = savings;
        bestThreshold = testThreshold;
      }
    }
    
    return bestThreshold;
  }
  
  /// Optimize self-consumption strategy
  /// Returns optimal battery capacity for maximizing self-consumption
  double optimizeBatterySize({
    required List<double> annualHourlyLoad,
    required List<double> annualHourlyProduction,
    required double electricityBuyPrice,
    required double electricitySellPrice,
    required double batteryCapitalCost, // $ per kWh
    required int batteryLifespanYears,
    required int systemLifespanYears,
  }) {
    // Test a range of battery sizes
    final double maxSize = _estimateOptimalBatterySize(annualHourlyLoad, annualHourlyProduction);
    const double minSize = 0;
    final double step = maxSize / 10;
    
    double bestNPV = 0;
    double optimalSize = 0;
    
    for (double size = minSize; size <= maxSize; size += step) {
      // Skip zero size
      if (size < 0.1) continue;
      
      // Create a battery system with this capacity
      final testBattery = BatterySystem(
        id: 'test_battery',
        manufacturer: 'Optimizer',
        model: 'Test Model',
        capacity: size,
        maxChargePower: size * 0.5, // Assuming 0.5C charge rate
        maxDischargePower: size * 0.5, // Assuming 0.5C discharge rate
        roundTripEfficiency: batterySystem.roundTripEfficiency,
        maxDepthOfDischarge: batterySystem.maxDepthOfDischarge,
        selfDischargeRate: batterySystem.selfDischargeRate,
        cycleLife: batterySystem.cycleLife,
        calendarLifeYears: batterySystem.calendarLifeYears,
        chemistry: batterySystem.chemistry,
        costPerKwh: batteryCapitalCost,
        installationCost: 1000, // Fixed installation cost
      );
      
      // Calculate NPV for this battery size
      final npv = _calculateBatterySizeNPV(
        battery: testBattery,
        annualHourlyLoad: annualHourlyLoad,
        annualHourlyProduction: annualHourlyProduction,
        electricityBuyPrice: electricityBuyPrice,
        electricitySellPrice: electricitySellPrice,
        batteryLifespanYears: batteryLifespanYears,
        systemLifespanYears: systemLifespanYears,
      );
      
      if (npv > bestNPV) {
        bestNPV = npv;
        optimalSize = size;
      }
    }
    
    return optimalSize;
  }
  
  /// Find minimum rate in time-of-use schedule
  double _findMinRate(List<TimeOfUseRate> rates) {
    double minRate = double.infinity;
    for (final rate in rates) {
      if (rate.rate < minRate) {
        minRate = rate.rate;
      }
    }
    return minRate;
  }
  
  /// Find maximum rate in time-of-use schedule
  double _findMaxRate(List<TimeOfUseRate> rates) {
    double maxRate = 0;
    for (final rate in rates) {
      if (rate.rate > maxRate) {
        maxRate = rate.rate;
      }
    }
    return maxRate;
  }
  
  /// Evaluate time-of-use thresholds by simulating a day
  double _evaluateTimeOfUseThresholds({
    required double chargeThreshold,
    required double dischargeThreshold,
    required List<TimeOfUseRate> timeOfUseRates,
    required List<double> typicalLoad,
    required List<double> typicalProduction,
  }) {
    // Create a custom time-of-use control strategy
    final customStrategy = (int hour, double batteryStateOfCharge, double maxCapacity) {
      // Get current rate
      double currentRate = 0.15; // Default rate
      for (final rate in timeOfUseRates) {
        if (hour >= rate.startHour && hour < rate.endHour) {
          currentRate = rate.rate;
          break;
        }
      }
      
      // Determine charge/discharge action based on thresholds
      bool shouldCharge = currentRate <= chargeThreshold && 
                          batteryStateOfCharge < maxCapacity;
                          
      bool shouldDischarge = currentRate >= dischargeThreshold && 
                            batteryStateOfCharge > 0;
      
      return {
        'shouldCharge': shouldCharge,
        'shouldDischarge': shouldDischarge,
      };
    };
    
    // Reset simulator to standard state
    simulator.reset(initialSocPercent: 50.0);
    
    // Simulate a day with these thresholds using the custom strategy
    final result = simulator.simulateDay(
      hourlyLoad: typicalLoad,
      hourlyPvProduction: typicalProduction,
      controlStrategy: BatteryControlStrategy.timeOfUse,
      timeOfUseRates: timeOfUseRates,
      customTimeOfUseStrategy: customStrategy, // Pass the custom strategy here
    );
    
    // Calculate savings compared to no battery
    double costWithoutBattery = 0;
    for (int hour = 0; hour < 24; hour++) {
      // Get TOU rate for this hour
      double rate = 0.15; // Default rate
      for (final touRate in timeOfUseRates) {
        if (hour >= touRate.startHour && hour < touRate.endHour) {
          rate = touRate.rate;
          break;
        }
      }
      
      final production = typicalProduction[hour];
      final load = typicalLoad[hour];
      final netLoad = load - production;
      
      if (netLoad > 0) {
        // Buying from grid
        costWithoutBattery += netLoad * rate;
      } else {
        // Selling to grid (assuming feed-in rate as 30% of purchase rate)
        costWithoutBattery -= -netLoad * rate * 0.3;
      }
    }
    
    // Calculate savings
    return costWithoutBattery - result.dailyCost;
  }
  
  /// Evaluate peak shaving threshold
  double _evaluatePeakShavingThreshold({
    required double threshold,
    required List<double> typicalLoad,
    required List<double> typicalProduction,
    required double demandChargeRate,
  }) {
    // Reset simulator
    simulator.reset(initialSocPercent: 50.0);
    
    // Simulate a day with grid import limit set to threshold
    final result = simulator.simulateDay(
      hourlyLoad: typicalLoad,
      hourlyPvProduction: typicalProduction,
      controlStrategy: BatteryControlStrategy.peakShaving,
      gridImportLimit: threshold,
    );
    
    // Calculate peak with the battery
    double peakWithBattery = 0;
    for (final hourResult in result.hourlyResults) {
      if (hourResult.gridImportPower > peakWithBattery) {
        peakWithBattery = hourResult.gridImportPower;
      }
    }
    
    // Find peak without battery
    double peakWithoutBattery = 0;
    for (int hour = 0; hour < math.min(typicalLoad.length, typicalProduction.length); hour++) {
      final netLoad = typicalLoad[hour] - typicalProduction[hour];
      if (netLoad > peakWithoutBattery) {
        peakWithoutBattery = netLoad;
      }
    }
    
    // Calculate savings from peak reduction
    final peakReduction = peakWithoutBattery - peakWithBattery;
    final peakSavings = peakReduction * demandChargeRate;
    
    // Also include daily energy cost savings
    double costWithoutBattery = 0;
    for (int hour = 0; hour < 24; hour++) {
      final production = typicalProduction[hour];
      final load = typicalLoad[hour];
      final netLoad = load - production;
      
      if (netLoad > 0) {
        // Buying from grid (assume flat rate)
        costWithoutBattery += netLoad * 0.15;
      } else {
        // Selling to grid
        costWithoutBattery -= -netLoad * 0.05;
      }
    }
    
    final energySavings = costWithoutBattery - result.dailyCost;
    
    // Total monthly savings (assuming 30 days per month for demand charges)
    return peakSavings + (energySavings * 30);
  }
  
  /// Estimate a reasonable upper bound for optimal battery size
  double _estimateOptimalBatterySize(
    List<double> annualHourlyLoad,
    List<double> annualHourlyProduction,
  ) {
    // One approach: Size battery to handle daily surplus/deficit
    // Calculate average daily surplus and deficit
    
    // Split data into days
    final int daysInYear = annualHourlyLoad.length ~/ 24;
    double totalSurplus = 0;
    double totalDeficit = 0;
    
    for (int day = 0; day < daysInYear; day++) {
      double daySurplus = 0;
      double dayDeficit = 0;
      
      for (int hour = 0; hour < 24; hour++) {
        final index = day * 24 + hour;
        if (index < annualHourlyLoad.length && index < annualHourlyProduction.length) {
          final netEnergy = annualHourlyProduction[index] - annualHourlyLoad[index];
          if (netEnergy > 0) {
            daySurplus += netEnergy;
          } else {
            dayDeficit -= netEnergy; // Convert to positive value
          }
        }
      }
      
      totalSurplus += daySurplus;
      totalDeficit += dayDeficit;
    }
    
    // Average daily surplus and deficit
    final avgDailySurplus = totalSurplus / daysInYear;
    final avgDailyDeficit = totalDeficit / daysInYear;
    
    // Maximum energy that could potentially be time-shifted in a day
    final potentialTimeShift = math.min(avgDailySurplus, avgDailyDeficit);
    
    // Add 20% margin and adjust for efficiency losses
    return potentialTimeShift * 1.2 / math.sqrt(batterySystem.roundTripEfficiency / 100);
  }
  
  /// Calculate NPV for a specific battery size
  double _calculateBatterySizeNPV({
    required BatterySystem battery,
    required List<double> annualHourlyLoad,
    required List<double> annualHourlyProduction,
    required double electricityBuyPrice,
    required double electricitySellPrice,
    required int batteryLifespanYears,
    required int systemLifespanYears,
  }) {
    // Initialize NPV with negative battery cost
    double npv = -battery.totalCost;
    
    // Create a simulator for this battery
    final batterySimulator = BatterySimulator(
      batterySystem: battery,
      initialSocPercent: 50.0,
    );
    
    // Simulate a full year by breaking it into days
    final int daysInYear = annualHourlyLoad.length ~/ 24;
    double annualSavings = 0;
    
    for (int day = 0; day < daysInYear; day++) {
      // Extract daily profile
      List<double> dailyLoad = [];
      List<double> dailyProduction = [];
      
      for (int hour = 0; hour < 24; hour++) {
        final index = day * 24 + hour;
        if (index < annualHourlyLoad.length && index < annualHourlyProduction.length) {
          dailyLoad.add(annualHourlyLoad[index]);
          dailyProduction.add(annualHourlyProduction[index]);
        }
      }
      
      if (dailyLoad.length == 24 && dailyProduction.length == 24) {
        // Run simulation for this day
        final result = batterySimulator.simulateDay(
          hourlyLoad: dailyLoad,
          hourlyPvProduction: dailyProduction,
          controlStrategy: BatteryControlStrategy.selfConsumption,
          gridImportRate: electricityBuyPrice,
          gridExportRate: electricitySellPrice,
        );
        
        // Calculate cost without battery
        double costWithoutBattery = 0;
        for (int hour = 0; hour < 24; hour++) {
          final netLoad = dailyLoad[hour] - dailyProduction[hour];
          if (netLoad > 0) {
            costWithoutBattery += netLoad * electricityBuyPrice;
          } else {
            costWithoutBattery -= -netLoad * electricitySellPrice;
          }
        }
        
        // Add savings for this day
        annualSavings += costWithoutBattery - result.dailyCost;
      }
    }
    
    // Calculate discounted cash flows for each year
    const double discountRate = 0.05; // Assume 5% discount rate
    int batteryReplacementYear = batteryLifespanYears;
    
    for (int year = 1; year <= systemLifespanYears; year++) {
      // If battery needs replacement
      if (year == batteryReplacementYear) {
        // Battery replacement cost (assume 20% reduction in cost every replacement)
        final replacementCost = battery.totalCost * math.pow(0.8, batteryReplacementYear ~/ batteryLifespanYears);
        npv -= replacementCost / math.pow(1 + discountRate, year);
        
        // Set next replacement year
        batteryReplacementYear += batteryLifespanYears;
      }
      
      // Annual maintenance cost (1% of battery cost)
      final maintenanceCost = battery.totalCost * 0.01;
      
      // Net annual cash flow
      final netCashFlow = annualSavings - maintenanceCost;
      
      // Add discounted cash flow to NPV
      npv += netCashFlow / math.pow(1 + discountRate, year);
    }
    
    return npv;
  }
}

/// Model for storing battery optimization results
class BatteryOptimizationResult {
  final Map<String, dynamic> parameters;
  final Map<String, dynamic> results;
  final List<HourlyBatteryResult> hourlySelfConsumption;
  final List<HourlyBatteryResult> hourlyTimeOfUse;
  final List<HourlyBatteryResult> hourlyPeakShaving;
  final double selfConsumptionSavings;
  final double timeOfUseSavings;
  final double peakShavingSavings;
  final BatteryControlStrategy recommendedStrategy;
  final String explanation;
  
  BatteryOptimizationResult({
    required this.parameters,
    required this.results,
    required this.hourlySelfConsumption,
    required this.hourlyTimeOfUse,
    required this.hourlyPeakShaving,
    required this.selfConsumptionSavings,
    required this.timeOfUseSavings,
    required this.peakShavingSavings,
    required this.recommendedStrategy,
    required this.explanation,
  });
  
  /// Get the results for a specific strategy
  List<HourlyBatteryResult> getHourlyResults(BatteryControlStrategy strategy) {
    switch (strategy) {
      case BatteryControlStrategy.selfConsumption:
        return hourlySelfConsumption;
      case BatteryControlStrategy.timeOfUse:
        return hourlyTimeOfUse;
      case BatteryControlStrategy.peakShaving:
        return hourlyPeakShaving;
      default:
        return hourlySelfConsumption;
    }
  }
  
  /// Get the annual savings for a strategy
  double getAnnualSavings(BatteryControlStrategy strategy) {
    switch (strategy) {
      case BatteryControlStrategy.selfConsumption:
        return selfConsumptionSavings * 365;
      case BatteryControlStrategy.timeOfUse:
        return timeOfUseSavings * 365;
      case BatteryControlStrategy.peakShaving:
        return peakShavingSavings * 12; // Monthly peak charges
      default:
        return selfConsumptionSavings * 365;
    }
  }
  
  /// Calculate the payback period for a strategy
  double getPaybackPeriod(BatteryControlStrategy strategy, double batteryCost) {
    final annualSavings = getAnnualSavings(strategy);
    if (annualSavings <= 0) return double.infinity;
    return batteryCost / annualSavings;
  }
}