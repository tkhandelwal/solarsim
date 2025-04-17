// lib/models/location.dart
class Location {
  final double latitude;
  final double longitude;
  final String address;
  final double elevation;
  final String timeZone;
  
  Location({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.elevation = 0,
    required this.timeZone,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'elevation': elevation,
      'timeZone': timeZone,
    };
  }
  
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude'],
      longitude: json['longitude'],
      address: json['address'],
      elevation: json['elevation'],
      timeZone: json['timeZone'],
    );
  }
}