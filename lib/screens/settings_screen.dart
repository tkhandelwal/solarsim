// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import other necessary providers

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isDarkMode = false;
  String _selectedUnits = 'Metric';
  String _selectedCurrency = 'USD';
  bool _showAdvancedOptions = false;
  bool _enableAutosave = true;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Theme toggle
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Enable dark theme for the application'),
                    value: _isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        _isDarkMode = value;
                      });
                    },
                  ),
                  
                  const Divider(),
                  
                  // Unit system
                  ListTile(
                    title: const Text('Unit System'),
                    subtitle: Text(_selectedUnits),
                    trailing: DropdownButton<String>(
                      value: _selectedUnits,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedUnits = value;
                          });
                        }
                      },
                      items: ['Metric', 'Imperial', 'Mixed'].map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // Currency
                  ListTile(
                    title: const Text('Currency'),
                    subtitle: Text(_selectedCurrency),
                    trailing: DropdownButton<String>(
                      value: _selectedCurrency,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCurrency = value;
                          });
                        }
                      },
                      items: ['USD', 'EUR', 'GBP', 'JPY', 'CNY'].map((currency) {
                        return DropdownMenuItem<String>(
                          value: currency,
                          child: Text(currency),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const Divider(),
                  
                  // Auto-save
                  SwitchListTile(
                    title: const Text('Enable Auto-save'),
                    subtitle: const Text('Automatically save changes to projects'),
                    value: _enableAutosave,
                    onChanged: (value) {
                      setState(() {
                        _enableAutosave = value;
                      });
                    },
                  ),
                  
                  // Advanced options
                  SwitchListTile(
                    title: const Text('Show Advanced Options'),
                    subtitle: const Text('Display additional configuration options'),
                    value: _showAdvancedOptions,
                    onChanged: (value) {
                      setState(() {
                        _showAdvancedOptions = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Management',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  ListTile(
                    leading: const Icon(Icons.cloud_upload),
                    title: const Text('Backup Data'),
                    subtitle: const Text('Save your projects to the cloud'),
                    onTap: () {
                      // This would initiate a backup in a real app
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Backup functionality would be implemented here')),
                      );
                    },
                  ),
                  
                  const Divider(),
                  
                  ListTile(
                    leading: const Icon(Icons.cloud_download),
                    title: const Text('Restore Data'),
                    subtitle: const Text('Restore projects from backup'),
                    onTap: () {
                      // This would initiate a restore in a real app
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Restore functionality would be implemented here')),
                      );
                    },
                  ),
                  
                  const Divider(),
                  
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Clear All Data'),
                    subtitle: const Text('Delete all projects and settings'),
                    onTap: () {
                      _showClearDataConfirmation();
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  const ListTile(
                    title: Text('SolarSim'),
                    subtitle: Text('Version 1.0.0'),
                  ),
                  
                  const Divider(),
                  
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('Privacy Policy'),
                    onTap: () {
                      // This would open the privacy policy in a real app
                    },
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Terms of Service'),
                    onTap: () {
                      // This would open the terms of service in a real app
                    },
                  ),
                  
                  const Divider(),
                  
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // This would show an about dialog in a real app
                        showAboutDialog(
                          context: context,
                          applicationName: 'SolarSim',
                          applicationVersion: '1.0.0',
                          applicationIcon: const FlutterLogo(size: 32),
                          applicationLegalese: '© 2025 SolarSim',
                          children: [
                            const SizedBox(height: 16),
                            const Text(
                              'SolarSim is a modern solar PV simulation software built with Flutter.',
                            ),
                          ],
                        );
                      },
                      child: const Text('About SolarSim'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to clear all data? This action cannot be undone and all your projects will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              // This would clear all data in a real app
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }
}