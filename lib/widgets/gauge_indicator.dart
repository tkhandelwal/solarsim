// lib/widgets/gauge_indicator.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class GaugeIndicator extends StatefulWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final double size;
  final Color valueColor;
  final Color backgroundColor;
  final double thickness;
  final String? title;
  final String? subtitle;
  final bool showValue;
  final bool animate;
  final Duration animationDuration;
  final List<GaugeRange>? ranges;
  
  const GaugeIndicator({
    Key? key,
    required this.value,
    this.minValue = 0.0,
    this.maxValue = 100.0,
    this.size = 200.0,
    this.valueColor = Colors.blue,
    this.backgroundColor = Colors.grey,
    this.thickness = 20.0,
    this.title,
    this.subtitle,
    this.showValue = true,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 1000),
    this.ranges,
  }) : super(key: key);

  @override
  State<GaugeIndicator> createState() => _GaugeIndicatorState();
}

class _GaugeIndicatorState extends State<GaugeIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animate ? widget.animationDuration : Duration.zero,
    );
    
    _animation = Tween<double>(
      begin: widget.minValue,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }
  
  @override
  void didUpdateWidget(GaugeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      
      _animationController.forward(from: 0.0);
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background and progress arcs
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GaugePainter(
                  value: _animation.value,
                  minValue: widget.minValue,
                  maxValue: widget.maxValue,
                  valueColor: widget.valueColor,
                  backgroundColor: widget.backgroundColor,
                  thickness: widget.thickness,
                  ranges: widget.ranges,
                ),
              );
            },
          ),
          
          // Needle (if using a needle style)
          if (true) // Change this condition if you want to toggle needle display
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _NeedlePainter(
                    value: _animation.value,
                    minValue: widget.minValue,
                    maxValue: widget.maxValue,
                  ),
                );
              },
            ),
          
          // Center cap for needle
          Container(
            width: widget.thickness * 1.2,
            height: widget.thickness * 1.2,
            decoration: const BoxDecoration(
              color: Colors.black87,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4.0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          
          // Value and title text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50), // Space for needle
              if (widget.showValue)
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Text(
                      _animation.value.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    );
                  },
                ),
              if (widget.title != null)
                Text(
                  widget.title!,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              if (widget.subtitle != null)
                Text(
                  widget.subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double minValue;
  final double maxValue;
  final Color valueColor;
  final Color backgroundColor;
  final double thickness;
  final List<GaugeRange>? ranges;
  
  _GaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.valueColor,
    required this.backgroundColor,
    required this.thickness,
    this.ranges,
  });
  
  get startAngle => null;
  
  get sweepAngle => null;
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - thickness) / 2;
    
    // Define arc angles (in radians)
    const startAngle = math.pi * 0.75; // 135 degrees
    const sweepAngle = math.pi * 1.5; // 270 degrees
    
    // Background arc paint
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    
    // Draw background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );
    
    // Draw ranges if provided
    if (ranges != null) {
      for (final range in ranges!) {
        final startPercent = (range.startValue - minValue) / (maxValue - minValue);
        final endPercent = (range.endValue - minValue) / (maxValue - minValue);
        
        final rangeStartAngle = startAngle + sweepAngle * startPercent;
        final rangeSweepAngle = sweepAngle * (endPercent - startPercent);
        
        final rangePaint = Paint()
          ..color = range.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.butt;
        
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          rangeStartAngle,
          rangeSweepAngle,
          false,
          rangePaint,
        );
      }
    } else {
      // Calculate value as percentage of the range
      final valuePercent = (value - minValue) / (maxValue - minValue);
      final valueSweepAngle = sweepAngle * valuePercent;
      
      // Value arc paint
      final valuePaint = Paint()
        ..color = valueColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round;
      
      // Draw value arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        valueSweepAngle,
        false,
        valuePaint,
      );
    }
    
    // Draw tick marks
    _drawTicks(canvas, center, radius, size);
  }
  
  void _drawTicks(Canvas canvas, Offset center, double radius, Size size) {
    final tickPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    const numberOfTicks = 6; // Adjust as needed
    
    for (int i = 0; i <= numberOfTicks; i++) {
      final tickPercent = i / numberOfTicks;
      final tickAngle = startAngle + (sweepAngle * tickPercent);
      
      final outerTickPoint = Offset(
        center.dx + (radius + thickness / 2) * math.cos(tickAngle),
        center.dy + (radius + thickness / 2) * math.sin(tickAngle),
      );
      
      final innerTickPoint = Offset(
        center.dx + (radius - thickness / 2) * math.cos(tickAngle),
        center.dy + (radius - thickness / 2) * math.sin(tickAngle),
      );
      
      canvas.drawLine(innerTickPoint, outerTickPoint, tickPaint);
      
      // Draw tick labels
      final labelValue = minValue + ((maxValue - minValue) * tickPercent);
      final textSpan = TextSpan(
        text: labelValue.toInt().toString(),
        style: const TextStyle(fontSize: 10, color: Colors.black54),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      textPainter.layout();
      
      final labelPoint = Offset(
        center.dx + (radius + thickness / 2 + 15) * math.cos(tickAngle) - textPainter.width / 2,
        center.dy + (radius + thickness / 2 + 15) * math.sin(tickAngle) - textPainter.height / 2,
      );
      
      textPainter.paint(canvas, labelPoint);
    }
  }
  
  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
           oldDelegate.minValue != minValue ||
           oldDelegate.maxValue != maxValue ||
           oldDelegate.valueColor != valueColor ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.thickness != thickness;
  }
}

