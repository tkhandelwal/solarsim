// lib/widgets/advanced_pv_dashboard.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:solarsim/models/project.dart';
import 'package:solarsim/models/solar_module.dart';
import 'package:solarsim/models/inverter.dart';
import 'package:solarsim/core/pv_system_simulator.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
                  
                  // Performance ratio gauge
                  SizedBox(
                    height: 200,
                    child: SfRadialGauge(
                      axes: <RadialAxis>[
                        RadialAxis(
                          minimum: 0,
                          maximum: 100,
                          ranges: <GaugeRange>[
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
                          pointers: <GaugePointer>[
                            NeedlePointer(
                              value: (_simulationResults['performanceRatio'] as double? ?? 0.0) * 100,
                              needleColor: Colors.black,
                              knobStyle: const KnobStyle(
                                knobRadius: 0.1,
                                sizeUnit: GaugeSizeUnit.factor,
                              ),
                            ),
                          ],
                          annotations: <GaugeAnnotation>[
                            GaugeAnnotation(
                              widget: Text(
                                '${((_simulationResults['performanceRatio'] as double? ?? 0.0) * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _getPerformanceColor(
                                    (_simulationResults['performanceRatio'] as double? ?? 0.0) * 100
                                  ),
                                ),
                              ),
                              angle: 90,
                              positionFactor: 0.5,
                            ),
                            const GaugeAnnotation(
                              widget: Text(
                                'Performance Ratio',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              angle: 90,
                              positionFactor: 0.8,
                            ),
                          ],
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
            
            // Current power gauge
            SizedBox(
              height: 160,
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: (_simulationResults['systemSizeKw'] as double? ?? 10.0) * 1.1,
                    radiusFactor: 0.8,
                    showLabels: true,
                    showTicks: true,
                    axisLabelStyle: const GaugeTextStyle(
                      fontSize: 10,
                    ),
                    ranges: <GaugeRange>[
                      GaugeRange(
                        startValue: 0,
                        endValue: (_simulationResults['systemSizeKw'] as double? ?? 10.0) * 0.2,
                        color: Colors.red[200],
                        startWidth: 20,
                        endWidth: 20,
                      ),
                      GaugeRange(
                        startValue: (_simulationResults['systemSizeKw'] as double? ?? 10.0) * 0.2,
                        endValue: (_simulationResults['systemSizeKw'] as double? ?? 10.0) * 0.7,
                        color: Colors.orange[300],
                        startWidth: 20,
                        endWidth: 20,
                      ),
                      GaugeRange(
                        startValue: (_simulationResults['systemSizeKw'] as double? ?? 10.0) * 0.7,
                        endValue: (_simulationResults['systemSizeKw'] as double? ?? 10.0) * 1.1,
                        color: Colors.green[400],
                        startWidth: 20,
                        endWidth: 20,
                      ),
                    ],
                    pointers: <GaugePointer>[
                      NeedlePointer(
                        value: _currentPower,
                        needleLength: 0.7,
                        needleColor: Colors.black,
                        knobStyle: const KnobStyle(
                          knobRadius: 0.1,
                          sizeUnit: GaugeSizeUnit.factor,
                          color: Colors.black,
                        ),
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_currentPower.toStringAsFixed(1)} kW',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Current Power',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        angle: 90,
                        positionFactor: 0.5,
                      ),
                    ],
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
                              const Icon(Icons.park, color: Colors.green, size: 40),
                              Text(
                                '= ${treeEquivalent.toStringAsFixed(1)} trees',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Column(
                            children: [
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
    // This would ideally be a custom interactive diagram showing energy flows
    // For now, we'll create a simplified static version
    
    return Stack(
      children: [
        // Background
        Positioned.fill(
          child: Container(
            color: Colors.blue[50],
          ),
        ),
        
        // Sun
        Positioned(
          top: 30,
          left: 50,
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellow.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.wb_sunny, size: 60, color: Colors.orange),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Sun', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        
        // Solar Panels
        Positioned(
          top: 150,
          left: MediaQuery.of(context).size.width / 2 - 100,
          child: Column(
            children: [
              Transform(
                transform: Matrix4.rotationX(0.5), // Tilt panels
                alignment: Alignment.center,
                child: Container(
                  width: 200,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue[900],
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 1,
                    ),
                    itemCount: 8,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.all(2),
                        color: Colors.blue[800],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Solar Panels', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${_currentPower.toStringAsFixed(1)} kW', style: TextStyle(color: Colors.blue[700])),
            ],
          ),
        ),
        
        // Inverter
        Positioned(
          top: 300,
          left: MediaQuery.of(context).size.width / 2 - 40,
          child: Column(
            children: [
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.electrical_services, size: 40, color: Colors.grey[800]),
                    const SizedBox(height: 4),
                    Container(
                      width: 40,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text('Inverter', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        
        // Battery (if applicable)
        if (widget.batteryCapacity != null)
          Positioned(
            top: 300,
            right: 50,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: 70,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.grey[600]!),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    Container(
                      width: 70,
                      height: 100 * _batteryStateOfCharge / 100,
                      decoration: BoxDecoration(
                        color: _getBatteryColor(_batteryStateOfCharge),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    Positioned(
                      top: 5,
                      child: Container(
                        width: 20,
                        height: 10,
                        decoration: BoxDecoration(
                          color