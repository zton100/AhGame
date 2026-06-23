import 'package:abyss_relic/models/affix_config.dart';
import 'package:abyss_relic/models/character_state.dart';
import 'package:abyss_relic/models/class_config.dart';
import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/equipment_instance.dart';
import 'package:abyss_relic/models/equipment_loadout.dart';
import 'package:abyss_relic/models/equipment_template.dart';
import 'package:abyss_relic/models/inventory_state.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/models/stat_block.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/stats/character_final_stats_service.dart';
import 'package:abyss_relic/systems/stats/stat_aggregation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CharacterFinalStatsService adds equipment base attack', () {
    const service = CharacterFinalStatsService();

    final result = service.compute(
      character: _character(),
      loadout: _loadout('eq_weapon'),
      inventory: InventoryState(
        equipmentInstanceIds: const ['eq_weapon'],
        equipmentInstances: {
          'eq_weapon': _equipment(
            rolledBaseStats: const [
              RolledBaseStat(stat: 'attack', value: 12),
            ],
          ),
        },
      ),
      database: _database(),
    );

    expect(result.warnings, isEmpty);
    expect(result.computedStats.finalStats.attack, 30);
    expect(result.computedStats.breakdownFor(StatKey.attack).flat, 12);
  });

  test('CharacterFinalStatsService applies percent affix modifiers', () {
    const service = CharacterFinalStatsService();

    final result = service.compute(
      character: _character(
          baseStats: const StatBlock(
        hp: 100,
        attack: 18,
        armor: 6,
        poisonDamage: 100,
      )),
      loadout: _loadout('eq_weapon'),
      inventory: InventoryState(
        equipmentInstanceIds: const ['eq_weapon'],
        equipmentInstances: {
          'eq_weapon': _equipment(
            rolledAffixes: const [
              RolledAffix(
                affixId: 'aff_poison_damage',
                rollValue: 0.20,
                exclusiveGroup: 'element_damage',
              ),
            ],
          ),
        },
      ),
      database: _database(),
    );

    expect(result.warnings, isEmpty);
    expect(result.computedStats.finalStats.poisonDamage, 120);
    expect(
        result.computedStats.breakdownFor(StatKey.poisonDamage).percent, 0.20);
  });

  test('CharacterFinalStatsService equipped stats exceed unequipped stats', () {
    const service = CharacterFinalStatsService();
    final character = _character();
    final database = _database();

    final unequipped = service.compute(
      character: character,
      loadout: const EquipmentLoadout.empty(),
      inventory: const InventoryState(equipmentInstanceIds: []),
      database: database,
    );
    final equipped = service.compute(
      character: character,
      loadout: _loadout('eq_weapon'),
      inventory: InventoryState(
        equipmentInstanceIds: const ['eq_weapon'],
        equipmentInstances: {
          'eq_weapon': _equipment(
            rolledBaseStats: const [
              RolledBaseStat(stat: 'attack', value: 12),
            ],
          ),
        },
      ),
      database: database,
    );

    expect(equipped.computedStats.finalStats.attack,
        greaterThan(unequipped.computedStats.finalStats.attack));
  });

  test('CharacterFinalStatsService warns when equipped instance is missing',
      () {
    const service = CharacterFinalStatsService();

    final result = service.compute(
      character: _character(),
      loadout: _loadout('missing_eq'),
      inventory: const InventoryState(equipmentInstanceIds: []),
      database: _database(),
    );

    expect(result.computedStats.finalStats.attack, 18);
    expect(result.warnings.single.code,
        CharacterFinalStatsWarningCode.missingEquipmentInstance);
    expect(result.warnings.single.equipmentInstanceId, 'missing_eq');
  });

  test('CharacterFinalStatsService exposes breakdowns for every stat', () {
    const service = CharacterFinalStatsService();

    final result = service.compute(
      character: _character(),
      loadout: const EquipmentLoadout.empty(),
      inventory: const InventoryState(equipmentInstanceIds: []),
      database: _database(),
    );

    for (final stat in StatKey.values) {
      expect(result.computedStats.breakdownFor(stat).finalValue, isNotNaN);
    }
  });
}

CharacterState _character({StatBlock? baseStats}) {
  return CharacterState(
    classConfig: ClassConfig(
      id: 'exile',
      name: 'Exile',
      tags: const ['poison'],
      baseStats: baseStats ?? const StatBlock(hp: 100, attack: 18, armor: 6),
      growth: const StatBlock(hp: 10, attack: 2, armor: 1),
    ),
    level: 1,
    experience: 0,
  );
}

EquipmentLoadout _loadout(String instanceId) {
  return EquipmentLoadout.empty().equip(
    EquipmentSlot.mainWeapon,
    instanceId,
  );
}

EquipmentInstance _equipment({
  List<RolledBaseStat> rolledBaseStats = const [],
  List<RolledAffix> rolledAffixes = const [],
}) {
  return EquipmentInstance(
    instanceId: 'eq_weapon',
    templateId: 'rusted_blade',
    qualityId: 'rare',
    level: 1,
    createdAt: DateTime.utc(2026, 6, 24),
    rolledBaseStats: rolledBaseStats,
    rolledAffixes: rolledAffixes,
  );
}

GameDatabase _database() {
  return GameDatabase.fromFiles([
    LoadedDataFile(
      meta: const DataFileMeta(
        assetPath: 'assets/data/affixes.json',
        schemaVersion: 1,
        recordCount: 1,
        topLevelKeys: ['schemaVersion', 'affixes'],
      ),
      json: {
        'schemaVersion': 1,
        'affixes': [
          {
            'id': 'aff_poison_damage',
            'name': 'Poison Damage',
            'type': 'element',
            'tags': ['poison'],
            'minLevel': 1,
            'weight': 100,
            'exclusiveGroup': 'element_damage',
            'rollRange': {'min': 0.10, 'max': 0.20, 'step': 0.01},
            'statModifiers': [
              {
                'stat': 'poison_damage',
                'mode': 'percent',
                'valueFromRoll': true,
              },
            ],
          },
        ],
      },
    ),
  ]);
}
