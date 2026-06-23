class FormulaConfig {
  const FormulaConfig({
    required this.id,
    required this.name,
    required this.criticalChanceHardCap,
    required this.defaultCriticalMultiplier,
    required this.resistanceHardCap,
    required this.armorConstant,
  });

  factory FormulaConfig.fromJson(Map<String, Object?> json) {
    final critical = Map<String, Object?>.from(json['critical'] as Map);
    final resistance = Map<String, Object?>.from(json['resistance'] as Map);
    final armor = Map<String, Object?>.from(json['armor'] as Map);

    return FormulaConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      criticalChanceHardCap: _number(critical, 'chanceHardCap'),
      defaultCriticalMultiplier: _number(critical, 'defaultMultiplier'),
      resistanceHardCap: _number(resistance, 'hardCap'),
      armorConstant: _number(armor, 'constant'),
    );
  }

  final String id;
  final String name;
  final double criticalChanceHardCap;
  final double defaultCriticalMultiplier;
  final double resistanceHardCap;
  final double armorConstant;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'critical': {
        'chanceHardCap': criticalChanceHardCap,
        'defaultMultiplier': defaultCriticalMultiplier,
      },
      'resistance': {'hardCap': resistanceHardCap},
      'armor': {'constant': armorConstant},
    };
  }

  static double _number(Map<String, Object?> json, String fieldName) {
    final value = json[fieldName];
    if (value is num) {
      return value.toDouble();
    }

    throw FormatException('Expected $fieldName to be a number.');
  }
}
