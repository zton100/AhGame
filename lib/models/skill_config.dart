class SkillConfig {
  const SkillConfig({
    required this.id,
    required this.name,
    required this.classId,
    required this.skillType,
    required this.tags,
    required this.cooldown,
    required this.resourceCost,
    required this.effects,
  });

  factory SkillConfig.fromJson(Map<String, Object?> json) {
    return SkillConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      classId: json['classId'] as String,
      skillType: json['skillType'] as String? ?? 'active',
      tags: List<String>.from(json['tags'] as List? ?? const []),
      cooldown: _number(json, 'cooldown', defaultValue: 0),
      resourceCost: _number(json, 'resourceCost', defaultValue: 0),
      effects: [
        for (final effect in json['effects'] as List? ?? const [])
          SkillEffectConfig.fromJson(
            Map<String, Object?>.from(effect as Map),
          ),
      ],
    );
  }

  final String id;
  final String name;
  final String classId;
  final String skillType;
  final List<String> tags;
  final double cooldown;
  final double resourceCost;
  final List<SkillEffectConfig> effects;

  bool get isActive => skillType == 'active';
  bool get isPassive => skillType == 'passive';
  bool get isUltimate => skillType == 'ultimate';

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'classId': classId,
      'skillType': skillType,
      'tags': tags,
      'cooldown': cooldown,
      'resourceCost': resourceCost,
      'effects': [for (final effect in effects) effect.toJson()],
    };
  }
}

class SkillEffectConfig {
  const SkillEffectConfig({
    required this.effectId,
    required this.params,
  });

  factory SkillEffectConfig.fromJson(Map<String, Object?> json) {
    return SkillEffectConfig(
      effectId: json['effectId'] as String,
      params: Map<String, Object?>.from(json['params'] as Map? ?? const {}),
    );
  }

  final String effectId;
  final Map<String, Object?> params;

  bool get isDirectDamage {
    return effectId == 'direct_damage' || effectId == 'deal_damage';
  }

  double get damageMultiplier {
    return _number(params, 'multiplier', defaultValue: 1);
  }

  String? get damageType => params['damageType'] as String?;

  Map<String, Object?> toJson() {
    return {
      'effectId': effectId,
      'params': params,
    };
  }
}

double _number(
  Map<String, Object?> json,
  String fieldName, {
  required double defaultValue,
}) {
  final value = json[fieldName];
  if (value == null) {
    return defaultValue;
  }

  if (value is num) {
    return value.toDouble();
  }

  throw FormatException('Expected $fieldName to be a number.');
}
