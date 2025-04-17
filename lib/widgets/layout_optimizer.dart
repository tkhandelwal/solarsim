// lib/widgets/layout_optimizer.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class LayoutOptimizer extends StatefulWidget {
  final double availableArea;
  final double areaWidth;
  final double areaLength;
  
  const LayoutOptimizer({
    super.key,
    required this.availableArea,
    required this.areaWidth,
    required this.areaLength,
  });

  @override
  State<LayoutOptimizer> createState() => _LayoutOptimizerState();
}

class _LayoutOptimizerState extends State<LayoutOptimizer> {
  double _moduleWidth = 1.0;
  double _moduleLength = 1.7;
  double _moduleSpacingVertical = 0.1;
  double _moduleSpacingHorizontal = 0.05;
  int _orientation = 0; // 0: Portrait, 1: Landscape
  int _rowsPerTable = 1;
  double _tableSpacing = 2.0;
  
  @override
  Widget build(BuildContext context) {
    // Calculate optimized layout
    final layout = _calculateOptimizedLayout();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layout Optimizer',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        
        // Module parameters
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Module Parameters',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        'Module Width (m)',
                        _moduleWidth.toString(),
                        (value) {
                          setState(() {
                            _moduleWidth = double.tryParse(value) ?? _moduleWidth;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildNumberField(
                        'Module Length (m)',
                        _moduleLength.toString(),
                        (value) {
                          setState(() {
                            _moduleLength = double.tryParse(value) ?? _moduleLength;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        'Vertical Spacing (m)',
                        _moduleSpacingVertical.toString(),
                        (value) {
                          setState(() {
                            _moduleSpacingVertical = double.tryParse(value) ?? _moduleSpacingVertical;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildNumberField(
                        'Horizontal Spacing (m)',
                        _moduleSpacingHorizontal.toString(),
                        (value) {
                          setState(() {
                            _moduleSpacingHorizontal = double.tryParse(value) ?? _moduleSpacingHorizontal;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(
                      value: 0,
                      label: Text('Portrait'),
                      icon: Icon(Icons.stay_current_portrait),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      label: Text('Landscape'),
                      icon: Icon(Icons.stay_current_landscape),
                    ),
                  ],
                  selected: {_orientation},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _orientation = selection.first;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Table parameters
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Table Configuration',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        'Rows per Table',
                        _rowsPerTable.toString(),
                        (value) {
                          setState(() {
                            _rowsPerTable = int.tryParse(value) ?? _rowsPerTable;
                            if (_rowsPerTable < 1) _rowsPerTable = 1;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildNumberField(
                        'Table Spacing (m)',
                        _tableSpacing.toString(),
                        (value) {
                          setState(() {
                            _tableSpacing = double.tryParse(value) ?? _tableSpacing;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Layout results
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Optimized Layout',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                // Layout visualization
                AspectRatio(
                  aspectRatio: widget.areaWidth / widget.areaLength,
                  child: LayoutVisualization(
                    areaWidth: widget.areaWidth,
                    areaLength: widget.areaLength,
                    moduleWidth: _orientation == 0 ? _moduleWidth : _moduleLength,
                    moduleLength: _orientation == 0 ? _moduleLength : _moduleWidth,
                    moduleSpacingHorizontal: _moduleSpacingHorizontal,
                    moduleSpacingVertical: _moduleSpacingVertical,
                    rowsPerTable: _rowsPerTable,
                    tableSpacing: _tableSpacing,
                    modulesPerRow: layout['modulesPerRow'],
                    tables: layout['tables'],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Layout metrics
                Column(
                  children: [
                    _buildMetricRow('Number of modules', '${layout['totalModules']}'),
                    _buildMetricRow('Modules per row', '${layout['modulesPerRow']}'),
                    _buildMetricRow('Number of tables', '${layout['tables']}'),
                    _buildMetricRow('Total PV capacity', '${layout['capacity'].toStringAsFixed(2)} kWp'),
                    _buildMetricRow('Coverage ratio', '${(layout['coverageRatio'] * 100).toStringAsFixed(1)}%'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Map<String, dynamic> _calculateOptimizedLayout() {
    // Calculate effective module dimensions based on orientation
    final effectiveModuleWidth = _orientation == 0 ? _moduleWidth : _moduleLength;
    final effectiveModuleLength = _orientation == 0 ? _moduleLength : _moduleWidth;
    
    // Calculate how many modules fit in a row
    final modulesPerRow = ((widget.areaWidth + _moduleSpacingHorizontal) / 
                        (effectiveModuleWidth + _moduleSpacingHorizontal)).floor();
    
    // Calculate total height of one table
    final tableHeight = _rowsPerTable * effectiveModuleLength + 
                      (_rowsPerTable - 1) * _moduleSpacingVertical;
    
    // Calculate how many tables fit
    final tables = ((widget.areaLength + _tableSpacing) / 
                  (tableHeight + _tableSpacing)).floor();
    
    // Calculate total modules
    final totalModules = modulesPerRow * _rowsPerTable * tables;
    
    // Calculate capacity (assuming 400W modules)
    final capacity = totalModules * 0.4; // kWp
    
    // Calculate coverage ratio
    final moduleArea = effectiveModuleWidth * effectiveModuleLength;
    final totalModuleArea = totalModules * moduleArea;
    final coverageRatio = totalModuleArea / widget.availableArea;
    
    return {
      'modulesPerRow': modulesPerRow,
      'tables': tables,
      'totalModules': totalModules,
      'capacity': capacity,
      'coverageRatio': coverageRatio,
    };
  }
  
  Widget _buildMetricRow(String label, String value) {
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
  
  Widget _buildNumberField(
    String label,
    String value,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          keyboardType: TextInputType.number,
          controller: TextEditingController(text: value),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class LayoutVisualization extends StatelessWidget {
  final double areaWidth;
  final double areaLength;
  final double moduleWidth;
  final double moduleLength;
  final double moduleSpacingHorizontal;
  final double moduleSpacingVertical;
  final int rowsPerTable;
  final double tableSpacing;
  final int modulesPerRow;
  final int tables;
  
  const LayoutVisualization({
    super.key,
    required this.areaWidth,
    required this.areaLength,
    required this.moduleWidth,
    required this.moduleLength,
    required this.moduleSpacingHorizontal,
    required this.moduleSpacingVertical,
    required this.rowsPerTable,
    required this.tableSpacing,
    required this.modulesPerRow,
    required this.tables,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        border: Border.all(color: Colors.black),
      ),
      child: CustomPaint(
        painter: LayoutPainter(
          areaWidth: areaWidth,
          areaLength: areaLength,
          moduleWidth: moduleWidth,
          moduleLength: moduleLength,
          moduleSpacingHorizontal: moduleSpacingHorizontal,
          moduleSpacingVertical: moduleSpacingVertical,
          rowsPerTable: rowsPerTable,
          tableSpacing: tableSpacing,
          modulesPerRow: modulesPerRow,
          tables: tables,
        ),
      ),
    );
  }
}

class LayoutPainter extends CustomPainter {
  final double areaWidth;
  final double areaLength;
  final double moduleWidth;
  final double moduleLength;
  final double moduleSpacingHorizontal;
  final double moduleSpacingVertical;
  final int rowsPerTable;
  final double tableSpacing;
  final int modulesPerRow;
  final int tables;
  
  LayoutPainter({
    required this.areaWidth,
    required this.areaLength,
    required this.moduleWidth,
    required this.moduleLength,
    required this.moduleSpacingHorizontal,
    required this.moduleSpacingVertical,
    required this.rowsPerTable,
    required this.tableSpacing,
    required this.modulesPerRow,
    required this.tables,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / areaWidth, size.height / areaLength);
    
    // Draw area border
    final areaPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, areaWidth * scale, areaLength * scale),
      areaPaint,
    );
    
    // Draw modules
    final modulePaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.fill;
    
    final moduleBorderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    for (int tableIndex = 0; tableIndex < tables; tableIndex++) {
      final tableY = tableIndex * (rowsPerTable * moduleLength + 
                             (rowsPerTable - 1) * moduleSpacingVertical + 
                             tableSpacing);
      
      for (int rowIndex = 0; rowIndex < rowsPerTable; rowIndex++) {
        final rowY = tableY + rowIndex * (moduleLength + moduleSpacingVertical);
        
        for (int moduleIndex = 0; moduleIndex < modulesPerRow; moduleIndex++) {
          final moduleX = moduleIndex * (moduleWidth + moduleSpacingHorizontal);
          
          final moduleRect = Rect.fromLTWH(
            moduleX * scale,
            rowY * scale,
            moduleWidth * scale,
            moduleLength * scale,
          );
          
          canvas.drawRect(moduleRect, modulePaint);
          canvas.drawRect(moduleRect, moduleBorderPaint);
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}