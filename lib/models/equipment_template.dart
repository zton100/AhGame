class EquipmentTemplate {
  const EquipmentTemplate({
    required this.id,
    required this.name,
    required this.slot,
    required this.allowedClasses,
    required this.minLevel,
    required this.qualityPool,
    required this.baseStats,
    required this.affixRules,
  });

  factory EquipmentTemplate.fromJson(Map<String, Object?> json) {
    return EquipmentTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      slot: EquipmentSlot.fromId(json['slot'] as String),
      allowedClasses: List<String>.from(json['allowedClasses'] as List),
      minLevel: json['minLevel'] as int,
      qualityPool: List<String>.from(json['qualityPool'] as List),
      baseStats: [
        for (final stat in json['baseStats'] as List)
          EquipmentBaseStatRange.fromJson(
              Map<String, Object?>.from(stat as Map)),
      ],
      affixRules: EquipmentAffixRules.fromJson(
        Map<String, Object?>.from(json['affixRules'] as Map),
      ),
    );
  }

  final String id;
  final String name;
  final EquipmentSlot slot;
  final List<String> allowedClasses;
  final int minLevel;
  final List<String> qualityPool;
  final List<EquipmentBaseStatRange> baseStats;
  final EquipmentAffixRules affixRules;
}

class EquipmentBaseStatRange {
  const EquipmentBaseStatRange({
    required this.stat,
    required this.min,
    required this.max,
  });

  factory EquipmentBaseStatRange.fromJson(Map<String, Object?> json) {
    return EquipmentBaseStatRange(
      stat: json['stat'] as String,
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
    );
  }

  final String stat;
  final double min;
  final double max;
}

class EquipmentAffixRules {
  const EquipmentAffixRules({
    required this.prefixMin,
    required this.prefixMax,
    required this.suffixMin,
    required this.suffixMax,
    required this.allowedTags,
  });

  factory EquipmentAffixRules.fromJson(Map<String, Object?> json) {
    return EquipmentAffixRules(
      prefixMin: json['prefixMin'] as int,
      prefixMax: json['prefixMax'] as int,
      suffixMin: json['suffixMin'] as int,
      suffixMax: json['suffixMax'] as int,
      allowedTags: List<String>.from(json['allowedTags'] as List),
    );
  }

  final int prefixMin;
  final int prefixMax;
  final int suffixMin;
  final int suffixMax;
  final List<String> allowedTags;
}

enum EquipmentSlot {
  mainWeapon('main_weapon'),
  offhand('offhand'),
  helmet('helmet'),
  chest('chest'),
  gloves('gloves'),
  boots('boots'),
  belt('belt'),
  amulet('amulet'),
  ring1('ring_1'),
  ring2('ring_2'),
  relic('relic'),
  soulCore('soul_core');

  const EquipmentSlot(this.id);

  final String id;

  static EquipmentSlot fromId(String id) {
    for (final slot in values) {
      if (slot.id == id) {
        return slot;
      }
    }

    throw ArgumentError.value(id, 'id', 'Unknown equipment slot.');
  }
}
