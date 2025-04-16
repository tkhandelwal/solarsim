// lib/widgets/create_project_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_sim/models/project.dart';
import 'package:solar_sim/models/location.dart';
import 'package:solar_sim/services/project_service.dart';

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