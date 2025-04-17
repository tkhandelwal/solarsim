// lib/widgets/circular_progress.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class CircularProgressGauge extends StatefulWidget {
  final double value;
  final double maxValue;
  final Color progressColor;
  final Color backgroundColor;
  final double size;
  final double strokeWidth;
  final Widget? child;
  final bool animate;
  final Duration animationDuration;
  
  const CircularProgressGauge({
    Key? key,
    required this.value,
    this.maxValue = 100.0,
    this.progressColor = Colors.blue,
    this.backgroundColor = Colors.grey,
    this.size = 150.0,
    this.strokeWidth = 10.0,
    this.child,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 1000),
  }) : super(key: key);

  @override
  State<CircularProgressGauge> createState() => _CircularProgressGaugeState();
}

class _CircularProgressGaugeState extends State<CircularProgressGauge> with SingleTickerProviderStateMixin {
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
      begin: 0.0,
      end: widget.value / widget.maxValue,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCirc,
    ));
    
    _animationController.forward();
  }
  
  @override
  void didUpdateWidget(CircularProgressGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value / widget.maxValue,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCirc,
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
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CircularProgressPainter(
                    progress: _animation.value,
                    progressColor: widget.progressColor,
                    backgroundColor: widget.backgroundColor,
                    strokeWidth: widget.strokeWidth,
                  ),
                );
              },
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;
  
  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final progressAngle = 2 * math.pi * progress;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from the top
      progressAngle,
      false,
      progressPaint,
    );
  }
  
  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.progressColor != progressColor ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}