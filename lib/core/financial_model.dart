// lib/core/financial_model.dart
import 'dart:math' as math;

/// Models the financial aspects of PV systems
class FinancialModel {
  /// Calculate levelized cost of energy (LCOE)
  static double calculateLCOE({
    required double initialInvestment,
    required double annualOperationAndMaintenance,
    required double annualEnergy,
    required double discountRate,
    required int projectLifetime,
  }) {
    double totalDiscountedCosts = initialInvestment;
    double totalDiscountedEnergy = 0;
    
    for (int year = 1; year <= projectLifetime; year++) {
      // Calculate discounted O&M costs
      final discountedOMCost = annualOperationAndMaintenance / math.pow(1 + discountRate, year);
      totalDiscountedCosts += discountedOMCost;
      
      // Calculate discounted energy
      final discountedEnergy = annualEnergy / math.pow(1 + discountRate, year);
      totalDiscountedEnergy += discountedEnergy;
    }
    
    // Calculate LCOE
    return totalDiscountedCosts / totalDiscountedEnergy;
  }
  
  /// Calculate net present value (NPV)
  static double calculateNPV({
    required double initialInvestment,
    required double annualEnergySavings,
    required double annualOperationAndMaintenance,
    required double discountRate,
    required int projectLifetime,
  }) {
    double npv = -initialInvestment;
    
    for (int year = 1; year <= projectLifetime; year++) {
      // Calculate net cash flow for the year
      final netCashFlow = annualEnergySavings - annualOperationAndMaintenance;
      
      // Calculate discounted cash flow
      final discountedCashFlow = netCashFlow / math.pow(1 + discountRate, year);
      
      // Add to NPV
      npv += discountedCashFlow;
    }
    
    return npv;
  }
  
  /// Calculate payback period
  static double calculatePaybackPeriod({
    required double initialInvestment,
    required double annualEnergySavings,
    required double annualOperationAndMaintenance,
  }) {
    // Calculate annual net savings
    final annualNetSavings = annualEnergySavings - annualOperationAndMaintenance;
    
    // Check if project is profitable
    if (annualNetSavings <= 0) {
      return double.infinity; // Never pays back
    }
    
    // Calculate simple payback period
    return initialInvestment / annualNetSavings;
  }
  
  /// Calculate internal rate of return (IRR)
  /// Uses a simple iterative approach
  static double calculateIRR({
    required double initialInvestment,
    required double annualEnergySavings,
    required double annualOperationAndMaintenance,
    required int projectLifetime,
  }) {
    // Start with a guess for IRR
    double irr = 0.1; // 10%
    double step = 0.01;
    int maxIterations = 100;
    double tolerance = 0.0001;
    
    for (int i = 0; i < maxIterations; i++) {
      // Calculate NPV with current IRR guess
      double npv = -initialInvestment;
      
      for (int year = 1; year <= projectLifetime; year++) {
        // Calculate net cash flow for the year
        final netCashFlow = annualEnergySavings - annualOperationAndMaintenance;
        
        // Calculate discounted cash flow
        final discountedCashFlow = netCashFlow / math.pow(1 + irr, year);
        
        // Add to NPV
        npv += discountedCashFlow;
      }
      
      // Check if NPV is close enough to zero
      if (npv.abs() < tolerance) {
        return irr;
      }
      
      // Adjust IRR based on NPV
      if (npv > 0) {
        irr += step;
      } else {
        irr -= step;
        step /= 2; // Reduce step size
      }
    }
    
    // Return best estimate after max iterations
    return irr;
  }
}