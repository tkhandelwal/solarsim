// lib/screens/project_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:solarsim/models/project.dart';
import 'package:solarsim/providers/projects_provider.dart';
import 'package:intl/intl.dart';
import 'package:solarsim/services/project_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:solarsim/widgets/module_selection_dialog.dart';
import 'package:solarsim/widgets/inverter_selection_dialog.dart';

class ProjectScreen extends ConsumerWidget {
  final String projectId;
  
  const ProjectScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectProvider(projectId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDeleteProject(context, ref),
          ),
        ],
      ),
      body: projectAsync.when(
        data: (project) => _buildProjectDetails(context, ref, project),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/simulation/$projectId'),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Run Simulation'),
      ),
    );
  }
  
  Widget _buildProjectDetails(BuildContext context, WidgetRef ref, Project project) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('System Type', _getSystemTypeLabel(project.systemType)),
                  _buildInfoRow('Created', dateFormat.format(project.createdAt)),
                  _buildInfoRow('Last Modified', dateFormat.format(project.modifiedAt)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Location information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Address', project.location.address),
                  _buildInfoRow('Coordinates', 
                    '${project.location.latitude.toStringAsFixed(4)}, ${project.location.longitude.toStringAsFixed(4)}'),
                  _buildInfoRow('Elevation', '${project.location.elevation} m'),
                  _buildInfoRow('Time Zone', project.location.timeZone),
                  
                  const SizedBox(height: 16),
                  // Map display
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(project.location.latitude, project.location.longitude),
                          initialZoom: 13.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 80.0,
                                height: 80.0,
                                point: LatLng(project.location.latitude, project.location.longitude),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // System configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Configuration',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildConfigurationSection(context, ref, 'PV Modules', 
                    'No modules configured', Icons.solar_power),
                  
                  const Divider(),
                  
                  _buildConfigurationSection(context, ref, 'Inverters', 
                    'No inverters configured', Icons.electrical_services),
                  
                  const Divider(),
                  
                  _buildConfigurationSection(context, ref, 'Mounting System', 
                    'No mounting system configured', Icons.architecture),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recent simulations (if any)
          Text(
            'Recent Simulations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('No simulations have been run yet'),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConfigurationSection(
    BuildContext context, 
    WidgetRef ref,
    String title, 
    String emptyMessage, 
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              onPressed: () {
                if (title == 'PV Modules') {
                  _showModuleSelectionDialog(context, ref);
                } else if (title == 'Inverters') {
                  _showInverterSelectionDialog(context, ref);
                } else {
                  // Show mounting system dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Add $title dialog would open here')),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(emptyMessage),
          ),
        ),
      ],
    );
  }
  
  void _showModuleSelectionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ModuleSelectionDialog(
        onModuleSelected: (module) {
          // TODO: Update project with selected module
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected module: ${module.manufacturer} ${module.model}'),
            ),
          );
        },
      ),
    );
  }
  
  void _showInverterSelectionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => InverterSelectionDialog(
        onInverterSelected: (inverter) {
          // TODO: Update project with selected inverter
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected inverter: ${inverter.manufacturer} ${inverter.model}'),
            ),
          );
        },
      ),
    );
  }
  
  String _getSystemTypeLabel(SystemType type) {
    switch (type) {
      case SystemType.gridConnected:
        return 'Grid-Connected';
      case SystemType.standalone:
        return 'Off-Grid / Standalone';
      case SystemType.pumping:
        return 'Solar Pumping';
      case SystemType.solarThermal:
        return 'Solar Thermal';
      case SystemType.hybrid:
        return 'Hybrid System';
    }
  }
  
  void _confirmDeleteProject(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text('Are you sure you want to delete this project? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final projectService = ref.read(projectServiceProvider);
              await projectService.deleteProject(projectId);
              if (!context.mounted) return;
              context.go('/');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}