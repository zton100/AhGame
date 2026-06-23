import 'equipment_template.dart';

class EquipmentLoadout {
  const EquipmentLoadout({required this.equippedBySlot});

  const EquipmentLoadout.empty() : equippedBySlot = const {};

  factory EquipmentLoadout.fromJson(Map<String, Object?> json) {
    return EquipmentLoadout(
      equippedBySlot: Map<String, String>.from(json['equippedBySlot'] as Map),
    );
  }

  final Map<String, String> equippedBySlot;

  String? equippedInstanceId(EquipmentSlot slot) {
    return equippedBySlot[slot.id];
  }

  EquipmentLoadout equip(EquipmentSlot slot, String instanceId) {
    return EquipmentLoadout(
      equippedBySlot: Map.unmodifiable({
        ...equippedBySlot,
        slot.id: instanceId,
      }),
    );
  }

  EquipmentLoadout unequip(EquipmentSlot slot) {
    final next = Map<String, String>.from(equippedBySlot)..remove(slot.id);
    return EquipmentLoadout(equippedBySlot: Map.unmodifiable(next));
  }

  Map<String, Object?> toJson() {
    return {'equippedBySlot': equippedBySlot};
  }
}
