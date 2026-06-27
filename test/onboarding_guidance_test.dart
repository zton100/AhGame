import 'package:abyss_relic/core/save/player_save_provider.dart';
import 'package:abyss_relic/features/onboarding/onboarding_guidance.dart';
import 'package:abyss_relic/models/equipment_instance.dart';
import 'package:abyss_relic/models/equipment_loadout.dart';
import 'package:abyss_relic/models/inventory_state.dart';
import 'package:abyss_relic/models/save_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new save recommends running battles first', () {
    final save = SaveData.newGame(now: DateTime.utc(2026));
    final inventory = inventoryStateFromSave(save.inventory);

    final guidance = const OnboardingGuidanceFactory().create(
      saveData: save,
      inventory: inventory,
      page: OnboardingGuidancePage.battle,
    );

    expect(guidance.title, '新手目标');
    expect(guidance.actionText, '优先操作：运行 10 场战斗');
    expect(guidance.goals.first.completed, isFalse);
  });

  test('equipment in inventory recommends equipping first', () {
    final equipment = _equipment();
    final save = SaveData.newGame(now: DateTime.utc(2026)).copyWith(
      inventory: InventorySave(
        equipmentInstanceIds: [equipment.instanceId],
        equipmentInstances: {equipment.instanceId: equipment},
      ),
    );
    final inventory = inventoryStateFromSave(save.inventory);

    final guidance = const OnboardingGuidanceFactory().create(
      saveData: save,
      inventory: inventory,
      page: OnboardingGuidancePage.equipment,
    );

    expect(guidance.message, contains('推荐装备'));
    expect(guidance.actionText, '优先操作：穿戴推荐装备');
  });

  test('equipped gear with materials recommends enhancement', () {
    final equipment = _equipment();
    final save = SaveData.newGame(now: DateTime.utc(2026)).copyWith(
      inventory: InventorySave(
        equipmentInstanceIds: [equipment.instanceId],
        equipmentInstances: {equipment.instanceId: equipment},
        equipmentLoadout: EquipmentLoadout(
          equippedBySlot: {'weapon': equipment.instanceId},
        ),
        materials: const [
          MaterialStack(materialId: 'gold', quantity: 10),
          MaterialStack(materialId: 'salvage_dust', quantity: 1),
        ],
      ),
    );
    final inventory = inventoryStateFromSave(save.inventory);

    final guidance = const OnboardingGuidanceFactory().create(
      saveData: save,
      inventory: inventory,
      page: OnboardingGuidancePage.character,
    );

    expect(guidance.message, contains('装备强化不足'));
    expect(guidance.actionText, '下一步：强化主力装备');
  });
}

EquipmentInstance _equipment({int enhanceLevel = 0}) {
  return EquipmentInstance(
    instanceId: 'eq_test_weapon',
    templateId: 'poison_blade',
    qualityId: 'rare',
    level: 1,
    createdAt: DateTime.utc(2026),
    rolledBaseStats: const [
      RolledBaseStat(stat: 'attack', value: 5),
    ],
    rolledAffixes: const [],
    enhanceLevel: enhanceLevel,
  );
}
