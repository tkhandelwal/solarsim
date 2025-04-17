// lib/services/simulation_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solarsim/models/project.dart';
import 'package:solarsim/models/simulation_result.dart';
import 'package:solarsim/models/solar_module.dart';
import 'package:solarsim/models/inverter.dart';
import 'package:solarsim/core/pv_system_simulator.dart';
import 'package:uuid/uuid.dart';

final simulationServiceProvider = Provider<SimulationService>((ref) {
  return SimulationService();
});

class SimulationService {
  final _uuid = const Uuid();
  
  // Sample data for simulation
  final _sampleModule = SolarModule(
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
  
  final _sampleInverter = Inverter(
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
  
  Future<SimulationResult> runSimulation(Project project) async {
    // In a real app, this would perform an actual simulation
    // using PVSystemSimulator and weather data
    
    // Simulate some processing time
    await Future.delayed(const Duration(seconds: 2));
    
    // Create simulator with sample data
    final simulator = PVSystemSimulator(
      project: project,
      module: _sampleModule,
      inverter: _sampleInverter,
      modulesInSeries: 10,
      stringsInParallel: 4,
      tiltAngle: 20,
      azimuthAngle: 180,
    );
    
    // For demonstration, return dummy results
    return SimulationResult(
      id: _uuid.v4(),
      projectId: project.id,
      createdAt: DateTime.now(),
      monthlyEnergy: {
        'Jan': 3450,
        'Feb': 3980,
        'Mar': 5210,
        'Apr': 5890,
        'May': 6450,
        'Jun': 6780,
        'Jul': 6920,
        'Aug': 6630,
        'Sep': 5980,
        'Oct': 4780,
        'Nov': 3450,
        'Dec': 2930,
      },
      annualEnergy: 62450,
      performanceRatio: 0.842,
      losses: {
        'soiling': 0.02,
        'shading': 0.03,
        'mismatch': 0.02,
        'wiring': 0.03,
        'inverter': 0.02,
        'temperature': 0.05,
      },
      financialMetrics: {
        'lcoe': 0.067,
        'paybackPeriod': 5.3,
        'npv': 72450,
        'irr': 0.187,
      },
    );
  }
}