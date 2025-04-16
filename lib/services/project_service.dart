// lib/services/project_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_sim/models/project.dart';
import 'package:solar_sim/models/location.dart';
import 'package:uuid/uuid.dart';

final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService();
});

class ProjectService {
  // In a real app, this would be connected to Firebase or another backend
  final List<Project> _projects = [];
  final _uuid = const Uuid();
  
  Future<List<Project>> getProjects() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _projects;
  }
  
  Future<Project> getProject(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _projects.firstWhere((p) => p.id == id);
  }
  
  Future<Project> createProject(
    String name,
    String description,
    SystemType systemType,
    Location location,
  ) async {
    final project = Project(
      id: _uuid.v4(),
      name: name,
      description: description,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      ownerId: 'current-user-id', // In a real app, get from auth
      systemType: systemType,
      location: location,
    );
    
    _projects.add(project);
    return project;
  }
  
  Future<void> updateProject(Project project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      _projects[index] = project.copyWith(
        modifiedAt: DateTime.now(),
      );
    }
  }
  
  Future<void> deleteProject(String id) async {
    _projects.removeWhere((p) => p.id == id);
  }
}