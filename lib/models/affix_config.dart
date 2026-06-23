import 'dart:math';

class AffixConfig {
  const AffixConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.tags,
    required this.minLevel,
    required this.weight,
    required this.rollRange,
    required this.statModifiers,
    required this.effect,
    required this.exclusiveGroup,
  });

  factory AffixConfig.fromJson(Map<String, Object?> json) {
    return AffixConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      tags: List<String>.from(json['tags'] as List? ?? const []),
      minLevel: json['minLevel'] as int,
      weight: json['weight'] as int,
      rollRange: json['rollRange'] == null
          ? null
          : AffixRollRange.fromJson(
              Map<String, Object?>.from(json['rollRange'] as Map),
            ),
      statModifiers: [
        for (final modifier
            in json['statModifiers'] as List? ?? const <Object?>[])
          AffixStatModifierConfig.fromJson(
            Map<String, Object?>.from(modifier as Map),
          ),
      ],
      effect: json['effect'] == null
          ? null
          : AffixEffectConfig.fromJson(
              Map<String, Object?>.from(json['effect'] as Map),
            ),
      exclusiveGroup: json['exclusiveGroup'] as String?,
    );
  }

  final String id;
  final String name;
  final String type;
  final List<String> tags;
  final int minLevel;
  final int weight;
  final AffixRollRange? rollRange;
  final List<AffixStatModifierConfig> statModifiers;
  final AffixEffectConfig? effect;
  final String? exclusiveGroup;
}

class AffixRollRange {
  const AffixRollRange({
    required this.min,
    required this.max,
    required this.step,
  });

  factory AffixRollRange.fromJson(Map<String, Object?> json) {
    return AffixRollRange(
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
      step: (json['step'] as num?)?.toDouble() ?? 0,
    );
  }

  final double min;
  final double max;
  final double step;

  double roll(Random random) {
    if (max <= min) {
      return min;
    }

    if (step <= 0) {
      return min + (max - min) * random.nextDouble();
    }

    final stepCount = ((max - min) / step).floor();
    final value = min + random.nextInt(stepCount + 1) * step;
    return value.clamp(min, max).toDouble();
  }
}

class AffixStatModifierConfig {
  const AffixStatModifierConfig({
    required this.stat,
    required this.mode,
    required this.valueFromRoll,
    required this.value,
  });

  factory AffixStatModifierConfig.fromJson(Map<String, Object?> json) {
    return AffixStatModifierConfig(
      stat: json['stat'] as String,
      mode: AffixModifierMode.fromId(json['mode'] as String),
      valueFromRoll: json['valueFromRoll'] as bool? ?? false,
      value: (json['value'] as num?)?.toDouble(),
    );
  }

  final String stat;
  final AffixModifierMode mode;
  final bool valueFromRoll;
  final double? value;
}

class AffixEffectConfig {
  const AffixEffectConfig({
    required this.effectId,
    required this.params,
  });

  factory AffixEffectConfig.fromJson(Map<String, Object?> json) {
    return AffixEffectConfig(
      effectId: json['effectId'] as String,
      params: Map<String, Object?>.from(json['params'] as Map? ?? const {}),
    );
  }

  final String effectId;
  final Map<String, Object?> params;
}

enum AffixModifierMode {
  flat('flat'),
  percent('percent'),
  more('more'),
  less('less');

  const AffixModifierMode(this.id);

  final String id;

  static AffixModifierMode fromId(String id) {
    for (final mode in values) {
      if (mode.id == id) {
        return mode;
      }
    }

    throw ArgumentError.value(id, 'id', 'Unknown affix modifier mode.');
  }
}

class RolledAffix {
  const RolledAffix({
    required this.affixId,
    required this.rollValue,
    required this.exclusiveGroup,
  });

  final String affixId;
  final double? rollValue;
  final String? exclusiveGroup;
}
