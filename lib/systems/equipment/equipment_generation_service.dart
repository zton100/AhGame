import 'dart:math';

import '../../models/affix_config.dart';
import '../../models/equipment_instance.dart';
import '../../models/equipment_template.dart';
import 'affix_roll_service.dart';
import 'equipment_template_service.dart';
import 'quality_service.dart';

class EquipmentGenerationService {
  const EquipmentGenerationService({
    required EquipmentTemplateService templateService,
    required QualityService qualityService,
    AffixRollService? affixRollService,
  })  : _templateService = templateService,
        _qualityService = qualityService,
        _affixRollService = affixRollService;

  final EquipmentTemplateService _templateService;
  final QualityService _qualityService;
  final AffixRollService? _affixRollService;

  EquipmentInstance generate({
    required String templateId,
    required String qualityId,
    required String classId,
    required int level,
    required int seed,
    DateTime? createdAt,
  }) {
    final template = _templateService.requireTemplate(templateId);
    final quality = _qualityService.requireQuality(qualityId);
    _validate(
        template: template,
        qualityId: qualityId,
        classId: classId,
        level: level);

    final random = Random(seed);
    final rolledBaseStats = [
      for (final stat in template.baseStats)
        RolledBaseStat(
          stat: stat.stat,
          value: _roll(stat.min, stat.max, random) * quality.statMultiplier,
        ),
    ];

    return EquipmentInstance(
      instanceId: _instanceId(
        templateId: templateId,
        qualityId: qualityId,
        level: level,
        seed: seed,
      ),
      templateId: templateId,
      qualityId: qualityId,
      level: level,
      createdAt: createdAt ?? DateTime.now().toUtc(),
      rolledBaseStats: rolledBaseStats,
      rolledAffixes: _rollAffixes(
        template: template,
        level: level,
        seed: seed,
        minCount: quality.affixMin,
        maxCount: quality.affixMax,
      ),
    );
  }

  void _validate({
    required EquipmentTemplate template,
    required String qualityId,
    required String classId,
    required int level,
  }) {
    if (level < template.minLevel) {
      throw StateError(
        'Template ${template.id} requires level ${template.minLevel}.',
      );
    }

    if (!template.qualityPool.contains(qualityId)) {
      throw StateError(
          'Template ${template.id} cannot roll quality $qualityId.');
    }

    if (!template.allowedClasses.contains('all') &&
        !template.allowedClasses.contains(classId)) {
      throw StateError('Template ${template.id} is not allowed for $classId.');
    }
  }

  double _roll(double min, double max, Random random) {
    if (max <= min) {
      return min;
    }

    return min + (max - min) * random.nextDouble();
  }

  int _rollAffixCount({
    required int minCount,
    required int maxCount,
    required Random random,
  }) {
    final min = minCount < 0
        ? 0
        : minCount > maxCount
            ? maxCount
            : minCount;
    if (maxCount <= min) {
      return min;
    }

    return min + random.nextInt(maxCount - min + 1);
  }

  List<RolledAffix> _rollAffixes({
    required EquipmentTemplate template,
    required int level,
    required int seed,
    required int minCount,
    required int maxCount,
  }) {
    final affixRollService = _affixRollService;
    if (affixRollService == null) {
      return const [];
    }

    final random = Random(seed ^ 0xaff1);
    final count = _rollAffixCount(
      minCount: minCount,
      maxCount: maxCount,
      random: random,
    );

    return affixRollService.rollAffixes(
      level: level,
      allowedTags: template.affixRules.allowedTags,
      count: count,
      seed: seed ^ 0xaff2,
    );
  }

  String _instanceId({
    required String templateId,
    required String qualityId,
    required int level,
    required int seed,
  }) {
    return 'eq_${templateId}_${qualityId}_${level}_$seed';
  }
}
