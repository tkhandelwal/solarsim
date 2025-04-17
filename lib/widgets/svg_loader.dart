// lib/widgets/svg_loader.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgLoader extends StatelessWidget {
  final String assetName;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;
  
  const SvgLoader({
    Key? key,
    required this.assetName,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetName,
      width: width,
      height: height,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      fit: fit,
    );
  }
}

// Sample SVG images for the app
class SvgIcons {
  static const String solarPanel = 'assets/icons/solar_panel.svg';
  static const String battery = 'assets/icons/battery.svg';
  static const String house = 'assets/icons/house.svg';
  static const String grid = 'assets/icons/grid.svg';
  static const String sun = 'assets/icons/sun.svg';
  static const String tree = 'assets/icons/tree.svg';
  static const String car = 'assets/icons/car.svg';
  
  // Simple method to generate SVG strings for testing without assets
  static String generateSvg(String type) {
    switch (type) {
      case 'solar_panel':
        return '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect x="10" y="20" width="80" height="60" fill="#3b82f6" stroke="#1e3a8a" stroke-width="2"/>
  <line x1="10" y1="35" x2="90" y2="35" stroke="#1e3a8a" stroke-width="1"/>
  <line x1="10" y1="50" x2="90" y2="50" stroke="#1e3a8a" stroke-width="1"/>
  <line x1="10" y1="65" x2="90" y2="65" stroke="#1e3a8a" stroke-width="1"/>
  <line x1="33" y1="20" x2="33" y2="80" stroke="#1e3a8a" stroke-width="1"/>
  <line x1="66" y1="20" x2="66" y2="80" stroke="#1e3a8a" stroke-width="1"/>
  <line x1="10" y1="80" x2="45" y2="90" stroke="#1e3a8a" stroke-width="2"/>
  <line x1="90" y1="80" x2="55" y2="90" stroke="#1e3a8a" stroke-width="2"/>
</svg>
''';
      case 'battery':
        return '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect x="25" y="20" width="50" height="70" rx="5" ry="5" fill="#e5e7eb" stroke="#4b5563" stroke-width="2"/>
  <rect x="40" y="10" width="20" height="10" rx="2" ry="2" fill="#4b5563"/>
  <rect x="30" y="25" width="40" height="60" fill="#10b981"/>
  <line x1="30" y1="45" x2="70" y2="45" stroke="#fff" stroke-width="1"/>
  <line x1="30" y1="65" x2="70" y2="65" stroke="#fff" stroke-width="1"/>
  <text x="50" y="55" font-family="Arial" font-size="12" fill="#fff" text-anchor="middle">80%</text>
</svg>
''';
      case 'house':
        return '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <polygon points="50,10 10,50 20,50 20,90 80,90 80,50 90,50" fill="#9ca3af" stroke="#4b5563" stroke-width="2"/>
  <rect x="40" y="60" width="20" height="30" fill="#7c3aed"/>
  <rect x="30" y="40" width="15" height="15" fill="#60a5fa"/>
  <rect x="55" y="40" width="15" height="15" fill="#60a5fa"/>
</svg>
''';
      case 'sun':
        return '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <circle cx="50" cy="50" r="25" fill="#fcd34d" stroke="#f59e0b" stroke-width="2"/>
  <line x1="50" y1="15" x2="50" y2="5" stroke="#f59e0b" stroke-width="3"/>
  <line x1="50" y1="95" x2="50" y2="85" stroke="#f59e0b" stroke-width="3"/>
  <line x1="15" y1="50" x2="5" y2="50" stroke="#f59e0b" stroke-width="3"/>
  <line x1="95" y1="50" x2="85" y2="50" stroke="#f59e0b" stroke-width="3"/>
  <line x1="26" y1="26" x2="19" y2="19" stroke="#f59e0b" stroke-width="3"/>
  <line x1="81" y1="81" x2="74" y2="74" stroke="#f59e0b" stroke-width="3"/>
  <line x1="26" y1="74" x2="19" y2="81" stroke="#f59e0b" stroke-width="3"/>
  <line x1="81" y1="19" x2="74" y2="26" stroke="#f59e0b" stroke-width="3"/>
</svg>
''';
      default:
        return '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <circle cx="50" cy="50" r="40" fill="#d1d5db" stroke="#6b7280" stroke-width="2"/>
  <text x="50" y="55" font-family="Arial" font-size="15" fill="#000" text-anchor="middle">SVG</text>
</svg>
''';
    }
  }
}

class SvgBuilder extends StatelessWidget {
  final String svgContent;
  final double? width;
  final double? height;
  final Color? color;
  
  const SvgBuilder({
    Key? key, 
    required this.svgContent,
    this.width,
    this.height,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      svgContent,
      width: width,
      height: height,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
    );
  }
}