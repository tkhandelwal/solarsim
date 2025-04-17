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
                
                // List of shading objects - in a real app, this would be editable
                _buildShadingObjectList(),
                
                const SizedBox(height: 8),
                
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Shading Object'),
                  onPressed: () {
                    // This would open a dialog to add a shading object
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add shading object dialog would open here')),
                    );
                  },
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
                
                Text('Shading loss: 4.2%'),
                const SizedBox(height: 4),
                Text('Annual energy reduction: 2,620 kWh'),
                
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
    // Sample shading objects - in a real app, this would be dynamic
    return Column(
      children: [
        _buildShadingObjectItem('Tree', 'Height: 10m, Distance: 15m, Azimuth: 120°'),
        _buildShadingObjectItem('Building', 'Height: 20m, Distance: 30m, Azimuth: 200°'),
        _buildShadingObjectItem('Mountain', 'Elevation: 15°, Azimuth range: 240° - 280°'),
      ],
    );
  }
  
  Widget _buildShadingObjectItem(String name, String details) {
    return ListTile(
      leading: const Icon(Icons.filter_hdr),
      title: Text(name),
      subtitle: Text(details),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () {
          // This would open a dialog to edit the shading object
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Edit $name dialog would open here')),
          );
        },
      ),
    );
  }
}

class SunPathChart extends StatelessWidget {
  final double latitude;
  final int month;
  
  const SunPathChart({
    super.key,
    required this.latitude,
    required this.month,
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
        ),
      ),
    );
  }
}

class SunPathPainter extends CustomPainter {
  final double latitude;
  final int month;
  
  SunPathPainter({
    required this.latitude,
    required this.month,
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
      
      if (elevation <= 0) continue;
      
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
      
      // Convert to chart coordinates
      final chartRadius = radius * (1 - elevation / 90);
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
      
      if (elevation <= 0) continue;
      
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
      
      // Convert to chart coordinates
      final chartRadius = radius * (1 - elevation / 90);
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
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}