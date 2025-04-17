// lib/widgets/financial_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CashFlowChart extends StatelessWidget {
  final double initialInvestment;
  final double annualRevenue;
  final int projectLifetime;
  final double discountRate;
  
  const CashFlowChart({
    super.key,
    required this.initialInvestment,
    required this.annualRevenue,
    required this.projectLifetime,
    required this.discountRate,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              horizontalInterval: initialInvestment / 5,
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    if (value % 5 != 0 && value != 0) {
                      return const Text('');
                    }
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8,
                      child: Text(
                        value.toInt().toString(),
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
                    // Format money values
                    final formattedValue = _formatCurrency(value);
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8,
                      child: Text(
                        formattedValue,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: true),
            minX: 0,
            maxX: projectLifetime.toDouble(),
            minY: -initialInvestment * 1.1,
            maxY: _calculateCumulativeCashFlow(projectLifetime) * 1.1,
            lineBarsData: [
              _getCumulativeCashFlowLine(),
              _getDiscountedCashFlowLine(),
            ],
          ),
        ),
      ),
    );
  }
  
  LineChartBarData _getCumulativeCashFlowLine() {
    final spots = <FlSpot>[];
    
    // Initial investment at year 0
    spots.add(FlSpot(0, -initialInvestment));
    
    // Calculate cumulative cash flow for each year
    for (int year = 1; year <= projectLifetime; year++) {
      final cumulativeCashFlow = _calculateCumulativeCashFlow(year);
      spots.add(FlSpot(year.toDouble(), cumulativeCashFlow));
    }
    
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: Colors.blue,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: Colors.blue.withOpacity(0.2),
      ),
    );
  }
  
  LineChartBarData _getDiscountedCashFlowLine() {
    final spots = <FlSpot>[];
    
    // Initial investment at year 0
    spots.add(FlSpot(0, -initialInvestment));
    
    // Calculate discounted cash flow for each year
    for (int year = 1; year <= projectLifetime; year++) {
      final discountedCashFlow = _calculateDiscountedCumulativeCashFlow(year);
      spots.add(FlSpot(year.toDouble(), discountedCashFlow));
    }
    
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: Colors.green,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: Colors.green.withOpacity(0.1),
      ),
    );
  }
  
  double _calculateCumulativeCashFlow(int year) {
    return -initialInvestment + (annualRevenue * year);
  }
  
  double _calculateDiscountedCumulativeCashFlow(int year) {
    double cumulativeNPV = -initialInvestment;
    
    for (int i = 1; i <= year; i++) {
      final discountFactor = 1 / Math.pow(1 + discountRate, i);
      cumulativeNPV += annualRevenue * discountFactor;
    }
    
    return cumulativeNPV;
  }
  
  String _formatCurrency(double value) {
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(0)}k';
    } else if (value <= -1000) {
      return '-\$${(value.abs() / 1000).toStringAsFixed(0)}k';
    } else {
      return '\$${value.toStringAsFixed(0)}';
    }
  }
}