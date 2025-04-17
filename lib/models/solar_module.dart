// lib/models/solar_module.dart
class SolarModule {
  final String id;
  final String manufacturer;
  final String model;
  final double powerRating; // Wp
  final double efficiency;
  final double length;
  final double width;
  final ModuleTechnology technology;
  final double temperatureCoefficient;
  final double nominalOperatingCellTemp;
  
  SolarModule({
    required this.id,
    required this.manufacturer,
    required this.model,
    required this.powerRating,
    required this.efficiency,
    required this.length,
    required this.width,
    required this.technology,
    required this.temperatureCoefficient,
    required this.nominalOperatingCellTemp,
  });
  
  double get area => length * width;
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'manufacturer': manufacturer,
      'model': model,
      'powerRating': powerRating,
      'efficiency': efficiency,
      'length': length,
      'width': width,
      'technology': technology.toString().split('.').last,
      'temperatureCoefficient': temperatureCoefficient,
      'nominalOperatingCellTemp': nominalOperatingCellTemp,
    };
  }
  
  factory SolarModule.fromJson(Map<String, dynamic> json) {
    return SolarModule(
      id: json['id'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      powerRating: json['powerRating'],
      efficiency: json['efficiency'],
      length: json['length'],
      width: json['width'],
      technology: ModuleTechnology.values.firstWhere(
        (e) => e.toString().split('.').last == json['technology'],
      ),
      temperatureCoefficient: json['temperatureCoefficient'],
      nominalOperatingCellTemp: json['nominalOperatingCellTemp'],
    );
  }
}

enum ModuleTechnology {
  monocrystalline,
  polycrystalline,
  thinFilm,
  amorphous,
  bifacial,
  cigs,
  cdte,
}