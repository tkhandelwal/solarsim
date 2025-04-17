// lib/core/battery_simulator.dart
import 'dart:math' as math;
import '../models/battery_system.dart';

/// Time-of-use electricity rate
class TimeOfUseRate {
  final int startHour;
  final int endHour;
  final double rate; // $/kWh
  final String name; // e.g., "Peak", "Off-Peak"
  
  TimeOfUseRate({
    required this.startHour,
    required this.endHour,
    required this.rate,
    required this.name,
  });
}

/// Hourly simulation result for battery operation
class HourlyBatteryResult {
  final int hour;
  final double stateOfCharge; // kWh
  final double stateOfChargePercent; // %
  final double batteryChargePower; // kW
  final double batteryDischargePower; // kW
  final double gridImportPower; // kW
  final double gridExportPower; // kW
  final double pvToLoad; // kW
  final double pvToBattery; // kW
  final double pvToGrid; // kW
  final double batteryToLoad; // kW
  final double gridToLoad; // kW
  final double cost; // $
  
  HourlyBatteryResult({
    required this.hour,
    required this.stateOfCharge,
    required this.stateOfChargePercent,
    required this.batteryChargePower,
    required this.batteryDischargePower,
    required this.gridImportPower,
    required this.gridExportPower,
    required this.pvToLoad,
    required this.pvToBattery,
    required this.pvToGrid,
    required this.batteryToLoad,
    required this.gridToLoad,
    required this.cost,
  });
}

/// Daily simulation result for battery operation
class DailyBatteryResult {
  final List<HourlyBatteryResult> hourlyResults;
  final double initialStateOfCharge; // kWh
  final double finalStateOfCharge; // kWh
  final double totalPvProduction; // kWh
  final double totalLoad; // kWh
  final double totalGridImport; // kWh
  final double totalGridExport; // kWh
  final double totalSelfConsumed; // kWh (PV directly to load + PV to battery to load)
  final double batteryChargeThroughput; // kWh
  final double batteryDischargeThroughput; // kWh
  final double selfConsumptionRate; // % of PV production
  final double selfSufficiencyRate; // % of load
  final double dailyCost; // $
  final double batteryUtilization; // % of battery capacity used
  final double cycleEquivalent; // fraction of a full cycle
  
  DailyBatteryResult({
    required this.hourlyResults,
    required this.initialStateOfCharge,
    required this.finalStateOfCharge,
    required this.totalPvProduction,
    required this.totalLoad,
    required this.totalGridImport,
    required this.totalGridExport,
    required this.totalSelfConsumed,
    required this.batteryChargeThroughput,
    required this.batteryDischargeThroughput,
    required this.selfConsumptionRate,
    required this.selfSufficiencyRate,
    required this.dailyCost,
    required this.batteryUtilization,
    required this.cycleEquivalent,
  });
}

/// Battery model for simulating battery operation with different control strategies
class BatterySimulator {
  final BatterySystem batterySystem;
  double _stateOfCharge; // kWh
  double _cycleCount = 0;
  double _calendarAge = 0; // years
  double _degradationFactor = 1.0;
  
  BatterySimulator({
    required this.batterySystem,
    double initialSocPercent = 50.0,
  }) : _stateOfCharge = (initialSocPercent / 100) * batterySystem.capacity * 0.9;
  
  /// Reset the simulation state
  void reset({double initialSocPercent = 50.0}) {
    _stateOfCharge = (initialSocPercent / 100) * batterySystem.capacity * 0.9;
    _cycleCount = 0;
    _calendarAge = 0;
    _degradationFactor = 1.0;
  }
  
  /// Get state of charge (kWh)
  double get stateOfCharge => _stateOfCharge;
  
  /// Get state of charge as percentage
  double get stateOfChargePercent => (_stateOfCharge / (batterySystem.capacity * _degradationFactor)) * 100;
  
  /// Get remaining capacity (kWh)
  double get remainingCapacity => batterySystem.capacity * _degradationFactor;
  
  /// Get degradation factor
  double get degradationFactor => _degradationFactor;
  
  /// Get cycle count
  double get cycleCount => _cycleCount;
  
