import 'package:equatable/equatable.dart';

/// Ward model representing a room/ward in the facility
class WardModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? nfcTagId;
  final int capacity;
  final int currentOccupancy;
  final String? floor;
  final String? building;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const WardModel({
    required this.id,
    required this.name,
    this.description,
    this.nfcTagId,
    this.capacity = 0,
    this.currentOccupancy = 0,
    this.floor,
    this.building,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if ward has NFC tag assigned
  bool get hasNfcTag => nfcTagId != null && nfcTagId!.isNotEmpty;

  /// Get occupancy percentage
  double get occupancyPercentage {
    if (capacity == 0) return 0;
    return (currentOccupancy / capacity) * 100;
  }

  /// Get available beds
  int get availableBeds => capacity - currentOccupancy;

  /// Get display location
  String get displayLocation {
    final parts = <String>[];
    if (building != null) parts.add(building!);
    return parts.isNotEmpty ? parts.join(', ') : 'N/A';
  }

  factory WardModel.fromJson(Map<String, dynamic> json) {
    return WardModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      nfcTagId: json['nfc_tag_id'] as String?,
      capacity: json['capacity'] as int? ?? 0,
      currentOccupancy: json['current_occupancy'] as int? ?? 0,
      floor: json['floor'] as String?,
      building: json['building'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'nfc_tag_id': nfcTagId,
      'capacity': capacity,
      'current_occupancy': currentOccupancy,
      'floor': floor,
      'building': building,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  WardModel copyWith({
    String? id,
    String? name,
    String? description,
    String? nfcTagId,
    int? capacity,
    int? currentOccupancy,
    String? floor,
    String? building,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      nfcTagId: nfcTagId ?? this.nfcTagId,
      capacity: capacity ?? this.capacity,
      currentOccupancy: currentOccupancy ?? this.currentOccupancy,
      floor: floor ?? this.floor,
      building: building ?? this.building,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        nfcTagId,
        capacity,
        currentOccupancy,
        floor,
        building,
        isActive,
        createdAt,
        updatedAt,
      ];
}
