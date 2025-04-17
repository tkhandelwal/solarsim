// lib/widgets/battery_storage.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class BatteryStorageSimulation extends StatefulWidget {
  final double dailyEnergyProduction;
  final Map<String, double> hourlyProduction;
  final Map<String, double> hourlyConsumption;
  
  const BatteryStorageSimulation({
    super.key,
    required this.dailyEnergyProduction,
    required this.hourlyProduction,
    required this.hourlyConsumption,
  });

  @override
  State<BatteryStorageSimulation> createState() => _BatteryStorageSimulationState();
}

class _BatteryStorageSimulationState extends State<BatteryStorageSimulation> {
  double _batteryCapacity = 10.0; // kWh
  double _maxChargePower = 5.0; // kW
  double _maxDischargePower = 5.0; // kW
  int _selectedDay = 0;
  
  final List<String> _dayOptions = ['Typical Sunny Day', 'Typical Cloudy Day', 'Worst Case Day', 'Best Case Day'];
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Battery Storage Simulation',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        
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
                
                // Battery capacity slider
                _buildSliderWithLabel(
                  'Battery Capacity (kWh)',
                  _batteryCapacity,
                  5,
                  50,
                  (value) {
                    setState(() {
                      _batteryCapacity = value.roundToDouble();
                    });
                  },
                ),
                
                // Max charge power slider
                _buildSliderWithLabel(
                  'Max Charging Power (kW)',
                  _maxChargePower,
                  1,
                  10,
                  (value) {
                    setState(() {
                      _maxChargePower = value.roundToDouble();
                    });
                  },
                ),
                