  /// Simulate battery operation for a day
  /// hourlyLoad and hourlyPvProduction should be kW for each hour of the day (24 values)
  DailyBatteryResult simulateDay({
    required List<double> hourlyLoad,
    required List<double> hourlyPvProduction,
    required BatteryControlStrategy controlStrategy,
    List<TimeOfUseRate>? timeOfUseRates,
    double gridImportRate = 0.15, // $/kWh
    double gridExportRate = 0.05, // $/kWh
    double? gridImportLimit,
    double? gridExportLimit,
  }) {
    if (hourlyLoad.length != 24 || hourlyPvProduction.length != 24) {
      throw ArgumentError('Hourly load and PV profiles must have 24 values');
    }
    
    // Initialize hourly results
    final hourlyResults = <HourlyBatteryResult>[];
    final initialSoc = _stateOfCharge;
    
    // Calculate effective capacity accounting for degradation
    final effectiveCapacity = batterySystem.capacity * _degradationFactor;
    final minSoc = effectiveCapacity * (1 - batterySystem.maxDepthOfDischarge);
    
    // Initialize totals
    double totalPvProduction = 0;
    double totalLoad = 0;
    double totalGridImport = 0;
    double totalGridExport = 0;
    double totalSelfConsumed = 0;
    double totalCost = 0;
    double batteryChargeThroughput = 0;
    double batteryDischargeThroughput = 0;
    
    // Process each hour
    for (int hour = 0; hour < 24; hour++) {
      final load = hourlyLoad[hour];
      final pvProduction = hourlyPvProduction[hour];
      
      // Update totals
      totalPvProduction += pvProduction;
      totalLoad += load;
      
      // Calculate energy balance (negative means excess, positive means deficit)
      final energyBalance = load - pvProduction;
      
      // Initialize hourly energy flows
      double batteryCharge = 0;
      double batteryDischarge = 0;
      double gridImport = 0;
      double gridExport = 0;
      double pvToLoad = 0;
      double pvToBattery = 0;
      double pvToGrid = 0;
      double batteryToLoad = 0;
      double gridToLoad = 0;
      
      // Get current import rate for this hour
      double currentImportRate = gridImportRate;
      if (controlStrategy == BatteryControlStrategy.timeOfUse && timeOfUseRates != null) {
        for (final rate in timeOfUseRates) {
          if (hour >= rate.startHour && hour < rate.endHour) {
            currentImportRate = rate.rate;
            break;
          }
        }
      }
      
      // Determine battery operation based on control strategy
      if (energyBalance < 0) {
        // Excess PV production
        final excessProduction = -energyBalance;
        
        // Direct PV consumption
        pvToLoad = load;
        
        // Should we charge the battery?
        bool shouldChargeBattery = true;
        
        if (controlStrategy == BatteryControlStrategy.timeOfUse) {
          // For TOU, check if we're in a low-price period
          // We might want to avoid charging if electricity is cheap now
          // and we anticipate higher prices later
          final currentHourPrice = currentImportRate;
          final averagePrice = _calculateAverageTouRate(timeOfUseRates);
          shouldChargeBattery = currentHourPrice <= averagePrice;
        }
        
        if (shouldChargeBattery && _stateOfCharge < effectiveCapacity) {
          // Available charging power (limited by battery power rating)
          final maxChargePower = math.min(excessProduction, batterySystem.maxChargePower);
          
          // Available capacity in battery
          final availableCapacity = effectiveCapacity - _stateOfCharge;
          
          // Calculate actual charge (accounting for charging efficiency)
          final chargingEfficiency = math.sqrt(batterySystem.roundTripEfficiency);
          final actualCharge = math.min(maxChargePower, availableCapacity / chargingEfficiency);
          
          // Update battery state
          batteryCharge = actualCharge;
          _stateOfCharge += actualCharge * chargingEfficiency;
          batteryChargeThroughput += actualCharge;
          
          // Track energy flow
          pvToBattery = actualCharge;
          totalSelfConsumed += actualCharge;
          
          // Remaining excess goes to grid
          final remainingExcess = excessProduction - actualCharge;
          if (remainingExcess > 0) {
            // Apply grid export limit if specified
            if (gridExportLimit != null) {
              gridExport = math.min(remainingExcess, gridExportLimit);
            } else {
              gridExport = remainingExcess;
            }
            pvToGrid = gridExport;
          }
        } else {
          // Battery is full or we chose not to charge, export all excess
          if (gridExportLimit != null) {
            gridExport = math.min(excessProduction, gridExportLimit);
          } else {
            gridExport = excessProduction;
          }
          pvToGrid = gridExport;
        }
      } else {
        // Energy deficit (load > production)
        final deficit = energyBalance;
        
        // Direct PV consumption
        pvToLoad = pvProduction;
        
        // Should we discharge the battery?
        bool shouldDischargeBattery = true;
        
        if (controlStrategy == BatteryControlStrategy.timeOfUse) {
          // For TOU, check if we're in a high-price period
          final currentHourPrice = currentImportRate;
          final averagePrice = _calculateAverageTouRate(timeOfUseRates);
          shouldDischargeBattery = currentHourPrice > averagePrice;
        } else if (controlStrategy == BatteryControlStrategy.peakShaving) {
          // For peak shaving, check if the current load would create a new peak
          if (gridImportLimit != null) {
            shouldDischargeBattery = deficit > gridImportLimit * 0.8;
          }
        }
        
        if (shouldDischargeBattery && _stateOfCharge > minSoc) {
          // Available discharging power (limited by battery power rating)
          final maxDischargePower = math.min(deficit, batterySystem.maxDischargePower);
          
          // Available energy in battery
          final availableEnergy = _stateOfCharge - minSoc;
          
          // Calculate actual discharge (accounting for discharge efficiency)
          final dischargingEfficiency = math.sqrt(batterySystem.roundTripEfficiency);
          final actualDischarge = math.min(maxDischargePower, availableEnergy * dischargingEfficiency);
          
          // Update battery state
          batteryDischarge = actualDischarge;
          _stateOfCharge -= actualDischarge / dischargingEfficiency;
          batteryDischargeThroughput += actualDischarge;
          
          // Track energy flow
          batteryToLoad = actualDischarge;
          totalSelfConsumed += actualDischarge; // from PV through battery
          
          // Remaining deficit from grid
          final remainingDeficit = deficit - actualDischarge;
          if (remainingDeficit > 0) {
            // Apply grid import limit if specified
            if (gridImportLimit != null) {
              gridImport = math.min(remainingDeficit, gridImportLimit);
            } else {
              gridImport = remainingDeficit;
            }
            gridToLoad = gridImport;
          }
        } else {
          // Battery is empty or we chose not to discharge, import all deficit
          if (gridImportLimit != null) {
            gridImport = math.min(deficit, gridImportLimit);
          } else {
            gridImport = deficit;
          }
          gridToLoad = gridImport;
        }
      }
      
      // Update totals
      totalGridImport += gridImport;
      totalGridExport += gridExport;
      
      // Calculate cost for this hour
      final importCost = gridImport * currentImportRate;
      final exportRevenue = gridExport * gridExportRate;
      final hourCost = importCost - exportRevenue;
      totalCost += hourCost;
      
      // Add hourly result
      hourlyResults.add(HourlyBatteryResult(
        hour: hour,
        stateOfCharge: _stateOfCharge,
        stateOfChargePercent: (_stateOfCharge / effectiveCapacity) * 100,
        batteryChargePower: batteryCharge,
        batteryDischargePower: batteryDischarge,
        gridImportPower: gridImport,
        gridExportPower: gridExport,
        pvToLoad: pvToLoad,
        pvToBattery: pvToBattery,
        pvToGrid: pvToGrid,
        batteryToLoad: batteryToLoad,
        gridToLoad: gridToLoad,
        cost: hourCost,
      ));
    }
    
    // Calculate metrics
    final selfConsumptionRate = totalPvProduction > 0 
        ? totalSelfConsumed / totalPvProduction * 100 
        : 0;
    
    final selfSufficiencyRate = totalLoad > 0 
        ? (totalLoad - totalGridImport) / totalLoad * 100 
        : 0;
    
    // Calculate cycle equivalent
    final cycleEquivalent = batteryChargeThroughput / effectiveCapacity;
    _cycleCount += cycleEquivalent;
    
    // Calculate battery utilization
    final batteryUtilization = (batteryChargeThroughput + batteryDischargeThroughput) / 
        (2 * effectiveCapacity) * 100;
    
    // Update calendar age and degradation
    _calendarAge += 1 / 365; // Add one day
    _updateDegradation();
    
    return DailyBatteryResult(
      hourlyResults: hourlyResults,
      initialStateOfCharge: initialSoc,
      finalStateOfCharge: _stateOfCharge,
      totalPvProduction: totalPvProduction,
      totalLoad: totalLoad,
      totalGridImport: totalGridImport,
      totalGridExport: totalGridExport,
      totalSelfConsumed: totalSelfConsumed,
      batteryChargeThroughput: batteryChargeThroughput,
      batteryDischargeThroughput: batteryDischargeThroughput,
      selfConsumptionRate: selfConsumptionRate.toDouble(),
      selfSufficiencyRate: selfSufficiencyRate.toDouble(),
      dailyCost: totalCost,
      batteryUtilization: batteryUtilization,
      cycleEquivalent: cycleEquivalent,
    );
  }
  
