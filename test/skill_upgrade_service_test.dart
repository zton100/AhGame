import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/inventory_state.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/models/save_data.dart';
import 'package:abyss_relic/models/skill_config.dart';
import 'package:abyss_relic/models/stat_block.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/save/save_migration_service.dart';
import 'package:abyss_relic/systems/skills/skill_effect_preview_service.dart';
import 'package:abyss_relic/systems/skills/skill_service.dart';
import 'package:abyss_relic/systems/skills/skill_upgrade_service.dart';
import 'package:abyss_relic/systems/stats/stat_aggregation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy v5 saves migrate with empty skill levels', () {
    final result = const SaveMigrationService().migrate({
      'saveVersion': 5,
      'createdAt': '2026-06-24T00:00:00.000Z',
      'lastSavedAt': '2026-06-24T00:10:00.000Z',
      'lastExitAt': null,
      'playerProgress': {
        'currentClassId': 'exile',
        'level': 3,
        'experience': 120,
      },
      'inventory': {
        'equipmentInstanceIds': <String>[],
      },
      'settings': {
        'soundEnabled': true,
        'hapticsEnabled': true,
      },
    });

    expect(result.saveData.saveVersion, SaveData.currentVersion);
    expect(result.saveData.playerProgress.skillLevels, isEmpty);
    expect(result.warnings, ['Migrated saveVersion 5 to 6.']);
  });

  test('upgrading a skill consumes gold and persists the new level', () {
    final save = SaveData.newGame().copyWith(
      inventory: const InventorySave(
        equipmentInstanceIds: [],
        materials: [MaterialStack(materialId: 'gold', quantity: 50)],
      ),
    );

    final result = const SkillUpgradeService().upgrade(
      saveData: save,
      skillService: SkillService(_database()),
      skillId: 'toxic_slash',
    );

    expect(result.accepted, isTrue);
    expect(result.previousLevel, 1);
    expect(result.newLevel, 2);
    expect(result.consumedGold, 20);
    expect(result.saveData.playerProgress.skillLevels['toxic_slash'], 2);
    expect(result.saveData.inventory.materials.single.quantity, 30);
  });

  test('insufficient gold and max level fail without modifying save', () {
    final poorSave = SaveData.newGame();
    final poorResult = const SkillUpgradeService().upgrade(
      saveData: poorSave,
      skillService: SkillService(_database()),
      skillId: 'toxic_slash',
    );

    expect(poorResult.accepted, isFalse);
    expect(poorResult.reason, SkillUpgradeReason.insufficientGold);
    expect(poorResult.saveData, same(poorSave));

    final maxSave = SaveData.newGame().copyWith(
      playerProgress: SaveData.newGame().playerProgress.copyWith(
        skillLevels: const {'toxic_slash': 10},
      ),
      inventory: const InventorySave(
        equipmentInstanceIds: [],
        materials: [MaterialStack(materialId: 'gold', quantity: 9999)],
      ),
    );
    final maxResult = const SkillUpgradeService().upgrade(
      saveData: maxSave,
      skillService: SkillService(_database()),
      skillId: 'toxic_slash',
    );

    expect(maxResult.accepted, isFalse);
    expect(maxResult.reason, SkillUpgradeReason.maxLevelReached);
  });

  test('skill preview damage increases with skill level', () {
    final skill = SkillConfig.fromJson(_skillRecord());
    final stats = const StatAggregationService().compute(
      base: const StatBlock(hp: 100, attack: 10, armor: 5),
    );

    final levelOne = const SkillEffectPreviewService().previewDamage(
      skill: skill,
      stats: stats,
      skillLevel: 1,
    );
    final levelThree = const SkillEffectPreviewService().previewDamage(
      skill: skill,
      stats: stats,
      skillLevel: 3,
    );

    expect(levelOne.damage, 12);
    expect(levelThree.damage, greaterThan(levelOne.damage));
  });
}

GameDatabase _database() {
  return GameDatabase.fromFiles([
    _file('assets/data/skills.json', {
      'schemaVersion': 1,
      'skills': [_skillRecord()],
    }),
  ]);
}

Map<String, Object?> _skillRecord() {
  return {
    'id': 'toxic_slash',
    'name': 'Toxic Slash',
    'classId': 'exile',
    'skillType': 'active',
    'tags': ['poison', 'shadow'],
    'cooldown': 3.0,
    'resourceCost': 10,
    'effects': [
      {
        'effectId': 'deal_damage',
        'params': {'multiplier': 1.2, 'damageType': 'poison'},
      },
    ],
  };
}

LoadedDataFile _file(String assetPath, Map<String, Object?> json) {
  return LoadedDataFile(
    meta: DataFileMeta(
      assetPath: assetPath,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      recordCount: 1,
      topLevelKeys: json.keys.toList(),
    ),
    json: json,
  );
}
