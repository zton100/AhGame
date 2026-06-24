import 'package:abyss_relic/models/affix_config.dart';
import 'package:abyss_relic/models/auto_salvage_config.dart';
import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/equipment_instance.dart';
import 'package:abyss_relic/models/equipment_loadout.dart';
import 'package:abyss_relic/models/inventory_state.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/models/save_data.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/inventory/auto_salvage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AutoSalvageConfig supports JSON round trip', () {
    const config = AutoSalvageConfig(
      enabled: true,
      minQualityToKeep: 'epic',
      minBuildMatchScoreToKeep: 72,
      allowedQualityIdsToSalvage: ['normal', 'magic'],
      maxInventoryUsageBeforeSalvage: 0.8,
    );

    final restored = AutoSalvageConfig.fromJson(config.toJson());

    expect(restored.enabled, isTrue);
    expect(restored.minQualityToKeep, 'epic');
    expect(restored.minBuildMatchScoreToKeep, 72);
    expect(restored.allowedQualityIdsToSalvage, ['normal', 'magic']);
    expect(restored.maxInventoryUsageBeforeSalvage, 0.8);
  });

  test('legacy inventory save defaults auto salvage config', () {
    final save = SaveData.fromJson({
      'saveVersion': SaveData.currentVersion,
      'createdAt': '2026-06-24T00:00:00.000Z',
      'lastSavedAt': '2026-06-24T00:00:00.000Z',
      'lastExitAt': null,
      'playerProgress': {
        'currentClassId': 'exile',
        'level': 1,
        'experience': 0,
      },
      'inventory': {
        'equipmentInstanceIds': <String>[],
      },
      'settings': {
        'soundEnabled': true,
        'hapticsEnabled': true,
      },
    });

    expect(save.inventory.autoSalvageConfig.enabled, isFalse);
    expect(save.inventory.autoSalvageConfig.minQualityToKeep, 'rare');
  });

  test('normal and magic equipment are salvaged into dust when enabled', () {
    final normal = _equipment('normal_blade', 'normal');
    final magic = _equipment('magic_blade', 'magic');
    final report = const AutoSalvageService().processInventory(
      inventory: _inventory([normal, magic]),
      database: _database(),
      classId: 'exile',
      config: AutoSalvageConfig.defaults.copyWith(enabled: true),
    );

    expect(report.salvagedEquipmentIds, ['normal_blade', 'magic_blade']);
    expect(report.state.equipmentInstanceIds, isEmpty);
    expect(report.state.equipmentInstances, isEmpty);
    expect(report.gainedMaterials.single.materialId, 'salvage_dust');
    expect(report.gainedMaterials.single.quantity, 2);
  });

  test('rare and above are kept by minQualityToKeep', () {
    final rare = _equipment('rare_blade', 'rare');
    final report = const AutoSalvageService().processInventory(
      inventory: _inventory([rare]),
      database: _database(),
      classId: 'exile',
      config: AutoSalvageConfig.defaults.copyWith(enabled: true),
    );

    expect(report.salvagedEquipmentIds, isEmpty);
    expect(report.keptEquipmentIds, ['rare_blade']);
  });

  test('locked and equipped equipment are never auto salvaged', () {
    final locked = _equipment('locked_blade', 'normal');
    final equipped = _equipment('equipped_blade', 'normal');
    final report = const AutoSalvageService().processInventory(
      inventory: _inventory(
        [locked, equipped],
        lockedIds: ['locked_blade'],
        loadout: const EquipmentLoadout(
          equippedBySlot: {'main_weapon': 'equipped_blade'},
        ),
      ),
      database: _database(),
      classId: 'exile',
      config: AutoSalvageConfig.defaults.copyWith(enabled: true),
    );

    expect(report.salvagedEquipmentIds, isEmpty);
    expect(
        report.reasonByEquipmentId['locked_blade'], AutoSalvageReason.locked);
    expect(
      report.reasonByEquipmentId['equipped_blade'],
      AutoSalvageReason.equipped,
    );
  });

  test('legendary and above are kept by default', () {
    final legendary = _equipment('legendary_blade', 'legendary');
    final report = const AutoSalvageService().processInventory(
      inventory: _inventory([legendary]),
      database: _database(),
      classId: 'exile',
      config: AutoSalvageConfig.defaults.copyWith(
        enabled: true,
        minQualityToKeep: 'abyss',
      ),
    );

    expect(report.salvagedEquipmentIds, isEmpty);
    expect(
      report.reasonByEquipmentId['legendary_blade'],
      AutoSalvageReason.legendaryOrAbove,
    );
  });

  test('high build match equipment is kept', () {
    final poison = _equipment(
      'poison_blade',
      'normal',
      affixes: [
        const RolledAffix(
          affixId: 'poison_edge',
          rollValue: 10,
          exclusiveGroup: null,
        ),
      ],
    );
    final report = const AutoSalvageService().processInventory(
      inventory: _inventory([poison]),
      database: _database(poisonWeight: 80),
      classId: 'exile',
      config: AutoSalvageConfig.defaults.copyWith(
        enabled: true,
        minBuildMatchScoreToKeep: 8,
      ),
    );

    expect(report.salvagedEquipmentIds, isEmpty);
    expect(
      report.reasonByEquipmentId['poison_blade'],
      AutoSalvageReason.highBuildMatch,
    );
  });
}

