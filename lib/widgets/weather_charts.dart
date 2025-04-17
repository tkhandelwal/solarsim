// lib/widgets/weather_charts.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:solarsim/core/weather_data.dart';

class IrradiationChart extends StatelessWidget {
  final WeatherData weatherData;
  
  const IrradiationChart({
    super.key,
    required this.weatherData,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.grey.shade200,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${_getMonthName(groupIndex)}\n${rod.toY.round()} kWh/m²',
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
                        _getMonthName(value.toInt())[0], // First letter of month
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
                        '${value.toInt()} kWh/m²',
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
              horizontalInterval: 50,
            ),
            borderData: FlBorderData(show: false),
            barGroups: _getMonthlyIrradiationGroups(),
          ),
        ),
      ),
    );
  }
  
  String _getMonthName(int index) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[index];
  }
  
  List<BarChartGroupData> _getMonthlyIrradiationGroups() {
    // Calculate monthly irradiation values from the weather data
    final monthlyGHI = <int, double>{};
    
    // Calculate monthly sums from the weatherData
    for (final monthEntry in weatherData.monthlyData.entries) {
      final month = monthEntry.key;
      final monthData = monthEntry.value;
      
      double monthlySum = 0;
      for (final day in monthData.dailyData) {
        // Sum up daily GHI values
        monthlySum += day.hourlyGlobalHorizontalIrradiance
            .fold<double>(0, (sum, value) => sum + value) / 1000; // Convert to kWh/m²
      }
      monthlyGHI[month-1] = monthlySum; // Month index 0-11
    }
    
    // Create bar chart groups for each month
    return List.generate(12, (index) {
      final value = monthlyGHI[index] ?? 0;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: Colors.orange,
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
}

class TemperatureChart extends StatelessWidget {
  final WeatherData weatherData;
  
  const TemperatureChart({
    super.key,
    required this.weatherData,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
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
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 4,
                      child: Text(
                        _getMonthName(value.toInt())[0], // First letter of month
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
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 4,
                      child: Text(
                        '${value.toInt()}°C',
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
            minY: _getMinTemperature() - 2,
            maxY: _getMaxTemperature() + 2,
            lineBarsData: [
              _getAverageTemperatureData(),
              _getMaxTemperatureData(),
              _getMinTemperatureData(),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getMonthName(int index) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[index];
  }
  
  double _getMinTemperature() {
    double minTemp = double.infinity;
    
    for (final monthEntry in weatherData.monthlyData.entries) {
      final monthData = monthEntry.value;
      
      for (final day in monthData.dailyData) {
        final dayMin = day.hourlyTemperature.reduce((a, b) => a < b ? a : b);
        if (dayMin < minTemp) {
          minTemp = dayMin;
        }
      }
    }
    
    return minTemp;
  }
  
  double _getMaxTemperature() {
    double maxTemp = double.negativeInfinity;
    
    for (final monthEntry in weatherData.monthlyData.entries) {
      final monthData = monthEntry.value;
      
      for (final day in monthData.dailyData) {
        final dayMax = day.hourlyTemperature.reduce((a, b) => a > b ? a : b);
        if (dayMax > maxTemp) {
          maxTemp = dayMax;
        }
      }
    }
    
    return maxTemp;
  }
  
  LineChartBarData _getAverageTemperatureData() {
    final spots = <FlSpot>[];
    
    for (int month = 1; month <= 12; month++) {
      if (weatherData.monthlyData.containsKey(month)) {
        final monthData = weatherData.monthlyData[month]!;
        
        // Calculate monthly average temperature
        double sum = 0;
        int count = 0;
        
        for (final day in monthData.dailyData) {
          for (final temp in day.hourlyTemperature) {
            sum += temp;
            count++;
          }
        }
        
        final avgTemp = count > 0 ? sum / count : 0;
        spots.add(FlSpot(month - 1, avgTemp.toDouble()));
      } else {
        // If no data for this month, interpolate or add a placeholder
        spots.add(FlSpot(month - 1, 0));
      }
    }
    
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Colors.blue,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: const Color.fromRGBO(0, 0, 255, 0.2), // RGBA format
      ),
    );
  }
  
  LineChartBarData _getMaxTemperatureData() {
    final spots = <FlSpot>[];
    
    for (int month = 1; month <= 12; month++) {
      if (weatherData.monthlyData.containsKey(month)) {
        final monthData = weatherData.monthlyData[month]!;
        
        // Calculate monthly max temperature
        double maxTemp = double.negativeInfinity;
        
        for (final day in monthData.dailyData) {
          final dayMax = day.hourlyTemperature.reduce((a, b) => a > b ? a : b);
          if (dayMax > maxTemp) {
            maxTemp = dayMax;
          }
        }
        
        spots.add(FlSpot(month - 1, maxTemp));
      } else {
        // If no data for this month, interpolate or add a placeholder
        spots.add(FlSpot(month - 1, 0));
      }
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
  
  LineChartBarData _getMinTemperatureData() {
    final spots = <FlSpot>[];
    
    for (int month = 1; month <= 12; month++) {
      if (weatherData.monthlyData.containsKey(month)) {
        final monthData = weatherData.monthlyData[month]!;
        
        // Calculate monthly min temperature
        double minTemp = double.infinity;
        
        for (final day in monthData.dailyData) {
          final dayMin = day.hourlyTemperature.reduce((a, b) => a < b ? a : b);
          if (dayMin < minTemp) {
            minTemp = dayMin;
          }
        }
        
        spots.add(FlSpot(month - 1, minTemp));
      } else {
        // If no data for this month, interpolate or add a placeholder
        spots.add(FlSpot(month - 1, 0));
      }
    }
    
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Colors.lightBlue,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
    );
  }
}

class WindSpeedChart extends StatelessWidget {
  final WeatherData weatherData;
  
  const WindSpeedChart({
    super.key,
    required this.weatherData,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.grey.shade200,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${_getMonthName(groupIndex)}\n${rod.toY.toStringAsFixed(1)} m/s',
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
                        _getMonthName(value.toInt())[0], // First letter of month
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
                        '${value.toStringAsFixed(1)} m/s',
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
              horizontalInterval: 1,
            ),
            borderData: FlBorderData(show: false),
            barGroups: _getMonthlyWindSpeedGroups(),
          ),
        ),
      ),
    );
  }
  
  String _getMonthName(int index) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[index];
  }
  
  List<BarChartGroupData> _getMonthlyWindSpeedGroups() {
    // Calculate monthly wind speed values from the weather data
    final monthlyWindSpeed = <int, double>{};
    
    // Calculate monthly averages from the weatherData
    for (final monthEntry in weatherData.monthlyData.entries) {
      final month = monthEntry.key;
      final monthData = monthEntry.value;
      
      double sum = 0;
      int count = 0;
      
      for (final day in monthData.dailyData) {
        for (final speed in day.hourlyWindSpeed) {
          sum += speed;
          count++;
        }
      }
      
      monthlyWindSpeed[month-1] = count > 0 ? sum / count : 0; // Month index 0-11
    }
    
    // Create bar chart groups for each month
    return List.generate(12, (index) {
      final value = monthlyWindSpeed[index] ?? 0;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: Colors.teal,
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
}

class WeatherDataSummaryGrid extends StatelessWidget {
  final WeatherData weatherData;
  
  const WeatherDataSummaryGrid({
    super.key,
    required this.weatherData,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildInfoCard(
          context,
          'Annual Irradiation',
          _calculateAnnualIrradiation().toStringAsFixed(0),
          'kWh/m²',
          Colors.orange,
          Icons.wb_sunny,
        ),
        _buildInfoCard(
          context,
          'Average Temperature',
          _calculateAverageTemperature().toStringAsFixed(1),
          '°C',
          Colors.red,
          Icons.thermostat,
        ),
        _buildInfoCard(
          context,
          'Average Wind Speed',
          _calculateAverageWindSpeed().toStringAsFixed(1),
          'm/s',
          Colors.teal,
          Icons.air,
        ),
        _buildInfoCard(
          context,
          'Average Humidity',
          _calculateAverageHumidity().toStringAsFixed(0),
          '%',
          Colors.blue,
          Icons.water_drop,
        ),
      ],
    );
  }
  
  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  double _calculateAnnualIrradiation() {
    double annualIrradiation = 0;
    
    for (final monthEntry in weatherData.monthlyData.entries) {
      final monthData = monthEntry.value;
      
      for (final day in monthData.dailyData) {
        // Sum up daily GHI values
        annualIrradiation += day.hourlyGlobalHorizontalIrradiance
            .fold<double>(0, (sum, value) => sum + value) / 1000; // Convert to kWh/m²
      }
    }
    
    return annualIrradiation;
  }
  
  double _calculateAverageTemperature() {
    double sum = 0;
    int count = 0;
    
    for (final monthEntry in weatherData.monthlyData.entries) {
      final monthData = monthEntry.value;
      
      for (final day in monthData.dailyData) {
        for (final temp in day.hourlyTemperature) {
          sum += temp;
          count++;
        }
      }
    }
    
    return count > 0 ? sum / count : 0;
  }
  
  double _calculateAverageWindSpeed() {
    double sum = 0;
    int count = 0;
    
    for (final monthEntry in weatherData.monthlyData.entries) {
      final monthData = monthEntry.value;
      
      for (final day in monthData.dailyData) {
        for (final speed in day.hourlyWindSpeed) {
          sum += speed;
          count++;
        }
      }
    }
    
    return count > 0 ? sum / count : 0;
  }
  
  double _calculateAverageHumidity() {
    double sum = 0;
    int count = 0;
    
    for (final monthEntry in weatherData.monthlyData.entries) {
      final monthData = monthEntry.value;
      
      for (final day in monthData.dailyData) {
        for (final humidity in day.hourlyHumidity) {
          sum += humidity;
          count++;
        }
      }
    }
    
    return count > 0 ? sum / count : 0;
  }
}