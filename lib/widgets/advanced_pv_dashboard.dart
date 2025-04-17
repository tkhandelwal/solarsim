// lib/widgets/advanced_pv_dashboard.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:solarsim/models/project.dart';
import 'package:solarsim/models/solar_module.dart';
import 'package:solarsim/models/inverter.dart';
import 'package:solarsim/core/pv_system_simulator.dart';

// Import our custom gauge widgets
import 'gauge_indicator.dart';
import 'svg_loader.dart';

class AdvancedPVDashboard extends StatefulWidget {
  final Project project;
  final SolarModule module;
  final Inverter inverter;
  final int modulesInSeries;
  final int stringsInParallel;
  final double tiltAngle;
  final double azimuthAngle;
  final Map<String, double> losses;
  final double? batteryCapacity;
  final bool isLiveData;
  
  const AdvancedPVDashboard({
    super.key,
    required this.project,
    required this.module,
    required this.inverter,
    required this.modulesInSeries,
    required this.stringsInParallel,
    required this.tiltAngle,
    required this.azimuthAngle,
    required this.losses,
    this.batteryCapacity,
    this.isLiveData = false,
  });

  @override
  State<AdvancedPVDashboard> createState() => _AdvancedPVDashboardState();
}

class _AdvancedPVDashboardState extends State<AdvancedPVDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _simulationResults = {};
  int _selectedTimeframe = 1; // 0: Today, 1: Month, 2: Year, 3: Lifetime
  String _selectedMonth = 'Annual';
  
  // Live data timers and values
  double _currentPower = 0.0;
  double _dailyEnergy = 0.0;
  double _monthlyEnergy = 0.0;
  double _yearlyEnergy = 0.0;
  double _lifetimeEnergy = 0.0;
  double _currentSelfConsumption = 30.0; // Percentage
  double _currentGridExport = 0.0;
  double _currentBatteryCharge = 0.0;
  double _batteryStateOfCharge = 50.0; // Percentage
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _runSimulation();
    
    // If in live data mode, start with simulated live values
    if (widget.isLiveData) {
      _simulateLiveData();
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Run simulation to generate dashboard data
  Future<void> _runSimulation() async {
    setState(() {
      _isLoading = true;
    });
    
    // Create a basic simulator
    final simulator = PVSystemSimulator(
      project: widget.project,
      module: widget.module,
      inverter: widget.inverter,
      modulesInSeries: widget.modulesInSeries,
      stringsInParallel: widget.stringsInParallel,
      tiltAngle: widget.tiltAngle,
      azimuthAngle: widget.azimuthAngle,
      soilingLoss: widget.losses['soiling'] ?? 0.02,
      shadingLoss: widget.losses['shading'] ?? 0.03,
      mismatchLoss: widget.losses['mismatch'] ?? 0.02,
      dcWiringLoss: widget.losses['wiring'] ?? 0.02,
      acWiringLoss: widget.losses['acWiring'] ?? 0.01,
      systemAvailability: 1 - (widget.losses['availability'] ?? 0.02),
    );
    
    // Generate simulated annual results
    final annualResults = simulator.simulateYear(year: DateTime.now().year);
    
    // Process results for dashboard
    final systemSizeKw = widget.module.powerRating * widget.modulesInSeries * 
        widget.stringsInParallel / 1000;
    
    final monthlyProduction = <String, double>{};
    for (final month in annualResults.monthlyResults) {
      monthlyProduction[month.monthName] = month.energyAC;
    }
    
    double totalSavings = annualResults.energyAC * 0.15; // Assume $0.15/kWh
    
    // Calculate CO2 savings (assuming 0.5 kg CO2/kWh)
    double co2Savings = annualResults.energyAC * 0.5;
    
    // Lifetime production estimate (25 years with 0.5% annual degradation)
    double lifetimeProduction = 0;
    for (int year = 1; year <= 25; year++) {
      lifetimeProduction += annualResults.energyAC * math.pow(0.995, year - 1);
    }
    
    // Generate hourly production for a typical day in each month
    final hourlyByMonth = <String, List<double>>{};
    for (final monthResult in annualResults.monthlyResults) {
      final hourlyData = _generateHourlyData(monthResult.energyAC, monthResult.month);
      hourlyByMonth[monthResult.monthName] = hourlyData;
    }
    
    setState(() {
      _simulationResults = {
        'systemSizeKw': systemSizeKw,
        'annualProduction': annualResults.energyAC,
        'specificYield': annualResults.specificYield,
        'performanceRatio': annualResults.averagePerformanceRatio,
        'monthlyProduction': monthlyProduction,
        'hourlyByMonth': hourlyByMonth,
        'totalSavings': totalSavings,
        'co2Savings': co2Savings,
        'lifetimeProduction': lifetimeProduction,
      };
      _isLoading = false;
    });
  }
  
  // Generate simulated hourly data for visualization
  List<double> _generateHourlyData(double dailyEnergy, int month) {
    final hourlyData = List<double>.filled(24, 0);
    
    // Use a bell curve distribution centered around noon
    // Adjust sunrise and sunset based on month
    int sunriseHour = 6;
    int sunsetHour = 18;
    
    // Adjust for seasonality
    if (month <= 3 || month >= 10) {
      // Winter months
      sunriseHour = 7;
      sunsetHour = 17;
    } else if (month >= 4 && month <= 9) {
      // Summer months
      sunriseHour = 5;
      sunsetHour = 19;
    }
    
    // Generate hourly values
    double totalFactor = 0;
    for (int hour = 0; hour < 24; hour++) {
      if (hour < sunriseHour || hour >= sunsetHour) {
        hourlyData[hour] = 0;
      } else {
        // Create a bell curve
        final normalizedHour = (hour - sunriseHour) / (sunsetHour - sunriseHour);
        final factor = math.sin(normalizedHour * math.pi);
        hourlyData[hour] = factor;
        totalFactor += factor;
      }
    }
    
    // Normalize to match daily energy
    if (totalFactor > 0) {
      for (int hour = 0; hour < 24; hour++) {
        hourlyData[hour] = hourlyData[hour] * dailyEnergy / totalFactor;
      }
    }
    
    return hourlyData;
  }
  
  // Simulate live data for the dashboard
  void _simulateLiveData() {
    // This would be replaced with actual data acquisition in a real app
    
    // Simulate current production based on time of day
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    
    // Get the production curve for the current month
    final currentMonth = DateFormat('MMMM').format(now);
    final monthlyProduction = _simulationResults['monthlyProduction'] as Map<String, double>? ?? {};
    final monthlyEnergy = monthlyProduction[currentMonth] ?? 0.0;
    
    // Generate hourly curve and find current hour's production
    final hourlyCurve = _generateHourlyData(monthlyEnergy / 30, now.month);
    
    // Interpolate between hours for smooth transitions
    double baseValue = hourlyCurve[hour];
    double nextValue = hour < 23 ? hourlyCurve[hour + 1] : 0;
    double interpolatedValue = baseValue + ((nextValue - baseValue) * minute / 60);
    
    // Add some random variation
    final random = math.Random();
    final variationFactor = 0.8 + (random.nextDouble() * 0.4); // 80-120% variation
    
    setState(() {
      _currentPower = interpolatedValue * variationFactor;
      
      // Update energy counters
      _dailyEnergy = monthlyEnergy / 30 * (hour / 24); // Simplified
      _monthlyEnergy = monthlyEnergy * now.day / DateTime(now.year, now.month + 1, 0).day;
      _yearlyEnergy = (_simulationResults['annualProduction'] as double? ?? 0.0) * now.month / 12;
      _lifetimeEnergy = _yearlyEnergy; // In a real app, this would accumulate over system life
      
      // Update battery status if battery exists
      if (widget.batteryCapacity != null) {
        // Simulate battery behavior
        if (_currentPower > 3.0) {
          // Excess generation, battery charges
          _currentSelfConsumption = 40.0;
          _currentGridExport = _currentPower * 0.2; // 20% export
          _currentBatteryCharge = (_currentPower * 0.4) / widget.batteryCapacity!; // 40% to battery
          _batteryStateOfCharge = math.min(100, _batteryStateOfCharge + _currentBatteryCharge);
        } else if (_currentPower > 1.0) {
          // Balanced generation
          _currentSelfConsumption = 80.0;
          _currentGridExport = 0.0;
          _currentBatteryCharge = (_currentPower * 0.1) / widget.batteryCapacity!; // 10% to battery
          _batteryStateOfCharge = math.min(100, _batteryStateOfCharge + _currentBatteryCharge);
        } else {
          // Low generation, battery discharges
          _currentSelfConsumption = 100.0;
          _currentGridExport = 0.0;
          _currentBatteryCharge = -0.5 / widget.batteryCapacity!; // Discharge
          _batteryStateOfCharge = math.max(10, _batteryStateOfCharge + _currentBatteryCharge);
        }
      } else {
        // No battery
        if (_currentPower > 2.5) {
          _currentSelfConsumption = 40.0;
          _currentGridExport = _currentPower * 0.6; // 60% export
        } else {
          _currentSelfConsumption = 90.0;
          _currentGridExport = _currentPower * 0.1; // 10% export
        }
      }
    });
    
    // Schedule next update in 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _simulateLiveData();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Energy Flow'),
            Tab(text: 'Production'),
            Tab(text: 'Analysis'),
          ],
        ),
        
        if (_isLoading)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildEnergyFlowTab(),
                _buildProductionTab(),
                _buildAnalysisTab(),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Information Card
          _buildSystemInfoCard(),
          
          const SizedBox(height: 16),
          
          // Current Status Card (for live data or simulated "right now" view)
          _buildCurrentStatusCard(),
          
          const SizedBox(height: 16),
          
          // Energy Production Summary Card
          _buildEnergyProductionCard(),
          
          const SizedBox(height: 16),
          
          // Environmental Impact Card
          _buildEnvironmentalImpactCard(),
        ],
      ),
    );
  }
  
  Widget _buildEnergyFlowTab() {
    return Column(
      children: [
        const SizedBox(height: 16),
        
        // Energy flow visualization
        Expanded(
          child: Center(
            child: _buildEnergyFlowDiagram(),
          ),
        ),
        
        // Flow metrics
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildEnergyFlowMetrics(),
        ),
      ],
    );
  }
  
  Widget _buildProductionTab() {
    return Column(
      children: [
        // Time period selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment<int>(
                value: 0,
                label: Text('Day'),
                icon: Icon(Icons.wb_sunny),
              ),
              ButtonSegment<int>(
                value: 1, 
                label: Text('Month'),
                icon: Icon(Icons.calendar_month),
              ),
              ButtonSegment<int>(
                value: 2,
                label: Text('Year'),
                icon: Icon(Icons.calendar_today),
              ),
              ButtonSegment<int>(
                value: 3,
                label: Text('Lifetime'),
                icon: Icon(Icons.access_time),
              ),
            ],
            selected: {_selectedTimeframe},
            onSelectionChanged: (selection) {
              setState(() {
                _selectedTimeframe = selection.first;
              });
            },
          ),
        ),
        
        if (_selectedTimeframe == 1) ...[
          // Month selector for monthly view
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Month',
                border: OutlineInputBorder(),
              ),
              value: _selectedMonth,
              items: [
                const DropdownMenuItem<String>(
                  value: 'Annual',
                  child: Text('All Months'),
                ),
                ...(_simulationResults['monthlyProduction'] as Map<String, double>?)?.keys.map((month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(month),
                  );
                }).toList() ?? [],
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMonth = value;
                  });
                }
              },
            ),
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Production chart based on selected timeframe
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildProductionChart(),
          ),
        ),
        
        const SizedBox(height: 16),
      ],
    );
  }
  
  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Metrics Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Metrics',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  // Performance ratio gauge - Using our custom gauge
                  SizedBox(
                    height: 200,
                    child: GaugeIndicator(
                      value: (_simulationResults['performanceRatio'] as double? ?? 0.0) * 100,
                      minValue: 0,
                      maxValue: 100,
                      valueColor: _getPerformanceColor(
                        (_simulationResults['performanceRatio'] as double? ?? 0.0) * 100
                      ),
                      backgroundColor: Colors.grey.shade300,
                      title: 'Performance Ratio',
                      subtitle: '${((_simulationResults['performanceRatio'] as double? ?? 0.0) * 100).toStringAsFixed(1)}%',
                      ranges: const [
                        GaugeRange(
                          startValue: 0,
                          endValue: 70,
                          color: Colors.red,
                        ),
                        GaugeRange(
                          startValue: 70,
                          endValue: 80,
                          color: Colors.orange,
                        ),
                        GaugeRange(
                          startValue: 80,
                          endValue: 100,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Specific yield comparison
                  Text(
                    'Specific Yield: ${(_simulationResults['specificYield'] as double? ?? 0.0).toStringAsFixed(0)} kWh/kWp',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  
                  LinearProgressIndicator(
                    value: math.min(1.0, ((_simulationResults['specificYield'] as double? ?? 0.0) / 1600)),
                    backgroundColor: Colors.grey[300],
                    color: _getYieldColor(_simulationResults['specificYield'] as double? ?? 0.0),
                    minHeight: 15,
                  ),
                  
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Low'),
                      Text('Average (1400)', style: TextStyle(color: Colors.blue[700])),
                      const Text('Excellent'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // System Losses Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Losses',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: _buildLossesChart(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Performance Comparison Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Comparison',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: _buildPerformanceComparisonChart(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSystemInfoCard() {
    // Calculate total modules
    final totalModules = widget.modulesInSeries * widget.stringsInParallel;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'System Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    // Show detailed system info dialog
                    showDialog(
                      context: context,
                      builder: (context) => _buildSystemDetailsDialog(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    'System Size',
                    '${(_simulationResults['systemSizeKw'] as double? ?? 0.0).toStringAsFixed(2)} kWp',
                    Icons.solar_power,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildInfoTile(
                    'Modules',
                    '$totalModules',
                    Icons.view_module,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildInfoTile(
                    'Tilt Angle',
                    '${widget.tiltAngle.toStringAsFixed(1)}°',
                    Icons.rotate_right,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.module.manufacturer} ${widget.module.model}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.inverter.manufacturer} ${widget.inverter.model}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCurrentStatusCard() {
    final maxPower = (_simulationResults['systemSizeKw'] as double? ?? 10.0) * 1.1;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Current Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Online'),
                const Spacer(),
                Text(
                  DateFormat('MMM d, yyyy - h:mm a').format(DateTime.now()),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Current power gauge with our custom gauge
            SizedBox(
              height: 160,
              child: GaugeIndicator(
                value: _currentPower,
                minValue: 0,
                maxValue: maxPower,
                valueColor: _getPowerGaugeColor(_currentPower, maxPower),
                backgroundColor: Colors.grey.shade200,
                thickness: 15,
                showValue: true,
                title: 'Current Power',
                subtitle: '${_currentPower.toStringAsFixed(1)} kW',
                ranges: [
                  GaugeRange(
                    startValue: 0,
                    endValue: maxPower * 0.2,
                    color: Colors.red.shade200,
                  ),
                  GaugeRange(
                    startValue: maxPower * 0.2,
                    endValue: maxPower * 0.7,
                    color: Colors.orange.shade300,
                  ),
                  GaugeRange(
                    startValue: maxPower * 0.7,
                    endValue: maxPower,
                    color: Colors.green.shade400,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Energy counters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEnergyCounter('Today', _dailyEnergy, Colors.green),
                _buildEnergyCounter('Month', _monthlyEnergy, Colors.blue),
                _buildEnergyCounter('Year', _yearlyEnergy, Colors.purple),
                _buildEnergyCounter('Lifetime', _lifetimeEnergy, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEnergyProductionCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Energy Production',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            AspectRatio(
              aspectRatio: 1.5,
              child: MonthlyProductionBarChart(
                monthlyEnergy: _simulationResults['monthlyProduction'] as Map<String, double>? ?? {},
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricBox(
                  'Annual Energy',
                  '${(_simulationResults['annualProduction'] as double? ?? 0.0).toStringAsFixed(0)} kWh',
                  Colors.blue[700],
                ),
                _buildMetricBox(
                  'Monthly Average',
                  '${((_simulationResults['annualProduction'] as double? ?? 0.0) / 12).toStringAsFixed(0)} kWh',
                  Colors.green[700],
                ),
                _buildMetricBox(
                  'Daily Average',
                  '${((_simulationResults['annualProduction'] as double? ?? 0.0) / 365).toStringAsFixed(1)} kWh',
                  Colors.orange[700],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEnvironmentalImpactCard() {
    // Calculate equivalent metrics
    final co2Savings = _simulationResults['co2Savings'] as double? ?? 0.0;
    final treeEquivalent = co2Savings / 20; // Approx 20kg CO2 per tree per year
    final carEquivalent = co2Savings / 4000; // Approx 4000kg CO2 per car per year
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Environmental Impact',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // CO2 avoided
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CO₂ Emissions Avoided'),
                      const SizedBox(height: 8),
                      Text(
                        '${co2Savings.toStringAsFixed(0)} kg',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              // Use SVG for tree icon
                              SvgBuilder(
                                svgContent: SvgIcons.generateSvg('tree'),
                                width: 40,
                                height: 40,
                                color: Colors.green,
                              ),
                              Text(
                                '= ${treeEquivalent.toStringAsFixed(1)} trees',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              // Use icon for car
                              const Icon(Icons.directions_car, color: Colors.blue, size: 40),
                              Text(
                                '= ${carEquivalent.toStringAsFixed(2)} cars',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Savings
            Row(
              children: [
                Expanded(
                  child: _buildSavingsMetric(
                    'Electricity Saved',
                    '\$${(_simulationResults['totalSavings'] as double? ?? 0.0).toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSavingsMetric(
                    'Lifetime Production',
                    '${(_simulationResults['lifetimeProduction'] as double? ?? 0.0).toStringAsFixed(0)} kWh',
                    Icons.all_inclusive,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEnergyFlowDiagram() {
    // This is a simplified energy flow diagram
    return Container(
      width: double.infinity,
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          // Sun
          Positioned(
            top: 20,
            left: 20,
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.yellow.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: SvgBuilder(
                      svgContent: SvgIcons.generateSvg('sun'),
                      width: 40,
                      height: 40,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Sun'),
              ],
            ),
          ),
          
          // PV Modules
          Positioned(
            top: 120,
            left: 120,
            child: Column(
              children: [
                SvgBuilder(
                  svgContent: SvgIcons.generateSvg('solar_panel'),
                  width: 120,
                  height: 80,
                ),
                const SizedBox(height: 8),
                const Text('PV Array'),
              ],
            ),
          ),
          
          // Inverter
          Positioned(
            top: 120,
            right: 250,
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    border: Border.all(color: Colors.grey.shade600),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.power, size: 24, color: Colors.grey.shade700),
                      const SizedBox(height: 4),
                      Container(
                        width: 40,
                        height: 6,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 40,
                        height: 6,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Inverter'),
              ],
            ),
          ),
          
          // Battery (if exists)
          if (widget.batteryCapacity != null)
            Positioned(
              top: 240,
              right: 150,
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      SvgBuilder(
                        svgContent: SvgIcons.generateSvg('battery'),
                        width: 60,
                        height: 80,
                      ),
                      Positioned(
                        bottom: 5,
                        child: Container(
                          width: 40,
                          height: 60 * _batteryStateOfCharge / 100,
                          decoration: BoxDecoration(
                            color: _getBatteryColor(_batteryStateOfCharge),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Battery'),
                  Text('${_batteryStateOfCharge.toStringAsFixed(0)}%'),
                ],
              ),
            ),
          
          // House/Load
          Positioned(
            top: 120,
            right: 60,
            child: Column(
              children: [
                SvgBuilder(
                  svgContent: SvgIcons.generateSvg('house'),
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 8),
                const Text('Home'),
              ],
            ),
          ),
          
          // Grid
          Positioned(
            bottom: 40,
            right: 60,
            child: Column(
              children: [
                Icon(Icons.electrical_services, size: 60, color: Colors.grey.shade700),
                const Text('Grid'),
              ],
            ),
          ),
          
          // Energy flow arrows
          _buildEnergyFlowArrows(),
          
          // Energy flow legends
          Positioned(
            bottom: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFlowLegend('PV Generation', Colors.yellow),
                const SizedBox(height: 4),
                _buildFlowLegend('Home Consumption', Colors.green),
                const SizedBox(height: 4),
                _buildFlowLegend('Grid Export', Colors.red),
                if (widget.batteryCapacity != null) ...[
                  const SizedBox(height: 4),
                  _buildFlowLegend('Battery Charge/Discharge', Colors.blue),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEnergyFlowArrows() {
    // This method would draw animated arrows showing the energy flow
    // For simplicity, we're just creating static arrows here
    return Stack(
      children: [
        // PV to Inverter arrow
        _buildArrow(
          start: const Offset(200, 160),
          end: const Offset(250, 160),
          color: Colors.yellow,
          width: 3.0,
        ),
        
        // Inverter to Home arrow
        _buildArrow(
          start: const Offset(310, 150),
          end: const Offset(360, 150),
          color: Colors.green,
          width: 3.0,
        ),
        
        // Inverter to Battery arrow (if battery exists)
        if (widget.batteryCapacity != null && _currentBatteryCharge > 0)
          _buildArrow(
            start: const Offset(280, 200),
            end: const Offset(280, 260),
            color: Colors.blue,
            width: 3.0,
          ),
        
        // Battery to Inverter arrow (if battery exists and discharging)
        if (widget.batteryCapacity != null && _currentBatteryCharge < 0)
          _buildArrow(
            start: const Offset(260, 260),
            end: const Offset(260, 200),
            color: Colors.blue,
            width: 3.0,
          ),
        
        // Inverter to Grid arrow (if exporting)
        if (_currentGridExport > 0)
          _buildArrow(
            start: const Offset(280, 320),
            end: const Offset(280, 360),
            color: Colors.red,
            width: 3.0,
          ),
        
        // Grid to Home arrow (if importing)
        if (_currentGridExport == 0)
          _buildArrow(
            start: const Offset(360, 210),
            end: const Offset(360, 360),
            color: Colors.green,
            width: 3.0,
          ),
        
        // Sun to PV arrow
        _buildArrow(
          start: const Offset(80, 70),
          end: const Offset(140, 120),
          color: Colors.yellow,
          width: 3.0,
        ),
      ],
    );
  }
  
  Widget _buildArrow({
    required Offset start,
    required Offset end,
    required Color color,
    required double width,
  }) {
    return CustomPaint(
      painter: ArrowPainter(
        startPoint: start,
        endPoint: end,
        color: color,
        strokeWidth: width,
      ),
      child: const SizedBox.expand(),
    );
  }
  
  Widget _buildFlowLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 4,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
  
  Widget _buildEnergyFlowMetrics() {
    // Create a card with energy flow metrics (generation, consumption, etc.)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Energy Flow Metrics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn(
                  'PV Generation',
                  '${_currentPower.toStringAsFixed(1)} kW',
                  Icons.solar_power,
                  Colors.amber,
                ),
                _buildMetricColumn(
                  'Self-Consumption',
                  '${_currentSelfConsumption.toStringAsFixed(0)}%',
                  Icons.home,
                  Colors.green,
                ),
                _buildMetricColumn(
                  'Grid Export',
                  '${_currentGridExport.toStringAsFixed(1)} kW',
                  Icons.arrow_upward,
                  Colors.red,
                ),
                if (widget.batteryCapacity != null)
                  _buildMetricColumn(
                    'Battery',
                    _currentBatteryCharge > 0 
                        ? '+${_currentBatteryCharge.toStringAsFixed(1)} kW'
                        : '${_currentBatteryCharge.toStringAsFixed(1)} kW',
                    _currentBatteryCharge > 0 ? Icons.arrow_downward : Icons.arrow_upward,
                    Colors.blue,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProductionChart() {
    // Choose which chart to show based on selected timeframe
    switch (_selectedTimeframe) {
      case 0: // Day
        return _buildDailyProductionChart();
      case 1: // Month
        return _buildMonthlyProductionChart();
      case 2: // Year
        return _buildYearlyProductionChart();
      case 3: // Lifetime
        return _buildLifetimeProductionChart();
      default:
        return _buildMonthlyProductionChart();
    }
  }
  
  Widget _buildDailyProductionChart() {
    // Get hourly data for the selected month
    final hourlyByMonth = _simulationResults['hourlyByMonth'] as Map<String, List<double>>? ?? {};
    
    // Default to current month if no month is selected
    final hourlyData = hourlyByMonth[_selectedMonth] ?? 
        hourlyByMonth[DateFormat('MMMM').format(DateTime.now())] ?? 
        List<double>.filled(24, 0);
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          show: true,
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
                      '$hour:00',
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
                    '${value.toStringAsFixed(1)} kWh',
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
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(hourlyData.length, (index) {
              return FlSpot(index.toDouble(), hourlyData[index]);
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
      ),
    );
  }
  
  Widget _buildMonthlyProductionChart() {
    final monthlyProduction = _simulationResults['monthlyProduction'] as Map<String, double>? ?? {};
    
    if (_selectedMonth == 'Annual') {
      // Show all months
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxMonthlyProduction(monthlyProduction) * 1.1,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final month = _getMonthName(group.x.toInt());
                final value = rod.toY;
                return BarTooltipItem(
                  '$month\n${value.round()} kWh',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text(
                      _getMonthName(value.toInt())[0], // First letter of month
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
                reservedSize: 20,
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
                      '${value.toInt()} kWh',
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
          gridData: const FlGridData(
            show: true,
            horizontalInterval: 500,
          ),
          borderData: FlBorderData(show: false),
          barGroups: _generateMonthlyBarGroups(monthlyProduction),
        ),
      );
    } else {
      // Show daily breakdown for selected month
      return _buildDailyBreakdownForMonth(_selectedMonth);
    }
  }
  
  Widget _buildYearlyProductionChart() {
    // This would show yearly production with degradation over time
    return LineChart(
      LineChartData(
        gridData: const FlGridData(
          show: true,
          horizontalInterval: 1000,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final year = value.toInt() + 1;
                if (year % 5 == 0 || year == 1 || year == 25) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      'Year $year',
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
                    '${value.toInt()} kWh',
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
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: _generateYearlyDegradationData(),
            isCurved: false,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLifetimeProductionChart() {
    // Show cumulative production over lifetime
    final annualProduction = _simulationResults['annualProduction'] as double? ?? 0.0;
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(
          show: true,
          horizontalInterval: 20000,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final year = value.toInt() + 1;
                if (year % 5 == 0 || year == 1 || year == 25) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      'Year $year',
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
                    '${value.toInt() / 1000}k kWh',
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
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: _generateCumulativeProductionData(annualProduction),
            isCurved: false,
            color: Colors.purple,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.purple.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDailyBreakdownForMonth(String month) {
    // This would show a daily breakdown for the selected month
    // For simplicity, we'll generate random values
    final daysInMonth = _getDaysInMonth(month);
    final random = math.Random(month.hashCode); // Seed for consistent values
    
    final avgDailyProduction = (_simulationResults['monthlyProduction'] as Map<String, double>)[month] ?? 0.0;
    final avgDaily = avgDailyProduction / daysInMonth;
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: avgDaily * 1.5,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = group.x.toInt() + 1;
              final value = rod.toY;
              return BarTooltipItem(
                'Day $day\n${value.toStringAsFixed(1)} kWh',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final day = value.toInt() + 1;
                if (day % 5 == 0 || day == 1 || day == daysInMonth) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text(
                      day.toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 20,
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
                    '${value.toStringAsFixed(1)} kWh',
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
        gridData: const FlGridData(
          show: true,
          horizontalInterval: 10,
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(daysInMonth, (index) {
          // Randomize daily production around the average
          final variationFactor = 0.7 + random.nextDouble() * 0.6; // 70-130%
          final dayValue = avgDaily * variationFactor;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: dayValue,
                color: Colors.teal,
                width: 8,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
  
  Widget _buildLossesChart() {
    // Create a pie chart showing the system losses
    final losses = List<PieChartSectionData>.empty(growable: true);
    
    // Add each type of loss
    if (widget.losses.containsKey('soiling')) {
      losses.add(PieChartSectionData(
        title: 'Soiling',
        value: widget.losses['soiling']! * 100,
        color: Colors.brown,
        radius: 100,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ));
    }
    
    if (widget.losses.containsKey('mismatch')) {
      losses.add(PieChartSectionData(
        title: 'Mismatch',
        value: widget.losses['mismatch']! * 100,
        color: Colors.purple,
        radius: 100,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ));
    }
    
    if (widget.losses.containsKey('wiring')) {
      losses.add(PieChartSectionData(
        title: 'Wiring',
        value: widget.losses['wiring']! * 100,
        color: Colors.orange,
        radius: 100,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ));
    }
    
    if (widget.losses.containsKey('inverter')) {
      losses.add(PieChartSectionData(
        title: 'Inverter',
        value: widget.losses['inverter']! * 100,
        color: Colors.blue,
        radius: 100,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ));
    }
    
    if (widget.losses.containsKey('temperature')) {
      losses.add(PieChartSectionData(
        title: 'Temperature',
        value: widget.losses['temperature']! * 100,
        color: Colors.red,
        radius: 100,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ));
    }
    
    // Add availability loss if present
    if (widget.losses.containsKey('availability')) {
      losses.add(PieChartSectionData(
        title: 'Availability',
        value: widget.losses['availability']! * 100,
        color: Colors.amber,
        radius: 100,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ));
    }
    
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: losses,
      ),
    );
  }
  
  Widget _buildPerformanceComparisonChart() {
    // Bar chart comparing the system to regional and optimal benchmarks
    final systemPerformance = _simulationResults['specificYield'] as double? ?? 0.0;
    
    // Fictional benchmarks - in a real app, these would come from actual data
    const regionalAverage = 1100.0;
    const optimalSystem = 1500.0;
    const theoreticalMax = 1800.0;
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: theoreticalMax * 1.1,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String title;
              switch (group.x.toInt()) {
                case 0:
                  title = 'Your System';
                  break;
                case 1:
                  title = 'Regional Average';
                  break;
                case 2:
                  title = 'Optimal System';
                  break;
                case 3:
                  title = 'Theoretical Max';
                  break;
                default:
                  title = 'Unknown';
              }
              return BarTooltipItem(
                '$title\n${rod.toY.round()} kWh/kWp',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String title;
                switch (value.toInt()) {
                  case 0:
                    title = 'Your System';
                    break;
                  case 1:
                    title = 'Regional Avg';
                    break;
                  case 2:
                    title = 'Optimal';
                    break;
                  case 3:
                    title = 'Max';
                    break;
                  default:
                    title = '';
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4,
                  child: Text(
                    title,
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
                  child: Text(
                    '${value.toInt()} kWh/kWp',
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
        gridData: const FlGridData(
          show: true,
          horizontalInterval: 300,
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: systemPerformance,
                color: Colors.blue,
                width: 30,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: regionalAverage,
                color: Colors.grey,
                width: 30,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: optimalSystem,
                color: Colors.green,
                width: 30,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [
              BarChartRodData(
                toY: theoreticalMax,
                color: Colors.amber,
                width: 30,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSystemDetailsDialog() {
    return AlertDialog(
      title: const Text('System Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // PV Module Details
            const Text(
              'PV Module',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Manufacturer', widget.module.manufacturer),
            _buildDetailRow('Model', widget.module.model),
            _buildDetailRow('Power Rating', '${widget.module.powerRating} W'),
            _buildDetailRow('Efficiency', '${(widget.module.efficiency * 100).toStringAsFixed(1)}%'),
            _buildDetailRow('Dimensions', '${widget.module.length} × ${widget.module.width} m'),
            _buildDetailRow('Temperature Coefficient', '${widget.module.temperatureCoefficient}%/°C'),
            _buildDetailRow('NOCT', '${widget.module.nominalOperatingCellTemp}°C'),
            
            const Divider(),
            
            // Inverter Details
            const Text(
              'Inverter',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Manufacturer', widget.inverter.manufacturer),
            _buildDetailRow('Model', widget.inverter.model),
            _buildDetailRow('AC Power Rating', '${(widget.inverter.ratedPowerAC / 1000).toStringAsFixed(1)} kW'),
            _buildDetailRow('Max DC Power', '${(widget.inverter.maxDCPower / 1000).toStringAsFixed(1)} kW'),
            _buildDetailRow('Efficiency', '${(widget.inverter.efficiency * 100).toStringAsFixed(1)}%'),
            _buildDetailRow('MPP Voltage Range', '${widget.inverter.minMPPVoltage}-${widget.inverter.maxMPPVoltage} V'),
            _buildDetailRow('MPP Trackers', '${widget.inverter.numberOfMPPTrackers}'),
            
            const Divider(),
            
            // System Configuration
            const Text(
              'System Configuration',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Modules in Series', '${widget.modulesInSeries}'),
            _buildDetailRow('Strings in Parallel', '${widget.stringsInParallel}'),
            _buildDetailRow('Total Modules', '${widget.modulesInSeries * widget.stringsInParallel}'),
            _buildDetailRow('System Size', '${(_simulationResults['systemSizeKw'] as double? ?? 0.0).toStringAsFixed(2)} kWp'),
            _buildDetailRow('Tilt Angle', '${widget.tiltAngle.toStringAsFixed(1)}°'),
            _buildDetailRow('Azimuth Angle', '${widget.azimuthAngle.toStringAsFixed(1)}°'),
            
            if (widget.batteryCapacity != null) ...[
              const Divider(),
              
              // Battery Details
              const Text(
                'Battery Storage',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('Battery Capacity', '${widget.batteryCapacity} kWh'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
  
  Widget _buildInfoTile(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricBox(String title, String value, Color? color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEnergyCounter(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)} kWh',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMetricColumn(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSavingsMetric(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  Color _getPerformanceColor(double performanceRatio) {
    if (performanceRatio >= 80) {
      return Colors.green;
    } else if (performanceRatio >= 70) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  Color _getYieldColor(double specificYield) {
    if (specificYield >= 1400) {
      return Colors.green;
    } else if (specificYield >= 1100) {
      return Colors.blue;
    } else if (specificYield >= 900) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  Color _getPowerGaugeColor(double power, double maxPower) {
    if (power >= maxPower * 0.7) {
      return Colors.green;
    } else if (power >= maxPower * 0.3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  Color _getBatteryColor(double stateOfCharge) {
    if (stateOfCharge >= 80) {
      return Colors.green;
    } else if (stateOfCharge >= 50) {
      return Colors.lightGreen;
    } else if (stateOfCharge >= 30) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  List<BarChartGroupData> _generateMonthlyBarGroups(Map<String, double> monthlyEnergy) {
    return List.generate(12, (index) {
      final month = _getMonthName(index);
      final value = monthlyEnergy[month] ?? 0;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: Colors.blue,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }
  
  List<FlSpot> _generateYearlyDegradationData() {
    final firstYearEnergy = _simulationResults['annualProduction'] as double? ?? 0.0;
    final spots = <FlSpot>[];
    
    for (int year = 1; year <= 25; year++) {
      // Apply 0.5% annual degradation
      final degradationFactor = math.pow(0.995, year - 1);
      final energyInYear = firstYearEnergy * degradationFactor;
      spots.add(FlSpot(year.toDouble() - 1, energyInYear));
    }
    
    return spots;
  }
  
  List<FlSpot> _generateCumulativeProductionData(double annualProduction) {
    double cumulativeEnergy = 0;
    final spots = <FlSpot>[];
    
    // Year 0 (starting point)
    spots.add(const FlSpot(0, 0));
    
    for (int year = 1; year <= 25; year++) {
      // Apply 0.5% annual degradation
      final degradationFactor = math.pow(0.995, year - 1);
      final yearlyEnergy = annualProduction * degradationFactor;
      cumulativeEnergy += yearlyEnergy;
      spots.add(FlSpot(year.toDouble(), cumulativeEnergy));
    }
    
    return spots;
  }
  
  double _getMaxMonthlyProduction(Map<String, double> monthlyEnergy) {
    if (monthlyEnergy.isEmpty) return 1000.0;
    return monthlyEnergy.values.reduce((max, value) => value > max ? value : max);
  }
  
  String _getMonthName(int index) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return months[index % 12];
  }
  
  int _getDaysInMonth(String month) {
    switch (month) {
      case 'January':
      case 'March':
      case 'May':
      case 'July':
      case 'August':
      case 'October':
      case 'December':
        return 31;
      case 'April':
      case 'June':
      case 'September':
      case 'November':
        return 30;
      case 'February':
        // Simplified leap year handling
        final currentYear = DateTime.now().year;
        final isLeapYear = (currentYear % 4 == 0 && currentYear % 100 != 0) || (currentYear % 400 == 0);
        return isLeapYear ? 29 : 28;
      default:
        return 30;
    }
  }
}

// Helper class for painting arrows
class ArrowPainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;
  final Color color;
  final double strokeWidth;
  
  ArrowPainter({
    required this.startPoint,
    required this.endPoint,
    required this.color,
    required this.strokeWidth,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    
    // Draw the line
    canvas.drawLine(startPoint, endPoint, paint);
    
    // Calculate the angle of the line
    final angle = math.atan2(
      endPoint.dy - startPoint.dy,
      endPoint.dx - startPoint.dx,
    );
    
    // Calculate arrow head points
    final arrowSize = 10.0;
    final arrowPoint1 = Offset(
      endPoint.dx - arrowSize * math.cos(angle - math.pi / 6),
      endPoint.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    
    final arrowPoint2 = Offset(
      endPoint.dx - arrowSize * math.cos(angle + math.pi / 6),
      endPoint.dy - arrowSize * math.sin(angle + math.pi / 6),
    );
    
    // Draw the arrow head
    final arrowPath = Path()
      ..moveTo(endPoint.dx, endPoint.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
      ..close();
    
    canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MonthlyProductionBarChart extends StatelessWidget {
  final Map<String, double> monthlyEnergy;
  
  const MonthlyProductionBarChart({
    super.key,
    required this.monthlyEnergy,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxMonthlyProduction() * 1.1,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final month = _getMonthName(group.x.toInt());
              final value = rod.toY;
              return BarTooltipItem(
                '$month\n${value.round()} kWh',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4,
                  child: Text(
                    _getMonthName(value.toInt())[0], // First letter of month
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
              reservedSize: 20,
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
                    '${value.toInt()} kWh',
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
        gridData: const FlGridData(
          show: true,
          horizontalInterval: 300,
        ),
        borderData: FlBorderData(show: false),
        barGroups: _generateBarGroups(),
      ),
    );
  }
  
  List<BarChartGroupData> _generateBarGroups() {
    return List.generate(12, (index) {
      final month = _getMonthName(index);
      final value = monthlyEnergy[month] ?? 0;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: Colors.blue,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }
  
  double _getMaxMonthlyProduction() {
    if (monthlyEnergy.isEmpty) return 1000.0;
    return monthlyEnergy.values.reduce((max, value) => value > max ? value : max);
  }
  
  String _getMonthName(int index) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return months[index % 12];
  }
}