// lib/widgets/battery_storage_simulation.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

class BatteryStorageSimulation extends StatefulWidget {
  final double dailyEnergyProduction;
  final double batteryCapacity;
  final double batteryPowerRating;
  final double batteryCost;
  final double electricityRate;
  final double feedInRate;
  
  const BatteryStorageSimulation({
    super.key,
    required this.dailyEnergyProduction,
    required this.batteryCapacity,
    required this.batteryPowerRating,
    required this.batteryCost,
    required this.electricityRate,
    required this.feedInRate,
  });

  @override
  State<BatteryStorageSimulation> createState() => _BatteryStorageSimulationState();
}

class _BatteryStorageSimulationState extends State<BatteryStorageSimulation> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Battery parameters
  double _batteryCapacity = 10.0; // kWh
  double _chargePower = 5.0; // kW
  double _dischargePower = 5.0; // kW
  double _roundTripEfficiency = 90.0; // %
  int _cycleLifetime = 5000; // cycles
  double _depthOfDischarge = 90.0; // %
  int _selectedDay = 0; // 0 = typical day, 1 = cloudy day, 2 = peak generation day
  
  // Load profile parameters
  double _dailyConsumption = 20.0; // kWh
  double _morningPeakPercent = 15.0; // % of daily consumption
  double _eveningPeakPercent = 40.0; // % of daily consumption
  double _nightTimeConsumptionPercent = 20.0; // % of daily consumption
  
  // Battery control strategy
  int _controlStrategy = 0; // 0 = self-consumption, 1 = time-of-use, 2 = peak shaving
  final List<double> _timeOfUseRates = [0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 
                                 0.15, 0.25, 0.25, 0.15, 0.15, 0.15,
                                 0.15, 0.15, 0.15, 0.15, 0.25, 0.35,
                                 0.35, 0.35, 0.25, 0.15, 0.10, 0.10]; // $/kWh
  
  // Grid parameters
  double _gridImportLimit = 4.0; // kW
  double _gridExportLimit = 5.0; // kW
  
  // Simulation results
  Map<String, dynamic> _results = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Initialize battery capacity from widget
    _batteryCapacity = widget.batteryCapacity;
    _chargePower = widget.batteryPowerRating;
    _dischargePower = widget.batteryPowerRating;
    
    // Run initial simulation
    _runSimulation();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _runSimulation() {
    // Generate hourly load profile
    final hourlyLoad = _generateLoadProfile();
    
    // Generate hourly production profile
    final hourlyProduction = _generateProductionProfile();
    
    // For three types of days: typical, cloudy, and peak generation
    final dayTypes = ['Typical', 'Cloudy', 'Peak'];
    final simResults = <String, Map<String, dynamic>>{};
    
    for (int i = 0; i < 3; i++) {
      final productionFactor = i == 0 ? 1.0 : (i == 1 ? 0.5 : 1.3);
      final dayProduction = List<double>.from(hourlyProduction.map((p) => p * productionFactor));
      
      // Run battery simulation
      final dayResults = _simulateBatteryOperation(hourlyLoad, dayProduction);
      simResults[dayTypes[i]] = dayResults;
    }
    
    // Calculate economic metrics
    final annualSavings = _calculateAnnualSavings(simResults);
    final paybackPeriod = widget.batteryCost / annualSavings;
    final batteryLifetime = _calculateBatteryLifetime();
    
    // Store simulation results
    setState(() {
      _results = {
        'hourlyLoad': hourlyLoad,
        'hourlyProduction': hourlyProduction,
        'dayResults': simResults,
        'annualSavings': annualSavings,
        'paybackPeriod': paybackPeriod,
        'batteryLifetime': batteryLifetime,
      };
    });
  }
  
  List<double> _generateLoadProfile() {
    // Generate a 24-hour load profile with morning and evening peaks
    final hourlyLoad = List<double>.filled(24, 0);
    
    // Base load (remaining consumption spread evenly)
    final baseLoadPercent = 100.0 - _morningPeakPercent - _eveningPeakPercent - _nightTimeConsumptionPercent;
    final baseLoad = _dailyConsumption * baseLoadPercent / 100 / 14; // per hour during daytime
    
    // Night load (lower constant load from 10pm to 6am)
    final nightLoad = _dailyConsumption * _nightTimeConsumptionPercent / 100 / 8; // per hour during night
    
    // Morning peak (6am to 9am)
    final morningPeakLoad = _dailyConsumption * _morningPeakPercent / 100 / 3; // per hour during morning peak
    
    // Evening peak (5pm to 9pm)
    final eveningPeakLoad = _dailyConsumption * _eveningPeakPercent / 100 / 4; // per hour during evening peak
    
    // Assign loads for each hour
    for (int hour = 0; hour < 24; hour++) {
      if (hour >= 22 || hour < 6) {
        // Night hours
        hourlyLoad[hour] = nightLoad;
      } else if (hour >= 6 && hour < 9) {
        // Morning peak
        hourlyLoad[hour] = morningPeakLoad;
      } else if (hour >= 17 && hour < 21) {
        // Evening peak
        hourlyLoad[hour] = eveningPeakLoad;
      } else {
        // Daytime base load
        hourlyLoad[hour] = baseLoad;
      }
    }
    
    return hourlyLoad;
  }
  
  List<double> _generateProductionProfile() {
    // Generate a bell-shaped solar production curve centered around noon
    final hourlyProduction = List<double>.filled(24, 0);
    final totalProduction = widget.dailyEnergyProduction;
    
    // Production only occurs between sunrise and sunset
    // Assume sunrise at 6am and sunset at 6pm (simplified)
    for (int hour = 6; hour < 18; hour++) {
      // Create a bell curve with peak at noon (hour 12)
      final position = (hour - 12) / 6; // -1 to 1 during daylight
      final bellCurveValue = math.exp(-3.5 * position * position);
      
      // Scale to match total daily production
      hourlyProduction[hour] = bellCurveValue;
    }
    
    // Normalize to match total daily production
    final sum = hourlyProduction.reduce((a, b) => a + b);
    for (int hour = 0; hour < 24; hour++) {
      hourlyProduction[hour] = hourlyProduction[hour] / sum * totalProduction;
    }
    
    return hourlyProduction;
  }
  
  Map<String, dynamic> _simulateBatteryOperation(List<double> hourlyLoad, List<double> hourlyProduction) {
    // Initialize battery state
    double batteryEnergyLevel = _batteryCapacity * 0.5; // Start at 50% state of charge
    final maxEnergy = _batteryCapacity * (_depthOfDischarge / 100); // Maximum usable capacity
    
    // Hourly simulation results
    final batteryChargeArr = List<double>.filled(24, 0);
    final batteryDischargeArr = List<double>.filled(24, 0);
    final batteryLevelArr = List<double>.filled(24, 0);
    final gridImportArr = List<double>.filled(24, 0);
    final gridExportArr = List<double>.filled(24, 0);
    final hourlyPvToLoadArr = List<double>.filled(24, 0);
    final hourlyPvToBatteryArr = List<double>.filled(24, 0);
    final hourlyPvToGridArr = List<double>.filled(24, 0);
    final hourlyBatteryToLoadArr = List<double>.filled(24, 0);
    final hourlyGridToLoadArr = List<double>.filled(24, 0);
    final hourlyCostArr = List<double>.filled(24, 0);
    
    // Track daily metrics
    double dailySelfConsumption = 0;
    double dailyGridImport = 0;
    double dailyGridExport = 0;
    double dailyCost = 0;
    double maxGridImport = 0;
    double maxGridExport = 0;
    
    // Cycle counting
    double cycleEquivalent = 0;
    
    // Simulate each hour of the day
    for (int hour = 0; hour < 24; hour++) {
      // Get rates for this hour
      final importRate = _controlStrategy == 1 ? _timeOfUseRates[hour] : widget.electricityRate;
      final exportRate = widget.feedInRate;
      
      // Calculate energy balance
      final production = hourlyProduction[hour];
      final load = hourlyLoad[hour];
      final energyBalance = production - load;
      
      // Reset hourly values
      batteryChargeArr[hour] = 0;
      batteryDischargeArr[hour] = 0;
      gridImportArr[hour] = 0;
      gridExportArr[hour] = 0;
      hourlyPvToLoadArr[hour] = 0;
      hourlyPvToBatteryArr[hour] = 0;
      hourlyPvToGridArr[hour] = 0;
      hourlyBatteryToLoadArr[hour] = 0;
      hourlyGridToLoadArr[hour] = 0;
      
      if (energyBalance > 0) {
        // Excess solar production
        
        // First, directly cover the load
        hourlyPvToLoadArr[hour] = load;
        
        // Then, determine what to do with excess
        double excess = energyBalance;
        
        // Should we charge the battery?
        bool shouldChargeBattery = true;
        if (_controlStrategy == 1) {
          // For time-of-use, only charge if current electricity price is low
          shouldChargeBattery = importRate < 0.20; // arbitrary threshold
        } else if (_controlStrategy == 2) {
          // For peak shaving, always prioritize battery charging
          shouldChargeBattery = true;
        }
        
        if (shouldChargeBattery && batteryEnergyLevel < maxEnergy) {
          // Charge battery with excess power (limited by charge rate and remaining capacity)
          final chargeAmount = math.min(excess, _chargePower);
          final capacityLimit = maxEnergy - batteryEnergyLevel;
          final actualCharge = math.min(chargeAmount, capacityLimit);
          
          batteryEnergyLevel += actualCharge * (_roundTripEfficiency / 100);
          batteryChargeArr[hour] = actualCharge;
          hourlyPvToBatteryArr[hour] = actualCharge;
          excess -= actualCharge;
          
          // Count partial cycle
          cycleEquivalent += actualCharge / _batteryCapacity;
        }
        
        // Export any remaining excess to grid
        if (excess > 0) {
          // Limited by grid export capacity
          final exportAmount = math.min(excess, _gridExportLimit);
          gridExportArr[hour] = exportAmount;
          hourlyPvToGridArr[hour] = exportAmount;
          dailyGridExport += exportAmount;
          
          if (exportAmount > maxGridExport) {
            maxGridExport = exportAmount;
          }
        }
      } else {
        // Energy deficit (load > production)
        
        // First, directly use available solar
        hourlyPvToLoadArr[hour] = production;
        
        // Then, determine how to cover the deficit
        double deficit = -energyBalance;
        
        // Should we discharge the battery?
        bool shouldDischargeBattery = true;
        if (_controlStrategy == 1) {
          // For time-of-use, discharge during high-price periods
          shouldDischargeBattery = importRate > 0.20; // arbitrary threshold
        } else if (_controlStrategy == 2) {
          // For peak shaving, check if discharging would help avoid a new peak
          final projectedGridImport = deficit > _gridImportLimit ? _gridImportLimit : deficit;
          shouldDischargeBattery = projectedGridImport > maxGridImport * 0.7; // arbitrary threshold
        }
        
        if (shouldDischargeBattery && batteryEnergyLevel > 0) {
          // Discharge battery to cover deficit (limited by discharge rate and available energy)
          final dischargeAmount = math.min(deficit, _dischargePower);
          final availableEnergy = batteryEnergyLevel;
          final actualDischarge = math.min(dischargeAmount, availableEnergy);
          
          batteryEnergyLevel -= actualDischarge;
          batteryDischargeArr[hour] = actualDischarge;
          hourlyBatteryToLoadArr[hour] = actualDischarge;
          deficit -= actualDischarge;
          
          // Count partial cycle
          cycleEquivalent += actualDischarge / _batteryCapacity;
        }
        
        // Import any remaining deficit from grid
        if (deficit > 0) {
          // Limited by grid import capacity
          final importAmount = math.min(deficit, _gridImportLimit);
          gridImportArr[hour] = importAmount;
          hourlyGridToLoadArr[hour] = importAmount;
          dailyGridImport += importAmount;
          
          if (importAmount > maxGridImport) {
            maxGridImport = importAmount;
          }
        }
      }
      
      // Record battery level for this hour
      batteryLevelArr[hour] = batteryEnergyLevel;
      
      // Calculate cost for this hour
      final importCost = gridImportArr[hour] * importRate;
      final exportRevenue = gridExportArr[hour] * exportRate;
      hourlyCostArr[hour] = importCost - exportRevenue;
      dailyCost += hourlyCostArr[hour];
      
      // Track self-consumption
      dailySelfConsumption += hourlyPvToLoadArr[hour] + hourlyPvToBatteryArr[hour];
    }
    
    // Calculate metrics
    final totalProduction = hourlyProduction.reduce((a, b) => a + b);
    final totalConsumption = hourlyLoad.reduce((a, b) => a + b);
    final selfConsumptionRate = dailySelfConsumption / totalProduction;
    final selfSufficiencyRate = (totalConsumption - dailyGridImport) / totalConsumption;
    
    return {
      'batteryChargeArr': batteryChargeArr,
      'batteryDischargeArr': batteryDischargeArr,
      'batteryLevelArr': batteryLevelArr,
      'gridImportArr': gridImportArr,
      'gridExportArr': gridExportArr,
      'hourlyPvToLoadArr': hourlyPvToLoadArr,
      'hourlyPvToBatteryArr': hourlyPvToBatteryArr,
      'hourlyPvToGridArr': hourlyPvToGridArr,
      'hourlyBatteryToLoadArr': hourlyBatteryToLoadArr,
      'hourlyGridToLoadArr': hourlyGridToLoadArr,
      'hourlyCostArr': hourlyCostArr,
      'dailyGridImport': dailyGridImport,
      'dailyGridExport': dailyGridExport,
      'dailyCost': dailyCost,
      'selfConsumptionRate': selfConsumptionRate,
      'selfSufficiencyRate': selfSufficiencyRate,
      'maxGridImport': maxGridImport,
      'maxGridExport': maxGridExport,
      'cycleEquivalent': cycleEquivalent,
    };
  }
  
  double _calculateAnnualSavings(Map<String, Map<String, dynamic>> simResults) {
    // Calculate weighted average savings based on day types
    // Assume: 70% typical days, 20% cloudy days, 10% peak days
    
    // First, calculate baseline cost without battery
    double baselineCost = 0;
    for (int dayType = 0; dayType < 3; dayType++) {
      final dayName = dayType == 0 ? 'Typical' : (dayType == 1 ? 'Cloudy' : 'Peak');
      final dayWeight = dayType == 0 ? 0.7 : (dayType == 1 ? 0.2 : 0.1);
      
      // Simulate a day without battery
      final hourlyLoad = _results['hourlyLoad'] as List<double>? ?? [];
      final hourlyProduction = _results['hourlyProduction'] as List<double>? ?? [];
      final productionFactor = dayType == 0 ? 1.0 : (dayType == 1 ? 0.5 : 1.3);
      final dayProduction = List<double>.from(hourlyProduction.map((p) => p * productionFactor));
      
      double dayCost = 0;
      for (int hour = 0; hour < 24; hour++) {
        final load = hourlyLoad[hour];
        final production = dayProduction[hour];
        
        final directUse = math.min(load, production);
        final gridImport = load - directUse;
        final gridExport = math.max(0, production - directUse);
        
        final importRate = _controlStrategy == 1 ? _timeOfUseRates[hour] : widget.electricityRate;
        dayCost += gridImport * importRate - gridExport * widget.feedInRate;
      }
      
      baselineCost += dayCost * 365 * dayWeight;
    }
    
    // Now calculate cost with battery
    double costWithBattery = 0;
    for (final entry in simResults.entries) {
      final dayType = entry.key;
      final results = entry.value;
      final dayWeight = dayType == 'Typical' ? 0.7 : (dayType == 'Cloudy' ? 0.2 : 0.1);
      
      costWithBattery += (results['dailyCost'] as double) * 365 * dayWeight;
    }
    
    return baselineCost - costWithBattery;
  }
  
  double _calculateBatteryLifetime() {
    // Calculate battery lifetime in years based on cycle life and cycle usage
    if (_results.isEmpty) return 10; // Default
    
    final dayResults = _results['dayResults'] as Map<String, Map<String, dynamic>>;
    double averageDailyCycles = 0;
    
    // Calculate weighted average cycles per day
    for (final entry in dayResults.entries) {
      final dayType = entry.key;
      final results = entry.value;
      final dayWeight = dayType == 'Typical' ? 0.7 : (dayType == 'Cloudy' ? 0.2 : 0.1);
      
      final cycleEquivalent = results['cycleEquivalent'] as double;
      averageDailyCycles += cycleEquivalent * dayWeight;
    }
    
    // Estimate years until cycle life is reached
    final yearsToReachCycleLife = _cycleLifetime / (averageDailyCycles * 365);
    
    // Cap at 15 years for calendar life
    return math.min(yearsToReachCycleLife, 15);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Operation'),
            Tab(text: 'Parameters'),
            Tab(text: 'Economics'),
          ],
        ),
        
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOperationTab(),
              _buildParametersTab(),
              _buildEconomicsTab(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildOperationTab() {
    if (_results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Get results for selected day type
    final dayTypes = ['Typical', 'Cloudy', 'Peak'];
    final dayType = dayTypes[_selectedDay];
    final dayResults = _results['dayResults'][dayType];
    
    if (dayResults == null) {
      return const Center(child: Text('No simulation results available.'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day type selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day Type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(
                        value: 0,
                        label: Text('Typical Day'),
                        icon: Icon(Icons.wb_sunny),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        label: Text('Cloudy Day'),
                        icon: Icon(Icons.cloud),
                      ),
                      ButtonSegment<int>(
                        value: 2,
                        label: Text('Peak Day'),
                        icon: Icon(Icons.wb_sunny_outlined),
                      ),
                    ],
                    selected: {_selectedDay},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _selectedDay = selection.first;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Summary metrics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operation Summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Self-Consumption',
                          '${(dayResults['selfConsumptionRate'] * 100).toStringAsFixed(1)}%',
                          Icons.recycling,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildMetricCard(
                          'Self-Sufficiency',
                          '${(dayResults['selfSufficiencyRate'] * 100).toStringAsFixed(1)}%',
                          Icons.home,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Grid Import',
                          '${dayResults['dailyGridImport'].toStringAsFixed(1)} kWh',
                          Icons.arrow_circle_down,
                          Colors.orange,
                        ),
                      ),
                      Expanded(
                        child: _buildMetricCard(
                          'Grid Export',
                          '${dayResults['dailyGridExport'].toStringAsFixed(1)} kWh',
                          Icons.arrow_circle_up,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Daily Cost',
                          '\$${dayResults['dailyCost'].toStringAsFixed(2)}',
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildMetricCard(
                          'Battery Cycles',
                          dayResults['cycleEquivalent'].toStringAsFixed(2),
                          Icons.battery_charging_full,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Energy flow chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Energy Flows',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: _buildEnergyFlowChart(
                      _results['hourlyLoad'],
                      _results['hourlyProduction'],
                      dayResults,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Battery state of charge chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Battery State of Charge',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: _buildBatteryStateChart(dayResults),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Grid interaction chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grid Interaction',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: _buildGridInteractionChart(dayResults),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildParametersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Battery parameters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Battery Parameters',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSliderWithField(
                    'Battery Capacity (kWh)',
                    _batteryCapacity,
                    0,
                    30,
                    (value) {
                      setState(() {
                        _batteryCapacity = value;
                        _runSimulation();
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSliderWithField(
                    'Charge Power (kW)',
                    _chargePower,
                    0,
                    10,
                    (value) {
                      setState(() {
                        _chargePower = value;
                        _runSimulation();
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSliderWithField(
                    'Discharge Power (kW)',
                    _dischargePower,
                    0,
                    10,
                    (value) {
                      setState(() {
                        _dischargePower = value;
                        _runSimulation();
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSliderWithField(
                    'Round Trip Efficiency (%)',
                    _roundTripEfficiency,
                    70,
                    100,
                    (value) {
                      setState(() {
                        _roundTripEfficiency = value;
                        _runSimulation();
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSliderWithField(
                    'Cycle Lifetime',
                    _cycleLifetime.toDouble(),
                    1000,
                    10000,
                    (value) {
                      setState(() {
                        _cycleLifetime = value.round();
                        _runSimulation();
                      });
                    },
                    divisions: 18,
                    numberFormat: '0',
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSliderWithField(
                    'Depth of Discharge (%)',
                    _depthOfDischarge,
                    50,
                    100,
                    (value) {
                      setState(() {
                        _depthOfDischarge = value;
                        _runSimulation();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Load profile parameters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Load Profile Parameters',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSliderWithField(
                    'Daily Consumption (kWh)',
                    _dailyConsumption,
                    5,
                    50,
                    (value) {
                      setState(() {
                        _dailyConsumption = value;
                        _runSimulation();
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSliderWithField(
                    'Morning Peak (%)',
                    _morningPeakPercent,
                    0,
                    40,
                    (value) {
                      setState(() {
                        _morningPeakPercent = value;
                        _runSimulation();
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSliderWithField(
                    'Evening Peak (%)',
                    _eveningPeakPercent,
                    0,
                    60,
                    (value) {
                      setState(() {
                        _eveningPeakPercent = value;
                        _runSimulation();
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSliderWithField(
                    'Night Time Consumption (%)',
                    _nightTimeConsumptionPercent,
                    0,
                    40,
                    (value) {
                      setState(() {
                        _nightTimeConsumptionPercent = value;
                        _runSimulation();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Control strategy
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Control Strategy',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(
                        value: 0,
                        label: Text('Self-Consumption'),
                        icon: Icon(Icons.home),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        label: Text('Time-of-Use'),
                        icon: Icon(Icons.schedule),
                      ),
                      ButtonSegment<int>(
                        value: 2,
                        label: Text('Peak Shaving'),
                        icon: Icon(Icons.trending_down),
                      ),
                    ],
                    selected: {_controlStrategy},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _controlStrategy = selection.first;
                        _runSimulation();
                      });
                    },
                  ),
                  
                  if (_controlStrategy == 1) ...[
                    const SizedBox(height: 16),
                    const Text('Time-of-Use Rates (\$/kWh)'),
                    const SizedBox(height: 8),
                    AspectRatio(
                      aspectRatio: 2,
                      child: _buildTimeOfUseChart(),
                    ),
                  ],
                  
                  if (_controlStrategy == 2) ...[
                    const SizedBox(height: 16),
                    
                    _buildSliderWithField(
                      'Grid Import Limit (kW)',
                      _gridImportLimit,
                      1,
                      10,
                      (value) {
                        setState(() {
                          _gridImportLimit = value;
                          _runSimulation();
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildSliderWithField(
                      'Grid Export Limit (kW)',
                      _gridExportLimit,
                      1,
                      10,
                      (value) {
                        setState(() {
                          _gridExportLimit = value;
                          _runSimulation();
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEconomicsTab() {
    if (_results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final annualSavings = _results['annualSavings'] as double;
    final paybackPeriod = _results['paybackPeriod'] as double;
    final batteryLifetime = _results['batteryLifetime'] as double;
    
    // Calculate ROI and other metrics
    final roi = (annualSavings * batteryLifetime - widget.batteryCost) / widget.batteryCost * 100;
    final npv = _calculateNPV(annualSavings, batteryLifetime);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow('Battery System Cost', '\$${NumberFormat('#,##0').format(widget.batteryCost.round())}'),
                  _buildInfoRow('Battery Cost per kWh', '\$${(widget.batteryCost / widget.batteryCapacity).round()}'),
                  _buildInfoRow('Annual Savings', '\$${NumberFormat('#,##0').format(annualSavings.round())}'),
                  _buildInfoRow('Simple Payback Period', '${paybackPeriod.toStringAsFixed(1)} years'),
                  _buildInfoRow('Expected Battery Lifetime', '${batteryLifetime.toStringAsFixed(1)} years'),
                  _buildInfoRow('Return on Investment', '${roi.toStringAsFixed(1)}%', 
                                roi > 0 ? Colors.green : Colors.red),
                  _buildInfoRow('Net Present Value', '\$${NumberFormat('#,##0').format(npv.round())}', 
                                npv > 0 ? Colors.green : Colors.red),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Savings breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Savings Breakdown',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: _buildSavingsBreakdownChart(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Cash flow chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cash Flow',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: _buildCashFlowChart(annualSavings, batteryLifetime),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sensitivity analysis
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sensitivity Analysis',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: _buildSensitivityChart(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEnergyFlowChart(List<double> hourlyLoad, List<double> hourlyProduction, Map<String, dynamic> dayResults) {
    final productionFactor = _selectedDay == 0 ? 1.0 : (_selectedDay == 1 ? 0.5 : 1.3);
    final batteryLevelArr = dayResults['batteryLevelArr'] as List<double>;
    final hourlyPvToLoadArr = dayResults['hourlyPvToLoadArr'] as List<double>;
    final hourlyPvToBatteryArr = dayResults['hourlyPvToBatteryArr'] as List<double>;
    final hourlyPvToGridArr = dayResults['hourlyPvToGridArr'] as List<double>;
    final hourlyBatteryToLoadArr = dayResults['hourlyBatteryToLoadArr'] as List<double>;
    final hourlyGridToLoadArr = dayResults['hourlyGridToLoadArr'] as List<double>;
    
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final dataIndex = touchedSpots.indexOf(spot);
                String label;
                Color color;
                
                if (dataIndex == 0) {
                  label = 'Load';
                  color = Colors.red;
                } else if (dataIndex == 1) {
                  label = 'Solar';
                  color = Colors.amber;
                } else if (dataIndex == 2) {
                  label = 'Grid Import';
                  color = Colors.blue;
                } else if (dataIndex == 3) {
                  label = 'Grid Export';
                  color = Colors.green;
                } else if (dataIndex == 4) {
                  label = 'Battery Discharge';
                  color = Colors.purple;
                } else {
                  label = '';
                  color = Colors.black;
                }
                
                return LineTooltipItem(
                  '$label: ${spot.y.toStringAsFixed(2)} kW',
                  TextStyle(color: color, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                if (hour % 3 == 0) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      _formatHour(hour),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    '${value.toStringAsFixed(1)} kW',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: 23,
        minY: 0,
        maxY: _getMaxChartValue(hourlyLoad, hourlyProduction, productionFactor),
        lineBarsData: [
          // Load curve
          LineChartBarData(
            spots: List.generate(24, (hour) {
              return FlSpot(hour.toDouble(), hourlyLoad[hour]);
            }),
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
          // Solar production curve
          LineChartBarData(
            spots: List.generate(24, (hour) {
              return FlSpot(hour.toDouble(), hourlyProduction[hour] * productionFactor);
            }),
            isCurved: true,
            color: Colors.amber,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
          // Grid import curve
          LineChartBarData(
            spots: List.generate(24, (hour) {
              return FlSpot(hour.toDouble(), hourlyGridToLoadArr[hour]);
            }),
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
          ),
          // Grid export curve
          LineChartBarData(
            spots: List.generate(24, (hour) {
              return FlSpot(hour.toDouble(), hourlyPvToGridArr[hour]);
            }),
            isCurved: true,
            color: Colors.green,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
          ),
          // Battery discharge curve
          LineChartBarData(
            spots: List.generate(24, (hour) {
              return FlSpot(hour.toDouble(), hourlyBatteryToLoadArr[hour]);
            }),
            isCurved: true,
            color: Colors.purple,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBatteryStateChart(Map<String, dynamic> dayResults) {
    final batteryLevelArr = dayResults['batteryLevelArr'] as List<double>;
    final batteryChargeArr = dayResults['batteryChargeArr'] as List<double>;
    final batteryDischargeArr = dayResults['batteryDischargeArr'] as List<double>;
    
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final hour = spot.x.toInt();
                final stateOfCharge = batteryLevelArr[hour];
                final percentage = (stateOfCharge / _batteryCapacity * 100).toStringAsFixed(1);
                
                String additionalInfo = '';
                if (batteryChargeArr[hour] > 0) {
                  additionalInfo = '\nCharging: ${batteryChargeArr[hour].toStringAsFixed(2)} kW';
                } else if (batteryDischargeArr[hour] > 0) {
                  additionalInfo = '\nDischarging: ${batteryDischargeArr[hour].toStringAsFixed(2)} kW';
                }
                
                return LineTooltipItem(
                  '${_formatHour(hour)}\nSoC: $percentage%$additionalInfo',
                  const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                if (hour % 3 == 0) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      _formatHour(hour),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final percentage = (value / _batteryCapacity * 100).round();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: 23,
        minY: 0,
        maxY: _batteryCapacity,
        lineBarsData: [
          // Battery state of charge
          LineChartBarData(
            spots: List.generate(24, (hour) {
              return FlSpot(hour.toDouble(), batteryLevelArr[hour]);
            }),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: _batteryCapacity * (_depthOfDischarge / 100),
              color: Colors.amber,
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                style: const TextStyle(fontSize: 10),
                labelResolver: (_) => 'Max DoD',
                alignment: Alignment.topRight,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGridInteractionChart(Map<String, dynamic> dayResults) {
    final gridImportArr = dayResults['gridImportArr'] as List<double>;
    final gridExportArr = dayResults['gridExportArr'] as List<double>;
    
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.white.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final hour = group.x.toInt();
              final value = rod.toY.abs();
              final isImport = rod.toY < 0;
              
              return BarTooltipItem(
                '${_formatHour(hour)}\n${isImport ? 'Import' : 'Export'}: ${value.toStringAsFixed(2)} kW',
                TextStyle(
                  color: isImport ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                if (hour % 3 == 0) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      _formatHour(hour),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    '${value.toStringAsFixed(1)} kW',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minY: -_getMaxGridValue(gridImportArr, gridExportArr) * 1.1,
        maxY: _getMaxGridValue(gridImportArr, gridExportArr) * 1.1,
        barGroups: List.generate(24, (hour) {
          final import = -gridImportArr[hour];
          final export = gridExportArr[hour];
          
          // Show import as negative bars and export as positive
          final value = import != 0 ? import : export;
          
          return BarChartGroupData(
            x: hour,
            barRods: [
              BarChartRodData(
                toY: value,
                color: value < 0 ? Colors.red : Colors.green,
                width: 12,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          );
        }),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 0,
              color: Colors.black,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeOfUseChart() {
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.white.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final hour = group.x.toInt();
              final rate = rod.toY;
              
              return BarTooltipItem(
                '${_formatHour(hour)}\n\${rate.toStringAsFixed(2)}/kWh',
                const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                if (hour % 3 == 0) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      _formatHour(hour),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: const Text(
                    '\${value.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minY: 0,
        barGroups: List.generate(24, (hour) {
          final rate = _timeOfUseRates[hour];
          
          // Color based on rate tiers
          Color barColor;
          if (rate <= 0.10) {
            barColor = Colors.green;
          } else if (rate <= 0.20) {
            barColor = Colors.amber;
          } else {
            barColor = Colors.red;
          }
          
          return BarChartGroupData(
            x: hour,
            barRods: [
              BarChartRodData(
                toY: rate,
                color: barColor,
                width: 12,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          );
        }),
      ),
    );
  }
  
  Widget _buildSavingsBreakdownChart() {
    // Estimate savings components
    final importSavings = 0.65 * _results['annualSavings'];
    final exportOptimization = 0.15 * _results['annualSavings'];
    final demandChargeSavings = 0.2 * _results['annualSavings'];
    
    final barGroups = [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: importSavings,
            color: Colors.blue,
            width: 40,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: exportOptimization,
            color: Colors.green,
            width: 40,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(
            toY: demandChargeSavings,
            color: Colors.orange,
            width: 40,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    ];
    
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.white.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label;
              if (group.x == 0) {
                label = 'Reduced Grid Import';
              } else if (group.x == 1) {
                label = 'Export Optimization';
              } else {
                label = 'Demand Charge Savings';
              }
              
              return BarTooltipItem(
                '$label\n\${rod.toY.toStringAsFixed(0)} per year',
                const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String label;
                if (value == 0) {
                  label = 'Grid Import';
                } else if (value == 1) {
                  label = 'Export';
                } else {
                  label = 'Demand';
                }
                
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: const Text(
                    '\${value.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        barGroups: barGroups,
      ),
    );
  }
  
  Widget _buildCashFlowChart(double annualSavings, double batteryLifetime) {
    final years = batteryLifetime.ceil() + 1;
    
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final year = spot.x.toInt();
                
                return LineTooltipItem(
                  'Year $year\n\${spot.y.toStringAsFixed(0)}',
                  const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final year = value.toInt();
                if (year % 2 == 0 || year == 1 || year == years.toInt() - 1) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      year.toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: const Text(
                    '\${value.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: years.toDouble(),
        minY: -widget.batteryCost,
        maxY: annualSavings * years,
        lineBarsData: [
          // Cumulative cash flow
          LineChartBarData(
            spots: [
              const FlSpot(0, 0),
              FlSpot(0.001, -widget.batteryCost), // Initial investment at time 0+
              ...List.generate(years, (year) {
                // Year 1, 2, 3, etc.
                return FlSpot(year + 1, -widget.batteryCost + annualSavings * (year + 1));
              }),
            ],
            isCurved: false,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.2),
              cutOffY: 0,
              applyCutOffY: true,
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 0,
              color: Colors.black,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSensitivityChart() {
    // Build sensitivity data for key parameters
    // X-axis: Parameter value in % of baseline
    // Y-axis: Payback period in years
    
    // Data for battery capacity vs payback period
    final batteryCapacityData = [
      const FlSpot(50, 2.2),  // 50% capacity -> 2.2 years payback
      const FlSpot(75, 3.3),  // 75% capacity -> 3.3 years payback
      const FlSpot(100, 4.5), // 100% capacity -> 4.5 years payback (baseline)
      const FlSpot(125, 5.6), // 125% capacity -> 5.6 years payback
      const FlSpot(150, 6.8), // 150% capacity -> 6.8 years payback
    ];
    
    // Data for electricity price vs payback period
    final electricityPriceData = [
      const FlSpot(50, 8.9),   // 50% price -> 8.9 years payback
      const FlSpot(75, 6.0),   // 75% price -> 6.0 years payback
      const FlSpot(100, 4.5),  // 100% price -> 4.5 years payback (baseline)
      const FlSpot(125, 3.6),  // 125% price -> 3.6 years payback
      const FlSpot(150, 3.0),  // 150% price -> 3.0 years payback
    ];
    
    // Data for self-consumption vs payback period
    final selfConsumptionData = [
      const FlSpot(50, 9.0),   // 50% self-consumption -> 9.0 years payback
      const FlSpot(75, 6.0),   // 75% self-consumption -> 6.0 years payback
      const FlSpot(100, 4.5),  // 100% self-consumption -> 4.5 years payback (baseline)
      const FlSpot(125, 3.6),  // 125% self-consumption -> 3.6 years payback
      const FlSpot(150, 3.0),  // 150% self-consumption -> 3.0 years payback
    ];
    
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final dataIndex = touchedSpots.indexOf(spot);
                String label;
                Color color;
                
                if (dataIndex == 0) {
                  label = 'Battery Capacity';
                  color = Colors.blue;
                } else if (dataIndex == 1) {
                  label = 'Electricity Price';
                  color = Colors.red;
                } else {
                  label = 'Self-Consumption';
                  color = Colors.purple;
                }
                
                return LineTooltipItem(
                  '$label\n${spot.x.toStringAsFixed(0)}% of baseline\n${spot.y.toStringAsFixed(1)} years payback',
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 25 == 0) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      '${value.toInt()}%',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    '${value.toStringAsFixed(1)} yrs',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 50,
        maxX: 150,
        minY: 2,
        maxY: 10,
        lineBarsData: [
          // Battery capacity
          LineChartBarData(
            spots: batteryCapacityData,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
          ),
          // Electricity price
          LineChartBarData(
            spots: electricityPriceData,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
          ),
          // Self-consumption
          LineChartBarData(
            spots: selfConsumptionData,
            isCurved: true,
            color: Colors.purple,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
          ),
        ],
        extraLinesData: ExtraLinesData(
          verticalLines: [
            VerticalLine(
              x: 100,
              color: Colors.black,
              strokeWidth: 2,
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSliderWithField(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged, {
    int? divisions,
    String numberFormat = '0.0',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions ?? ((max - min) * 10).round(),
                onChanged: onChanged,
              ),
            ),
            Expanded(
              flex: 1,
              child: TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                  text: value.toStringAsFixed(numberFormat == '0' ? 0 : 1),
                ),
                onChanged: (text) {
                  final newValue = double.tryParse(text);
                  if (newValue != null && newValue >= min && newValue <= max) {
                    onChanged(newValue);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatHour(int hour) {
    if (hour == 0 || hour == 24) {
      return '12 AM';
    } else if (hour < 12) {
      return '$hour AM';
    } else if (hour == 12) {
      return '12 PM';
    } else {
      return '${hour - 12} PM';
    }
  }
  
  double _getMaxChartValue(List<double> hourlyLoad, List<double> hourlyProduction, double productionFactor) {
    double maxLoad = 0;
    double maxProduction = 0;
    
    for (final load in hourlyLoad) {
      if (load > maxLoad) maxLoad = load;
    }
    
    for (final production in hourlyProduction) {
      if (production * productionFactor > maxProduction) {
        maxProduction = production * productionFactor;
      }
    }
    
    return math.max(maxLoad, maxProduction) * 1.1;
  }
  
  double _getMaxGridValue(List<double> gridImportArr, List<double> gridExportArr) {
    double maxImport = 0;
    double maxExport = 0;
    
    for (final import in gridImportArr) {
      if (import > maxImport) maxImport = import;
    }
    
    for (final export in gridExportArr) {
      if (export > maxExport) maxExport = export;
    }
    
    return math.max(maxImport, maxExport);
  }
  
  double _calculateNPV(double annualSavings, double batteryLifetime) {
    double npv = -widget.batteryCost;
    const discountRate = 0.05; // 5% discount rate
    
    for (int year = 1; year <= batteryLifetime; year++) {
      final discountFactor = 1 / math.pow(1 + discountRate, year);
      npv += annualSavings * discountFactor;
    }
    
    return npv;
  }
}