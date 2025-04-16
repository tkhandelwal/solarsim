// lib/providers/projects_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_sim/models/project.dart';
import 'package:solar_sim/services/project_service.dart';

final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final projectService = ref.watch(projectServiceProvider);
  return projectService.getProjects();
});

final projectProvider = FutureProvider.family<Project, String>((ref, id) async {
  final projectService = ref.watch(projectServiceProvider);
  return projectService.getProject(id);
});