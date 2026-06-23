import 'affix_config.dart';

class EquipmentInstance {
  const EquipmentInstance({
    required this.instanceId,
    required this.templateId,
    required this.qualityId,
    required this.level,
    required this.createdAt,
    required this.rolledBaseStats,
    required this.rolledAffixes,
  });

  factory EquipmentInstance.fromJson(Map<String, Object?> json) {
    return EquipmentInstance(
      instanceId: json['instanceId'] as String,
      templateId: json['templateId'] as String,
      qualityId: json['qualityId'] as String,
      level: json['level'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      rolledBaseStats: [
        for (final stat in json['rolledBaseStats'] as List)
          RolledBaseStat.fromJson(Map<String, Object?>.from(stat as Map)),
      ],
      rolledAffixes: [
        for (final affix in json['rolledAffixes'] as List? ?? const [])
          if (affix is String)
            RolledAffix(
              affixId: affix,
              rollValue: null,
              exclusiveGroup: null,
            )
          else
            RolledAffix.fromJson(Map<String, Object?>.from(affix as Map)),
      ],
    );
  }

  final String instanceId;
  final String templateId;
  final String qualityId;
  final int level;
  final DateTime createdAt;
  final List<RolledBaseStat> rolledBaseStats;
  final List<RolledAffix> rolledAffixes;

  Map<String, Object?> toJson() {
    return {
      'instanceId': instanceId,
      'templateId': templateId,
      'qualityId': qualityId,
      'level': level,
      'createdAt': createdAt.toIso8601String(),
      'rolledBaseStats': [
        for (final stat in rolledBaseStats) stat.toJson(),
      ],
      'rolledAffixes': [
        for (final affix in rolledAffixes) affix.toJson(),
      ],
    };
  }
}

class RolledBaseStat {
  const RolledBaseStat({
    required this.stat,
    required this.value,
  });

  factory RolledBaseStat.fromJson(Map<String, Object?> json) {
    return RolledBaseStat(
      stat: json['stat'] as String,
      value: (json['value'] as num).toDouble(),
    );
  }

  final String stat;
  final double value;

  Map<String, Object?> toJson() {
    return {
      'stat': stat,
      'value': value,
    };
  }
}
