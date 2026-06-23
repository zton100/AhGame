import 'package:abyss_relic/models/affix_config.dart';
import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/equipment_instance.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/systems/build/build_score_service.dart';
import 'package:abyss_relic/systems/build/build_service.dart';
import 'package:abyss_relic/systems/build/equipment_compare_service.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BuildScoreService scores matching affixes above raw attack', () {
    final database = _database();
    final service = BuildScoreService(database);
    const assessment = BuildAssessment(
      buildId: 'poison_shadow',
      label: 'Poison Shadow',
      isMixed: false,
      tagWeights: {'poison': 8, 'shadow': 4},
      buildScores: {'poison_shadow': 20},
    );

    final poison = service.scoreEquipment(
      equipment: _equipment(
        instanceId: 'poison',
        templateId: 'poison_blade',
        attack: 8,
        affixIds: const ['aff_poison_damage'],
      ),
      assessment: assessment,
    );
    final rawAttack = service.scoreEquipment(
      equipment: _equipment(
        instanceId: 'raw',
        templateId: 'plain_axe',
        attack: 20,
        affixIds: const [],
      ),
      assessment: assessment,
    );

    expect(poison.matchScore, greaterThan(rawAttack.matchScore));
    expect(poison.matchedTags, contains('poison'));
  });

  test('BuildScoreService penalizes rejected tags', () {
    final database = _database();
    final service = BuildScoreService(database);
    const assessment = BuildAssessment(
      buildId: 'poison_shadow',
      label: 'Poison Shadow',
      isMixed: false,
      tagWeights: {'poison': 8, 'shadow': 4},
      buildScores: {'poison_shadow': 20},
    );

    final fire = service.scoreEquipment(
      equipment: _equipment(
        instanceId: 'fire',
        templateId: 'fire_wand',
        attack: 8,
        affixIds: const ['aff_fire_damage'],
      ),
      assessment: assessment,
    );

    expect(fire.rejectedTags, contains('fire'));
    expect(fire.matchScore, lessThan(0));
  });

  test('BuildScoreService keeps mixed builds conservative', () {
    final database = _database();
    final service = BuildScoreService(database);
    const mixed = BuildAssessment(
      buildId: BuildAssessment.mixedBuildId,
      label: 'Mixed Build',
      isMixed: true,
      tagWeights: {'utility': 1},
      buildScores: {},
    );

    final score = service.scoreEquipment(
      equipment: _equipment(
        instanceId: 'poison',
        templateId: 'poison_blade',
        attack: 8,
        affixIds: const ['aff_poison_damage'],
      ),
      assessment: mixed,
    );

    expect(score.matchScore, 0);
    expect(score.matchedTags, isEmpty);
  });

  test('EquipmentCompareService compares candidate against equipped item', () {
    final database = _database();
    final service = EquipmentCompareService(
      scoreService: BuildScoreService(database),
    );
    const assessment = BuildAssessment(
      buildId: 'poison_shadow',
      label: 'Poison Shadow',
      isMixed: false,
      tagWeights: {'poison': 8, 'shadow': 4},
      buildScores: {'poison_shadow': 20},
    );

    final comparison = service.compare(
      candidate: _equipment(
        instanceId: 'poison',
        templateId: 'poison_blade',
        attack: 8,
        affixIds: const ['aff_poison_damage'],
      ),
      equipped: _equipment(
        instanceId: 'raw',
        templateId: 'plain_axe',
        attack: 20,
        affixIds: const [],
      ),
      assessment: assessment,
    );

    expect(comparison.recommendation, EquipmentRecommendation.upgrade);
    expect(comparison.matchScoreDelta, greaterThan(0));
    expect(comparison.attackDelta, lessThan(0));
  });
}

EquipmentInstance _equipment({
  required String instanceId,
  required String templateId,
  required double attack,
  required List<String> affixIds,
}) {
  return EquipmentInstance(
    instanceId: instanceId,
    templateId: templateId,
    qualityId: 'rare',
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
        {
          'id': 'fire_wand',
          'name': 'Fire Wand',
          'affixRules': {
            'prefixMin': 0,
            'prefixMax': 1,
            'suffixMin': 0,
            'suffixMax': 1,
            'allowedTags': ['fire', 'burn'],
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
          'id': 'aff_fire_damage',
          'name': 'Fire Damage',
          'type': 'element',
          'tags': ['fire', 'burn'],
          'minLevel': 1,
          'weight': 100,
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
