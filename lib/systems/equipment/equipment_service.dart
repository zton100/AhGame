import '../../models/equipment_instance.dart';
import '../../models/equipment_loadout.dart';
import '../../models/equipment_template.dart';

class EquipmentService {
  const EquipmentService();

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

  EquipmentLoadout unequip({
    required EquipmentLoadout loadout,
    required EquipmentSlot slot,
  }) {
    return loadout.unequip(slot);
  }
}
