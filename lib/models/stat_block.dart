class StatBlock {
  const StatBlock({
    required this.hp,
    required this.attack,
    required this.armor,
  });

  factory StatBlock.fromJson(Map<String, Object?> json) {
    return StatBlock(
      hp: _number(json, 'hp'),
      attack: _number(json, 'attack'),
      armor: _number(json, 'armor'),
    );
  }

  final double hp;
  final double attack;
  final double armor;

  StatBlock operator +(StatBlock other) {
    return StatBlock(
      hp: hp + other.hp,
      attack: attack + other.attack,
      armor: armor + other.armor,
    );
  }

  StatBlock scale(num multiplier) {
    return StatBlock(
      hp: hp * multiplier,
      attack: attack * multiplier,
      armor: armor * multiplier,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'hp': hp,
      'attack': attack,
      'armor': armor,
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