                // Max discharge power slider
                _buildSliderWithLabel(
                  'Max Discharging Power (kW)',
                  _maxDischargePower,
                  1,
                  10,
                  (value) {
                    setState(() {
                      _maxDischargePower = value.roundToDouble();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Day selection
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
                const SizedBox(height: 8),
                
                DropdownButtonFormField<int>(
                  value: _selectedDay,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(_dayOptions.length, (index) {
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Text(_dayOptions[index]),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedDay = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Results chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simulation Results',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                AspectRatio(
                  aspectRatio: 1.6,
                  child: BatterySimulationChart(
                    batteryCapacity: _batteryCapacity,
                    maxChargePower: _maxChargePower,
                    maxDischargePower: _maxDischargePower,
                    selectedDay: _selectedDay,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Key metrics
                Column(
                  children: [
                    _buildMetricRow('Self-consumption rate', '78.3%'),
                    _buildMetricRow('Self-sufficiency rate', '65.2%'),
                    _buildMetricRow('Grid energy import', '4.2 kWh/day'),
                    _buildMetricRow('Grid energy export', '8.5 kWh/day'),
                    _buildMetricRow('Battery cycles per year', '320'),
                    _buildMetricRow('Expected battery lifetime', '10 years'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSliderWithLabel(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${value.toStringAsFixed(1)}'),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 2).toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }
  
  Widget _buildMetricRow(String label, String value) {
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

class BatterySimulationChart extends StatelessWidget {
  final double batteryCapacity;
  final double maxChargePower;
  final double maxDischargePower;
  final int selectedDay;
  
  const BatterySimulationChart({
    super.key,
    required this.batteryCapacity,
    required this.maxChargePower,
    required this.maxDischargePower,
    required this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
          ),
          touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {},
          handleBuiltInTouches: true,
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: batteryCapacity / 5,
          verticalInterval: 3,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 3,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                if (hour % 3 != 0) return const Text('');
                
                String text;
                if (hour == 0 || hour == 24) {
                  text = '12 AM';
                } else if (hour < 12) {
                  text = '$hour AM';
                } else if (hour == 12) {
                  text = '12 PM';
                } else {
                  text = '${hour - 12} PM';
                }
                
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(text, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: batteryCapacity / 5,
              getTitlesWidget: (value, meta) {
                final state = (value / batteryCapacity * 100).round();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: value >= 0 && value <= batteryCapacity 
                      ? Text('$state%', style: const TextStyle(fontSize: 10))
                      : const Text(''),
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
          border: Border.all(color: const Color(0xff37434d)),
        ),
        minX: 0,
        maxX: 24,
        minY: 0,
        maxY: batteryCapacity,
        lineBarsData: [
          _getBatteryStateOfChargeData(),
          _getSolarProductionData(),
          _getConsumptionData(),
        ],
        lineTouchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final lineData = touchedSpot.bar;
              String unit = '';
              String title = '';
              if (lineData == _getBatteryStateOfChargeData()) {
                title = 'Battery';
                unit = 'kWh';
              } else if (lineData == _getSolarProductionData()) {
                title = 'Solar';
                unit = 'kW';
              } else if (lineData == _getConsumptionData()) {
                title = 'Consumption';
                unit = 'kW';
              }
              
              return LineTooltipItem(
                '$title: ${touchedSpot.y.toStringAsFixed(1)} $unit',
                TextStyle(
                  color: touchedSpot.bar.color,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }
  
  LineChartBarData _getBatteryStateOfChargeData() {
    // Generate synthetic battery state of charge data
    // In a real app, this would be calculated based on the system model
    final List<FlSpot> spots = [];
    
    // Initial state of charge (50%)
    double stateOfCharge = batteryCapacity * 0.5;
    spots.add(FlSpot(0, stateOfCharge));
    
    for (int hour = 1; hour <= 24; hour++) {
      // Energy balance for the hour
      final production = _getSolarProductionForHour(hour);
      final consumption = _getConsumptionForHour(hour);
      final energyBalance = production - consumption;
      
      // Update state of charge based on energy balance
      if (energyBalance > 0) {
        // Charging - limited by max charge power
        final chargingEnergy = math.min(energyBalance, maxChargePower);
        stateOfCharge = math.min(batteryCapacity, stateOfCharge + chargingEnergy);
      } else {
        // Discharging - limited by max discharge power
        final dischargingEnergy = math.min(-energyBalance, maxDischargePower);
        stateOfCharge = math.max(0, stateOfCharge - dischargingEnergy);
      }
      
      spots.add(FlSpot(hour.toDouble(), stateOfCharge));
    }
    
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Colors.blue,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: Colors.blue.withOpacity(0.2),
      ),
    );
  }
  
  LineChartBarData _getSolarProductionData() {
    // Generate synthetic solar production data
    final List<FlSpot> spots = [];
    
    for (int hour = 0; hour <= 24; hour++) {
      spots.add(FlSpot(hour.toDouble(), _getSolarProductionForHour(hour)));
    }
    
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Colors.orange,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
    );
  }
  
  LineChartBarData _getConsumptionData() {
    // Generate synthetic consumption data
    final List<FlSpot> spots = [];
    
    for (int hour = 0; hour <= 24; hour++) {
      spots.add(FlSpot(hour.toDouble(), _getConsumptionForHour(hour)));
    }
    
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Colors.red,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
    );
  }
  
  double _getSolarProductionForHour(int hour) {
    // Different production profiles for different day types
    switch (selectedDay) {
      case 0: // Sunny day
        if (hour < 6 || hour > 20) return 0;
        const peakPower = 8.0;
        return peakPower * math.sin((hour - 6) / 14 * math.pi);
      case 1: // Cloudy day
        if (hour < 7 || hour > 19) return 0;
        const peakPower = 3.0;
        return peakPower * math.sin((hour - 7) / 12 * math.pi) * (0.7 + 0.3 * math.sin(hour * 5));
      case 2: // Worst case day
        if (hour < 8 || hour > 17) return 0;
        const peakPower = 1.5;
        return peakPower * math.sin((hour - 8) / 9 * math.pi) * (0.5 + 0.5 * math.sin(hour * 3));
      case 3: // Best case day
        if (hour < 5 || hour > 21) return 0;
        const peakPower = 10.0;
        return peakPower * math.sin((hour - 5) / 16 * math.pi);
      default:
        return 0;
    }
  }
  
  double _getConsumptionForHour(int hour) {
    // Typical residential consumption profile
    final List<double> hourlyProfile = [
      0.2, 0.15, 0.15, 0.15, 0.2, 0.3,    // 0-5h
      0.5, 1.0, 1.2, 0.8, 0.6, 0.5,       // 6-11h
      0.6, 0.5, 0.5, 0.6, 0.8, 1.5,       // 12-17h
      2.0, 1.8, 1.5, 1.0, 0.5, 0.3,       // 18-23h
    ];
    
    return hourlyProfile[hour];
  }
}