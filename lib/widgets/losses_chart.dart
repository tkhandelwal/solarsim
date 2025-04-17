// lib/widgets/losses_chart.dart continued
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SystemLossesChart extends StatefulWidget {
  final Map<String, double> losses;
  
  const SystemLossesChart({
    super.key,
    required this.losses,
  });

  @override
  State<SystemLossesChart> createState() => _SystemLossesChartState();
}

class _SystemLossesChartState extends State<SystemLossesChart> {
  int touchedIndex = -1;
  
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _getSections(),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _getLegendItems(),
            ),
          ),
        ],
      ),
    );
  }
  
  List<PieChartSectionData> _getSections() {
    int i = 0;
    return widget.losses.entries.map((entry) {
      final isTouched = i == touchedIndex;
      final color = _getLossColor(entry.key);
      final value = entry.value * 100; // Convert to percentage
      final radius = isTouched ? 60.0 : 50.0;
      
      final section = PieChartSectionData(
        color: color,
        value: value,
        title: '${value.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: isTouched ? 16 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
      
      i++;
      return section;
    }).toList();
  }
  
  List<Widget> _getLegendItems() {
    return widget.losses.entries.map((entry) {
      final color = _getLossColor(entry.key);
      final name = _getLossName(entry.key);
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(name),
            const SizedBox(width: 4),
            Text(
              '(${(entry.value * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }).toList();
  }
  
  Color _getLossColor(String lossType) {
    switch (lossType) {
      case 'soiling':
        return Colors.brown;
      case 'shading':
        return Colors.grey;
      case 'mismatch':
        return Colors.purple;
      case 'wiring':
        return Colors.orange;
      case 'inverter':
        return Colors.blue;
      case 'temperature':
        return Colors.red;
      default:
        return Colors.green;
    }
  }
  
  String _getLossName(String lossType) {
    switch (lossType) {
      case 'soiling':
        return 'Soiling Loss';
      case 'shading':
        return 'Shading Loss';
      case 'mismatch':
        return 'Mismatch Loss';
      case 'wiring':
        return 'Wiring Loss';
      case 'inverter':
        return 'Inverter Loss';
      case 'temperature':
        return 'Temperature Loss';
      default:
        return lossType;
    }
  }
}