  /// Update capacity degradation based on cycle count and calendar age
  void _updateDegradation() {
    // Simplified degradation model
    // Combines cycle degradation and calendar degradation
    
    // Cycle degradation (linear model)
    final cycleAgingFactor = math.min(1.0, _cycleCount / batterySystem.cycleLife);
    
    // Calendar degradation (linear model)
    final calendarAgingFactor = math.min(1.0, _calendarAge / batterySystem.calendarLifeYears);
    
    // Combined degradation (take the worse of the two)
    final combinedAgingFactor = math.max(cycleAgingFactor, calendarAgingFactor);
    
    // Calculate degradation factor (remaining capacity percentage)
    // Most batteries have 80% end-of-life criteria
    _degradationFactor = 1.0 - (combinedAgingFactor * 0.2);
  }
  
  /// Calculate average TOU rate
  double _calculateAverageTouRate(List<TimeOfUseRate>? rates) {
    if (rates == null || rates.isEmpty) {
      return 0.15; // Default rate
    }
    
    double sum = 0;
    int count = 0;
    
    for (final rate in rates) {
      final hours = rate.endHour - rate.startHour;
      sum += rate.rate * hours;
      count += hours;
    }
    
    return count > 0 ? sum / count : 0.15;
  }
  
  /// Simulate self-consumption for multiple days with different profiles
  List<DailyBatteryResult> simulateMultipleDays({
    required List<List<double>> dailyLoadProfiles,
    required List<List<double>> dailyPvProfiles,
    required BatteryControlStrategy controlStrategy,
    List<TimeOfUseRate>? timeOfUseRates,
    double gridImportRate = 0.15,
    double gridExportRate = 0.05,
  }) {
    final results = <DailyBatteryResult>[];
    
    for (int day = 0; day < dailyLoadProfiles.length; day++) {
      final dailyResult = simulateDay(
        hourlyLoad: dailyLoadProfiles[day],
        hourlyPvProduction: dailyPvProfiles[day],
        controlStrategy: controlStrategy,
        timeOfUseRates: timeOfUseRates,
        gridImportRate: gridImportRate,
        gridExportRate: gridExportRate,
      );
      
      results.add(dailyResult);
    }
    
    return results;
  }
  
