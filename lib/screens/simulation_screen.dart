// lib/screens/simulation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:solarsim/models/project.dart';
import 'package:solarsim/providers/projects_provider.dart';
import 'package:solarsim/providers/simulation_provider.dart';
import 'package:solarsim/widgets/module_selection_dialog.dart';
import 'package:solarsim/widgets/inverter_selection_dialog.dart';



// Import other necessary models and providers

class SimulationScreen extends ConsumerStatefulWidget {
  final String simulationId;
  
  const SimulationScreen({
    super.key,
    required this.simulationId,
  });

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSimulating = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectProvider(widget.simulationId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulation'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Parameters'),
            Tab(text: 'System'),
            Tab(text: 'Weather'),
            Tab(text: 'Results'),
          ],
        ),
      ),
      body: projectAsync.when(
        data: (project) => _buildSimulationContent(context, project),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSimulating ? null : () => _runSimulation(context),
        icon: _isSimulating 
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.play_arrow),
        label: Text(_isSimulating ? 'Simulating...' : 'Run Simulation'),
        backgroundColor: _isSimulating ? Colors.grey : null,
      ),
    );
  }
  
  Widget _buildSimulationContent(BuildContext context, Project project) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildParametersTab(context, project),
        _buildSystemTab(context, project),
        _buildWeatherTab(context, project),
        _buildResultsTab(context, project),
      ],
    );
  }
  
  Widget _buildParametersTab(BuildContext context, Project project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulation Parameters',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Simulation period
                  _buildParameterSection(
                    context,
                    'Simulation Period',
                    [
                      _buildDropdownField(
                        'Period Type',
                        'Annual',
                        ['Annual', 'Monthly', 'Daily', 'Hourly'],
                        (value) {},
                      ),
                      _buildDropdownField(
                        'Year',
                        '2025',
                        ['2024', '2025', '2026'],
                        (value) {},
                      ),
                    ],
                  ),
                  
                  const Divider(),
                  
                  // Orientation parameters
                  _buildParameterSection(
                    context,
                    'Module Orientation',
                    [
                      _buildDropdownField(
                        'Tracking Type',
                        'Fixed',
                        ['Fixed', 'Single-Axis', 'Dual-Axis'],
                        (value) {},
                      ),
                      _buildSliderField(
                        'Tilt Angle (°)',
                        20,
                        0,
                        90,
                      ),
                      _buildSliderField(
                        'Azimuth (°)',
                        180,
                        0,
                        360,
                      ),
                    ],
                  ),
                  
                  const Divider(),
                  
                  // Loss parameters
                  _buildParameterSection(
                    context,
                    'System Losses',
                    [
                      _buildSliderField(
                        'Soiling Loss (%)',
                        2,
                        0,
                        10,
                      ),
                      _buildSliderField(
                        'Shading Loss (%)',
                        3,
                        0,
                        20,
                      ),
                      _buildSliderField(
                        'Mismatch Loss (%)',
                        2,
                        0,
                        5,
                      ),
                      _buildSliderField(
                        'DC Wiring Loss (%)',
                        2,
                        0,
                        5,
                      ),
                      _buildSliderField(
                        'AC Wiring Loss (%)',
                        1,
                        0,
                        5,
                      ),
                    ],
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
                    'Financial Parameters',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildNumberField(
                    'System Cost (USD)',
                    '10000',
                    (value) {},
                  ),
                  _buildNumberField(
                    'Electricity Price (USD/kWh)',
                    '0.12',
                    (value) {},
                  ),
                  _buildSliderField(
                    'Discount Rate (%)',
                    4,
                    0,
                    10,
                  ),
                  _buildNumberField(
                    'Project Lifetime (years)',
                    '25',
                    (value) {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSystemTab(BuildContext context, Project project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PV Modules',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Module selection - in a real app, this would be a dropdown
                  // with a database of modules
                  ListTile(
                    title: const Text('Select Module'),
                    subtitle: const Text('No module selected'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ModuleSelectionDialog(
                            onModuleSelected: (module) {
                              // Handle selected module
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Selected module: ${module.manufacturer} ${module.model}'),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      child: const Text('Select'),
                    ),
                  ),
                  
                  const Divider(),
                  
                  // Module configuration
                  _buildNumberField(
                    'Modules in Series',
                    '10',
                    (value) {},
                  ),
                  _buildNumberField(
                    'Strings in Parallel',
                    '4',
                    (value) {},
                  ),
                  const Divider(),
                  
                  // Module information display - empty for now
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Module information will be displayed here'),
                    ),
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
                    'Inverters',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Inverter selection
                  ListTile(
                    title: const Text('Select Inverter'),
                    subtitle: const Text('No inverter selected'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => InverterSelectionDialog(
                            onInverterSelected: (inverter) {
                              // Handle selected inverter
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Selected inverter: ${inverter.manufacturer} ${inverter.model}'),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      child: const Text('Select'),
                    ),
                  ),
                  
                  const Divider(),
                  
                  // Inverter configuration
                  _buildNumberField(
                    'Number of Inverters',
                    '1',
                    (value) {},
                  ),
                  
                  const Divider(),
                  
                  // Inverter information display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Inverter information will be displayed here'),
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
  
  Widget _buildWeatherTab(BuildContext context, Project project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weather Data Source',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDropdownField(
                    'Data Source',
                    'Synthetic',
                    ['Synthetic', 'Import TMY3', 'Import CSV', 'Weather API'],
                    (value) {},
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Location information
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
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
                        Text(project.location.address),
                        Text('Lat: ${project.location.latitude.toStringAsFixed(4)}, Long: ${project.location.longitude.toStringAsFixed(4)}'),
                        Text('Time Zone: ${project.location.timeZone}'),
                      ],
                    ),
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
                    'Monthly Irradiation Data',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Simple bar chart placeholder
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Irradiation chart would be displayed here'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Temperature data
                  Text(
                    'Monthly Temperature Data',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Temperature chart would be displayed here'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultsTab(BuildContext context, Project project) {
    final simulationAsync = ref.watch(runSimulationProvider(widget.simulationId));
    
    return simulationAsync.when(
      data: (simulationResult) {
        // Show simulation results
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Simulation Results',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              // Energy production overview
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Energy Production',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildInfoRow('Annual Energy', '${simulationResult.annualEnergy.toStringAsFixed(0)} kWh'),
                      _buildInfoRow('Performance Ratio', '${(simulationResult.performanceRatio * 100).toStringAsFixed(1)}%'),
                      
                      const SizedBox(height: 16),
                      
                      // Placeholder for chart
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text('Monthly energy chart would be displayed here'),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Financial overview
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial Overview',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildInfoRow('LCOE', '\$${simulationResult.financialMetrics['lcoe']?.toStringAsFixed(3)}/kWh'),
                      _buildInfoRow('Payback Period', '${simulationResult.financialMetrics['paybackPeriod']?.toStringAsFixed(1)} years'),
                      _buildInfoRow('NPV', '\$${simulationResult.financialMetrics['npv']?.toStringAsFixed(0)}'),
                      _buildInfoRow('IRR', '${((simulationResult.financialMetrics['irr'] ?? 0) * 100).toStringAsFixed(1)}%'),
                      
                      const SizedBox(height: 16),
                      
                      ElevatedButton.icon(
                        icon: const Icon(Icons.assignment),
                        label: const Text('View Detailed Report'),
                        onPressed: () {
                          context.go('/report/${widget.simulationId}');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Simulation Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'An error occurred while running the simulation.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: () => _runSimulation(context),
            ),
          ],
        ),
      ),
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
    );
  }
  
  Widget _buildParameterSection(
    BuildContext context,
    String title,
    List<Widget> fields,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...fields,
      ],
    );
  }
  
  Widget _buildDropdownField(
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(label),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
              ),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSliderField(
    String label,
    double value,
    double min,
    double max,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(value.toStringAsFixed(1)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 10).toInt(),
            label: value.toStringAsFixed(1),
            onChanged: (newValue) {
              // In a real app, update state here
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildNumberField(
    String label,
    String value,
    Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        controller: TextEditingController(text: value),
        onChanged: onChanged,
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  void _runSimulation(BuildContext context) {
    setState(() {
      _isSimulating = true;
    });
    
    // Call the actual simulation service using the provider
    ref.read(runSimulationProvider(widget.simulationId).future).then(
      (simulationResult) {
        setState(() {
          _isSimulating = false;
        });
        
        // Navigate to the results tab
        _tabController.animateTo(3);
        
        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simulation completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      },
      onError: (error) {
        setState(() {
          _isSimulating = false;
        });
        
        // Show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Simulation failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }
}