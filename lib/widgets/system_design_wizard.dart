// lib/widgets/system_design_wizard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solarsim/models/project.dart';
import 'package:solarsim/models/solar_module.dart';
import 'package:solarsim/models/inverter.dart';
import 'package:solarsim/models/location.dart';
import 'package:solarsim/services/project_service.dart';
import 'package:solarsim/widgets/module_selection_dialog.dart';
import 'package:solarsim/widgets/inverter_selection_dialog.dart';
import 'package:solarsim/core/pv_array.dart';

class SystemDesignWizard extends ConsumerStatefulWidget {
  final Project project;
  final Function(Project) onComplete;
  
  const SystemDesignWizard({
    super.key,
    required this.project,
    required this.onComplete,
  });

  @override
  ConsumerState<SystemDesignWizard> createState() => _SystemDesignWizardState();
}

class _SystemDesignWizardState extends ConsumerState<SystemDesignWizard> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isAutoDesign = true;
  
  // System design parameters
  double _systemCapacity = 10.0; // kWp
  SolarModule? _selectedModule;
  Inverter? _selectedInverter;
  int _modulesInSeries = 0;
  int _stringsInParallel = 0;
  double _tiltAngle = 20.0;
  double _azimuthAngle = 180.0;
  bool _useBatteryStorage = false;
  double _batteryCapacity = 10.0; // kWh
  double _batteryPower = 5.0; // kW
  double _roofArea = 100.0; // m²
  double _annualConsumption = 5000.0; // kWh
  double _electricityRate = 0.15; // $/kWh
  String _mountingType = 'Roof Mount';
  
  // Financial parameters
  double _moduleUnitCost = 0.5; // $/W
  double _inverterUnitCost = 0.2; // $/W
  double _batteryUnitCost = 500; // $/kWh
  double _bos = 0.3; // $/W (Balance of System)
  double _installation = 0.5; // $/W
  double _annualMaintenance = 0.01; // % of total cost
  double _discountRate = 0.04; // 4%
  int _financingTerm = 25; // years
  
  // Auto-design results
  Map<String, dynamic> _autoDesignResults = {};
  
  @override
  void initState() {
    super.initState();
    // Load default module and inverter
    _selectedModule = SolarModule(
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
    );
    
    _selectedInverter = Inverter(
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
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Design Wizard'),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep == 1 && _isAutoDesign) {
              _runAutoDesign();
            }
            
            if (_currentStep < 4) {
              setState(() {
                _currentStep += 1;
              });
            } else {
              _completeWizard();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            }
          },
          steps: [
            _buildSiteInfoStep(),
            _buildDesignApproachStep(),
            _buildSystemConfigStep(),
            _buildComponentSelectionStep(),
            _buildFinancialParametersStep(),
          ],
        ),
      ),
    );
  }
  
  Step _buildSiteInfoStep() {
    return Step(
      title: const Text('Site Information'),
      content: Column(
        children: [
          // Location
          ListTile(
            title: const Text('Location'),
            subtitle: Text(widget.project.location.address),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // In a real app, show a location picker
              },
            ),
          ),
          
          const Divider(),
          
          // Roof area
          _buildSliderWithField(
            'Available Roof Area (m²)',
            _roofArea,
            20,
            500,
            (value) {
              setState(() {
                _roofArea = value;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Annual consumption
          _buildSliderWithField(
            'Annual Energy Consumption (kWh)',
            _annualConsumption,
            1000,
            20000,
            (value) {
              setState(() {
                _annualConsumption = value;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Electricity rate
          _buildSliderWithField(
            'Electricity Rate (\$/kWh)',
            _electricityRate,
            0.05,
            0.5,
            (value) {
              setState(() {
                _electricityRate = value;
              });
            },
            divisions: 45,
            numberFormat: '0.00',
          ),
          
          const SizedBox(height: 16),
          
          // Mounting type
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Mounting Type',
              border: OutlineInputBorder(),
            ),
            value: _mountingType,
            items: [
              'Roof Mount',
              'Ground Mount',
              'Carport',
              'Facade',
              'Tracker - Single Axis',
              'Tracker - Dual Axis',
            ].map((type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _mountingType = value;
                  
                  // Update tilt angle based on mounting type
                  if (value.contains('Tracker')) {
                    _tiltAngle = 0; // Will be dynamic for trackers
                  } else if (value == 'Facade') {
                    _tiltAngle = 90;
                  } else {
                    _tiltAngle = 20; // Default for roof/ground mount
                  }
                });
              }
            },
          ),
        ],
      ),
      isActive: _currentStep >= 0,
    );
  }
  
  Step _buildDesignApproachStep() {
    return Step(
      title: const Text('Design Approach'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auto vs Manual design
          SwitchListTile(
            title: const Text('Automatic System Design'),
            subtitle: const Text('Let the app optimize your system configuration'),
            value: _isAutoDesign,
            onChanged: (value) {
              setState(() {
                _isAutoDesign = value;
              });
            },
          ),
          
          const Divider(),
          
          if (_isAutoDesign) ...[
            const Text(
              'Design Goals',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Design goals for auto-design
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Optimization Priority',
                border: OutlineInputBorder(),
              ),
              value: 'Maximum ROI',
              items: [
                'Maximum ROI',
                'Maximize Self-Consumption',
                'Shortest Payback Period',
                'Maximum Energy Production',
                'Minimize Upfront Cost',
              ].map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {},
            ),
            
            const SizedBox(height: 16),
            
            // System capacity target
            _buildSliderWithField(
              'Target System Capacity (kWp)',
              _systemCapacity,
              1,
              50,
              (value) {
                setState(() {
                  _systemCapacity = value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Battery storage
            SwitchListTile(
              title: const Text('Include Battery Storage'),
              subtitle: const Text('Add battery for energy storage and backup power'),
              value: _useBatteryStorage,
              onChanged: (value) {
                setState(() {
                  _useBatteryStorage = value;
                });
              },
            ),
            
            if (_useBatteryStorage) ...[
              const SizedBox(height: 16),
              
              _buildSliderWithField(
                'Battery Capacity (kWh)',
                _batteryCapacity,
                2,
                40,
                (value) {
                  setState(() {
                    _batteryCapacity = value;
                  });
                },
              ),
            ],
          ] else ...[
            const Text(
              'Manual Design Parameters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Manual design parameters
            _buildSliderWithField(
              'System Capacity (kWp)',
              _systemCapacity,
              1,
              50,
              (value) {
                setState(() {
                  _systemCapacity = value;
                });
              },
            ),
          ],
        ],
      ),
      isActive: _currentStep >= 1,
    );
  }
  
  Step _buildSystemConfigStep() {
    return Step(
      title: const Text('System Configuration'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Module and inverter count
          if (_isAutoDesign && _autoDesignResults.isNotEmpty) ...[
            // Auto-design results
            const Text(
              'Auto-Design Results',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('System Capacity', '${_autoDesignResults['capacity'].toStringAsFixed(2)} kWp'),
            _buildInfoRow('Module Count', '${_autoDesignResults['moduleCount']}'),
            _buildInfoRow('Modules in Series', '${_autoDesignResults['modulesInSeries']}'),
            _buildInfoRow('Strings in Parallel', '${_autoDesignResults['stringsInParallel']}'),
            _buildInfoRow('Inverter Model', '${_selectedInverter?.manufacturer} ${_selectedInverter?.model}'),
            _buildInfoRow('DC/AC Ratio', '${_autoDesignResults['dcAcRatio'].toStringAsFixed(2)}'),
            
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Re-run Auto-Design'),
              onPressed: _runAutoDesign,
            ),
          ] else ...[
            // Manual configuration
            if (_selectedModule != null) ...[
              _buildInfoRow('Selected Module', '${_selectedModule?.manufacturer} ${_selectedModule?.model}'),
              _buildInfoRow('Module Power', '${_selectedModule?.powerRating} W'),
            ],
            
            const SizedBox(height: 16),
            
            // Modules in series
            _buildNumberField(
              'Modules in Series',
              _modulesInSeries.toString(),
              (value) {
                setState(() {
                  _modulesInSeries = int.tryParse(value) ?? _modulesInSeries;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Strings in parallel
            _buildNumberField(
              'Strings in Parallel',
              _stringsInParallel.toString(),
              (value) {
                setState(() {
                  _stringsInParallel = int.tryParse(value) ?? _stringsInParallel;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            if (_selectedModule != null && _modulesInSeries > 0 && _stringsInParallel > 0) ...[
              _buildInfoRow(
                'Total System Power',
                '${(_selectedModule!.powerRating * _modulesInSeries * _stringsInParallel / 1000).toStringAsFixed(2)} kWp',
              ),
            ],
          ],
          
          const Divider(),
          
          // Orientation parameters
          Text(
            _mountingType.contains('Tracker') ? 'Tracker Configuration' : 'Array Orientation',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Tilt angle
          _buildSliderWithField(
            'Tilt Angle (°)',
            _tiltAngle,
            0,
            90,
            (value) {
              setState(() {
                _tiltAngle = value;
              });
            },
            enabled: !_mountingType.contains('Tracker'),
          ),
          
          const SizedBox(height: 16),
          
          // Azimuth angle
          _buildSliderWithField(
            'Azimuth Angle (°)',
            _azimuthAngle,
            0,
            360,
            (value) {
              setState(() {
                _azimuthAngle = value;
              });
            },
            enabled: !_mountingType.contains('Dual Axis'),
          ),
          
          if (_mountingType.contains('Tracker')) ...[
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tracking Algorithm',
                border: OutlineInputBorder(),
              ),
              value: 'Astronomical Tracking',
              items: [
                'Astronomical Tracking',
                'Light Sensing',
                'Hybrid Tracking',
              ].map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {},
            ),
          ],
          
          const Divider(),
          
          // Battery configuration
          if (_useBatteryStorage) ...[
            const Text(
              'Battery Configuration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _buildSliderWithField(
              'Battery Capacity (kWh)',
              _batteryCapacity,
              2,
              40,
              (value) {
                setState(() {
                  _batteryCapacity = value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildSliderWithField(
              'Battery Power (kW)',
              _batteryPower,
              1,
              20,
              (value) {
                setState(() {
                  _batteryPower = value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Battery Chemistry',
                border: OutlineInputBorder(),
              ),
              value: 'Lithium Ion',
              items: [
                'Lithium Ion',
                'Lithium Iron Phosphate',
                'Lead Acid',
                'Flow Battery',
              ].map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {},
            ),
          ],
        ],
      ),
      isActive: _currentStep >= 2,
    );
  }
  
  Step _buildComponentSelectionStep() {
    return Step(
      title: const Text('Component Selection'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PV Module selection
          const Text(
            'PV Module',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          if (_selectedModule != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedModule!.manufacturer} ${_selectedModule!.model}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Power: ${_selectedModule!.powerRating} W'),
                    Text('Efficiency: ${(_selectedModule!.efficiency * 100).toStringAsFixed(1)}%'),
                    Text('Size: ${_selectedModule!.length} × ${_selectedModule!.width} m'),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Text('No module selected'),
          ],
          
          const SizedBox(height: 8),
          
          ElevatedButton.icon(
            icon: const Icon(Icons.change_circle),
            label: const Text('Select Module'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ModuleSelectionDialog(
                  onModuleSelected: (module) {
                    setState(() {
                      _selectedModule = module;
                      
                      // Update system configuration if in auto-design mode
                      if (_isAutoDesign) {
                        _runAutoDesign();
                      }
                    });
                  },
                ),
              );
            },
          ),
          
          const Divider(),
          
          // Inverter selection
          const Text(
            'Inverter',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          if (_selectedInverter != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedInverter!.manufacturer} ${_selectedInverter!.model}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('AC Power: ${(_selectedInverter!.ratedPowerAC / 1000).toStringAsFixed(1)} kW'),
                    Text('Efficiency: ${(_selectedInverter!.efficiency * 100).toStringAsFixed(1)}%'),
                    Text('MPP Voltage Range: ${_selectedInverter!.minMPPVoltage} - ${_selectedInverter!.maxMPPVoltage} V'),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Text('No inverter selected'),
          ],
          
          const SizedBox(height: 8),
          
          ElevatedButton.icon(
            icon: const Icon(Icons.change_circle),
            label: const Text('Select Inverter'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => InverterSelectionDialog(
                  onInverterSelected: (inverter) {
                    setState(() {
                      _selectedInverter = inverter;
                      
                      // Update system configuration if in auto-design mode
                      if (_isAutoDesign) {
                        _runAutoDesign();
                      }
                    });
                  },
                ),
              );
            },
          ),
          
          if (_useBatteryStorage) ...[
            const Divider(),
            
            const Text(
              'Battery System',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generic Lithium Ion Battery',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Capacity: ${_batteryCapacity.toStringAsFixed(1)} kWh'),
                    Text('Power: ${_batteryPower.toStringAsFixed(1)} kW'),
                    const Text('Round Trip Efficiency: 92%'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              icon: const Icon(Icons.change_circle),
              label: const Text('Select Battery System'),
              onPressed: () {
                // In a full app, show a battery selection dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Battery selection would open here')),
                );
              },
            ),
          ],
        ],
      ),
      isActive: _currentStep >= 3,
    );
  }
  
  Step _buildFinancialParametersStep() {
    // Calculate estimated system cost
    final modulesCost = _selectedModule != null ? 
        _selectedModule!.powerRating * _modulesInSeries * _stringsInParallel * _moduleUnitCost / 1000 : 0.0;
        
    final inverterCost = _selectedInverter != null ?
        _selectedInverter!.ratedPowerAC * _inverterUnitCost / 1000 : 0.0;
        
    final bosCost = _selectedModule != null ?
        _selectedModule!.powerRating * _modulesInSeries * _stringsInParallel * _bos / 1000 : 0.0;
        
    final installationCost = _selectedModule != null ?
        _selectedModule!.powerRating * _modulesInSeries * _stringsInParallel * _installation / 1000 : 0.0;
        
    final batteryCost = _useBatteryStorage ? _batteryCapacity * _batteryUnitCost : 0.0;
    
    final totalSystemCost = modulesCost + inverterCost + bosCost + installationCost + batteryCost;
    
    return Step(
      title: const Text('Financial Parameters'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cost breakdown
          const Text(
            'System Cost Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow('PV Modules', '\$${modulesCost.toStringAsFixed(2)}'),
          _buildInfoRow('Inverter(s)', '\$${inverterCost.toStringAsFixed(2)}'),
          if (_useBatteryStorage)
            _buildInfoRow('Battery System', '\$${batteryCost.toStringAsFixed(2)}'),
          _buildInfoRow('Balance of System', '\$${bosCost.toStringAsFixed(2)}'),
          _buildInfoRow('Installation', '\$${installationCost.toStringAsFixed(2)}'),
          
          const Divider(),
          _buildInfoRow('Total System Cost', '\$${totalSystemCost.toStringAsFixed(2)}', isBold: true),
          
          const Divider(),
          
          // Cost per watt
          _buildInfoRow(
            'Cost per Watt', 
            '\$${(totalSystemCost / (_selectedModule!.powerRating * _modulesInSeries * _stringsInParallel / 1000)).toStringAsFixed(2)}/W',
          ),
          
          const Divider(),
          
          // Financial parameters - adjust costs
          const Text(
            'Cost Parameters',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildSliderWithField(
            'Module Cost (\$/W)',
            _moduleUnitCost,
            0.2,
            1.0,
            (value) {
              setState(() {
                _moduleUnitCost = value;
              });
            },
            divisions: 16,
            numberFormat: '0.00',
          ),
          
          const SizedBox(height: 16),
          
          _buildSliderWithField(
            'Inverter Cost (\$/W)',
            _inverterUnitCost,
            0.1,
            0.5,
            (value) {
              setState(() {
                _inverterUnitCost = value;
              });
            },
            divisions: 8,
            numberFormat: '0.00',
          ),
          
          if (_useBatteryStorage) ...[
            const SizedBox(height: 16),
            
            _buildSliderWithField(
              'Battery Cost (\$/kWh)',
              _batteryUnitCost,
              200,
              1000,
              (value) {
                setState(() {
                  _batteryUnitCost = value;
                });
              },
              numberFormat: '0',
            ),
          ],
          
          const SizedBox(height: 16),
          
          _buildSliderWithField(
            'Balance of System (\$/W)',
            _bos,
            0.1,
            0.5,
            (value) {
              setState(() {
                _bos = value;
              });
            },
            divisions: 8,
            numberFormat: '0.00',
          ),
          
          const SizedBox(height: 16),
          
          _buildSliderWithField(
            'Installation Cost (\$/W)',
            _installation,
            0.2,
            1.0,
            (value) {
              setState(() {
                _installation = value;
              });
            },
            divisions: 16,
            numberFormat: '0.00',
          ),
          
          const Divider(),
          
          // Financial analysis parameters
          const Text(
            'Financial Analysis Parameters',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildSliderWithField(
            'Annual Maintenance (% of system cost)',
            _annualMaintenance * 100,
            0.5,
            3.0,
            (value) {
              setState(() {
                _annualMaintenance = value / 100;
              });
            },
            divisions: 5,
            numberFormat: '0.0',
            displaySuffix: '%',
          ),
          
          const SizedBox(height: 16),
          
          _buildSliderWithField(
            'Discount Rate (%)',
            _discountRate * 100,
            1.0,
            10.0,
            (value) {
              setState(() {
                _discountRate = value / 100;
              });
            },
            divisions: 18,
            numberFormat: '0.0',
            displaySuffix: '%',
          ),
          
          const SizedBox(height: 16),
          
          _buildSliderWithField(
            'Analysis Period (years)',
            _financingTerm.toDouble(),
            10,
            30,
            (value) {
              setState(() {
                _financingTerm = value.round();
              });
            },
            numberFormat: '0',
          ),
        ],
      ),
      isActive: _currentStep >= 4,
    );
  }
  
  Widget _buildSliderWithField(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged, {
    int? divisions,
    String numberFormat = '0.0',
    String displaySuffix = '',
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions ?? ((max - min) * 10).round(),
                onChanged: enabled ? onChanged : null,
              ),
            ),
            Expanded(
              flex: 1,
              child: TextField(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  suffixText: displaySuffix,
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                  text: value.toStringAsFixed(numberFormat.contains('.') ? int.parse(numberFormat.split('.')[1].length.toString()) : 0),
                ),
                onChanged: (text) {
                  final newValue = double.tryParse(text);
                  if (newValue != null && newValue >= min && newValue <= max && enabled) {
                    onChanged(newValue);
                  }
                },
                enabled: enabled,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildNumberField(
    String label,
    String value,
    Function(String) onChanged,
  ) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      controller: TextEditingController(text: value),
      onChanged: onChanged,
    );
  }
  
  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
  
  void _runAutoDesign() {
    if (_selectedModule == null || _selectedInverter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a module and inverter first')),
      );
      return;
    }
    
    // Calculate how many kW we need
    final targetWattage = _systemCapacity * 1000;
    
    // Calculate optimal modules in series based on inverter voltage window
    final optimalModulesInSeries = PVArray.calculateOptimalModulesInSeries(
      module: _selectedModule!,
      inverter: _selectedInverter!,
    );
    
    if (optimalModulesInSeries <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected module and inverter are not compatible')),
      );
      return;
    }
    
    // Calculate how many strings we need to reach target capacity
    final stringPower = _selectedModule!.powerRating * optimalModulesInSeries;
    final requiredStrings = (targetWattage / stringPower).ceil();
    
    // Calculate actual system capacity
    final actualCapacity = _selectedModule!.powerRating * optimalModulesInSeries * requiredStrings / 1000;
    
    // Calculate DC/AC ratio
    final dcAcRatio = (actualCapacity * 1000) / _selectedInverter!.ratedPowerAC;
    
    // Check if we need multiple inverters
    final inverterCount = (actualCapacity * 1000 / _selectedInverter!.ratedPowerAC).ceil();
    
    // Store the results
    setState(() {
      _autoDesignResults = {
        'capacity': actualCapacity,
        'moduleCount': optimalModulesInSeries * requiredStrings,
        'modulesInSeries': optimalModulesInSeries,
        'stringsInParallel': requiredStrings,
        'dcAcRatio': dcAcRatio,
        'inverterCount': inverterCount,
      };
      
      // Update system configuration
      _modulesInSeries = optimalModulesInSeries;
      _stringsInParallel = requiredStrings;
    });
  }
  
  void _completeWizard() {
    // In a real app, we would update the project with the new system configuration
    // For now, just call the onComplete callback
    widget.onComplete(widget.project);
  }
}