  /// Project long-term economics of battery system
  Map<String, dynamic> projectEconomics({
    required int yearsToProject,
    required double annualLoadkWh,
    required double annualPvProductionkWh,
    required double gridImportRate,
    required double gridExportRate,
    required double annualElectricityPriceInflation,
    required double discountRate,
    required BatteryControlStrategy controlStrategy,
  }) {
    // Initial investment
    final initialInvestment = batterySystem.totalCost;
    
    // Annual operation and maintenance cost (1% of battery cost)
    final annualOandM = initialInvestment * 0.01;
    
    // Estimated savings per day with battery
    // This is a simplification - in a real implementation you would
    // run the simulation for typical days and average the results
    double dailySavingsWithBattery = 0;
    double dailySavingsWithoutBattery = 0;
    
    // Simplified model for daily savings:
    // With Battery: Assume 70% self-consumption
    // Without Battery: Assume 30% self-consumption
    final dailyPvProduction = annualPvProductionkWh / 365;
    final dailyLoad = annualLoadkWh / 365;
    
    // Distribute load and production to 24 hours using typical profiles
    final typicalLoadProfile = _generateTypicalLoadProfile(dailyLoad);
    final typicalPvProfile = _generateTypicalPvProfile(dailyPvProduction);
    
    // Calculate baseline cost without battery
    double baselineCost = 0;
    for (int hour = 0; hour < 24; hour++) {
      final load = typicalLoadProfile[hour];
      final pv = typicalPvProfile[hour];
      
      final directUse = math.min(load, pv);
      final gridImport = load - directUse;
      final gridExport = math.max(0, pv - directUse);
      
      baselineCost += gridImport * gridImportRate - gridExport * gridExportRate;
    }
    
    // Calculate cost with battery
    final batteryResult = simulateDay(
      hourlyLoad: typicalLoadProfile,
      hourlyPvProduction: typicalPvProfile,
      controlStrategy: controlStrategy,
      gridImportRate: gridImportRate,
      gridExportRate: gridExportRate,
    );
    
    final costWithBattery = batteryResult.dailyCost;
    
    // Calculate daily savings
    final dailySavings = baselineCost - costWithBattery;
    
    // Project annual savings
    final annualSavings = dailySavings * 365;
    
    // Expected battery replacement costs
    // Assume battery needs replacement when it reaches 80% of capacity
    final batteryLifespan = math.min(
      batterySystem.cycleLife / (batteryResult.cycleEquivalent * 365),
      batterySystem.calendarLifeYears.toDouble()
    );
    
    // Calculate number of battery replacements needed
    final replacementsNeeded = (yearsToProject / batteryLifespan).floor();
    
    // Calculate replacement costs (assume battery costs decrease by 5% per year)
    final replacementCosts = <int, double>{};
    for (int i = 1; i <= replacementsNeeded; i++) {
      final replacementYear = (batteryLifespan * i).round();
      if (replacementYear < yearsToProject) {
        final costReduction = math.pow(0.95, replacementYear); // 5% annual cost reduction
        replacementCosts[replacementYear] = batterySystem.totalCost * costReduction;
      }
    }
    
    // Calculate year-by-year cash flows
    final yearlyNetCashFlow = <int, double>{};
    final yearlyCumulativeCashFlow = <int, double>{};
    
    // Initial investment (year 0)
    yearlyNetCashFlow[0] = -initialInvestment;
    yearlyCumulativeCashFlow[0] = -initialInvestment;
    
    // Calculate NPV and discounted payback period
    double npv = -initialInvestment;
    int discountedPaybackYear = yearsToProject + 1; // Default to beyond projection period
    
    for (int year = 1; year <= yearsToProject; year++) {
      // Calculate savings with inflation
      final inflationFactor = math.pow(1 + annualElectricityPriceInflation, year - 1);
      final yearlyEnergySavings = annualSavings * inflationFactor;
      
      // Calculate net cash flow
      double yearCashFlow = yearlyEnergySavings - annualOandM;
      
      // Subtract replacement cost if needed
      if (replacementCosts.containsKey(year)) {
        yearCashFlow -= replacementCosts[year]!;
      }
      
      yearlyNetCashFlow[year] = yearCashFlow;
      
      // Update cumulative cash flow
      yearlyCumulativeCashFlow[year] = (yearlyCumulativeCashFlow[year - 1] ?? 0) + yearCashFlow;
      
      // Calculate discounted cash flow for NPV
      final discountedCashFlow = yearCashFlow / math.pow(1 + discountRate, year);
      npv += discountedCashFlow;
      
      // Check for discounted payback
      if (discountedPaybackYear > yearsToProject && npv >= 0) {
        discountedPaybackYear = year;
      }
    }
    
    // Calculate simple payback period
    double simplePaybackPeriod = initialInvestment / annualSavings;
    
    // If replacements are needed before payback, adjust
    for (final entry in replacementCosts.entries) {
      if (entry.key < simplePaybackPeriod) {
        simplePaybackPeriod += entry.value / annualSavings;
      }
    }
    
    // Estimate IRR using Newton-Raphson method
    double irr = _calculateIRR(yearlyNetCashFlow, yearsToProject);
    
    // Return all economic metrics
    return {
      'npv': npv,
      'irr': irr,
      'simplePaybackPeriod': simplePaybackPeriod,
      'discountedPaybackPeriod': discountedPaybackYear > yearsToProject ? double.infinity : discountedPaybackYear.toDouble(),
      'batteryLifespan': batteryLifespan,
      'replacementsNeeded': replacementsNeeded,
      'yearlyCashFlow': yearlyNetCashFlow,
      'yearlyCumulativeCashFlow': yearlyCumulativeCashFlow,
      'annualSavings': annualSavings,
      'batteryDailyUsage': batteryResult.cycleEquivalent,
      'selfConsumptionRate': batteryResult.selfConsumptionRate,
      'selfSufficiencyRate': batteryResult.selfSufficiencyRate,
    };
  }
  
