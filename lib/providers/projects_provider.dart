// lib/providers/projects_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solarsim/models/project.dart';
import 'package:solarsim/services/project_service.dart';

final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final projectService = ref.watch(projectServiceProvider);
  return projectService.getProjects();
});

final projectProvider = FutureProvider.family<Project, String>((ref, id) async {
  final projectService = ref.watch(projectServiceProvider);
  return projectService.getProject(id);
});