class StatBlock {
  const StatBlock({
    required this.hp,
    required this.attack,
    required this.armor,
    this.critChance = 0,
    this.critDamage = 0,
    this.attackSpeed = 0,
    this.poisonDamage = 0,
    this.fireDamage = 0,
    this.frostDamage = 0,
    this.shadowDamage = 0,
    this.holyDamage = 0,
    this.summonDamage = 0,
    this.blockChance = 0,
    this.shield = 0,
  });

  factory StatBlock.fromJson(Map<String, Object?> json) {
    return StatBlock(
      hp: _number(json, 'hp'),
      attack: _number(json, 'attack'),
      armor: _number(json, 'armor'),
      critChance: _optionalNumber(json, 'crit_chance'),
      critDamage: _optionalNumber(json, 'crit_damage'),
      attackSpeed: _optionalNumber(json, 'attack_speed'),
      poisonDamage: _optionalNumber(json, 'poison_damage'),
      fireDamage: _optionalNumber(json, 'fire_damage'),
      frostDamage: _optionalNumber(json, 'frost_damage'),
      shadowDamage: _optionalNumber(json, 'shadow_damage'),
      holyDamage: _optionalNumber(json, 'holy_damage'),
      summonDamage: _optionalNumber(json, 'summon_damage'),
      blockChance: _optionalNumber(json, 'block_chance'),
      shield: _optionalNumber(json, 'shield'),
    );
  }

  factory StatBlock.fromStatIdMap(Map<String, double> values) {
    return StatBlock(
      hp: values['hp'] ?? 0,
      attack: values['attack'] ?? 0,
      armor: values['armor'] ?? 0,
      critChance: values['crit_chance'] ?? 0,
      critDamage: values['crit_damage'] ?? 0,
      attackSpeed: values['attack_speed'] ?? 0,
      poisonDamage: values['poison_damage'] ?? 0,
      fireDamage: values['fire_damage'] ?? 0,
      frostDamage: values['frost_damage'] ?? 0,
      shadowDamage: values['shadow_damage'] ?? 0,
      holyDamage: values['holy_damage'] ?? 0,
      summonDamage: values['summon_damage'] ?? 0,
      blockChance: values['block_chance'] ?? 0,
      shield: values['shield'] ?? 0,
    );
  }

  final double hp;
  final double attack;
  final double armor;
  final double critChance;
  final double critDamage;
  final double attackSpeed;
  final double poisonDamage;
  final double fireDamage;
  final double frostDamage;
  final double shadowDamage;
  final double holyDamage;
  final double summonDamage;
  final double blockChance;
  final double shield;

  StatBlock operator +(StatBlock other) {
    return StatBlock(
      hp: hp + other.hp,
      attack: attack + other.attack,
      armor: armor + other.armor,
      critChance: critChance + other.critChance,
      critDamage: critDamage + other.critDamage,
      attackSpeed: attackSpeed + other.attackSpeed,
      poisonDamage: poisonDamage + other.poisonDamage,
      fireDamage: fireDamage + other.fireDamage,
      frostDamage: frostDamage + other.frostDamage,
      shadowDamage: shadowDamage + other.shadowDamage,
      holyDamage: holyDamage + other.holyDamage,
      summonDamage: summonDamage + other.summonDamage,
      blockChance: blockChance + other.blockChance,
      shield: shield + other.shield,
    );
  }

  StatBlock scale(num multiplier) {
    return StatBlock(
      hp: hp * multiplier,
      attack: attack * multiplier,
      armor: armor * multiplier,
      critChance: critChance * multiplier,
      critDamage: critDamage * multiplier,
      attackSpeed: attackSpeed * multiplier,
      poisonDamage: poisonDamage * multiplier,
      fireDamage: fireDamage * multiplier,
      frostDamage: frostDamage * multiplier,
      shadowDamage: shadowDamage * multiplier,
      holyDamage: holyDamage * multiplier,
      summonDamage: summonDamage * multiplier,
      blockChance: blockChance * multiplier,
      shield: shield * multiplier,
    );
  }

  double valueForId(String statId) {
    switch (statId) {
      case 'hp':
        return hp;
      case 'attack':
        return attack;
      case 'armor':
        return armor;
      case 'crit_chance':
        return critChance;
      case 'crit_damage':
        return critDamage;
      case 'attack_speed':
        return attackSpeed;
      case 'poison_damage':
        return poisonDamage;
      case 'fire_damage':
        return fireDamage;
      case 'frost_damage':
        return frostDamage;
      case 'shadow_damage':
        return shadowDamage;
      case 'holy_damage':
        return holyDamage;
      case 'summon_damage':
        return summonDamage;
      case 'block_chance':
        return blockChance;
      case 'shield':
        return shield;
      default:
        return 0;
    }
  }

  Map<String, Object?> toJson() {
    return {
      'hp': hp,
      'attack': attack,
      'armor': armor,
      'crit_chance': critChance,
      'crit_damage': critDamage,
      'attack_speed': attackSpeed,
      'poison_damage': poisonDamage,
      'fire_damage': fireDamage,
      'frost_damage': frostDamage,
      'shadow_damage': shadowDamage,
      'holy_damage': holyDamage,
      'summon_damage': summonDamage,
      'block_chance': blockChance,
      'shield': shield,
    };
  }

  static double _number(Map<String, Object?> json, String fieldName) {
    final value = json[fieldName];
    if (value is num) {
      return value.toDouble();
    }

    throw FormatException('Expected $fieldName to be a number.');
  }

  static double _optionalNumber(Map<String, Object?> json, String fieldName) {
    final value = json[fieldName];
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    throw FormatException('Expected $fieldName to be a number.');
  }
}
