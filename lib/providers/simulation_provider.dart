// lib/providers/simulation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_sim/models/simulation_result.dart';
import 'package:solar_sim/services/simulation_service.dart';
import 'package:solar_sim/providers/projects_provider.dart';

final runSimulationProvider = FutureProvider.family<SimulationResult, String>((ref, projectId) async {
  final simulationService = ref.watch(simulationServiceProvider);
  final project = await ref.watch(projectProvider(projectId).future);
  return simulationService.runSimulation(project);
});