// lib/widgets/financial_roi.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FinancialROIAnalysis extends StatefulWidget {
  final double systemCost;
  final double annualSavings;
  final double electricityPrice;
  final double electricityPriceInflation;
  
  const FinancialROIAnalysis({
    super.key,
    required this.systemCost,
    required this.annualSavings,
    required this.electricityPrice,
    required this.electricityPriceInflation,
  });

  @override
  State<FinancialROIAnalysis> createState() => _FinancialROIAnalysisState();
}

class _FinancialROIAnalysisState extends State<FinancialROIAnalysis> {
  double _discountRate = 4.0; // %
  int _analysisYears = 25;
  bool _showNominalValues = false;
  
  @override
  Widget build(BuildContext context) {
    // Calculate key financial metrics
    final paybackPeriod = _calculatePaybackPeriod();
    final npv = _calculateNPV();
    final irr = _calculateIRR();
    final roi = _calculateROI();
    final lcoe = _calculateLCOE();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Analysis',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        
        // Parameters card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Parameters',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                // Discount rate slider
                _buildSliderWithLabel(
                  'Discount Rate (%)',
                  _discountRate,
                  0,
                  10,
                  (value) {
                    setState(() {
                      _discountRate = value;
                    });
                  },
                ),
                
                // Analysis period slider
                _buildSliderWithLabel(
                  'Analysis Period (years)',
                  _analysisYears.toDouble(),
                  10,
                  40,
                  (value) {
                    setState(() {
                      _analysisYears = value.round();
                    });
                  },
                ),
                
                // Nominal vs. discounted values switch
                SwitchListTile(
                  title: const Text('Show Nominal Values'),
                  subtitle: const Text('Display actual cash flows without discounting'),
                  value: _showNominalValues,
                  onChanged: (value) {
                    setState(() {
                      _showNominalValues = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Financial metrics card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Metrics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                _buildMetricRow('Payback Period', '${paybackPeriod.toStringAsFixed(1)} years'),
                _buildMetricRow('Net Present Value (NPV)', '\$${npv.toStringAsFixed(0)}'),
                _buildMetricRow('Internal Rate of Return (IRR)', '${(irr * 100).toStringAsFixed(1)}%'),
                _buildMetricRow('Return on Investment (ROI)', '${(roi * 100).toStringAsFixed(1)}%'),
                _buildMetricRow('Levelized Cost of Energy (LCOE)', '\$${lcoe.toStringAsFixed(3)}/kWh'),
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
                  'Cash Flow Analysis',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                AspectRatio(
                  aspectRatio: 1.6,
                  child: CashFlowChart(
                    systemCost: widget.systemCost,
                    annualSavings: widget.annualSavings,
                    discountRate: _discountRate / 100,
                    analysisYears: _analysisYears,
                    showNominalValues: _showNominalValues,
                    electricityPriceInflation: widget.electricityPriceInflation,
                  ),
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
            Text(value.toStringAsFixed(1)),
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
  
  double _calculatePaybackPeriod() {
    return widget.systemCost / widget.annualSavings;
  }
  
  double _calculateNPV() {
    double npv = -widget.systemCost;
    
    for (int year = 1; year <= _analysisYears; year++) {
      final annualSavings = widget.annualSavings * 
          math.pow(1 + widget.electricityPriceInflation, year - 1);
      npv += annualSavings / math.pow(1 + _discountRate / 100, year);
    }
    
    return npv;
  }
  
  double _calculateIRR() {
    // Simple IRR calculation - in a real app, use a more robust algorithm
    double irr = 0.05; // Initial guess
    int maxIterations = 100;
    double tolerance = 0.0001;
    
    for (int i = 0; i < maxIterations; i++) {
      double npv = -widget.systemCost;
      
      for (int year = 1; year <= _analysisYears; year++) {
        final annualSavings = widget.annualSavings * 
            math.pow(1 + widget.electricityPriceInflation, year - 1);
        npv += annualSavings / math.pow(1 + irr, year);
      }
      
      if (npv.abs() < tolerance) {
        return irr;
      }
      
      if (npv > 0) {
        irr += 0.001;
      } else {
        irr -= 0.001;
      }
    }
    
    return irr;
  }
  
  double _calculateROI() {
    // Simple ROI (nominal)
    return (_analysisYears * widget.annualSavings - widget.systemCost) / widget.systemCost;
  }
  
  double _calculateLCOE() {
    // Simplified LCOE calculation
    const annualProduction = 62450; // kWh
    double totalDiscountedCosts = widget.systemCost;
    double totalDiscountedEnergy = 0;
    
    for (int year = 1; year <= _analysisYears; year++) {
      // Assume operating costs of 1% of system cost per year
      final operatingCost = widget.systemCost * 0.01;
      totalDiscountedCosts += operatingCost / math.pow(1 + _discountRate / 100, year);
      
      // Annual energy production with 0.5% degradation per year
      final yearlyProduction = annualProduction * math.pow(0.995, year - 1);
      totalDiscountedEnergy += yearlyProduction / math.pow(1 + _discountRate / 100, year);
    }
    
    return totalDiscountedCosts / totalDiscountedEnergy;
  }
}

class CashFlowChart extends StatelessWidget {
  final double systemCost;
  final double annualSavings;
  final double discountRate;
  final int analysisYears;
  final bool showNominalValues;
  final double electricityPriceInflation;
  
  const CashFlowChart({
    super.key,
    required this.systemCost,
    required this.annualSavings,
    required this.discountRate,
    required this.analysisYears,
    required this.showNominalValues,
    required this.electricityPriceInflation,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: 10000,
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
        maxX: analysisYears.toDouble(),
        minY: -systemCost * 1.1,
        maxY: _calculateCumulativeCashFlow(analysisYears) * 1.1,
        lineBarsData: [
          showNominalValues 
              ? _getNominalCashFlowLine()
              : _getDiscountedCashFlowLine(),
        ],
      ),
    );
  }
  
  LineChartBarData _getNominalCashFlowLine() {
    final spots = <FlSpot>[];
    
    // Initial investment at year 0
    spots.add(FlSpot(0, -systemCost));
    
    // Calculate cumulative cash flow for each year
    for (int year = 1; year <= analysisYears; year++) {
      final cumulativeCashFlow = _calculateNominalCumulativeCashFlow(year);
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
    spots.add(FlSpot(0, -systemCost));
    
    // Calculate discounted cash flow for each year
    for (int year = 1; year <= analysisYears; year++) {
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
    return showNominalValues
        ? _calculateNominalCumulativeCashFlow(year)
        : _calculateDiscountedCumulativeCashFlow(year);
  }
  
  double _calculateNominalCumulativeCashFlow(int year) {
    double cumulativeCashFlow = -systemCost;
    
    for (int i = 1; i <= year; i++) {
      final yearlyRevenue = annualSavings * 
          math.pow(1 + electricityPriceInflation, i - 1);
      cumulativeCashFlow += yearlyRevenue;
    }
    
    return cumulativeCashFlow;
  }
  
  double _calculateDiscountedCumulativeCashFlow(int year) {
    double cumulativeNPV = -systemCost;
    
    for (int i = 1; i <= year; i++) {
      final yearlyRevenue = annualSavings * 
          math.pow(1 + electricityPriceInflation, i - 1);
      final discountFactor = 1 / math.pow(1 + discountRate, i);
      cumulativeNPV += yearlyRevenue * discountFactor;
    }
    
    return cumulativeNPV;
  }
  
  String _formatCurrency(double value) {
    if (value >= 10000) {
      return '\$${(value / 1000).toStringAsFixed(0)}k';
    } else if (value <= -10000) {
      return '-\$${(value.abs() / 1000).toStringAsFixed(0)}k';
    } else {
      return '\$${value.toStringAsFixed(0)}';
    }
  }
}