EquipmentInstance _equipment(
  String id,
  String qualityId, {
  List<RolledAffix> affixes = const [],
}) {
  return EquipmentInstance(
    instanceId: id,
    templateId: 'rusted_blade',
    qualityId: qualityId,
    level: 1,
    createdAt: DateTime.utc(2026, 6, 24),
    rolledBaseStats: const [
      RolledBaseStat(stat: 'attack', value: 3),
    ],
    rolledAffixes: affixes,
  );
}

InventoryState _inventory(
  List<EquipmentInstance> equipment, {
  List<String> lockedIds = const [],
  EquipmentLoadout loadout = const EquipmentLoadout.empty(),
}) {
  return InventoryState(
    equipmentInstanceIds: [for (final item in equipment) item.instanceId],
    equipmentInstances: {
      for (final item in equipment) item.instanceId: item,
    },
    equipmentLoadout: loadout,
    lockedEquipmentInstanceIds: lockedIds,
  );
}

GameDatabase _database({int poisonWeight = 10}) {
  return GameDatabase.fromFiles([
    _file('assets/data/classes.json', {
      'schemaVersion': 1,
      'classes': [
        {
          'id': 'exile',
          'name': 'Exile',
          'tags': ['poison'],
          'baseStats': {'hp': 100, 'attack': 18, 'armor': 6},
          'growth': {'hp': 10, 'attack': 2, 'armor': 1},
        },
      ],
    }),
    _file('assets/data/builds.json', {
      'schemaVersion': 1,
      'builds': [
        {
          'id': 'exile_poison',
          'classId': 'exile',
          'name': 'Poison',
          'tagWeights': {'poison': poisonWeight},
        },
      ],
    }),
    _file('assets/data/equipment_templates.json', {
      'schemaVersion': 1,
      'equipment_templates': [
        {
          'id': 'rusted_blade',
          'name': 'Rusted Blade',
          'slot': 'main_weapon',
          'allowedClasses': ['exile'],
          'minLevel': 1,
          'qualityPool': ['normal', 'magic', 'rare'],
          'baseStats': [
            {'stat': 'attack', 'min': 1, 'max': 3},
          ],
          'affixRules': {
            'prefixMin': 0,
            'prefixMax': 0,
            'suffixMin': 0,
            'suffixMax': 0,
            'allowedTags': <String>[],
          },
        },
      ],
    }),
    _file('assets/data/affixes.json', {
      'schemaVersion': 1,
      'affixes': [
        {
          'id': 'poison_edge',
          'name': 'Poison Edge',
          'type': 'prefix',
          'tags': ['poison'],
          'effect': {
            'effectId': 'stat_modifier',
            'params': {'stat': 'poison_damage'},
          },
          'roll': {'min': 1, 'max': 10, 'step': 1},
        },
      ],
    }),
  ]);
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
