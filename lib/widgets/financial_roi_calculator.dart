// lib/widgets/financial_roi_calculator.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class FinancialROICalculator extends StatefulWidget {
  final double systemCost;
  final double annualProduction;
  final int systemSizeWatts;
  final double electricityRate;
  final bool hasBattery;
  final double batteryCapacity;
  final double batterySystemCost;
  
  const FinancialROICalculator({
    super.key,
    required this.systemCost,
    required this.annualProduction,
    required this.systemSizeWatts,
    required this.electricityRate,
    this.hasBattery = false,
    this.batteryCapacity = 0,
    this.batterySystemCost = 0,
  });

  @override
  State<FinancialROICalculator> createState() => _FinancialROICalculatorState();
}

class _FinancialROICalculatorState extends State<FinancialROICalculator> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Financial parameters - default values
  double _discountRate = 4.0; // %
  double _electricityPriceInflation = 3.0; // %
  double _selfConsumptionRate = 30.0; // %
  double _feedInTariff = 0.05; // $/kWh
  double _maintenanceCost = 0.5; // % of system cost per year
  int _analysisYears = 25;
  bool _includeDepreciation = false;
  bool _includeIncentives = true;
  double _federalTaxCredit = 30.0; // %
  double _stateTaxCredit = 0.0; // %
  double _upfrontRebate = 0.0; // $
  double _srecs = 0.0; // $/MWh
  
  // Loan financing parameters
  bool _useFinancing = false;
  double _loanAmount = 0.0; // $
  double _loanInterestRate = 5.0; // %
  int _loanTerm = 10; // years
  
  // Calculated results
  Map<String, dynamic> _results = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loanAmount = widget.systemCost;
    _calculateResults();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _calculateResults() {
    // Calculate the total system cost after incentives
    final federalTaxCreditAmount = widget.systemCost * (_federalTaxCredit / 100);
    final stateTaxCreditAmount = widget.systemCost * (_stateTaxCredit / 100);
    final netSystemCost = widget.systemCost - federalTaxCreditAmount - 
                         stateTaxCreditAmount - _upfrontRebate;
    
    // Annual savings calculation
    final selfConsumedEnergy = widget.annualProduction * (_selfConsumptionRate / 100);
    final exportedEnergy = widget.annualProduction - selfConsumedEnergy;
    
    final electricitySavings = selfConsumedEnergy * widget.electricityRate;
    final feedInRevenue = exportedEnergy * _feedInTariff;
    final srecRevenue = widget.annualProduction / 1000 * _srecs; // MWh
    
    final annualRevenue = electricitySavings + feedInRevenue + srecRevenue;
    final annualMaintenance = widget.systemCost * (_maintenanceCost / 100);
    
    // Loan payment calculation
    double annualLoanPayment = 0;
    if (_useFinancing) {
      final monthlyInterestRate = _loanInterestRate / 100 / 12;
      final numberOfPayments = _loanTerm * 12;
      final monthlyPayment = _loanAmount * monthlyInterestRate * 
                            math.pow(1 + monthlyInterestRate, numberOfPayments) / 
                            (math.pow(1 + monthlyInterestRate, numberOfPayments) - 1);
      annualLoanPayment = monthlyPayment * 12;
    }
    
    // Cash flow analysis
    final yearlyNetCashFlow = <int, double>{};
    final yearlyCumulativeCashFlow = <int, double>{};
    final yearlyDiscountedCashFlow = <int, double>{};
    final yearlyDiscountedCumulativeCashFlow = <int, double>{};
    
    double netCashFlowSum = -netSystemCost; // Initial investment
    double discountedCashFlowSum = -netSystemCost; // Initial investment
    
    for (int year = 1; year <= _analysisYears; year++) {
      // Annual revenue with electricity price inflation
      final yearlyRevenue = annualRevenue * math.pow(1 + _electricityPriceInflation / 100, year - 1);
      
      // Annual costs
      double yearlyCosts = annualMaintenance;
      if (_useFinancing && year <= _loanTerm) {
        yearlyCosts += annualLoanPayment;
      }
      
      // Annual depreciation benefit (simplified)
      double depreciationBenefit = 0;
      if (_includeDepreciation && year <= 5) {
        // MACRS 5-year depreciation schedule (simplified)
        const depreciationRates = [0.2, 0.32, 0.192, 0.1152, 0.1152, 0.0576];
        final depreciationAmount = widget.systemCost * depreciationRates[year - 1];
        depreciationBenefit = depreciationAmount * 0.21; // Assuming 21% corporate tax rate
      }
      
      // Net cash flow for the year
      final netCashFlow = yearlyRevenue - yearlyCosts + depreciationBenefit;
      yearlyNetCashFlow[year] = netCashFlow;
      
      // Cumulative cash flow
      netCashFlowSum += netCashFlow;
      yearlyCumulativeCashFlow[year] = netCashFlowSum;
      
      // Discounted cash flow
      final discountedCashFlow = netCashFlow / math.pow(1 + _discountRate / 100, year);
      yearlyDiscountedCashFlow[year] = discountedCashFlow;
      
      // Cumulative discounted cash flow
      discountedCashFlowSum += discountedCashFlow;
      yearlyDiscountedCumulativeCashFlow[year] = discountedCashFlowSum;
    }
    
    // Calculate financial metrics
    
    // Simple payback period
    double paybackPeriod = 0;
    if (annualRevenue > annualMaintenance) {
      paybackPeriod = netSystemCost / (annualRevenue - annualMaintenance);
    } else {
      paybackPeriod = double.infinity;
    }
    
    // Discounted payback period using linear interpolation
    double discountedPaybackPeriod = double.infinity;
    for (int year = 1; year < _analysisYears; year++) {
      if ((yearlyDiscountedCumulativeCashFlow[year] ?? 0) < 0 && 
          (yearlyDiscountedCumulativeCashFlow[year + 1] ?? 0) > 0) {
        final y1 = yearlyDiscountedCumulativeCashFlow[year] ?? 0;
        final y2 = yearlyDiscountedCumulativeCashFlow[year + 1] ?? 0;
        discountedPaybackPeriod = year + (-y1) / (y2 - y1);
        break;
      }
    }
    
    // Net present value (NPV)
    final npv = discountedCashFlowSum;
    
    // Calculate internal rate of return (IRR) using trial and error
    double irr = 0;
    for (double testRate = -0.5; testRate <= 1.0; testRate += 0.001) {
      double testNPV = -netSystemCost;
      for (int year = 1; year <= _analysisYears; year++) {
        final cashFlow = yearlyNetCashFlow[year] ?? 0;
        testNPV += cashFlow / math.pow(1 + testRate, year);
      }
      
      if (testNPV.abs() < 1.0) {
        irr = testRate;
        break;
      }
    }
    
    // Return on investment (ROI)
    final roi = discountedCashFlowSum / netSystemCost;
    
    // Levelized cost of energy (LCOE)
    double totalDiscountedEnergy = 0;
    double totalDiscountedCosts = netSystemCost;
    
    for (int year = 1; year <= _analysisYears; year++) {
      // Discounted energy production (assuming 0.5% annual degradation)
      final yearlyProduction = widget.annualProduction * math.pow(0.995, year - 1);
      final discountedProduction = yearlyProduction / math.pow(1 + _discountRate / 100, year);
      totalDiscountedEnergy += discountedProduction;
      
      // Discounted costs
      final discountedMaintenance = annualMaintenance / math.pow(1 + _discountRate / 100, year);
      totalDiscountedCosts += discountedMaintenance;
    }
    
    double lcoe = 0;
    if (totalDiscountedEnergy > 0) {
      lcoe = totalDiscountedCosts / totalDiscountedEnergy;
    }
    
    // Store results
    setState(() {
      _results = {
        'netSystemCost': netSystemCost,
        'annualRevenue': annualRevenue,
        'annualMaintenance': annualMaintenance,
        'paybackPeriod': paybackPeriod,
        'discountedPaybackPeriod': discountedPaybackPeriod,
        'npv': npv,
        'irr': irr,
        'roi': roi,
        'lcoe': lcoe,
        'yearlyNetCashFlow': yearlyNetCashFlow,
        'yearlyCumulativeCashFlow': yearlyCumulativeCashFlow,
        'yearlyDiscountedCashFlow': yearlyDiscountedCashFlow,
        'yearlyDiscountedCumulativeCashFlow': yearlyDiscountedCumulativeCashFlow,
        'electricitySavings': electricitySavings,
        'feedInRevenue': feedInRevenue,
        'srecRevenue': srecRevenue,
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
            Tab(text: 'Results'),
            Tab(text: 'Parameters'),
            Tab(text: 'Cash Flow'),
          ],
        ),
        
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildResultsTab(),
              _buildParametersTab(),
              _buildCashFlowTab(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildResultsTab() {
    if (_results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial metrics summary card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Return Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Cost and savings
                  _buildInfoRow(
                    'Total System Cost',
                    currencyFormat.format(widget.systemCost),
                  ),
                  if (_includeIncentives)
                    _buildInfoRow(
                      'Net Cost After Incentives',
                      currencyFormat.format(_results['netSystemCost']),
                    ),
                  _buildInfoRow(
                    'Annual Revenue',
                    currencyFormat.format(_results['annualRevenue']),
                  ),
                  
                  const Divider(),
                  
                  // Key financial metrics
                  _buildInfoRow(
                    'Net Present Value (NPV)',
                    currencyFormat.format(_results['npv']),
                    _results['npv'] >= 0 ? Colors.green : Colors.red,
                  ),
                  _buildInfoRow(
                    'Return on Investment (ROI)',
                    '${(_results['roi'] * 100).toStringAsFixed(1)}%',
                    _results['roi'] >= 0 ? Colors.green : Colors.red,
                  ),
                  _buildInfoRow(
                    'Internal Rate of Return (IRR)',
                    '${(_results['irr'] * 100).toStringAsFixed(1)}%',
                    _results['irr'] >= 0 ? Colors.green : Colors.red,
                  ),
                  _buildInfoRow(
                    'Simple Payback Period',
                    '${_results['paybackPeriod'].toStringAsFixed(1)} years',
                  ),
                  _buildInfoRow(
                    'Discounted Payback Period',
                    _results['discountedPaybackPeriod'] != double.infinity
                        ? '${_results['discountedPaybackPeriod'].toStringAsFixed(1)} years'
                        : 'N/A',
                  ),
                  _buildInfoRow(
                    'Levelized Cost of Energy (LCOE)',
                    '\$${(_results['lcoe']).toStringAsFixed(3)}/kWh',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Cost breakdown chart
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Cost Breakdown',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: _buildCostBreakdownChart(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Annual revenue breakdown chart
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Annual Revenue Breakdown',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: _buildRevenueBreakdownChart(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 25-year savings chart
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cumulative Savings Over 25 Years',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: _buildCumulativeSavingsChart(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildInfoRow(
                    'Total Savings (25 years)',
                    currencyFormat.format(_results['yearlyCumulativeCashFlow'][_analysisYears]),
                  ),
                  _buildInfoRow(
                    'Discounted Savings (25 years)',
                    currencyFormat.format(_results['yearlyDiscountedCumulativeCashFlow'][_analysisYears]),
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
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow(
                    'System Size',
                    '${(widget.systemSizeWatts / 1000).toStringAsFixed(1)} kWp',
                  ),
                  _buildInfoRow(
                    'System Cost',
                    '\$${widget.systemCost.toStringAsFixed(0)}',
                  ),
                  _buildInfoRow(
                    'Cost per Watt',
                    '\$${(widget.systemCost / widget.systemSizeWatts).toStringAsFixed(2)}/W',
                  ),
                  _buildInfoRow(
                    'Annual Production',
                    '${widget.annualProduction.toStringAsFixed(0)} kWh',
                  ),
                  _buildInfoRow(
                    'Specific Yield',
                    '${(widget.annualProduction / (widget.systemSizeWatts / 1000)).toStringAsFixed(0)} kWh/kWp',
                  ),
                  
                  if (widget.hasBattery) ...[
                    const Divider(),
                    
                    _buildInfoRow(
                      'Battery Capacity',
                      '${widget.batteryCapacity.toStringAsFixed(1)} kWh',
                    ),
                    _buildInfoRow(
                      'Battery System Cost',
                      '\$${widget.batterySystemCost.toStringAsFixed(0)}',
                    ),
                    _buildInfoRow(
                      'Battery Cost per kWh',
                      '\$${(widget.batterySystemCost / widget.batteryCapacity).toStringAsFixed(0)}/kWh',
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Financial parameters
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Parameters',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSliderWithField(
                    'Electricity Rate (\$/kWh)',
                    widget.electricityRate,
                    0.05,
                    0.5,
                    (value) {
                      // Can't change this parameter as it's provided by parent
                    },
                    enabled: false,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSliderWithField(
                    'Self-Consumption Rate (%)',
                    _selfConsumptionRate,
                    0,
                    100,
                    (value) {
                      setState(() {
                        _selfConsumptionRate = value;
                        _calculateResults();
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSliderWithField(
                    'Feed-in Tariff (\$/kWh)',
                    _feedInTariff,
                    0,
                    0.2,
                    (value) {
                      setState(() {
                        _feedInTariff = value;
                        _calculateResults();
                      });
                    },
                    divisions: 20,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSliderWithField(
                    'Electricity Price Inflation (%)',
                    _electricityPriceInflation,
                    0,
                    10,
                    (value) {
                      setState(() {
                        _electricityPriceInflation = value;
                        _calculateResults();
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSliderWithField(
                    'Maintenance Cost (% of system cost)',
                    _maintenanceCost,
                    0,
                    3,
                    (value) {
                      setState(() {
                        _maintenanceCost = value;
                        _calculateResults();
                      });
                    },
                    divisions: 30,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSliderWithField(
                    'Discount Rate (%)',
                    _discountRate,
                    0,
                    15,
                    (value) {
                      setState(() {
                        _discountRate = value;
                        _calculateResults();
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSliderWithField(
                    'Analysis Period (years)',
                    _analysisYears.toDouble(),
                    5,
                    40,
                    (value) {
                      setState(() {
                        _analysisYears = value.round();
                        _calculateResults();
                      });
                    },
                    divisions: 35,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Incentives
          Card(
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
                        'Incentives',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Switch(
                        value: _includeIncentives,
                        onChanged: (value) {
                          setState(() {
                            _includeIncentives = value;
                            _calculateResults();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_includeIncentives) ...[
                    _buildSliderWithField(
                      'Federal Tax Credit (%)',
                      _federalTaxCredit,
                      0,
                      50,
                      (value) {
                        setState(() {
                          _federalTaxCredit = value;
                          _calculateResults();
                        });
                      },
                      divisions: 50,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildSliderWithField(
                      'State Tax Credit (%)',
                      _stateTaxCredit,
                      0,
                      50,
                      (value) {
                        setState(() {
                          _stateTaxCredit = value;
                          _calculateResults();
                        });
                      },
                      divisions: 50,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildSliderWithField(
                      'Upfront Rebate (\$)',
                      _upfrontRebate,
                      0,
                      10000,
                      (value) {
                        setState(() {
                          _upfrontRebate = value;
                          _calculateResults();
                        });
                      },
                      numberFormat: '0',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildSliderWithField(
                      'SREC Value (\$/MWh)',
                      _srecs,
                      0,
                      500,
                      (value) {
                        setState(() {
                          _srecs = value;
                          _calculateResults();
                        });
                      },
                      numberFormat: '0',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Checkbox(
                          value: _includeDepreciation,
                          onChanged: (value) {
                            setState(() {
                              _includeDepreciation = value ?? false;
                              _calculateResults();
                            });
                          },
                        ),
                        const Text('Include Depreciation Benefits (Commercial only)'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Financing options
          Card(
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
                        'Financing',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Switch(
                        value: _useFinancing,
                        onChanged: (value) {
                          setState(() {
                            _useFinancing = value;
                            _calculateResults();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_useFinancing) ...[
                    _buildSliderWithField(
                      'Loan Amount (\$)',
                      _loanAmount,
                      0,
                      widget.systemCost,
                      (value) {
                        setState(() {
                          _loanAmount = value;
                          _calculateResults();
                        });
                      },
                      numberFormat: '0',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildSliderWithField(
                      'Loan Interest Rate (%)',
                      _loanInterestRate,
                      0,
                      15,
                      (value) {
                        setState(() {
                          _loanInterestRate = value;
                          _calculateResults();
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildSliderWithField(
                      'Loan Term (years)',
                      _loanTerm.toDouble(),
                      5,
                      30,
                      (value) {
                        setState(() {
                          _loanTerm = value.round();
                          _calculateResults();
                        });
                      },
                      divisions: 25,
                      numberFormat: '0',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildInfoRow(
                      'Monthly Payment',
                      '\$${_calculateMonthlyLoanPayment().toStringAsFixed(2)}',
                    ),
                    
                    _buildInfoRow(
                      'Total Loan Payments',
                      '\$${(_calculateMonthlyLoanPayment() * _loanTerm * 12).toStringAsFixed(2)}',
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
  
  Widget _buildCashFlowTab() {
    if (_results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cash Flow Analysis',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: _buildCashFlowChart(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yearly Cash Flow Table',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildCashFlowTable(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCostBreakdownChart() {
    // Calculate cost components
    final moduleCost = widget.systemCost * 0.5; // Modules typically 50% of cost
    final inverterCost = widget.systemCost * 0.15; // Inverters typically 15% of cost
    final installationCost = widget.systemCost * 0.25; // Installation typically 25% of cost
    final balanceOfSystemCost = widget.systemCost * 0.1; // Balance of system typically 10% of cost
    final batteryCost = widget.hasBattery ? widget.batterySystemCost : 0;
    
    double totalCost = widget.systemCost;
    if (widget.hasBattery) {
      totalCost += widget.batterySystemCost;
    }
    
    // Define data for chart
    final pieData = [
      PieChartSectionData(
        value: moduleCost / totalCost * 100,
        title: 'Modules',
        color: Colors.blue,
        radius: 100,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        value: inverterCost / totalCost * 100,
        title: 'Inverter',
        color: Colors.green,
        radius: 100,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        value: installationCost / totalCost * 100,
        title: 'Install',
        color: Colors.orange,
        radius: 100,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        value: balanceOfSystemCost / totalCost * 100,
        title: 'BOS',
        color: Colors.purple,
        radius: 100,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      if (widget.hasBattery)
        PieChartSectionData(
          value: batteryCost / totalCost * 100,
          title: 'Battery',
          color: Colors.red,
          radius: 100,
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
    ];
    
    return PieChart(
      PieChartData(
        sections: pieData,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }
  
  Widget _buildRevenueBreakdownChart() {
    // Get revenue components
    final electricitySavings = _results['electricitySavings'] ?? 0.0;
    final feedInRevenue = _results['feedInRevenue'] ?? 0.0;
    final srecRevenue = _results['srecRevenue'] ?? 0.0;
    
    final totalRevenue = electricitySavings + feedInRevenue + srecRevenue;
    
    // Define data for chart
    final pieData = [
      PieChartSectionData(
        value: electricitySavings / totalRevenue * 100,
        title: 'Savings',
        color: Colors.green,
        radius: 100,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      if (feedInRevenue > 0)
        PieChartSectionData(
          value: feedInRevenue / totalRevenue * 100,
          title: 'Export',
          color: Colors.blue,
          radius: 100,
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      if (srecRevenue > 0)
        PieChartSectionData(
          value: srecRevenue / totalRevenue * 100,
          title: 'SRECs',
          color: Colors.orange,
          radius: 100,
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
    ];
    
    return PieChart(
      PieChartData(
        sections: pieData,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }
  
  Widget _buildCumulativeSavingsChart() {
    final yearlyCumulativeCashFlow = _results['yearlyCumulativeCashFlow'] as Map<int, double>;
    final yearlyDiscountedCumulativeCashFlow = _results['yearlyDiscountedCumulativeCashFlow'] as Map<int, double>;
    
    // Determine the maximum y value for the chart
    double maxY = 0;
    for (final value in yearlyCumulativeCashFlow.values) {
      if (value > maxY) maxY = value;
    }
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10000,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value % 5 == 0 || value == 1 || value == _analysisYears) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      value.toInt().toString(),
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
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    NumberFormat.compactCurrency(symbol: '\$').format(value),
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
        maxX: _analysisYears.toDouble(),
        minY: -widget.systemCost,
        maxY: maxY * 1.1,
        lineBarsData: [
          // Nominal cash flow
          LineChartBarData(
            spots: [
              FlSpot(0, -_results['netSystemCost']),
              ...List.generate(_analysisYears, (index) {
                final year = index + 1;
                return FlSpot(year.toDouble(), yearlyCumulativeCashFlow[year] ?? 0);
              }),
            ],
            isCurved: false,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color.fromRGBO(76, 175, 80, 0.2), // const RGBA for Colors.green with 0.2 opacity
              cutOffY: 0,
              applyCutOffY: true,
            ),
          ),
          // Discounted cash flow
          LineChartBarData(
            spots: [
              FlSpot(0, -_results['netSystemCost']),
              ...List.generate(_analysisYears, (index) {
                final year = index + 1;
                return FlSpot(year.toDouble(), yearlyDiscountedCumulativeCashFlow[year] ?? 0);
              }),
            ],
            isCurved: false,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
            belowBarData: BarAreaData(
              show: true,
              color: const Color.fromRGBO(0, 0, 255, 0.1), // RGBA format
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
  
  Widget _buildCashFlowChart() {
    final yearlyNetCashFlow = _results['yearlyNetCashFlow'] as Map<int, double>;
    
    // Determine the maximum y value for the chart
    double maxY = 0;
    double minY = 0;
    for (final value in yearlyNetCashFlow.values) {
      if (value > maxY) maxY = value;
      if (value < minY) minY = value;
    }
    
    // For the initial investment
    if (-_results['netSystemCost'] < minY) {
      minY = -_results['netSystemCost'];
    }
    
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
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final year = value.toInt();
                if (year % 5 == 0 || year == 1 || year == _analysisYears) {
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
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    NumberFormat.compactCurrency(symbol: '\$').format(value),
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
        maxX: _analysisYears.toDouble(),
        minY: minY * 1.1,
        maxY: maxY * 1.1,
        lineBarsData: [
          // Net cash flow bar chart (represented as line chart with dots)
          LineChartBarData(
            spots: [
              FlSpot(0, -_results['netSystemCost']), // Initial investment
              ...List.generate(_analysisYears, (index) {
                final year = index + 1;
                return FlSpot(year.toDouble(), yearlyNetCashFlow[year] ?? 0);
              }),
            ],
            isCurved: false,
            color: Colors.amber,
            barWidth: 8,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
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
  
  Widget _buildCashFlowTable() {
    final yearlyNetCashFlow = _results['yearlyNetCashFlow'] as Map<int, double>;
    final yearlyCumulativeCashFlow = _results['yearlyCumulativeCashFlow'] as Map<int, double>;
    final yearlyDiscountedCashFlow = _results['yearlyDiscountedCashFlow'] as Map<int, double>;
    final yearlyDiscountedCumulativeCashFlow = _results['yearlyDiscountedCumulativeCashFlow'] as Map<int, double>;
    
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    return DataTable(
      columnSpacing: 16,
      columns: const [
        DataColumn(label: Text('Year')),
        DataColumn(label: Text('Net Cash Flow'), numeric: true),
        DataColumn(label: Text('Cumulative'), numeric: true),
        DataColumn(label: Text('Discounted\nCash Flow'), numeric: true),
        DataColumn(label: Text('Discounted\nCumulative'), numeric: true),
      ],
      rows: [
        // Year 0 (initial investment)
        DataRow(
          cells: [
            const DataCell(Text('0')),
            DataCell(Text(currencyFormat.format(-_results['netSystemCost']))),
            DataCell(Text(currencyFormat.format(-_results['netSystemCost']))),
            DataCell(Text(currencyFormat.format(-_results['netSystemCost']))),
            DataCell(Text(currencyFormat.format(-_results['netSystemCost']))),
          ],
        ),
        // Years 1 to analysisYears
        ...List.generate(_analysisYears, (index) {
          final year = index + 1;
          return DataRow(
            cells: [
              DataCell(Text(year.toString())),
              DataCell(Text(currencyFormat.format(yearlyNetCashFlow[year] ?? 0))),
              DataCell(Text(currencyFormat.format(yearlyCumulativeCashFlow[year] ?? 0))),
              DataCell(Text(currencyFormat.format(yearlyDiscountedCashFlow[year] ?? 0))),
              DataCell(Text(currencyFormat.format(yearlyDiscountedCumulativeCashFlow[year] ?? 0))),
            ],
          );
        }),
      ],
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
    bool enabled = true,
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
                onChanged: enabled ? onChanged : null,
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
                onChanged: enabled ? (text) {
                  final newValue = double.tryParse(text);
                  if (newValue != null && newValue >= min && newValue <= max) {
                    onChanged(newValue);
                  }
                } : null,
                enabled: enabled,
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
  
  double _calculateMonthlyLoanPayment() {
    if (!_useFinancing || _loanAmount <= 0 || _loanTerm <= 0) {
      return 0;
    }
    
    final monthlyInterestRate = _loanInterestRate / 100 / 12;
    final numberOfPayments = _loanTerm * 12;
    final monthlyPayment = _loanAmount * monthlyInterestRate * 
                           math.pow(1 + monthlyInterestRate, numberOfPayments) / 
                           (math.pow(1 + monthlyInterestRate, numberOfPayments) - 1);
    
    return monthlyPayment;
  }
}