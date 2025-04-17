// lib/widgets/inverter_selection_dialog.dart
import 'package:flutter/material.dart';
import 'package:solarsim/models/inverter.dart';

class InverterSelectionDialog extends StatefulWidget {
  final Function(Inverter) onInverterSelected;
  final Inverter? initialSelectedInverter;
  
  const InverterSelectionDialog({
    super.key,
    required this.onInverterSelected,
    this.initialSelectedInverter,
  });

  @override
  State<InverterSelectionDialog> createState() => _InverterSelectionDialogState();
}

class _InverterSelectionDialogState extends State<InverterSelectionDialog> {
  Inverter? _selectedInverter;
  String _searchQuery = '';
  InverterType? _filterType;
  
  // Sample inverters data - in a real app, this would come from a database
  final List<Inverter> _inverters = [
    Inverter(
      id: 'inverter1',
      manufacturer: 'SMA',
      model: 'Sunny Tripower 15000TL',
      ratedPowerAC: 15000,
      maxDCPower: 18000,
      efficiency: 0.98,
      minMPPVoltage: 360,
      maxMPPVoltage: 800,
      numberOfMPPTrackers: 2,
      type: InverterType.string,
    ),
    Inverter(
      id: 'inverter2',
      manufacturer: 'Fronius',
      model: 'Symo 10.0-3-M',
      ratedPowerAC: 10000,
      maxDCPower: 15000,
      efficiency: 0.975,
      minMPPVoltage: 270,
      maxMPPVoltage: 800,
      numberOfMPPTrackers: 2,
      type: InverterType.string,
    ),
    Inverter(
      id: 'inverter3',
      manufacturer: 'SolarEdge',
      model: 'SE7600H',
      ratedPowerAC: 7600,
      maxDCPower: 11800,
      efficiency: 0.99,
      minMPPVoltage: 400,
      maxMPPVoltage: 900,
      numberOfMPPTrackers: 1,
      type: InverterType.string,
    ),
    Inverter(
      id: 'inverter4',
      manufacturer: 'Enphase',
      model: 'IQ7+',
      ratedPowerAC: 290,
      maxDCPower: 350,
      efficiency: 0.97,
      minMPPVoltage: 27,
      maxMPPVoltage: 39,
      numberOfMPPTrackers: 1,
      type: InverterType.microinverter,
    ),
    Inverter(
      id: 'inverter5',
      manufacturer: 'ABB',
      model: 'TRIO-50.0-TL-OUTD',
      ratedPowerAC: 50000,
      maxDCPower: 75000,
      efficiency: 0.985,
      minMPPVoltage: 500,
      maxMPPVoltage: 950,
      numberOfMPPTrackers: 1,
      type: InverterType.central,
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _selectedInverter = widget.initialSelectedInverter;
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
              'Select Inverter',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Search and filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search inverters...',
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
                DropdownButton<InverterType?>(
                  value: _filterType,
                  hint: const Text('Type'),
                  items: [
                    const DropdownMenuItem<InverterType?>(
                      value: null,
                      child: Text('All'),
                    ),
                    ...InverterType.values.map((type) {
                      return DropdownMenuItem<InverterType?>(
                        value: type,
                        child: Text(_getInverterTypeLabel(type)),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterType = value;
                    });
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Inverter list
            Expanded(
              child: ListView(
                children: _getFilteredInverters().map((inverter) {
                  final isSelected = _selectedInverter?.id == inverter.id;
                  
                  return Card(
                    color: isSelected ? Colors.blue.shade50 : null,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedInverter = inverter;
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
                                    '${inverter.manufacturer} ${inverter.model}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${inverter.ratedPowerAC / 1000} kW | ${(inverter.efficiency * 100).toStringAsFixed(1)}% efficiency',
                                  ),
                                  Text(
                                    '${_getInverterTypeLabel(inverter.type)} | MPP: ${inverter.minMPPVoltage}-${inverter.maxMPPVoltage} V',
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
                  onPressed: _selectedInverter != null
                      ? () {
                          widget.onInverterSelected(_selectedInverter!);
                          Navigator.of(context).pop();
                        }
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
  
  List<Inverter> _getFilteredInverters() {
    return _inverters.where((inverter) {
      // Apply search filter
      final searchMatch = 
          inverter.manufacturer.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inverter.model.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Apply type filter
      final typeMatch = _filterType == null || 
          inverter.type == _filterType;
      
      return searchMatch && typeMatch;
    }).toList();
  }
  
  String _getInverterTypeLabel(InverterType type) {
    switch (type) {
      case InverterType.string:
        return 'String Inverter';
      case InverterType.central:
        return 'Central Inverter';
      case InverterType.microinverter:
        return 'Microinverter';
      case InverterType.hybrid:
        return 'Hybrid Inverter';
    }
  }
}