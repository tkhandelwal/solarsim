// This will complete the create_project_dialog.dart file
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:solarsim/models/project.dart';
import 'package:solarsim/models/location.dart';
import 'package:solarsim/services/project_service.dart';

class CreateProjectDialog extends ConsumerStatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  ConsumerState<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends ConsumerState<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  SystemType _selectedSystemType = SystemType.gridConnected;
  
  // In a real app, you would have a location picker
  // For now, we'll use a simple dummy location
  final _dummyLocation = Location(
    latitude: 37.7749,
    longitude: -122.4194,
    address: 'San Francisco, CA',
    timeZone: 'America/Los_Angeles',
  );
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Project'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  hintText: 'Enter a name for your project',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter a description for your project',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SystemType>(
                value: _selectedSystemType,
                decoration: const InputDecoration(
                  labelText: 'System Type',
                ),
                items: SystemType.values.map((type) {
                  return DropdownMenuItem<SystemType>(
                    value: type,
                    child: Text(_getSystemTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSystemType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Location info display - in a real app, this would be a location picker
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_dummyLocation.address),
                    Text('Lat: ${_dummyLocation.latitude.toStringAsFixed(4)}, Long: ${_dummyLocation.longitude.toStringAsFixed(4)}'),
                    Text('Time Zone: ${_dummyLocation.timeZone}'),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.location_on),
                      label: const Text('Change Location'),
                      onPressed: () {
                        // In a real app, show a location picker here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location picker would open here')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createProject,
          child: const Text('Create'),
        ),
      ],
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
  
  void _createProject() async {
    if (_formKey.currentState!.validate()) {
      final projectService = ref.read(projectServiceProvider);
      
      final project = await projectService.createProject(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
        _selectedSystemType,
        _dummyLocation,
      );
      
      if (!mounted) return;
      
      context.pop();
      context.go('/project/${project.id}');
    }
  }
}