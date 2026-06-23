import '../../models/equipment_instance.dart';
import '../config/game_database.dart';

class BuildService {
  const BuildService(
    GameDatabase database, {
    List<BuildConfig> buildConfigs = _defaultBuildConfigs,
  })  : _database = database,
        _buildConfigs = buildConfigs;

  final GameDatabase _database;
  final List<BuildConfig> _buildConfigs;

  BuildAssessment assess({
    required String classId,
    Iterable<String> skillIds = const [],
    Iterable<EquipmentInstance> equipment = const [],
  }) {
    final tagWeights = <String, double>{};

    _addTags(
      tagWeights,
      _tagsFromRecord(_database.findRecord('classes', classId)),
      1,
    );

    for (final skillId in skillIds) {
      _addTags(
        tagWeights,
        _tagsFromRecord(_database.findRecord('skills', skillId)),
        2,
      );
    }

    for (final item in equipment) {
      final template = _database.findRecord(
        'equipment_templates',
        item.templateId,
      );
      final affixRules = template?['affixRules'];
      if (affixRules is Map) {
        _addTags(
          tagWeights,
          List<String>.from(affixRules['allowedTags'] as List? ?? const []),
          0.5,
        );
      }

      for (final rolledAffix in item.rolledAffixes) {
        _addTags(
          tagWeights,
          _tagsFromRecord(_database.findRecord('affixes', rolledAffix.affixId)),
          3,
        );
      }
    }

    final scores = {
      for (final config in _buildConfigs) config.id: config.score(tagWeights),
    };
    final ranked = [..._buildConfigs]..sort((a, b) {
        return scores[b.id]!.compareTo(scores[a.id]!);
      });
    final best = ranked.first;
    final bestScore = scores[best.id]!;
    final secondScore = ranked.length > 1 ? scores[ranked[1].id]! : 0.0;

    if (bestScore < 4 || bestScore - secondScore < 2) {
      return BuildAssessment(
        buildId: BuildAssessment.mixedBuildId,
        label: 'Mixed Build',
        isMixed: true,
        tagWeights: Map.unmodifiable(tagWeights),
        buildScores: Map.unmodifiable(scores),
      );
    }

    return BuildAssessment(
      buildId: best.id,
      label: best.label,
      isMixed: false,
      tagWeights: Map.unmodifiable(tagWeights),
      buildScores: Map.unmodifiable(scores),
    );
  }

  List<String> _tagsFromRecord(Map<String, Object?>? record) {
    return List<String>.from(record?['tags'] as List? ?? const []);
  }

  void _addTags(
    Map<String, double> tagWeights,
    Iterable<String> tags,
    double weight,
  ) {
    for (final tag in tags) {
      tagWeights[tag] = (tagWeights[tag] ?? 0) + weight;
    }
  }
}

class BuildConfig {
  const BuildConfig({
    required this.id,
    required this.label,
    required this.coreTags,
    required this.secondaryTags,
  });

  final String id;
  final String label;
  final List<String> coreTags;
  final List<String> secondaryTags;

  double score(Map<String, double> tagWeights) {
    var score = 0.0;

    for (final tag in coreTags) {
      score += (tagWeights[tag] ?? 0) * 2;
    }

    for (final tag in secondaryTags) {
      score += tagWeights[tag] ?? 0;
    }

    return score;
  }
}

class BuildAssessment {
  const BuildAssessment({
    required this.buildId,
    required this.label,
    required this.isMixed,
    required this.tagWeights,
    required this.buildScores,
  });

  static const mixedBuildId = 'mixed';

  final String buildId;
  final String label;
  final bool isMixed;
  final Map<String, double> tagWeights;
  final Map<String, double> buildScores;
}

const _defaultBuildConfigs = [
  BuildConfig(
    id: 'poison_shadow',
    label: 'Poison Shadow',
    coreTags: ['poison', 'shadow'],
    secondaryTags: ['bleed', 'low_hp', 'crit'],
  ),
  BuildConfig(
    id: 'summon_undead',
    label: 'Summon Undead',
    coreTags: ['summon', 'undead'],
    secondaryTags: ['curse', 'shield'],
  ),
  BuildConfig(
    id: 'fire_burn',
    label: 'Fire Burn',
    coreTags: ['fire', 'burn'],
    secondaryTags: ['spell', 'burst'],
  ),
  BuildConfig(
    id: 'frost_crit',
    label: 'Frost Crit',
    coreTags: ['frost', 'crit'],
    secondaryTags: ['ranged', 'control'],
  ),
  BuildConfig(
    id: 'holy_block',
    label: 'Holy Block',
    coreTags: ['holy', 'block'],
    secondaryTags: ['heal', 'judgement'],
  ),
];
