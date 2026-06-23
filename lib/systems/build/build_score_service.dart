import '../../models/equipment_instance.dart';
import '../config/game_database.dart';
import 'build_service.dart';

class BuildScoreService {
  const BuildScoreService(this._database);

  final GameDatabase _database;

  EquipmentBuildScore scoreEquipment({
    required EquipmentInstance equipment,
    required BuildAssessment assessment,
  }) {
    final attackScore = _baseStat(equipment, 'attack');
    if (assessment.isMixed) {
      return EquipmentBuildScore(
        equipmentId: equipment.instanceId,
        buildId: assessment.buildId,
        matchScore: 0,
        attackScore: attackScore,
        matchedTags: const [],
        rejectedTags: const [],
      );
    }

    final tags = _equipmentTags(equipment);
    final matchedTags = <String>{};
    final rejectedTags = <String>{};
    var matchScore = 0.0;

    for (final tag in tags) {
      final buildWeight = assessment.tagWeights[tag] ?? 0;
      if (buildWeight > 0) {
        matchedTags.add(tag);
        matchScore += 4 + buildWeight;
        continue;
      }

      if (_isRejected(tag, assessment)) {
        rejectedTags.add(tag);
        matchScore -= 6;
      }
    }

    return EquipmentBuildScore(
      equipmentId: equipment.instanceId,
      buildId: assessment.buildId,
      matchScore: matchScore,
      attackScore: attackScore,
      matchedTags: List.unmodifiable(matchedTags),
      rejectedTags: List.unmodifiable(rejectedTags),
    );
  }

  Set<String> _equipmentTags(EquipmentInstance equipment) {
    final tags = <String>{};
    final template = _database.findRecord(
      'equipment_templates',
      equipment.templateId,
    );
    final affixRules = template?['affixRules'];
    if (affixRules is Map) {
      tags.addAll(
        List<String>.from(affixRules['allowedTags'] as List? ?? const []),
      );
    }

    for (final affix in equipment.rolledAffixes) {
      final record = _database.findRecord('affixes', affix.affixId);
      tags.addAll(List<String>.from(record?['tags'] as List? ?? const []));
    }

    return tags;
  }

  bool _isRejected(String tag, BuildAssessment assessment) {
    if (assessment.tagWeights.containsKey(tag)) {
      return false;
    }

    for (final knownTag in assessment.tagWeights.keys) {
      if (_exclusiveGroups[tag] == _exclusiveGroups[knownTag]) {
        return true;
      }
    }

    return false;
  }

  double _baseStat(EquipmentInstance equipment, String stat) {
    return equipment.rolledBaseStats
        .where((baseStat) => baseStat.stat == stat)
        .fold<double>(0, (sum, baseStat) => sum + baseStat.value);
  }
}

class EquipmentBuildScore {
  const EquipmentBuildScore({
    required this.equipmentId,
    required this.buildId,
    required this.matchScore,
    required this.attackScore,
    required this.matchedTags,
    required this.rejectedTags,
  });

  final String equipmentId;
  final String buildId;
  final double matchScore;
  final double attackScore;
  final List<String> matchedTags;
  final List<String> rejectedTags;
}

const _exclusiveGroups = {
  'poison': 'element_damage',
  'shadow': 'dark_damage',
  'fire': 'element_damage',
  'burn': 'element_damage',
  'frost': 'element_damage',
  'holy': 'element_damage',
  'summon': 'minion',
  'undead': 'minion',
};
