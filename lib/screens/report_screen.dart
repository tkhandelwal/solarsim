// lib/screens/report_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solarsim/models/project.dart';
import 'package:solarsim/providers/projects_provider.dart';
import 'package:intl/intl.dart';
// Import other necessary providers and models

class ReportScreen extends ConsumerWidget {
  final String reportId;
  
  const ReportScreen({
    super.key,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectProvider(reportId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulation Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // In a real app, this would share the report
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality would be implemented here')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // In a real app, this would download the report as PDF
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF export would be implemented here')),
              );
            },
          ),
        ],
      ),
      body: projectAsync.when(
        data: (project) => _buildReportContent(context, project),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
  
  Widget _buildReportContent(BuildContext context, Project project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulation Results: ${project.name}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generated on ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSummaryRow('System Type', _getSystemTypeLabel(project.systemType)),
                  _buildSummaryRow('Location', project.location.address),
                  _buildSummaryRow('PV Capacity', '40 kWp'),
                  _buildSummaryRow('Inverter Capacity', '35 kW'),
                  _buildSummaryRow('Annual Energy Production', '62,450 kWh'),
                  _buildSummaryRow('Specific Yield', '1,561 kWh/kWp'),
                  _buildSummaryRow('Performance Ratio', '84.2%'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Energy production chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Energy Production',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Placeholder for chart
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Monthly production chart would be displayed here'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Table with monthly values
                  _buildMonthlyProductionTable(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // System losses chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Losses',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Placeholder for losses chart
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text('System losses chart would be displayed here'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Financial analysis
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Analysis',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSummaryRow('System Cost', '\$40,000'),
                  _buildSummaryRow('Annual Revenue', '\$7,494'),
                  _buildSummaryRow('Levelized Cost of Energy (LCOE)', '\$0.067/kWh'),
                  _buildSummaryRow('Payback Period', '5.3 years'),
                  _buildSummaryRow('Net Present Value (NPV)', '\$72,450'),
                  _buildSummaryRow('Internal Rate of Return (IRR)', '18.7%'),
                  
                  const SizedBox(height: 16),
                  
                  // Placeholder for cashflow chart
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Cash flow chart would be displayed here'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
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
  
  Widget _buildMonthlyProductionTable() {
    return Table(
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 1,
      ),
      columnWidths: const {
        0: FlexColumnWidth(1.5),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
          ),
          children: [
            _buildTableCell('Month', isHeader: true),
            _buildTableCell('Energy (kWh)', isHeader: true),
            _buildTableCell('Irradiation (kWh/m²)', isHeader: true),
            _buildTableCell('PR (%)', isHeader: true),
          ],
        ),
        // Data rows - this would normally be generated from actual data
        _buildMonthRow('January', '3,450', '85.2', '83.1'),
        _buildMonthRow('February', '3,980', '98.6', '83.5'),
        _buildMonthRow('March', '5,210', '128.4', '84.1'),
        _buildMonthRow('April', '5,890', '143.7', '84.6'),
        _buildMonthRow('May', '6,450', '156.3', '85.2'),
        _buildMonthRow('June', '6,780', '163.5', '85.5'),
        _buildMonthRow('July', '6,920', '167.2', '85.3'),
        _buildMonthRow('August', '6,630', '160.5', '85.2'),
        _buildMonthRow('September', '5,980', '144.8', '84.8'),
        _buildMonthRow('October', '4,780', '116.9', '84.5'),
        _buildMonthRow('November', '3,450', '85.3', '83.7'),
        _buildMonthRow('December', '2,930', '73.2', '83.2'),
        // Total row
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
          ),
          children: [
            _buildTableCell('Total/Average', isHeader: true),
            _buildTableCell('62,450', isHeader: true),
            _buildTableCell('1,523.6', isHeader: true),
            _buildTableCell('84.2', isHeader: true),
          ],
        ),
      ],
    );
  }
  
  TableRow _buildMonthRow(String month, String energy, String irradiation, String pr) {
    return TableRow(
      children: [
        _buildTableCell(month),
        _buildTableCell(energy),
        _buildTableCell(irradiation),
        _buildTableCell(pr),
      ],
    );
  }
  
  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
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
}