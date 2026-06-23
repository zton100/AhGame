import 'equipment_instance.dart';

class InventoryState {
  const InventoryState({
    required this.equipmentInstanceIds,
    this.equipmentInstances = const {},
    this.equipmentCapacity = defaultEquipmentCapacity,
    this.materials = const [],
    this.lockedEquipmentInstanceIds = const [],
  });

  factory InventoryState.fromJson(Map<String, Object?> json) {
    return InventoryState(
      equipmentInstanceIds: List<String>.from(
        json['equipmentInstanceIds'] as List? ?? const [],
      ),
      equipmentInstances: {
        for (final entry
            in (json['equipmentInstances'] as Map? ?? const {}).entries)
          entry.key as String: EquipmentInstance.fromJson(
            Map<String, Object?>.from(entry.value as Map),
          ),
      },
      equipmentCapacity:
          json['equipmentCapacity'] as int? ?? defaultEquipmentCapacity,
      materials: [
        for (final material in json['materials'] as List? ?? const [])
          MaterialStack.fromJson(Map<String, Object?>.from(material as Map)),
      ],
      lockedEquipmentInstanceIds: List<String>.from(
        json['lockedEquipmentInstanceIds'] as List? ?? const [],
      ),
    );
  }

  static const defaultEquipmentCapacity = 40;

  final List<String> equipmentInstanceIds;
  final Map<String, EquipmentInstance> equipmentInstances;
  final int equipmentCapacity;
  final List<MaterialStack> materials;
  final List<String> lockedEquipmentInstanceIds;

  bool get isEquipmentFull => equipmentInstanceIds.length >= equipmentCapacity;

  InventoryState copyWith({
    List<String>? equipmentInstanceIds,
    Map<String, EquipmentInstance>? equipmentInstances,
    int? equipmentCapacity,
    List<MaterialStack>? materials,
    List<String>? lockedEquipmentInstanceIds,
  }) {
    return InventoryState(
      equipmentInstanceIds: equipmentInstanceIds ?? this.equipmentInstanceIds,
      equipmentInstances: equipmentInstances ?? this.equipmentInstances,
      equipmentCapacity: equipmentCapacity ?? this.equipmentCapacity,
      materials: materials ?? this.materials,
      lockedEquipmentInstanceIds:
          lockedEquipmentInstanceIds ?? this.lockedEquipmentInstanceIds,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'equipmentInstanceIds': equipmentInstanceIds,
      'equipmentInstances': {
        for (final entry in equipmentInstances.entries)
          entry.key: entry.value.toJson(),
      },
      'equipmentCapacity': equipmentCapacity,
      'materials': [
        for (final material in materials) material.toJson(),
      ],
      'lockedEquipmentInstanceIds': lockedEquipmentInstanceIds,
    };
  }
}

class MaterialStack {
  const MaterialStack({
    required this.materialId,
    required this.quantity,
  });

  factory MaterialStack.fromJson(Map<String, Object?> json) {
    return MaterialStack(
      materialId: json['materialId'] as String,
      quantity: json['quantity'] as int,
    );
  }

  final String materialId;
  final int quantity;

  MaterialStack copyWith({int? quantity}) {
    return MaterialStack(
      materialId: materialId,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'materialId': materialId,
      'quantity': quantity,
    };
  }
}
