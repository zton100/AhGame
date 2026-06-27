import '../../core/theme/quality_theme.dart';
import '../../models/affix_config.dart';
import '../../models/equipment_instance.dart';
import '../../systems/build/build_service.dart';
import '../../systems/build/equipment_compare_service.dart';
import '../../systems/config/game_database.dart';
import '../common/game_text_labels.dart';

class EquipmentCardViewModelFactory {
  const EquipmentCardViewModelFactory({
    required GameDatabase database,
    required EquipmentCompareService compareService,
  })  : _database = database,
        _compareService = compareService;

  final GameDatabase _database;
  final EquipmentCompareService _compareService;

  EquipmentCardViewModel create({
    required EquipmentInstance equipment,
    required BuildAssessment assessment,
    EquipmentInstance? equipped,
  }) {
    final comparison = _compareService.compare(
      candidate: equipment,
      equipped: equipped,
      assessment: assessment,
    );
    final template = _database.findRecord(
      'equipment_templates',
      equipment.templateId,
    );
    final quality = _database.findRecord('qualities', equipment.qualityId);
    final themeQuality = _qualityThemeFor(equipment.qualityId);

    return EquipmentCardViewModel(
      equipmentId: equipment.instanceId,
      title: template?['name'] as String? ?? equipment.templateId,
      qualityId: equipment.qualityId,
      qualityLabel: quality?['name'] as String? ??
          themeQuality?.label ??
          equipment.qualityId,
      qualityColorValue: _colorValue(themeQuality),
      baseStats: [
        for (final stat in equipment.rolledBaseStats)
          EquipmentStatViewModel(
            label: statLabel(stat.stat),
            value: stat.value,
          ),
      ],
      affixes: [
        for (final affix in equipment.rolledAffixes) _affixViewModel(affix),
      ],
      matchScore: comparison.candidateScore.matchScore,
      matchScoreDelta: comparison.matchScoreDelta,
      attackDelta: comparison.attackDelta,
      matchedTags: comparison.candidateScore.matchedTags,
      rejectedTags: comparison.candidateScore.rejectedTags,
      recommendationLabel: _recommendationLabel(comparison.recommendation),
    );
  }

  EquipmentAffixViewModel _affixViewModel(RolledAffix affix) {
    final record = _database.findRecord('affixes', affix.affixId);
    return EquipmentAffixViewModel(
      affixId: affix.affixId,
      name: record?['name'] as String? ?? affix.affixId,
      rollValue: affix.rollValue,
      tags: [
        for (final tag in List<String>.from(
          record?['tags'] as List? ?? const [],
        ))
          tagLabel(tag),
      ],
      isMechanic: record?['effect'] is Map,
    );
  }

  EquipmentQuality? _qualityThemeFor(String qualityId) {
    for (final quality in EquipmentQuality.values) {
      if (quality.id == qualityId) {
        return quality;
      }
    }

    return null;
  }

  int _colorValue(EquipmentQuality? quality) {
    final color = quality?.color;
    if (color == null) {
      return 0xFFB7BEC9;
    }

    return (color.a * 255).round() << 24 |
        (color.r * 255).round() << 16 |
        (color.g * 255).round() << 8 |
        (color.b * 255).round();
  }

  String _recommendationLabel(EquipmentRecommendation recommendation) {
    switch (recommendation) {
      case EquipmentRecommendation.upgrade:
        return '推荐替换';
      case EquipmentRecommendation.sidegrade:
        return '可选替换';
      case EquipmentRecommendation.downgrade:
        return '不推荐';
    }
  }
}

class EquipmentCardViewModel {
  const EquipmentCardViewModel({
    required this.equipmentId,
    required this.title,
    required this.qualityId,
    required this.qualityLabel,
    required this.qualityColorValue,
    required this.baseStats,
    required this.affixes,
    required this.matchScore,
    required this.matchScoreDelta,
    required this.attackDelta,
    required this.matchedTags,
    required this.rejectedTags,
    required this.recommendationLabel,
  });

  final String equipmentId;
  final String title;
  final String qualityId;
  final String qualityLabel;
  final int qualityColorValue;
  final List<EquipmentStatViewModel> baseStats;
  final List<EquipmentAffixViewModel> affixes;
  final double matchScore;
  final double matchScoreDelta;
  final double attackDelta;
  final List<String> matchedTags;
  final List<String> rejectedTags;
  final String recommendationLabel;
}

class EquipmentStatViewModel {
  const EquipmentStatViewModel({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

class EquipmentAffixViewModel {
  const EquipmentAffixViewModel({
    required this.affixId,
    required this.name,
    required this.rollValue,
    required this.tags,
    required this.isMechanic,
  });

  final String affixId;
  final String name;
  final double? rollValue;
  final List<String> tags;
  final bool isMechanic;
}
