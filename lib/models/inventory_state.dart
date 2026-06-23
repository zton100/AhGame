import 'equipment_instance.dart';
import 'equipment_loadout.dart';

class InventoryState {
  const InventoryState({
    required this.equipmentInstanceIds,
    this.equipmentInstances = const {},
    this.equipmentLoadout = const EquipmentLoadout.empty(),
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
      equipmentLoadout: json['equipmentLoadout'] is Map
          ? EquipmentLoadout.fromJson(
              Map<String, Object?>.from(json['equipmentLoadout'] as Map),
            )
          : const EquipmentLoadout.empty(),
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
  final EquipmentLoadout equipmentLoadout;
  final int equipmentCapacity;
  final List<MaterialStack> materials;
  final List<String> lockedEquipmentInstanceIds;

  bool get isEquipmentFull => equipmentInstanceIds.length >= equipmentCapacity;

  InventoryState copyWith({
    List<String>? equipmentInstanceIds,
    Map<String, EquipmentInstance>? equipmentInstances,
    EquipmentLoadout? equipmentLoadout,
    int? equipmentCapacity,
    List<MaterialStack>? materials,
    List<String>? lockedEquipmentInstanceIds,
  }) {
    return InventoryState(
      equipmentInstanceIds: equipmentInstanceIds ?? this.equipmentInstanceIds,
      equipmentInstances: equipmentInstances ?? this.equipmentInstances,
      equipmentLoadout: equipmentLoadout ?? this.equipmentLoadout,
      equipmentCapacity: equipmentCapacity ?? this.equipmentCapacity,
      materials: materials ?? this.materials,
      lockedEquipmentInstanceIds:
          lockedEquipmentInstanceIds ?? this.lockedEquipmentInstanceIds,
    );
  }

  bool isLocked(String instanceId) {
    return lockedEquipmentInstanceIds.contains(instanceId);
  }

  InventoryState lockEquipment(String instanceId) {
    if (isLocked(instanceId)) {
      return this;
    }

    return copyWith(
      lockedEquipmentInstanceIds: [
        ...lockedEquipmentInstanceIds,
        instanceId,
      ],
    );
  }

  InventoryState unlockEquipment(String instanceId) {
    if (!isLocked(instanceId)) {
      return this;
    }

    return copyWith(
      lockedEquipmentInstanceIds: [
        for (final id in lockedEquipmentInstanceIds)
          if (id != instanceId) id,
      ],
    );
  }

  Map<String, Object?> toJson() {
    return {
      'equipmentInstanceIds': equipmentInstanceIds,
      'equipmentInstances': {
        for (final entry in equipmentInstances.entries)
          entry.key: entry.value.toJson(),
      },
      'equipmentLoadout': equipmentLoadout.toJson(),
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
