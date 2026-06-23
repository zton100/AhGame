import '../../models/equipment_instance.dart';
import '../../models/equipment_loadout.dart';
import '../../models/equipment_template.dart';
import '../../models/inventory_state.dart';
import '../inventory/equipment_instance_store.dart';

class EquipmentService {
  const EquipmentService({
    EquipmentInstanceStore equipmentStore = const EquipmentInstanceStore(),
  }) : _equipmentStore = equipmentStore;

  final EquipmentInstanceStore _equipmentStore;

  EquipmentLoadout equip({
    required EquipmentLoadout loadout,
    required EquipmentInstance equipment,
    required EquipmentTemplate template,
    required String classId,
    required int level,
  }) {
    if (equipment.templateId != template.id) {
      throw StateError(
        'Equipment ${equipment.instanceId} does not match template ${template.id}.',
      );
    }

    if (level < template.minLevel) {
      throw StateError(
        'Template ${template.id} requires level ${template.minLevel}.',
      );
    }

    if (!template.allowedClasses.contains('all') &&
        !template.allowedClasses.contains(classId)) {
      throw StateError('Template ${template.id} is not allowed for $classId.');
    }

    return loadout.equip(template.slot, equipment.instanceId);
  }

  EquipmentLoadout equipFromInventory({
    required EquipmentLoadout loadout,
    required InventoryState inventory,
    required String instanceId,
    required EquipmentTemplate template,
    required String classId,
    required int level,
  }) {
    final equipment = _equipmentStore.requireInstance(
      state: inventory,
      instanceId: instanceId,
    );

    return equip(
      loadout: loadout,
      equipment: equipment,
      template: template,
      classId: classId,
      level: level,
    );
  }

  EquipmentLoadout unequip({
    required EquipmentLoadout loadout,
    required EquipmentSlot slot,
  }) {
    return loadout.unequip(slot);
  }
}
