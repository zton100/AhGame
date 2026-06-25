import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/equipment_instance.dart';
import 'package:abyss_relic/models/equipment_loadout.dart';
import 'package:abyss_relic/models/equipment_template.dart';
import 'package:abyss_relic/models/inventory_state.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/equipment/equipment_recommendation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recommends a better current-class upgrade for the same slot', () {
    final inventory = _inventory();

    final result = const EquipmentRecommendationService().recommendBestUpgrade(
      inventory: inventory,
      database: _database(),
      classId: 'exile',
      level: 5,
    );

    expect(result.accepted, isTrue);
    expect(result.candidate?.equipment.instanceId, 'better_weapon');
    expect(result.loadout.equippedInstanceId(EquipmentSlot.mainWeapon),
        'better_weapon');
  });

  test('ignores unusable class and level candidates', () {
    final result = const EquipmentRecommendationService().recommendBestUpgrade(
      inventory: _inventory(onlyUnusable: true),
      database: _database(),
      classId: 'exile',
      level: 1,
    );

    expect(result.accepted, isFalse);
    expect(result.reason, EquipmentRecommendationReason.noUpgradeFound);
  });
}

InventoryState _inventory({bool onlyUnusable = false}) {
  final equipped = _equipment('equipped_weapon', 'rusted_blade', 8);
  final better = _equipment('better_weapon', 'venom_blade', 18);
  final lockedOut = _equipment('locked_out', 'ember_staff', 30);
  final highLevel = _equipment('high_level', 'late_blade', 40);

  return InventoryState(
    equipmentInstanceIds: onlyUnusable
        ? const ['equipped_weapon', 'locked_out', 'high_level']
        : const ['equipped_weapon', 'better_weapon', 'locked_out'],
    equipmentInstances: {
      'equipped_weapon': equipped,
      'better_weapon': better,
      'locked_out': lockedOut,
      'high_level': highLevel,
    },
    equipmentLoadout: EquipmentLoadout.empty().equip(
      EquipmentSlot.mainWeapon,
      'equipped_weapon',
    ),
  );
}

EquipmentInstance _equipment(String id, String templateId, double attack) {
  return EquipmentInstance(
    instanceId: id,
    templateId: templateId,
    qualityId: 'rare',
    level: 1,
    createdAt: DateTime.utc(2026, 6, 25),
    rolledBaseStats: [RolledBaseStat(stat: 'attack', value: attack)],
    rolledAffixes: const [],
  );
}

GameDatabase _database() {
  return GameDatabase.fromFiles([
    _file('assets/data/classes.json', {
      'schemaVersion': 1,
      'classes': [
        {
          'id': 'exile',
          'name': 'Exile',
          'tags': ['poison', 'shadow'],
        },
      ],
    }),
    _file('assets/data/equipment_templates.json', {
      'schemaVersion': 1,
      'equipment_templates': [
        _template('rusted_blade', 'Rusted Blade', ['exile'], 1),
        _template('venom_blade', 'Venom Blade', ['exile'], 1),
        _template('ember_staff', 'Ember Staff', ['ember_mage'], 1),
        _template('late_blade', 'Late Blade', ['exile'], 10),
      ],
    }),
  ]);
}

Map<String, Object?> _template(
  String id,
  String name,
  List<String> allowedClasses,
  int minLevel,
) {
  return {
    'id': id,
    'name': name,
    'slot': 'main_weapon',
    'allowedClasses': allowedClasses,
    'minLevel': minLevel,
    'qualityPool': ['rare'],
    'baseStats': [
      {'stat': 'attack', 'min': 1, 'max': 10},
    ],
    'affixRules': {
      'prefixMin': 0,
      'prefixMax': 0,
      'suffixMin': 0,
      'suffixMax': 0,
      'allowedTags': ['poison', 'shadow'],
    },
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
