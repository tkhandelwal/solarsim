// lib/widgets/advanced_pv_forecast.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:solarsim/models/project.dart';
import 'package:solarsim/models/solar_module.dart';
import 'package:solarsim/models/inverter.dart';
import 'package:solarsim/core/pv_system_simulator.dart';
import 'package:solarsim/core/weather_data.dart';
import 'package:solarsim/services/weather_service.dart';
import 'dart:math' as math;

class AdvancedPVForecast extends StatefulWidget {
  final Project project;
  final SolarModule module;
  final Inverter inverter;
  final int modulesInSeries;
  final int stringsInParallel;
  final double tiltAngle;
  final double azimuthAngle;
  final Map<String, double> losses;
  
  const AdvancedPVForecast({
    super.key,
    required this.project,
    required this.module,
    required this.inverter,
    required this.modulesInSeries,
    required this.stringsInParallel,
    required this.tiltAngle,
    required this.azimuthAngle,
    required this.losses,
  });

  @override
  State<AdvancedPVForecast> createState() => _AdvancedPVForecastState();
}

class _AdvancedPVForecastState extends State<AdvancedPVForecast> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  WeatherData? _weatherData;
  Map<String, dynamic> _forecastResults = {};
  bool _isLoading = true;
  bool _isDetailedView = false;
  String _selectedChart = 'production';
  int _selectedYear = 1; // 1st year
  String _selectedDetailMonth = 'Annual';
  String _selectedDetailDay = 'Typical';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWeatherData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
    });
    
    // In a real app, this would load actual weather data from a weather service
    // For now, we'll use the test weather data
    final weatherService = WeatherService();
    final weatherData = await weatherService.getWeatherData(widget.project);
    
    setState(() {
      _weatherData = weatherData;
      _runSimulation();
      _isLoading = false;
    });
  }
  
  void _runSimulation() {
    if (_weatherData == null) return;
    
    // Create a simulator
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
      acWiringLoss: widget.losses['wiring'] ?? 0.01,
      systemAvailability: 1 - (widget.losses['availability'] ?? 0.02),
    );
    
    // Run the simulation for the first year
    final yearlyResult = simulator.simulateYear(year: 2025);
    
    // Extract monthly and annual results
    final monthlyEnergy = <String, double>{};
    for (int i = 0; i < yearlyResult.monthlyResults.length; i++) {
      final month = yearlyResult.monthlyResults[i];
      monthlyEnergy[month.monthName] = month.energyAC;
    }
    
    // Generate production forecast for 25 years
    final yearlyDegradation = widget.module.technology == ModuleTechnology.thinFilm ? 0.007 : 0.005;
    final yearlyProduction = <int, double>{};
    double cumulativeProduction = 0;
    
    for (int year = 1; year <= 25; year++) {
      final degradationFactor = math.pow(1 - yearlyDegradation, year - 1);
      final annualProduction = yearlyResult.energyAC * degradationFactor;
      yearlyProduction[year] = annualProduction;
      cumulativeProduction += annualProduction;
    }
    
    // Generate typical daily profiles for each month
    final monthlyDailyProfiles = <String, List<HourlySimulationResult>>{};
    for (final monthResult in yearlyResult.monthlyResults) {
      // In a real app, this would use actual simulated hourly data
      // For now, we'll generate synthetic data based on the month's energy
      final monthName = monthResult.monthName;
      final dailyEnergy = monthResult.energyAC / DateTime(2025, monthResult.month + 1, 0).day;
      
      // Generate hourly production for a typical day in this month
      final hourlyResults = <HourlySimulationResult>[];
      
      for (int hour = 0; hour < 24; hour++) {
        double hourlyFactor;
        if (hour < 6 || hour > 19) {
          hourlyFactor = 0;
        } else {
          hourlyFactor = math.sin((hour - 6) * math.pi / 14);
        }
        
        final hourlyEnergy = dailyEnergy * hourlyFactor;
        
        hourlyResults.add(HourlySimulationResult(
          dateTime: DateTime(2025, monthResult.month, 15, hour),
          globalHorizontalIrradiance: hourlyFactor * 1000,
          planeOfArrayIrradiance: hourlyFactor * 1200,
          ambientTemperature: 20 + 5 * hourlyFactor,
          cellTemperature: 25 + 20 * hourlyFactor,
          dcPower: hourlyEnergy * 1.1 * 1000,
          acPower: hourlyEnergy * 1000,
          efficiency: 0.15 + 0.02 * hourlyFactor,
          performanceRatio: 0.8 + 0.05 * hourlyFactor,
        ));
      }
      
      monthlyDailyProfiles[monthName] = hourlyResults;
    }
    
    // Store the results
    setState(() {
      _forecastResults = {
        'annualEnergy': yearlyResult.energyAC,
        'monthlyEnergy': monthlyEnergy,
        'specificYield': yearlyResult.specificYield,
        'performanceRatio': yearlyResult.averagePerformanceRatio,
        'yearlyProduction': yearlyProduction,
        'cumulativeProduction': cumulativeProduction,
        'monthlyDailyProfiles': monthlyDailyProfiles,
      };
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Annual'),
            Tab(text: 'Monthly'),
            Tab(text: 'Daily'),
          ],
        ),
        
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAnnualTab(),
                _buildMonthlyTab(),
                _buildDailyTab(),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildAnnualTab() {
    if (_forecastResults.isEmpty) {
      return const Center(child: Text('No forecast data available'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Annual production summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Annual Production Summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow(
                    'First Year Energy Production',
                    '${(_forecastResults['annualEnergy'] as double).toStringAsFixed(0)} kWh',
                  ),
                  _buildInfoRow(
                    'Specific Yield',
                    '${(_forecastResults['specificYield'] as double).toStringAsFixed(0)} kWh/kWp',
                  ),
                  _buildInfoRow(
                    'Performance Ratio',
                    '${((_forecastResults['performanceRatio'] as double) * 100).toStringAsFixed(1)}%',
                  ),
                  _buildInfoRow(
                    'Lifetime Production (25 yrs)',
                    '${(_forecastResults['cumulativeProduction'] as double).toStringAsFixed(0)} kWh',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Chart selection
          Row(
            children: [
              const Text('View: '),
              const SizedBox(width: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'production',
                    label: Text('Annual Production'),
                  ),
                  ButtonSegment<String>(
                    value: 'degradation',
                    label: Text('Degradation'),
                  ),
                ],
                selected: {_selectedChart},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedChart = selection.first;
                  });
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Annual production chart
          if (_selectedChart == 'production')
            _buildAnnualProductionChart()
          else
            _buildDegradationChart(),
            
          const SizedBox(height: 16),
          
          // Monthly breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Production Breakdown',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  AspectRatio(
                    aspectRatio: 1.6,
                    child: MonthlyProductionChart(
                      monthlyEnergy: _forecastResults['monthlyEnergy'],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMonthlyTab() {
    if (_forecastResults.isEmpty) {
      return const Center(child: Text('No forecast data available'));
    }
    
    final monthlyEnergy = _forecastResults['monthlyEnergy'] as Map<String, double>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month selector
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select Month',
              border: OutlineInputBorder(),
            ),
            value: _selectedDetailMonth,
            items: [
              const DropdownMenuItem<String>(
                value: 'Annual',
                child: Text('Annual Overview'),
              ),
              ...monthlyEnergy.keys.map((month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(month),
                );
              }),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedDetailMonth = value;
                });
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          if (_selectedDetailMonth == 'Annual')
            _buildMonthlyComparisonTable(monthlyEnergy)
          else
            _buildMonthlyDetailView(_selectedDetailMonth),
        ],
      ),
    );
  }
  
  Widget _buildDailyTab() {
    if (_forecastResults.isEmpty) {
      return const Center(child: Text('No forecast data available'));
    }
    
    final monthlyDailyProfiles = _forecastResults['monthlyDailyProfiles'] as Map<String, List<HourlySimulationResult>>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month selector
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Month',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedDetailMonth != 'Annual' ? _selectedDetailMonth : 'January',
                  items: monthlyDailyProfiles.keys.map((month) {
                    return DropdownMenuItem<String>(
                      value: month,
                      child: Text(month),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedDetailMonth = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Day Type',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedDetailDay,
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'Typical',
                      child: Text('Typical Day'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Clear',
                      child: Text('Clear Sky'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Cloudy',
                      child: Text('Cloudy Day'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedDetailDay = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Daily profile chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hourly Power Output - $_selectedDetailMonth ($_selectedDetailDay Day)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  AspectRatio(
                    aspectRatio: 1.6,
                    child: DailyProfileChart(
                      hourlyResults: _getDailyProfile(_selectedDetailMonth, _selectedDetailDay),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Daily parameters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Parameters',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDailyParametersTable(_selectedDetailMonth, _selectedDetailDay),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnnualProductionChart() {
    final yearlyProduction = _forecastResults['yearlyProduction'] as Map<int, double>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Annual Energy Production',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Select Year',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              value: _selectedYear,
              items: List.generate(25, (index) {
                final year = index + 1;
                return DropdownMenuItem<int>(
                  value: year,
                  child: Text('Year $year'),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedYear = value;
                  });
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            AspectRatio(
              aspectRatio: 1.6,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.grey.shade200,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          'Year ${group.x + 1}\n${rod.toY.round()} kWh',
                          const TextStyle(color: Colors.black),
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
                          final year = value.toInt() + 1;
                          if (year % 5 == 0 || year == 1 || year == 25) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 4,
                              child: Text(
                                year.toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) {
                            return const Text('');
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4,
                            child: Text(
                              '${value.toInt()} kWh',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
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
                    horizontalInterval: 5000,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(25, (index) {
                    final year = index + 1;
                    final value = yearlyProduction[year] ?? 0;
                    
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          color: year == _selectedYear ? Colors.orange : Colors.blue.shade200,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (_selectedYear > 0) ...[
              _buildInfoRow(
                'Year $_selectedYear Production',
                '${yearlyProduction[_selectedYear]?.toStringAsFixed(0)} kWh',
              ),
              _buildInfoRow(
                'Degradation from Year 1',
                '-${((1 - (yearlyProduction[_selectedYear] ?? 0) / (yearlyProduction[1] ?? 1)) * 100).toStringAsFixed(1)}%',
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildDegradationChart() {
    final yearlyProduction = _forecastResults['yearlyProduction'] as Map<int, double>;
    final firstYearProduction = yearlyProduction[1] ?? 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Module Degradation Over Time',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            AspectRatio(
              aspectRatio: 1.6,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.grey.shade200,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final year = spot.x.toInt();
                          final percentage = spot.y;
                          return LineTooltipItem(
                            'Year $year\n${percentage.toStringAsFixed(1)}%',
                            TextStyle(color: Colors.blue.shade800),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: const FlGridData(
                    show: true,
                    horizontalInterval: 5,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final year = value.toInt();
                          if (year % 5 == 0 || year == 1 || year == 25) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 4,
                              child: Text(
                                year.toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4,
                            child: Text(
                              '${value.toInt()}%',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
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
                  minX: 1,
                  maxX: 25,
                  minY: 80,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(25, (index) {
                        final year = index + 1;
                        final production = yearlyProduction[year] ?? 0;
                        final percentage = (production / firstYearProduction) * 100;
                        
                        return FlSpot(year.toDouble(), percentage);
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
                    // Warranty line
                    LineChartBarData(
                      spots: const [
                        FlSpot(1, 97),
                        FlSpot(10, 90),
                        FlSpot(25, 80),
                      ],
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      dashArray: [5, 5],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Container(
                  width: 16,
                  height: 3,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                const Text('Actual Performance'),
                const SizedBox(width: 16),
                Container(
                  width: 16,
                  height: 3,
                  color: Colors.red,
                  margin: const EdgeInsets.only(right: 2),
                ),
                Container(
                  width: 16,
                  height: 3,
                  color: Colors.transparent,
                  margin: const EdgeInsets.only(right: 2),
                ),
                Container(
                  width: 16,
                  height: 3,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                const Text('Manufacturer Warranty'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMonthlyComparisonTable(Map<String, double> monthlyEnergy) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Production Comparison',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('Month')),
                  DataColumn(label: Text('Energy (kWh)'), numeric: true),
                  DataColumn(label: Text('Daily Average (kWh)'), numeric: true),
                  DataColumn(label: Text('% of Annual'), numeric: true),
                ],
                rows: monthlyEnergy.entries.map((entry) {
                  final month = entry.key;
                  final energy = entry.value;
                  final daysInMonth = _getDaysInMonth(month);
                  final dailyAverage = energy / daysInMonth;
                  final percentOfAnnual = energy / (_forecastResults['annualEnergy'] as double) * 100;
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(month)),
                      DataCell(Text(energy.toStringAsFixed(0))),
                      DataCell(Text(dailyAverage.toStringAsFixed(1))),
                      DataCell(Text(percentOfAnnual.toStringAsFixed(1))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMonthlyDetailView(String month) {
    final monthlyEnergy = _forecastResults['monthlyEnergy'] as Map<String, double>;
    final energy = monthlyEnergy[month] ?? 0;
    final daysInMonth = _getDaysInMonth(month);
    final dailyAverage = energy / daysInMonth;
    
    // Weather conditions for the month (simplified for now)
    final averageTemp = _getMonthlyTemperature(month);
    final averageIrradiance = _getMonthlyIrradiance(month);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$month Production Summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                _buildInfoRow('Total Energy Production', '${energy.toStringAsFixed(0)} kWh'),
                _buildInfoRow('Daily Average', '${dailyAverage.toStringAsFixed(1)} kWh'),
                _buildInfoRow('Average Temperature', '${averageTemp.toStringAsFixed(1)} °C'),
                _buildInfoRow('Average Irradiance', '${averageIrradiance.toStringAsFixed(0)} W/m²'),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Production Profile',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                AspectRatio(
                  aspectRatio: 1.6,
                  child: DailyProfileChart(
                    hourlyResults: _getDailyProfile(month, 'Typical'),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Weather data for the month
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather Conditions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                AspectRatio(
                  aspectRatio: 1.6,
                  child: _buildMonthlyWeatherChart(month),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMonthlyWeatherChart(String month) {
    // Generate synthetic temperature and irradiance data for the month
    final daysInMonth = _getDaysInMonth(month);
    final baseTemp = _getMonthlyTemperature(month);
    final baseIrradiance = _getMonthlyIrradiance(month);
    
    final dailyTemps = List.generate(daysInMonth, (index) {
      return baseTemp + (math.Random().nextDouble() * 4 - 2);
    });
    
    final dailyIrradiance = List.generate(daysInMonth, (index) {
      return baseIrradiance * (0.7 + math.Random().nextDouble() * 0.6);
    });
    
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.grey.shade200,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final day = spot.x.toInt() + 1;
                final value = spot.y;
                final seriesIndex = touchedSpots.indexOf(spot);
                
                if (seriesIndex == 0) {
                  return LineTooltipItem(
                    'Day $day\n${value.toStringAsFixed(1)} °C',
                    const TextStyle(color: Colors.red),
                  );
                } else {
                  return LineTooltipItem(
                    'Day $day\n${value.toStringAsFixed(0)} W/m²',
                    const TextStyle(color: Colors.orange),
                  );
                }
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final day = value.toInt() + 1;
                if (day % 5 == 0 || day == 1 || day == daysInMonth) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      day.toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    '${value.toInt()} °C',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    '${value.toInt()} W/m²',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: daysInMonth - 1,
        minY: 0,
        maxY: 40,
        lineBarsData: [
          // Temperature line
          LineChartBarData(
            spots: List.generate(daysInMonth, (index) {
              return FlSpot(index.toDouble(), dailyTemps[index]);
            }),
            isCurved: true,
            color: Colors.red,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: baseTemp,
              color: Colors.red.withOpacity(0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDailyParametersTable(String month, String dayType) {
    final hourlyData = _getDailyProfile(month, dayType);
    
    // Calculate some daily parameters
    double totalEnergy = 0;
    double peakPower = 0;
    double avgTemperature = 0;
    int dayHours = 0;
    
    for (final hourData in hourlyData) {
      totalEnergy += hourData.acPower / 1000; // Convert to kWh (assuming hourly data)
      if (hourData.acPower > peakPower) {
        peakPower = hourData.acPower;
      }
      
      if (hourData.acPower > 0) {
        avgTemperature += hourData.cellTemperature;
        dayHours++;
      }
    }
    
    avgTemperature = dayHours > 0 ? avgTemperature / dayHours : 0;
    
    // Calculate sunrise and sunset times
    final sunriseHour = hourlyData.indexWhere((hour) => hour.acPower > 0);
    final sunsetHour = hourlyData.lastIndexWhere((hour) => hour.acPower > 0);
    
    final sunrise = sunriseHour >= 0 ? _formatHour(sunriseHour) : 'N/A';
    final sunset = sunsetHour >= 0 ? _formatHour(sunsetHour) : 'N/A';
    
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.5),
        1: FlexColumnWidth(1),
      },
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        _buildTableRow('Daily Energy', '${totalEnergy.toStringAsFixed(1)} kWh'),
        _buildTableRow('Peak Power', '${(peakPower / 1000).toStringAsFixed(2)} kW'),
        _buildTableRow('Average Cell Temp', '${avgTemperature.toStringAsFixed(1)} °C'),
        _buildTableRow('Sunrise', sunrise),
        _buildTableRow('Sunset', sunset),
        _buildTableRow('Daylight Hours', '${dayHours}h'),
      ],
    );
  }
  
  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(value),
        ),
      ],
    );
  }
  
  List<HourlySimulationResult> _getDailyProfile(String month, String dayType) {
    final monthlyDailyProfiles = _forecastResults['monthlyDailyProfiles'] as Map<String, List<HourlySimulationResult>>;
    final baseProfile = monthlyDailyProfiles[month] ?? [];
    
    if (dayType == 'Typical') {
      return baseProfile;
    } 
    
    // Apply modifier for different day types
    final multiplier = dayType == 'Clear' ? 1.2 : 0.6; // Clear day or cloudy day
    
    return baseProfile.map((hourData) {
      return HourlySimulationResult(
        dateTime: hourData.dateTime,
        globalHorizontalIrradiance: hourData.globalHorizontalIrradiance * multiplier,
        planeOfArrayIrradiance: hourData.planeOfArrayIrradiance * multiplier,
        ambientTemperature: hourData.ambientTemperature,
        cellTemperature: hourData.cellTemperature,
        dcPower: hourData.dcPower * multiplier,
        acPower: hourData.acPower * multiplier,
        efficiency: hourData.efficiency,
        performanceRatio: hourData.performanceRatio,
      );
    }).toList();
  }
  
  double _getMonthlyTemperature(String month) {
    // Simplified temperature model based on typical seasonal patterns
    const monthTemps = {
      'January': 5.0,
      'February': 6.0,
      'March': 10.0,
      'April': 14.0,
      'May': 18.0,
      'June': 22.0,
      'July': 25.0,
      'August': 24.0,
      'September': 20.0,
      'October': 15.0,
      'November': 10.0,
      'December': 6.0,
    };
    
    return monthTemps[month] ?? 15.0;
  }
  
  double _getMonthlyIrradiance(String month) {
    // Simplified irradiance model based on typical seasonal patterns
    const monthIrradiance = {
      'January': 200.0,
      'February': 300.0,
      'March': 400.0,
      'April': 500.0,
      'May': 600.0,
      'June': 650.0,
      'July': 700.0,
      'August': 650.0,
      'September': 500.0,
      'October': 350.0,
      'November': 250.0,
      'December': 200.0,
    };
    
    return monthIrradiance[month] ?? 400.0;
  }
  
  int _getDaysInMonth(String month) {
    const monthDays = {
      'January': 31,
      'February': 28,
      'March': 31,
      'April': 30,
      'May': 31,
      'June': 30,
      'July': 31,
      'August': 31,
      'September': 30,
      'October': 31,
      'November': 30,
      'December': 31,
    };
    
    return monthDays[month] ?? 30;
  }
  
  String _formatHour(int hour) {
    if (hour < 12) {
      return '$hour:00 AM';
    } else if (hour == 12) {
      return '12:00 PM';
    } else {
      return '${hour - 12}:00 PM';
    }
  }
  
  Widget _buildInfoRow(String label, String value) {
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
}

class MonthlyProductionChart extends StatelessWidget {
  final Map<String, double> monthlyEnergy;
  
  const MonthlyProductionChart({
    super.key,
    required this.monthlyEnergy,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.grey.shade200,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final month = _getMonthFromIndex(groupIndex);
              return BarTooltipItem(
                '$month\n${rod.toY.round()} kWh',
                const TextStyle(color: Colors.black),
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
                    _getMonthFromIndex(value.toInt())[0], // First letter of month
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const Text('');
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4,
                  child: Text(
                    '${value.toInt()} kWh',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
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
        barGroups: _getBarGroups(),
      ),
    );
  }
  
  List<BarChartGroupData> _getBarGroups() {
    return List.generate(12, (index) {
      final month = _getMonthFromIndex(index);
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
  
  String _getMonthFromIndex(int index) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    
    return months[index];
  }
}

class DailyProfileChart extends StatelessWidget {
  final List<HourlySimulationResult> hourlyResults;
  
  const DailyProfileChart({
    super.key,
    required this.hourlyResults,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.grey.shade200,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final hour = spot.x.toInt();
                final power = spot.y;
                return LineTooltipItem(
                  '${_formatHour(hour)}\n${(power / 1000).toStringAsFixed(2)} kW',
                  const TextStyle(color: Colors.blue),
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2000,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                if (hour % 3 == 0) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      _formatHourShort(hour),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    '${(value / 1000).toStringAsFixed(1)} kW',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
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
        maxY: _getMaxPower() * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(24, (index) {
              final hourData = hourlyResults.isNotEmpty && index < hourlyResults.length
                  ? hourlyResults[index]
                  : null;
              
              return FlSpot(
                index.toDouble(),
                hourData?.acPower ?? 0,
              );
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
  
  double _getMaxPower() {
    if (hourlyResults.isEmpty) return 5000;
    
    double maxPower = 0;
    for (final hour in hourlyResults) {
      if (hour.acPower > maxPower) {
        maxPower = hour.acPower;
      }
    }
    
    return maxPower;
  }
  
  String _formatHour(int hour) {
    if (hour < 12) {
      return '$hour:00 AM';
    } else if (hour == 12) {
      return '12:00 PM';
    } else {
      return '${hour - 12}:00 PM';
    }
  }
  
  String _formatHourShort(int hour) {
    if (hour < 12) {
      return '${hour}A';
    } else if (hour == 12) {
      return '12P';
    } else {
      return '${hour - 12}P';
    }
  }
}