  /// Calculate IRR using Newton-Raphson method
  double _calculateIRR(Map<int, double> cashFlows, int years) {
    // Initial guess
    double irr = 0.1;
    
    // Newton-Raphson iteration
    for (int i = 0; i < 100; i++) {
      double npv = 0;
      double derivative = 0;
      
      for (int year = 0; year <= years; year++) {
        final cashFlow = cashFlows[year] ?? 0;
        final discountFactor = math.pow(1 + irr, year);
        
        npv += cashFlow / discountFactor;
        if (year > 0) {
          derivative -= year * cashFlow / math.pow(1 + irr, year + 1);
        }
      }
      
      // Check if we're close enough to zero
      if (npv.abs() < 0.001) {
        return irr;
      }
      
      // Update irr using Newton-Raphson formula
      final delta = npv / derivative;
      irr -= delta;
      
      // Bound irr to avoid divergence
      if (irr < -0.9) irr = -0.9;
      if (irr > 0.9) irr = 0.9;
    }
    
    return irr;
  }
  
  /// Generate a typical residential load profile (hourly kW for a day)
  List<double> _generateTypicalLoadProfile(double dailyTotal) {
    // Typical residential load pattern with morning and evening peaks
    final hourlyFactors = [
      0.3, 0.2, 0.2, 0.2, 0.2, 0.3, // 0-5h
      0.5, 0.7, 0.9, 0.7, 0.6, 0.6, // 6-11h
      0.7, 0.7, 0.6, 0.6, 0.7, 1.0, // 12-17h
      1.2, 1.0, 0.8, 0.6, 0.4, 0.3, // 18-23h
    ];
    
    // Sum of factors
    final sumFactors = hourlyFactors.reduce((sum, factor) => sum + factor);
    
    // Scale factors to match daily total
    return hourlyFactors.map((factor) => factor * dailyTotal / sumFactors).toList();
  }
  
  /// Generate a typical PV production profile (hourly kW for a day)
  List<double> _generateTypicalPvProfile(double dailyTotal) {
    // Simplified bell curve centered around noon
    final hourlyFactors = [
      0.0, 0.0, 0.0, 0.0, 0.0, 0.0, // 0-5h
      0.1, 0.3, 0.5, 0.7, 0.9, 1.0, // 6-11h
      1.0, 0.9, 0.7, 0.5, 0.3, 0.1, // 12-17h
      0.0, 0.0, 0.0, 0.0, 0.0, 0.0, // 18-23h
    ];
    
    // Sum of factors
    final sumFactors = hourlyFactors.reduce((sum, factor) => sum + factor);
    
    // Scale factors to match daily total
    return hourlyFactors.map((factor) => factor * dailyTotal / sumFactors).toList();
  }
}