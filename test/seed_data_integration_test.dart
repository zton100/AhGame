import 'package:abyss_relic/models/affix_config.dart';
import 'package:abyss_relic/systems/character/class_service.dart';
import 'package:abyss_relic/systems/character/level_service.dart';
import 'package:abyss_relic/systems/build/build_service.dart';
import 'package:abyss_relic/systems/config/data_loader.dart';
import 'package:abyss_relic/systems/config/game_database_service.dart';
import 'package:abyss_relic/systems/equipment/affix_effect_resolver.dart';
import 'package:abyss_relic/systems/equipment/affix_roll_service.dart';
import 'package:abyss_relic/systems/equipment/equipment_template_service.dart';
import 'package:abyss_relic/systems/equipment/equipment_generation_service.dart';
import 'package:abyss_relic/systems/equipment/quality_service.dart';
import 'package:abyss_relic/systems/stats/damage_formula_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seed data loads into GameDatabase without config issues', () async {
    final result = await const GameDatabaseService(
      dataLoader: DataLoader(),
    ).loadDataDirectory();

    expect(result.issues, isEmpty);
    expect(result.database.findRecord('classes', 'exile'), isNotNull);
    expect(result.database.findRecord('classes', 'necrospeaker'), isNotNull);
    expect(result.database.findRecord('classes', 'ember_mage'), isNotNull);
    expect(result.database.findRecord('classes', 'frost_ranger'), isNotNull);
    expect(result.database.findRecord('classes', 'sanctifier'), isNotNull);
    expect(result.database.findRecord('skills', 'toxic_slash'), isNotNull);
    expect(
      result.database.findRecord('drop_pools', 'drop_chapter_1'),
      isNotNull,
    );
    expect(result.database.findRecord('level_curves', 'default'), isNotNull);
    expect(result.database.findRecord('formula_config', 'default'), isNotNull);
    expect(result.database.findRecord('qualities', 'normal'), isNotNull);
    expect(
      result.database.findRecord('affixes', 'aff_poison_damage_pct_t1'),
      isNotNull,
    );
  });

  test('seed class data can be parsed by ClassService', () async {
    final result = await const GameDatabaseService(
      dataLoader: DataLoader(),
    ).loadDataDirectory();

    final classes = ClassService(result.database).listClasses();

    expect(classes.map((classConfig) => classConfig.id), [
      'ember_mage',
      'exile',
      'frost_ranger',
      'necrospeaker',
      'sanctifier',
    ]);
    for (final classConfig in classes) {
      expect(classConfig.name, isNotEmpty);
      expect(classConfig.tags, isNotEmpty);
      expect(classConfig.baseStats.hp, greaterThan(0));
      expect(classConfig.growth.attack, greaterThan(0));
    }
  });

  test('seed level curve can level a character', () async {
    final result = await const GameDatabaseService(
      dataLoader: DataLoader(),
    ).loadDataDirectory();

    final curve = LevelService(database: result.database).requireCurve();

    expect(curve.id, 'default');
    expect(curve.levelForTotalExperience(0), 1);
    expect(curve.levelForTotalExperience(100), 2);
  });

  test('seed formula config can calculate damage', () async {
    final result = await const GameDatabaseService(
      dataLoader: DataLoader(),
    ).loadDataDirectory();

    final damage = DamageFormulaService(database: result.database).calculate(
      const DamageContext(
        baseDamage: 100,
        skillMultiplier: 1,
        criticalChance: 1,
        resistance: 0,
        armor: 0,
        roll: 0,
      ),
    );

    expect(damage.isCritical, isTrue);
    expect(damage.finalDamage, 150);
  });

  test('seed equipment templates and qualities can be parsed', () async {
    final result = await const GameDatabaseService(
      dataLoader: DataLoader(),
    ).loadDataDirectory();

    final templates = EquipmentTemplateService(result.database).listTemplates();
    final qualities = QualityService(result.database).listQualities();

    expect(templates, hasLength(5));
    expect(templates.map((template) => template.id), contains('rusted_blade'));
    expect(qualities, hasLength(8));
    expect(qualities.last.id, 'forbidden');
  });

  test('seed equipment templates can generate an equipment instance', () async {
    final result = await const GameDatabaseService(
      dataLoader: DataLoader(),
    ).loadDataDirectory();
    final templateService = EquipmentTemplateService(result.database);
    final qualityService = QualityService(result.database);

    final equipment = EquipmentGenerationService(
      templateService: templateService,
      qualityService: qualityService,
      affixRollService: AffixRollService(result.database),
    ).generate(
      templateId: 'rusted_blade',
      qualityId: 'rare',
      classId: 'exile',
      level: 1,
      seed: 100,
    );

    expect(equipment.instanceId, isNotEmpty);
    expect(equipment.templateId, 'rusted_blade');
    expect(equipment.rolledBaseStats.single.stat, 'attack');
    expect(equipment.rolledAffixes.single.affixId, 'aff_poison_damage_pct_t1');
  });

  test('seed affixes can be parsed and rolled', () async {
    final result = await const GameDatabaseService(
      dataLoader: DataLoader(),
    ).loadDataDirectory();

    final service = AffixRollService(result.database);
    final candidates = service.candidatesFor(
      level: 1,
      allowedTags: const ['poison'],
    );
    final rolled = service.rollAffixes(
      level: 1,
      allowedTags: const ['poison'],
      count: 1,
      seed: 100,
    );

    expect(candidates.map((affix) => affix.id),
        contains('aff_poison_damage_pct_t1'));
    expect(candidates.map((affix) => affix.id),
        isNot(contains('aff_poison_can_crit')));
    expect(rolled.single.affixId, 'aff_poison_damage_pct_t1');
    expect(rolled.single.rollValue, isNotNull);
  });

  test('seed mechanic affixes can be resolved', () async {
    final result = await const GameDatabaseService(
      dataLoader: DataLoader(),
    ).loadDataDirectory();

    final affix =
        AffixRollService(result.database).requireAffix('aff_poison_can_crit');
    final resolved = const AffixEffectResolver().resolve(
      affix: affix,
      rolledAffix: const RolledAffix(
        affixId: 'aff_poison_can_crit',
        rollValue: null,
        exclusiveGroup: 'core_mechanic',
      ),
    );

    expect(resolved.eventTriggers.single.effectId, 'poison_can_crit');
    expect(resolved.warnings, isEmpty);
  });

  test('seed class skill and equipment tags identify a build', () async {
    final result = await const GameDatabaseService(
      dataLoader: DataLoader(),
    ).loadDataDirectory();
    final templateService = EquipmentTemplateService(result.database);
    final qualityService = QualityService(result.database);
    final equipment = EquipmentGenerationService(
      templateService: templateService,
      qualityService: qualityService,
      affixRollService: AffixRollService(result.database),
    ).generate(
      templateId: 'rusted_blade',
      qualityId: 'rare',
      classId: 'exile',
      level: 1,
      seed: 100,
    );

    final assessment = BuildService(result.database).assess(
      classId: 'exile',
      skillIds: const ['toxic_slash'],
      equipment: [equipment],
    );

    expect(assessment.buildId, 'poison_shadow');
    expect(assessment.isMixed, isFalse);
  });
}
