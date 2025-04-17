// lib/services/project_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solarsim/models/project.dart';
import 'package:solarsim/models/location.dart';
import 'package:uuid/uuid.dart';

final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService();
});

class ProjectService {
  // In a real app, this would be connected to Firebase or another backend
  final List<Project> _projects = [];
  final _uuid = const Uuid();
  
  // Initialize with sample projects
  void initializeSampleProjects() {
    if (_projects.isNotEmpty) return;
    
    // Sample locations
    final sanFrancisco = Location(
      latitude: 37.7749,
      longitude: -122.4194,
      address: 'San Francisco, CA',
      elevation: 16,
      timeZone: 'America/Los_Angeles',
    );
    
    final newYork = Location(
      latitude: 40.7128,
      longitude: -74.0060,
      address: 'New York, NY',
      elevation: 10,
      timeZone: 'America/New_York',
    );
    
    // Create sample projects
    final project1 = Project(
      id: _uuid.v4(),
      name: 'Residential Rooftop',
      description: 'A 10kW residential rooftop solar installation',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      modifiedAt: DateTime.now().subtract(const Duration(days: 2)),
      ownerId: 'user-1',
      systemType: SystemType.gridConnected,
      location: sanFrancisco,
    );
    
    final project2 = Project(
      id: _uuid.v4(),
      name: 'Commercial Building',
      description: 'A 200kW commercial rooftop installation with battery storage',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      modifiedAt: DateTime.now().subtract(const Duration(days: 1)),
      ownerId: 'user-1',
      systemType: SystemType.hybrid,
      location: newYork,
    );
    
    _projects.addAll([project1, project2]);
  }
  
  Future<List<Project>> getProjects() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _projects;
  }
  
  Future<Project> getProject(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _projects.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Project not found: $id'),
    );
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