// lib/widgets/system_3d_view.dart
import 'package:flutter/material.dart';
import 'package:solarsim/models/solar_module.dart';

class System3DView extends StatefulWidget {
  final int modulesInSeries;
  final int stringsInParallel;
  final SolarModule module;
  final double tiltAngle;
  final double azimuthAngle;
  
  const System3DView({
    super.key,
    required this.modulesInSeries,
    required this.stringsInParallel,
    required this.module,
    required this.tiltAngle,
    required this.azimuthAngle,
  });

  @override
  State<System3DView> createState() => _System3DViewState();
}

class _System3DViewState extends State<System3DView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _rotationAngle = 0;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _controller.addListener(() {
      setState(() {
        _rotationAngle = _controller.value * 2 * 3.14159;
      });
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.5,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Sky
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.blue.shade200, Colors.blue.shade50],
                      ),
                    ),
                  ),
                ),
                
                // Ground
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    color: Colors.green.shade100,
                  ),
                ),
                
                // Solar panel array
                Center(
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // perspective
                      ..rotateY(_rotationAngle)
                      ..rotateX(-0.4),
                    alignment: Alignment.center,
                    child: _buildSolarArray(),
                  ),
                ),
                
                // Sun
                Positioned(
                  right: 40,
                  top: 40,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.yellow,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.yellow,
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Controls overlay
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Tilt: ${widget.tiltAngle.toStringAsFixed(1)}°',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Azimuth: ${widget.azimuthAngle.toStringAsFixed(1)}°',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.modulesInSeries * widget.stringsInParallel} modules - ${(widget.module.powerRating * widget.modulesInSeries * widget.stringsInParallel / 1000).toStringAsFixed(2)} kWp',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
  
  Widget _buildSolarArray() {
    // Calculate array dimensions
    const moduleWidth = 50.0;
    final moduleHeight = moduleWidth * (widget.module.length / widget.module.width);
    
    final arrayWidth = moduleWidth * widget.modulesInSeries;
    final arrayHeight = moduleHeight * widget.stringsInParallel;
    
    return Transform(
      transform: Matrix4.identity()
        ..rotateX(widget.tiltAngle * 3.14159 / 180),
      alignment: Alignment.bottomCenter,
      child: Container(
        width: arrayWidth,
        height: arrayHeight,
        decoration: BoxDecoration(
          color: Colors.blue.shade900,
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.modulesInSeries,
            childAspectRatio: widget.module.width / widget.module.length,
          ),
          itemCount: widget.modulesInSeries * widget.stringsInParallel,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
                border: Border.all(color: Colors.white, width: 1),
              ),
            );
          },
        ),
      ),
    );
  }
}