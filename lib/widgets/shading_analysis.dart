// lib/widgets/shading_analysis.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ShadingAnalysisView extends StatefulWidget {
  final double latitude;
  final double longitude;
  
  const ShadingAnalysisView({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<ShadingAnalysisView> createState() => _ShadingAnalysisViewState();
}

class _ShadingAnalysisViewState extends State<ShadingAnalysisView> {
  // Parameters for the sun path chart
  final double _maxSolarElevation = 90;
  final double _minSolarElevation = 0;
  final double _maxSolarAzimuth = 360;
  
  // Times of the year for analysis
  final List<String> _analysisMonths = ['Dec', 'Mar', 'Jun'];
  
  // Selected time for analysis
  String _selectedMonth = 'Mar';
  
  // List to track shading objects
  final List<ShadingObject> _shadingObjects = [];
  
  // Add method to add a new shading object
  void _addShadingObject() {
    // Show dialog to add shading object
    showDialog(
      context: context,
      builder: (context) => ShadingObjectDialog(
        onSave: (shadingObject) {
          setState(() {
            _shadingObjects.add(shadingObject);
          });
        },
      ),
    );
  }
  
  // Add method to edit an existing shading object
  void _editShadingObject(int index) {
    showDialog(
      context: context,
      builder: (context) => ShadingObjectDialog(
        initialObject: _shadingObjects[index],
        onSave: (shadingObject) {
          setState(() {
            _shadingObjects[index] = shadingObject;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shading Analysis',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        
        // Controls for time selection
        Row(
          children: [
            const Text('Select time of year:'),
            const SizedBox(width: 16),
            SegmentedButton<String>(
              segments: _analysisMonths.map((month) {
                return ButtonSegment<String>(
                  value: month,
                  label: Text(month),
                );
              }).toList(),
              selected: {_selectedMonth},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedMonth = selection.first;
                });
              },
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Sun path chart
        AspectRatio(
          aspectRatio: 1.6,
          child: SunPathChart(
            latitude: widget.latitude,
            month: _analysisMonths.indexOf(_selectedMonth) * 3 + 1, // Convert to month number
            shadingObjects: _shadingObjects,
            // Pass the parameters to the SunPathChart
            maxSolarElevation: _maxSolarElevation,
            minSolarElevation: _minSolarElevation, 
            maxSolarAzimuth: _maxSolarAzimuth,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Shading objects editor
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shading Objects',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                
                // List of shading objects
                _buildShadingObjectList(),
                
                const SizedBox(height: 8),
                
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Shading Object'),
                  onPressed: _addShadingObject,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Impact on energy production
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shading Impact',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                
                Builder(builder: (context) {
                  // Calculate shading loss
                  final shadingLoss = _calculateShadingLoss();
                  const annualProduction = 10000.0; // kWh, replace with actual system production
                  final energyReduction = annualProduction * shadingLoss;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Shading loss: ${(shadingLoss * 100).toStringAsFixed(1)}%'),
                      const SizedBox(height: 4),
                      Text('Annual energy reduction: ${energyReduction.toStringAsFixed(0)} kWh'),
                    ],
                  );
                }),
                
                const SizedBox(height: 16),
                
                // Monthly impact chart placeholder
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Monthly shading impact chart would be displayed here'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildShadingObjectList() {
    if (_shadingObjects.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No shading objects added. Click "Add Shading Object" to begin.'),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _shadingObjects.length,
      itemBuilder: (context, index) {
        final object = _shadingObjects[index];
        return _buildShadingObjectItem(
          object.name,
          object.getDetailsString(),
          index,
        );
      },
    );
  }
  
  Widget _buildShadingObjectItem(String name, String details, int index) {
    return ListTile(
      leading: const Icon(Icons.filter_hdr),
      title: Text(name),
      subtitle: Text(details),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editShadingObject(index),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              setState(() {
                _shadingObjects.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }
  
  double _calculateShadingLoss() {
    // This is a simplified calculation
    // In a real implementation, you would:
    // 1. Calculate solar position for each hour of the year
    // 2. Check if each position is shaded by objects
    // 3. Sum up the potential production for all hours
    // 4. Calculate the percentage loss due to shading
    
    double totalPotentialEnergy = 0;
    double shadedEnergy = 0;
    
    // For each month
    for (int month = 1; month <= 12; month++) {
      // Number of days in month
      final daysInMonth = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month];
      
      // For each hour of a typical day in this month
      for (int hour = 6; hour <= 18; hour++) {
        final declination = 23.45 * math.sin((month - 3) * 30 * math.pi / 180);
        final hourAngle = (hour - 12) * 15;
        
        // Calculate solar position
        final sinElevation = math.sin(widget.latitude * math.pi / 180) * math.sin(declination * math.pi / 180) +
                           math.cos(widget.latitude * math.pi / 180) * math.cos(declination * math.pi / 180) *
                           math.cos(hourAngle * math.pi / 180);
        
        final elevation = math.asin(sinElevation) * 180 / math.pi;
        
        if (elevation <= 0) continue; // Sun below horizon
        
        final sinAzimuth = -math.cos(declination * math.pi / 180) * 
                          math.sin(hourAngle * math.pi / 180) /
                          math.cos(elevation * math.pi / 180);
                          
        final cosAzimuth = (math.sin(declination * math.pi / 180) * math.cos(widget.latitude * math.pi / 180) -
                          math.cos(declination * math.pi / 180) * math.sin(widget.latitude * math.pi / 180) *
                          math.cos(hourAngle * math.pi / 180)) /
                          math.cos(elevation * math.pi / 180);
                          
        var azimuth = math.atan2(sinAzimuth, cosAzimuth) * 180 / math.pi;
        if (azimuth < 0) azimuth += 360;
        
        // Estimate energy for this hour
        // This is a simplification - real calculation would use the solar radiation model
        final hourlyEnergy = math.max(0, math.sin(elevation * math.pi / 180)) * daysInMonth;
        totalPotentialEnergy += hourlyEnergy;
        
        // Check if this position is shaded
        bool isShaded = false;
        for (final object in _shadingObjects) {
          if (_isSolarPositionShaded(elevation, azimuth, object)) {
            isShaded = true;
            break;
          }
        }
        
        if (isShaded) {
          shadedEnergy += hourlyEnergy;
        }
      }
    }
    
    // Calculate shading loss percentage
    return totalPotentialEnergy > 0 ? shadedEnergy / totalPotentialEnergy : 0;
  }
  
  bool _isSolarPositionShaded(double elevation, double azimuth, ShadingObject object) {
    switch (object.type) {
      case ShadingObjectType.tree:
      case ShadingObjectType.pole:
      case ShadingObjectType.building:
        final objectElevation = math.atan(object.height / object.distance) * 180 / math.pi;
        
        // For buildings with width
        if (object.type == ShadingObjectType.building && object.width != null) {
          final angularWidth = math.atan(object.width! / (2 * object.distance)) * 180 / math.pi * 2;
          final azimuthStart = object.azimuth - angularWidth / 2;
          final azimuthEnd = object.azimuth + angularWidth / 2;
          
          return elevation <= objectElevation && 
                 azimuth >= azimuthStart && 
                 azimuth <= azimuthEnd;
        }
        
        // For point objects
        const angularSize = 2.0; // Approximate angular size in degrees
        return elevation <= objectElevation && 
               (azimuth >= object.azimuth - angularSize && 
                azimuth <= object.azimuth + angularSize);
        
      case ShadingObjectType.mountain:
      case ShadingObjectType.horizon:
        return elevation <= (object.elevationAngle ?? 0) &&
               azimuth >= (object.azimuthStart ?? 0) && 
               azimuth <= (object.azimuthEnd ?? 0);
    }
  }
}

class SunPathChart extends StatelessWidget {
  final double latitude;
  final int month;
  final List<ShadingObject> shadingObjects;
  final double maxSolarElevation;
  final double minSolarElevation;
  final double maxSolarAzimuth;
  
  const SunPathChart({
    super.key,
    required this.latitude,
    required this.month,
    required this.shadingObjects,
    required this.maxSolarElevation,
    required this.minSolarElevation,
    required this.maxSolarAzimuth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: CustomPaint(
        painter: SunPathPainter(
          latitude: latitude,
          month: month,
          shadingObjects: shadingObjects,
          maxSolarElevation: maxSolarElevation,
          minSolarElevation: minSolarElevation,
          maxSolarAzimuth: maxSolarAzimuth,
        ),
      ),
    );
  }
}

class SunPathPainter extends CustomPainter {
  final double latitude;
  final int month;
  final List<ShadingObject> shadingObjects;
  final double maxSolarElevation;
  final double minSolarElevation;
  final double maxSolarAzimuth;
  
  // Sun path chart parameters
  final double _maxSolarElevation = 90;
  final double _minSolarElevation = 0;
  final double _maxSolarAzimuth = 360;
  
  SunPathPainter({
    required this.latitude,
    required this.month,
    required this.shadingObjects,
    required this.maxSolarElevation,
    required this.minSolarElevation,
    required this.maxSolarAzimuth,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    
    // Draw the horizon circle
    final horizonPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, radius, horizonPaint);
    
    // Draw the cardinal directions
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    _drawCardinalDirection(canvas, center, radius, 0, 'N', textPainter);
    _drawCardinalDirection(canvas, center, radius, 90, 'E', textPainter);
    _drawCardinalDirection(canvas, center, radius, 180, 'S', textPainter);
    _drawCardinalDirection(canvas, center, radius, 270, 'W', textPainter);
    
    // Draw elevation circles
    for (int elevation = 15; elevation < 90; elevation += 15) {
      final elevationRadius = radius * (1 - elevation / 90);
      final elevationPaint = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      
      canvas.drawCircle(center, elevationRadius, elevationPaint);
      
      // Draw elevation labels
      textPainter.text = TextSpan(
        text: '$elevation°',
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center.dx + 5, center.dy - elevationRadius - textPainter.height),
      );
    }
    
    // Draw azimuth lines
    for (int azimuth = 0; azimuth < 360; azimuth += 30) {
      final radians = azimuth * math.pi / 180;
      final x = center.dx + radius * math.sin(radians);
      final y = center.dy - radius * math.cos(radians);
      
      final azimuthPaint = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      
      canvas.drawLine(center, Offset(x, y), azimuthPaint);
    }
    
    // Draw sun path for solstices and equinox
    _drawSunPath(canvas, center, radius, 21); // Summer solstice
    _drawSunPath(canvas, center, radius, 12); // Spring/Fall equinox
    _drawSunPath(canvas, center, radius, 3);  // Winter solstice
    
    // Draw sun positions at different hours for the selected month
    _drawSunPositions(canvas, center, radius, month);
    
    // Draw legend
    _drawLegend(canvas, size);
    
    // Draw shading objects
    _drawShadingObjects(canvas, center, radius, shadingObjects);
  }
  
  void _drawCardinalDirection(
    Canvas canvas, 
    Offset center, 
    double radius, 
    double degrees, 
    String label,
    TextPainter textPainter,
  ) {
    final radians = degrees * math.pi / 180;
    final x = center.dx + (radius + 15) * math.sin(radians);
    final y = center.dy - (radius + 15) * math.cos(radians);
    
    textPainter.text = TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }
  
  void _drawSunPath(Canvas canvas, Offset center, double radius, int month) {
    // This is a simplified approximation - in a real app, use the actual solar position algorithms
    // Calculate solar declination for the month (simplified)
    final declination = 23.45 * math.sin((month - 3) * 30 * math.pi / 180);
    
    // Solar path color based on month
    Color pathColor;
    if (month == 3) { // Winter solstice
      pathColor = Colors.blue;
    } else if (month == 12) { // Equinox
      pathColor = Colors.green;
    } else { // Summer solstice
      pathColor = Colors.red;
    }
    
    final sunPathPaint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final path = Path();
    var isFirstPoint = true;
    
    // Draw the sun path for each hour of the day
    for (double hour = 6; hour <= 18; hour += 0.5) {
      // Convert hour angle to azimuth and elevation
      final hourAngle = (hour - 12) * 15;
      
      // Simplified solar position calculation
      final sinElevation = math.sin(latitude * math.pi / 180) * math.sin(declination * math.pi / 180) +
                          math.cos(latitude * math.pi / 180) * math.cos(declination * math.pi / 180) *
                          math.cos(hourAngle * math.pi / 180);
      
      final elevation = math.asin(sinElevation) * 180 / math.pi;
      
      // Skip points below minimum elevation
      if (elevation < _minSolarElevation) continue;
      // Also cap at maximum elevation
      final clampedElevation = math.min(elevation, _maxSolarElevation);
      
      final sinAzimuth = -math.cos(declination * math.pi / 180) * 
                        math.sin(hourAngle * math.pi / 180) /
                        math.cos(elevation * math.pi / 180);
                        
      final cosAzimuth = (math.sin(declination * math.pi / 180) * math.cos(latitude * math.pi / 180) -
                        math.cos(declination * math.pi / 180) * math.sin(latitude * math.pi / 180) *
                        math.cos(hourAngle * math.pi / 180)) /
                        math.cos(elevation * math.pi / 180);
                        
      var azimuth = math.atan2(sinAzimuth, cosAzimuth) * 180 / math.pi;
      
      if (azimuth < 0) {
        azimuth += 360;
      }
      
      // Skip points beyond maximum azimuth
      if (azimuth > _maxSolarAzimuth) continue;
      
      // Convert to chart coordinates
      final chartRadius = radius * (1 - clampedElevation / _maxSolarElevation);
      final x = center.dx + chartRadius * math.sin(azimuth * math.pi / 180);
      final y = center.dy - chartRadius * math.cos(azimuth * math.pi / 180);
      
      if (isFirstPoint) {
        path.moveTo(x, y);
        isFirstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, sunPathPaint);
  }
  
  void _drawSunPositions(Canvas canvas, Offset center, double radius, int month) {
    // For the selected month, draw sun positions at different hours
    final declination = 23.45 * math.sin((month - 3) * 30 * math.pi / 180);
    
    for (int hour = 6; hour <= 18; hour += 2) {
      // Convert hour angle to azimuth and elevation
      final hourAngle = (hour - 12) * 15;
      
      // Simplified solar position calculation (same as in _drawSunPath)
      final sinElevation = math.sin(latitude * math.pi / 180) * math.sin(declination * math.pi / 180) +
                          math.cos(latitude * math.pi / 180) * math.cos(declination * math.pi / 180) *
                          math.cos(hourAngle * math.pi / 180);
      
      final elevation = math.asin(sinElevation) * 180 / math.pi;
      
      if (elevation <= _minSolarElevation) continue;
      
      final sinAzimuth = -math.cos(declination * math.pi / 180) * 
                        math.sin(hourAngle * math.pi / 180) /
                        math.cos(elevation * math.pi / 180);
                        
      final cosAzimuth = (math.sin(declination * math.pi / 180) * math.cos(latitude * math.pi / 180) -
                        math.cos(declination * math.pi / 180) * math.sin(latitude * math.pi / 180) *
                        math.cos(hourAngle * math.pi / 180)) /
                        math.cos(elevation * math.pi / 180);
                        
      var azimuth = math.atan2(sinAzimuth, cosAzimuth) * 180 / math.pi;
      
      if (azimuth < 0) {
        azimuth += 360;
      }
      
      if (azimuth > _maxSolarAzimuth) continue;
      
      // Convert to chart coordinates
      final chartRadius = radius * (1 - math.min(elevation, _maxSolarElevation) / _maxSolarElevation);
      final x = center.dx + chartRadius * math.sin(azimuth * math.pi / 180);
      final y = center.dy - chartRadius * math.cos(azimuth * math.pi / 180);
      
      // Draw sun position marker
      final sunPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), 4, sunPaint);
      
      // Draw hour label
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$hour:00',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + 5, y - textPainter.height / 2),
      );
    }
  }
  
  void _drawLegend(Canvas canvas, Size size) {
    final legendPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Winter solstice
    legendPaint.color = Colors.blue;
    canvas.drawLine(
      Offset(20, size.height - 40),
      Offset(40, size.height - 40),
      legendPaint,
    );
    
    textPainter.text = const TextSpan(
      text: 'Winter Solstice (Dec 21)',
      style: TextStyle(color: Colors.black, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(45, size.height - 45));
    
    // Equinox
    legendPaint.color = Colors.green;
    canvas.drawLine(
      Offset(20, size.height - 25),
      Offset(40, size.height - 25),
      legendPaint,
    );
    
    textPainter.text = const TextSpan(
      text: 'Equinox (Mar/Sep 21)',
      style: TextStyle(color: Colors.black, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(45, size.height - 30));
    
    // Summer solstice
    legendPaint.color = Colors.red;
    canvas.drawLine(
      Offset(20, size.height - 10),
      Offset(40, size.height - 10),
      legendPaint,
    );
    
    textPainter.text = const TextSpan(
      text: 'Summer Solstice (Jun 21)',
      style: TextStyle(color: Colors.black, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(45, size.height - 15));
  }
  
  void _drawShadingObjects(Canvas canvas, Offset center, double radius, List<ShadingObject> shadingObjects) {
    for (final object in shadingObjects) {
      switch (object.type) {
        case ShadingObjectType.tree:
        case ShadingObjectType.pole:
        case ShadingObjectType.building:
          _drawObjectWithElevation(canvas, center, radius, object);
          break;
        case ShadingObjectType.mountain:
        case ShadingObjectType.horizon:
          _drawHorizonProfile(canvas, center, radius, object);
          break;
      }
    }
  }

  void _drawObjectWithElevation(Canvas canvas, Offset center, double radius, ShadingObject object) {
  // Calculate the angular height (elevation) of the object
  final elevationAngle = math.atan(object.height / object.distance) * 180 / math.pi;
  
  // Calculate the azimuth range for the object (for buildings with width)
  double azimuthStart = object.azimuth;
  double azimuthEnd = object.azimuth;
  
  if (object.type == ShadingObjectType.building && object.width != null) {
    // Calculate angular width
    final angularWidth = math.atan(object.width! / (2 * object.distance)) * 180 / math.pi * 2;
    azimuthStart = object.azimuth - angularWidth / 2;
    azimuthEnd = object.azimuth + angularWidth / 2;
  }
  
  // Define the shading object color
  final shadingPaint = Paint()
    ..color = Colors.black54
    ..style = PaintingStyle.fill;
  
  // Define border paint
  final borderPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  
  // Create a path for the shading object
  final path = Path();
  
  // Calculate chart points
  final chartRadius = radius * (1 - elevationAngle / maxSolarElevation);
  
  // For point objects (trees, poles)
  if (object.type == ShadingObjectType.tree || object.type == ShadingObjectType.pole) {
    // Simple circle for trees and poles
    final x = center.dx + chartRadius * math.sin(object.azimuth * math.pi / 180);
    final y = center.dy - chartRadius * math.cos(object.azimuth * math.pi / 180);
    
    final circleSize = radius * 0.05; // Size proportional to chart
    canvas.drawCircle(Offset(x, y), circleSize, shadingPaint);
    canvas.drawCircle(Offset(x, y), circleSize, borderPaint);
  } else {
    // For buildings with width, create a segment
    final startX = center.dx + chartRadius * math.sin(azimuthStart * math.pi / 180);
    final startY = center.dy - chartRadius * math.cos(azimuthStart * math.pi / 180);
    
    // We'll remove these unused variables:
    // final endX = center.dx + chartRadius * math.sin(azimuthEnd * math.pi / 180);
    // final endY = center.dy - chartRadius * math.cos(azimuthEnd * math.pi / 180);
    
    // Path from center to start, along the arc, and back to center
    path.moveTo(center.dx, center.dy);
    path.lineTo(startX, startY);
    
    // Draw the arc
    final rect = Rect.fromCircle(center: center, radius: chartRadius);
    path.arcTo(
      rect,
      (90 - azimuthStart) * math.pi / 180, // Convert to radians and adjust for coordinate system
      (azimuthStart - azimuthEnd) * math.pi / 180, // Arc angle in radians
      false,
    );
    
    path.lineTo(center.dx, center.dy);
    path.close();
    
    canvas.drawPath(path, shadingPaint);
    canvas.drawPath(path, borderPaint);
  }
}

  void _drawHorizonProfile(Canvas canvas, Offset center, double radius, ShadingObject object) {
    // For mountains or horizon profiles
    final elevationAngle = object.elevationAngle ?? 0;
    final azimuthStart = object.azimuthStart ?? 0;
    final azimuthEnd = object.azimuthEnd ?? 0;
    
    final shadingPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    final path = Path();
    
    // Calculate chart radius
    final chartRadius = radius * (1 - elevationAngle / _maxSolarElevation);
    
    // Create a path for the mountain/horizon
    final startX = center.dx + chartRadius * math.sin(azimuthStart * math.pi / 180);
    final startY = center.dy - chartRadius * math.cos(azimuthStart * math.pi / 180);
    
    path.moveTo(center.dx, center.dy);
    path.lineTo(startX, startY);
    
    // Draw the arc
    final rect = Rect.fromCircle(center: center, radius: chartRadius);
    path.arcTo(
      rect,
      (90 - azimuthStart) * math.pi / 180,
      (azimuthStart - azimuthEnd) * math.pi / 180,
      false,
    );
    
    path.lineTo(center.dx, center.dy);
    path.close();
    
    canvas.drawPath(path, shadingPaint);
    canvas.drawPath(path, borderPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Define a class for shading objects
class ShadingObject {
  final String name;
  final ShadingObjectType type;
  final double height; // meters
  final double distance; // meters
  final double azimuth; // degrees
  final double? width; // meters, optional
  final double? elevationAngle; // degrees, optional for distant objects
  final double? azimuthStart; // degrees, optional for wide objects
  final double? azimuthEnd; // degrees, optional for wide objects
  
  ShadingObject({
    required this.name,
    required this.type,
    required this.height,
    required this.distance,
    required this.azimuth,
    this.width,
    this.elevationAngle,
    this.azimuthStart,
    this.azimuthEnd,
  });
  
  String getDetailsString() {
    switch (type) {
      case ShadingObjectType.tree:
      case ShadingObjectType.pole:
      case ShadingObjectType.building:
        return 'Height: ${height}m, Distance: ${distance}m, Azimuth: ${azimuth}°';
      case ShadingObjectType.mountain:
      case ShadingObjectType.horizon:
        return 'Elevation: ${elevationAngle}°, Azimuth range: ${azimuthStart}° - ${azimuthEnd}°';
    }
  }
}

enum ShadingObjectType {
  tree,
  pole,
  building,
  mountain,
  horizon,
}

// Dialog to add/edit shading objects
class ShadingObjectDialog extends StatefulWidget {
  final ShadingObject? initialObject;
  final Function(ShadingObject) onSave;
  
  const ShadingObjectDialog({
    Key? key,
    this.initialObject,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ShadingObjectDialog> createState() => _ShadingObjectDialogState();
}

class _ShadingObjectDialogState extends State<ShadingObjectDialog> {
  late TextEditingController _nameController;
  late ShadingObjectType _type;
  late TextEditingController _heightController;
  late TextEditingController _distanceController;
  late TextEditingController _azimuthController;
  late TextEditingController _widthController;
  late TextEditingController _elevationAngleController;
  late TextEditingController _azimuthStartController;
  late TextEditingController _azimuthEndController;
  
  @override
  void initState() {
    super.initState();
    
    final initialObject = widget.initialObject;
    _nameController = TextEditingController(text: initialObject?.name ?? '');
    _type = initialObject?.type ?? ShadingObjectType.tree;
    _heightController = TextEditingController(text: initialObject?.height.toString() ?? '10');
    _distanceController = TextEditingController(text: initialObject?.distance.toString() ?? '15');
    _azimuthController = TextEditingController(text: initialObject?.azimuth.toString() ?? '180');
    _widthController = TextEditingController(text: initialObject?.width?.toString() ?? '5');
    _elevationAngleController = TextEditingController(text: initialObject?.elevationAngle?.toString() ?? '15');
    _azimuthStartController = TextEditingController(text: initialObject?.azimuthStart?.toString() ?? '160');
    _azimuthEndController = TextEditingController(text: initialObject?.azimuthEnd?.toString() ?? '200');
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _distanceController.dispose();
    _azimuthController.dispose();
    _widthController.dispose();
    _elevationAngleController.dispose();
    _azimuthStartController.dispose();
    _azimuthEndController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialObject == null ? 'Add Shading Object' : 'Edit Shading Object'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<ShadingObjectType>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Object Type',
                border: OutlineInputBorder(),
              ),
              items: ShadingObjectType.values.map((type) {
                return DropdownMenuItem<ShadingObjectType>(
                  value: type,
                  child: Text(type.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _type = value;
                  });
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Show relevant fields based on object type
            if (_type == ShadingObjectType.tree || 
                _type == ShadingObjectType.pole || 
                _type == ShadingObjectType.building) ...[
              TextField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: 'Height (m)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _distanceController,
                decoration: const InputDecoration(
                  labelText: 'Distance (m)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _azimuthController,
                decoration: const InputDecoration(
                  labelText: 'Azimuth (°)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              
              if (_type == ShadingObjectType.building) ...[
                const SizedBox(height: 16),
                
                TextField(
                  controller: _widthController,
                  decoration: const InputDecoration(
                    labelText: 'Width (m)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ],
            
            if (_type == ShadingObjectType.mountain || 
                _type == ShadingObjectType.horizon) ...[
              TextField(
                controller: _elevationAngleController,
                decoration: const InputDecoration(
                  labelText: 'Elevation Angle (°)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _azimuthStartController,
                decoration: const InputDecoration(
                  labelText: 'Azimuth Start (°)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _azimuthEndController,
                decoration: const InputDecoration(
                  labelText: 'Azimuth End (°)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Create new shading object from form data
            final shadingObject = ShadingObject(
              name: _nameController.text.isEmpty ? 'Unnamed Object' : _nameController.text,
              type: _type,
              height: double.tryParse(_heightController.text) ?? 10,
              distance: double.tryParse(_distanceController.text) ?? 15,
              azimuth: double.tryParse(_azimuthController.text) ?? 180,
              width: double.tryParse(_widthController.text),
              elevationAngle: double.tryParse(_elevationAngleController.text),
              azimuthStart: double.tryParse(_azimuthStartController.text),
              azimuthEnd: double.tryParse(_azimuthEndController.text),
            );
            
            widget.onSave(shadingObject);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}