class _NeedlePainter extends CustomPainter {
  final double value;
  final double minValue;
  final double maxValue;
  
  _NeedlePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35; // Needle length
    
    // Calculate needle angle based on value
    final valuePercent = (value - minValue) / (maxValue - minValue);
    const startAngle = math.pi * 0.75; // 135 degrees
    const sweepAngle = math.pi * 1.5; // 270 degrees
    final needleAngle = startAngle + (sweepAngle * valuePercent);
    
    // Needle endpoint
    final needlePoint = Offset(
      center.dx + radius * math.cos(needleAngle),
      center.dy + radius * math.sin(needleAngle),
    );
    
    // Create needle path
    final needlePath = Path();
    
    // Needle width at base
    final baseWidth = size.width * 0.05;
    
    // Calculate points for the base of the needle
    final baseAngle1 = needleAngle + math.pi / 2;
    final baseAngle2 = needleAngle - math.pi / 2;
    
    final basePoint1 = Offset(
      center.dx + baseWidth * math.cos(baseAngle1),
      center.dy + baseWidth * math.sin(baseAngle1),
    );
    
    final basePoint2 = Offset(
      center.dx + baseWidth * math.cos(baseAngle2),
      center.dy + baseWidth * math.sin(baseAngle2),
    );
    
    // Draw the needle
    needlePath.moveTo(basePoint1.dx, basePoint1.dy);
    needlePath.lineTo(needlePoint.dx, needlePoint.dy);
    needlePath.lineTo(basePoint2.dx, basePoint2.dy);
    needlePath.close();
    
    // Needle paint
    final needlePaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [Colors.red.shade800, Colors.red.shade600],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    // Draw needle
    canvas.drawPath(needlePath, needlePaint);
    
    // Draw needle shadow
    canvas.drawShadow(needlePath, Colors.black26, 4.0, true);
  }
  
  @override
  bool shouldRepaint(_NeedlePainter oldDelegate) {
    return oldDelegate.value != value ||
           oldDelegate.minValue != minValue ||
           oldDelegate.maxValue != maxValue;
  }
}

class GaugeRange {
  final double startValue;
  final double endValue;
  final Color color;
  
  const GaugeRange({
    required this.startValue,
    required this.endValue,
    required this.color,
  });
}