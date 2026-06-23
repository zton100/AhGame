class InventoryState {
  const InventoryState({
    required this.equipmentInstanceIds,
    this.equipmentCapacity = defaultEquipmentCapacity,
    this.materials = const [],
  });

  factory InventoryState.fromJson(Map<String, Object?> json) {
    return InventoryState(
      equipmentInstanceIds: List<String>.from(
        json['equipmentInstanceIds'] as List? ?? const [],
      ),
      equipmentCapacity:
          json['equipmentCapacity'] as int? ?? defaultEquipmentCapacity,
      materials: [
        for (final material in json['materials'] as List? ?? const [])
          MaterialStack.fromJson(Map<String, Object?>.from(material as Map)),
      ],
    );
  }

  static const defaultEquipmentCapacity = 40;

  final List<String> equipmentInstanceIds;
  final int equipmentCapacity;
  final List<MaterialStack> materials;

  bool get isEquipmentFull => equipmentInstanceIds.length >= equipmentCapacity;

  InventoryState copyWith({
    List<String>? equipmentInstanceIds,
    int? equipmentCapacity,
    List<MaterialStack>? materials,
  }) {
    return InventoryState(
      equipmentInstanceIds: equipmentInstanceIds ?? this.equipmentInstanceIds,
      equipmentCapacity: equipmentCapacity ?? this.equipmentCapacity,
      materials: materials ?? this.materials,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'equipmentInstanceIds': equipmentInstanceIds,
      'equipmentCapacity': equipmentCapacity,
      'materials': [
        for (final material in materials) material.toJson(),
      ],
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
