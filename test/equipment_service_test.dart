import 'package:abyss_relic/models/equipment_instance.dart';
import 'package:abyss_relic/models/equipment_loadout.dart';
import 'package:abyss_relic/models/equipment_template.dart';
import 'package:abyss_relic/systems/equipment/equipment_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EquipmentService equips valid equipment into its slot', () {
    const service = EquipmentService();

    final updated = service.equip(
      loadout: const EquipmentLoadout.empty(),
      equipment: _equipment(),
      template: _template(),
      classId: 'exile',
      level: 5,
    );

    expect(updated.equippedInstanceId(EquipmentSlot.mainWeapon), 'eq_1');
  });

  test('EquipmentService rejects class and level mismatches', () {
    const service = EquipmentService();

    expect(
      () => service.equip(
        loadout: const EquipmentLoadout.empty(),
        equipment: _equipment(),
        template: _template(),
        classId: 'ember_mage',
        level: 5,
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      () => service.equip(
        loadout: const EquipmentLoadout.empty(),
        equipment: _equipment(),
        template: _template(minLevel: 10),
        classId: 'exile',
        level: 5,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('EquipmentService unequips equipment from a slot', () {
    const service = EquipmentService();
    final loadout = EquipmentLoadout.empty().equip(
      EquipmentSlot.mainWeapon,
      'eq_1',
    );

    final updated = service.unequip(
      loadout: loadout,
      slot: EquipmentSlot.mainWeapon,
    );

    expect(updated.equippedInstanceId(EquipmentSlot.mainWeapon), isNull);
  });

  test('EquipmentLoadout supports JSON round trip', () {
    final loadout = EquipmentLoadout.empty().equip(
      EquipmentSlot.mainWeapon,
      'eq_1',
    );

    final restored = EquipmentLoadout.fromJson(loadout.toJson());

    expect(restored.equippedInstanceId(EquipmentSlot.mainWeapon), 'eq_1');
  });
}

EquipmentInstance _equipment() {
  return EquipmentInstance(
    instanceId: 'eq_1',
    templateId: 'rusted_blade',
    qualityId: 'rare',
    level: 5,
    createdAt: DateTime.utc(2026, 6, 23),
    rolledBaseStats: const [RolledBaseStat(stat: 'attack', value: 12)],
    rolledAffixes: const [],
  );
}

EquipmentTemplate _template({int minLevel = 1}) {
  return EquipmentTemplate(
    id: 'rusted_blade',
    name: 'Rusted Blade',
    slot: EquipmentSlot.mainWeapon,
    allowedClasses: const ['exile'],
    minLevel: minLevel,
    qualityPool: const ['rare'],
    baseStats: const [
      EquipmentBaseStatRange(stat: 'attack', min: 8, max: 14),
    ],
    affixRules: const EquipmentAffixRules(
      prefixMin: 0,
      prefixMax: 1,
      suffixMin: 0,
      suffixMax: 1,
      allowedTags: ['poison'],
    ),
  );
}
