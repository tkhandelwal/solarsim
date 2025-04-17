// lib/screens/enhanced_simulation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solarsim/models/project.dart';
import 'package:solarsim/models/solar_module.dart';
import 'package:solarsim/models/inverter.dart';
import 'package:solarsim/providers/projects_provider.dart';
import 'package:solarsim/widgets/system_design_wizard.dart';
import 'package:solarsim/widgets/advanced_pv_forecast.dart';
import 'package:solarsim/widgets/financial_roi_calculator.dart';
import 'package:solarsim/widgets/battery_storage_simulation.dart';
import 'package:solarsim/widgets/shading_analysis.dart';
import 'package:solarsim/widgets/layout_optimizer.dart';

class EnhancedSimulationScreen extends ConsumerStatefulWidget {
  final String projectId;
  
  const EnhancedSimulationScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<EnhancedSimulationScreen> createState() => _EnhancedSimulationScreenState();
}

class _EnhancedSimulationScreenState extends ConsumerState<EnhancedSimulationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // System configuration state
  SolarModule? _selectedModule;
  Inverter? _selectedInverter;
  int _modulesInSeries = 0;
  int _stringsInParallel = 0;
  final double _tiltAngle = 20.0;
  final double _azimuthAngle = 180.0;
  final bool _hasBattery = false;
  final double _batteryCapacity = 10.0;
  final double _batteryCost = 5000.0;
  
  // Financial parameters
  double _systemCost = 0.0;
  double _annualProduction = 0.0;
  
  // System losses
  final Map<String, double> _losses = {
    'soiling': 0.02,
    'shading': 0.03,
    'mismatch': 0.02,
    'wiring': 0.02,
    'availability': 0.02,
    'temperature': 0.05,
  };
  
  // Design state
  bool _isDesignComplete = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Load sample data (in a real app, this would be from a database)
    _initializeSampleData();
  }
  
  void _initializeSampleData() {
    // Initialize with sample module and inverter
    _selectedModule = SolarModule(
      id: 'module1',
      manufacturer: 'SunPower',
      model: 'SPR-X22-360',
      powerRating: 360,
      efficiency: 0.22,
      length: 1.7,
      width: 1.0,
      technology: ModuleTechnology.monocrystalline,
      temperatureCoefficient: -0.32,
      nominalOperatingCellTemp: 45,
    );
    
    _selectedInverter = Inverter(
      id: 'inverter1',
      manufacturer: 'SMA',
      model: 'Sunny Tripower 15000TL',
      ratedPowerAC: 15000,
      maxDCPower: 18000,
      efficiency: 0.98,
      minMPPVoltage: 360,
      maxMPPVoltage: 800,
      numberOfMPPTrackers: 2,
      type: InverterType.string,
    );
    
    // Set initial array configuration
    _modulesInSeries = 10;
    _stringsInParallel = 4;
    
    // Calculate system cost and annual production
    _calculateSystemMetrics();
  }
  
  void _calculateSystemMetrics() {
    if (_selectedModule == null || _selectedInverter == null) return;
    
    // Calculate system size in Watts
    final systemSizeWatts = _selectedModule!.powerRating * _modulesInSeries * _stringsInParallel;
    
    // Calculate system cost (simplified)
    final moduleCost = systemSizeWatts * 0.5; // $0.50/W for modules
    final inverterCost = _selectedInverter!.ratedPowerAC * 0.2; // $0.20/W for inverter
    final bosCost = systemSizeWatts * 0.3; // $0.30/W for balance of system
    final installationCost = systemSizeWatts * 0.5; // $0.50/W for installation
    
    _systemCost = moduleCost + inverterCost + bosCost + installationCost;
    
    // Calculate annual production (simplified)
    // Assume 1500 kWh/kWp annual yield for a typical location
    _annualProduction = systemSizeWatts / 1000 * 1500;
    
    setState(() {
      _isDesignComplete = true;
    });
  }
  
  void _updateSystemConfiguration(Project project) {
    // Update with design from the wizard
    _calculateSystemMetrics();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar System Simulation'),
      ),
      body: ref.watch(projectProvider(widget.projectId)).when(
        data: (project) => _buildSimulationContent(context, project),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
  
  Widget _buildSimulationContent(BuildContext context, Project project) {
    if (!_isDesignComplete) {
      return SystemDesignWizard(
        project: project,
        onComplete: _updateSystemConfiguration,
      );
    }
    
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Production'),
            Tab(text: 'Financial Analysis'),
            Tab(text: 'Battery Storage'),
            Tab(text: 'Shading Analysis'),
            Tab(text: 'Layout Optimizer'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProductionTab(project),
              _buildFinancialTab(),
              _buildBatteryTab(),
              _buildShadingTab(project),
              _buildLayoutTab(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildProductionTab(Project project) {
    if (_selectedModule == null || _selectedInverter == null) {
      return const Center(child: Text('Module or inverter not selected.'));
    }
    
    return AdvancedPVForecast(
      project: project,
      module: _selectedModule!,
      inverter: _selectedInverter!,
      modulesInSeries: _modulesInSeries,
      stringsInParallel: _stringsInParallel,
      tiltAngle: _tiltAngle,
      azimuthAngle: _azimuthAngle,
      losses: _losses,
    );
  }
  
  Widget _buildFinancialTab() {
    if (_selectedModule == null) {
      return const Center(child: Text('Module not selected.'));
    }
    
    final systemSizeWatts = _selectedModule!.powerRating * _modulesInSeries * _stringsInParallel;
    
    return FinancialROICalculator(
      systemCost: _systemCost,
      annualProduction: _annualProduction,
      systemSizeWatts: systemSizeWatts.toInt(),
      electricityRate: 0.15, // $/kWh
      hasBattery: _hasBattery,
      batteryCapacity: _batteryCapacity,
      batterySystemCost: _batteryCost,
    );
  }
  
  Widget _buildBatteryTab() {
    return BatteryStorageSimulation(
      dailyEnergyProduction: _annualProduction / 365,
      batteryCapacity: _batteryCapacity,
      batteryPowerRating: 5.0,
      batteryCost: _batteryCost,
      electricityRate: 0.15,
      feedInRate: 0.05,
    );
  }
  
  Widget _buildShadingTab(Project project) {
    return ShadingAnalysisView(
      latitude: project.location.latitude,
      longitude: project.location.longitude,
    );
  }
  
  Widget _buildLayoutTab() {
    if (_selectedModule == null) {
      return const Center(child: Text('Module not selected.'));
    }
    
    // For demo purposes, assume 100 m² roof area
    return const LayoutOptimizer(
      availableArea: 100.0,
      areaWidth: 10.0,
      areaLength: 10.0,
    );
  }
}



