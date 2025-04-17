// lib/widgets/module_selection_dialog.dart
import 'package:flutter/material.dart';
import 'package:solarsim/models/solar_module.dart';

class ModuleSelectionDialog extends StatefulWidget {
    final Function(SolarModule) onModuleSelected;

  final SolarModule? initialSelectedModule;
  
  const ModuleSelectionDialog({
    super.key,
        required this.onModuleSelected,
    this.initialSelectedModule,
  });

  @override
  State<ModuleSelectionDialog> createState() => _ModuleSelectionDialogState();
}

class _ModuleSelectionDialogState extends State<ModuleSelectionDialog> {
  SolarModule? _selectedModule;
  String _searchQuery = '';
  ModuleTechnology? _filterTechnology;
  
  // Sample modules data - in a real app, this would come from a database
  final List<SolarModule> _modules = [
    SolarModule(
      id: 'module1',
      manufacturer: 'SunPower',
      model: 'SPR-X22-360',
      powerRating: 360,
      efficiency: 0.22,
      length: 1.7,
      width: 1.0,
      technology: ModuleTechnology.monocrystalline,
      temperatureCoefficient: -0.32,
      nominalOperatingCellTemp: 45,
    ),
    SolarModule(
      id: 'module2',
      manufacturer: 'LG',
      model: 'NeON R 370W',
      powerRating: 370,
      efficiency: 0.215,
      length: 1.7,
      width: 1.016,
      technology: ModuleTechnology.monocrystalline,
      temperatureCoefficient: -0.30,
      nominalOperatingCellTemp: 44,
    ),
    SolarModule(
      id: 'module3',
      manufacturer: 'Canadian Solar',
      model: 'CS3W-410P',
      powerRating: 410,
      efficiency: 0.198,
      length: 2.108,
      width: 1.048,
      technology: ModuleTechnology.polycrystalline,
      temperatureCoefficient: -0.37,
      nominalOperatingCellTemp: 42,
    ),
    SolarModule(
      id: 'module4',
      manufacturer: 'First Solar',
      model: 'Series 6',
      powerRating: 420,
      efficiency: 0.187,
      length: 2.0,
      width: 1.2,
      technology: ModuleTechnology.thinFilm,
      temperatureCoefficient: -0.28,
      nominalOperatingCellTemp: 41,
    ),
    SolarModule(
      id: 'module5',
      manufacturer: 'JinkoSolar',
      model: 'Eagle 66TR G4',
      powerRating: 380,
      efficiency: 0.205,
      length: 1.75,
      width: 1.05,
      technology: ModuleTechnology.monocrystalline,
      temperatureCoefficient: -0.35,
      nominalOperatingCellTemp: 45,
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _selectedModule = widget.initialSelectedModule;
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select PV Module',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Search and filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search modules...',
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<ModuleTechnology?>(
                  value: _filterTechnology,
                  hint: const Text('Technology'),
                  items: [
                    const DropdownMenuItem<ModuleTechnology?>(
                      value: null,
                      child: Text('All'),
                    ),
                    ...ModuleTechnology.values.map((tech) {
                      return DropdownMenuItem<ModuleTechnology?>(
                        value: tech,
                        child: Text(_getTechnologyLabel(tech)),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterTechnology = value;
                    });
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Module list
            Expanded(
              child: ListView(
                children: _getFilteredModules().map((module) {
                  final isSelected = _selectedModule?.id == module.id;
                  
                  return Card(
                    color: isSelected ? Colors.blue.shade50 : null,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedModule = module;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            isSelected 
                                ? const Icon(Icons.check_circle, color: Colors.blue)
                                : const Icon(Icons.circle_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${module.manufacturer} ${module.model}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${module.powerRating} W | ${(module.efficiency * 100).toStringAsFixed(1)}% efficiency',
                                  ),
                                  Text(
                                    '${_getTechnologyLabel(module.technology)} | ${module.length} × ${module.width} m',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedModule != null
                      ? () => Navigator.of(context).pop(_selectedModule)
                      : null,
                  child: const Text('Select'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  List<SolarModule> _getFilteredModules() {
    return _modules.where((module) {
      // Apply search filter
      final searchMatch = 
          module.manufacturer.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          module.model.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Apply technology filter
      final technologyMatch = _filterTechnology == null || 
          module.technology == _filterTechnology;
      
      return searchMatch && technologyMatch;
    }).toList();
  }
  
  String _getTechnologyLabel(ModuleTechnology technology) {
    switch (technology) {
      case ModuleTechnology.monocrystalline:
        return 'Monocrystalline';
      case ModuleTechnology.polycrystalline:
        return 'Polycrystalline';
      case ModuleTechnology.thinFilm:
        return 'Thin Film';
      case ModuleTechnology.amorphous:
        return 'Amorphous Silicon';
      case ModuleTechnology.bifacial:
        return 'Bifacial';
      case ModuleTechnology.cigs:
        return 'CIGS';
      case ModuleTechnology.cdte:
        return 'CdTe';
    }
  }
}