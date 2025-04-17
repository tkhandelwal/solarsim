// lib/providers/simulation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solarsim/models/simulation_result.dart';
import 'package:solarsim/services/simulation_service.dart';
import 'package:solarsim/providers/projects_provider.dart';

final runSimulationProvider = FutureProvider.family<SimulationResult, String>((ref, projectId) async {
  final simulationService = ref.watch(simulationServiceProvider);
  final project = await ref.watch(projectProvider(projectId).future);
  return simulationService.runSimulation(project);
});