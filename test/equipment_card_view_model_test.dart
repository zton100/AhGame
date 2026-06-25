import 'package:abyss_relic/models/affix_config.dart';
import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/equipment_instance.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/systems/build/build_score_service.dart';
import 'package:abyss_relic/systems/build/build_service.dart';
import 'package:abyss_relic/systems/build/equipment_compare_service.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/features/equipment/equipment_card_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EquipmentCardViewModelFactory exposes quality and affix details', () {
    final database = _database();
    final factory = _factory(database);

    final viewModel = factory.create(
      equipment: _equipment(
        instanceId: 'poison',
        templateId: 'poison_blade',
        qualityId: 'rare',
        attack: 8,
        affixIds: const ['aff_poison_damage', 'aff_poison_can_crit'],
      ),
      assessment: _poisonAssessment,
    );

    expect(viewModel.title, 'Poison Blade');
    expect(viewModel.qualityId, 'rare');
    expect(viewModel.qualityLabel, '稀有');
    expect(viewModel.qualityColorValue, 0xFFD6B84A);
    expect(viewModel.baseStats.single.label, 'attack');
    expect(viewModel.affixes.map((affix) => affix.name), [
      'Poison Damage',
      'Poison Can Crit',
    ]);
    expect(viewModel.affixes.last.isMechanic, isTrue);
    expect(viewModel.matchScore, greaterThan(0));
    expect(viewModel.matchedTags, contains('poison'));
  });

  test('EquipmentCardViewModelFactory includes replacement deltas', () {
    final database = _database();
    final factory = _factory(database);

    final viewModel = factory.create(
      equipment: _equipment(
        instanceId: 'poison',
        templateId: 'poison_blade',
        qualityId: 'rare',
        attack: 8,
        affixIds: const ['aff_poison_damage'],
      ),
      equipped: _equipment(
        instanceId: 'raw',
        templateId: 'plain_axe',
        qualityId: 'rare',
        attack: 20,
        affixIds: const [],
      ),
      assessment: _poisonAssessment,
    );

    expect(viewModel.recommendationLabel, 'Upgrade');
    expect(viewModel.matchScoreDelta, greaterThan(0));
    expect(viewModel.attackDelta, lessThan(0));
  });
}

const _poisonAssessment = BuildAssessment(
  buildId: 'poison_shadow',
  label: 'Poison Shadow',
  isMixed: false,
  tagWeights: {'poison': 8, 'shadow': 4},
  buildScores: {'poison_shadow': 20},
);

EquipmentCardViewModelFactory _factory(GameDatabase database) {
  return EquipmentCardViewModelFactory(
    database: database,
    compareService: EquipmentCompareService(
      scoreService: BuildScoreService(database),
    ),
  );
}

EquipmentInstance _equipment({
  required String instanceId,
  required String templateId,
  required String qualityId,
  required double attack,
  required List<String> affixIds,
}) {
  return EquipmentInstance(
    instanceId: instanceId,
    templateId: templateId,
    qualityId: qualityId,
    level: 5,
    createdAt: DateTime.utc(2026, 1, 1),
    rolledBaseStats: [
      RolledBaseStat(stat: 'attack', value: attack),
    ],
    rolledAffixes: [
      for (final affixId in affixIds)
        RolledAffix(
          affixId: affixId,
          rollValue: 0.12,
          exclusiveGroup: null,
        ),
    ],
  );
}

GameDatabase _database() {
  return GameDatabase.fromFiles([
    _file('assets/data/equipment_templates.json', {
      'schemaVersion': 1,
      'equipment_templates': [
        {
          'id': 'poison_blade',
          'name': 'Poison Blade',
          'affixRules': {
            'prefixMin': 0,
            'prefixMax': 1,
            'suffixMin': 0,
            'suffixMax': 1,
            'allowedTags': ['poison', 'shadow'],
          },
        },
        {
          'id': 'plain_axe',
          'name': 'Plain Axe',
          'affixRules': {
            'prefixMin': 0,
            'prefixMax': 1,
            'suffixMin': 0,
            'suffixMax': 1,
            'allowedTags': ['physical'],
          },
        },
      ],
    }),
    _file('assets/data/affixes.json', {
      'schemaVersion': 1,
      'affixes': [
        {
          'id': 'aff_poison_damage',
          'name': 'Poison Damage',
          'type': 'element',
          'tags': ['poison'],
          'minLevel': 1,
          'weight': 100,
        },
        {
          'id': 'aff_poison_can_crit',
          'name': 'Poison Can Crit',
          'type': 'mechanic',
          'tags': ['poison', 'crit'],
          'minLevel': 35,
          'weight': 8,
          'effect': {'effectId': 'poison_can_crit', 'params': {}},
        },
      ],
    }),
    _file('assets/data/quality_config.json', {
      'schemaVersion': 1,
      'qualities': [
        {
          'id': 'rare',
          'name': '稀有',
          'affixMin': 3,
          'affixMax': 4,
          'statMultiplier': 1.18,
          'specialEffectChance': 0.02,
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
