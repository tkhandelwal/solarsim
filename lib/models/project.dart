// lib/models/project.dart
import 'package:solarsim/models/location.dart';

class Project {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String ownerId;
  final List<String> collaboratorIds;
  final bool isPublic;
  final SystemType systemType;
  final Location location;
  
  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.modifiedAt,
    required this.ownerId,
    this.collaboratorIds = const [],
    this.isPublic = false,
    required this.systemType,
    required this.location,
  });
  
  Project copyWith({
    String? name,
    String? description,
    DateTime? modifiedAt,
    List<String>? collaboratorIds,
    bool? isPublic,
    SystemType? systemType,
    Location? location,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
      ownerId: ownerId,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
      isPublic: isPublic ?? this.isPublic,
      systemType: systemType ?? this.systemType,
      location: location ?? this.location,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'ownerId': ownerId,
      'collaboratorIds': collaboratorIds,
      'isPublic': isPublic,
      'systemType': systemType.toString().split('.').last,
      'location': location.toJson(),
    };
  }
  
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      modifiedAt: DateTime.parse(json['modifiedAt']),
      ownerId: json['ownerId'],
      collaboratorIds: List<String>.from(json['collaboratorIds']),
      isPublic: json['isPublic'],
      systemType: SystemType.values.firstWhere(
        (e) => e.toString().split('.').last == json['systemType'],
      ),
      location: Location.fromJson(json['location']),
    );
  }
}

enum SystemType {
  gridConnected,
  standalone,
  pumping,
  solarThermal,
  hybrid,
}

