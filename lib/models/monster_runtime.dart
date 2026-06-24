import 'dart:math' as math;

class MonsterRuntime {
  const MonsterRuntime({
    required this.monsterId,
    required this.level,
    required this.maxHp,
    required this.currentHp,
    required this.attack,
    required this.armor,
    required this.tags,
  });

  factory MonsterRuntime.fromJson(Map<String, Object?> json) {
    return MonsterRuntime(
      monsterId: json['monsterId'] as String,
      level: json['level'] as int,
      maxHp: (json['maxHp'] as num).toDouble(),
      currentHp: (json['currentHp'] as num).toDouble(),
      attack: (json['attack'] as num).toDouble(),
      armor: (json['armor'] as num).toDouble(),
      tags: List<String>.from(json['tags'] as List? ?? const []),
    );
  }

  final String monsterId;
  final int level;
  final double maxHp;
  final double currentHp;
  final double attack;
  final double armor;
  final List<String> tags;

  bool get isAlive => currentHp > 0;

  MonsterRuntime takeDamage(num amount) {
    final damage = math.max(0, amount.toDouble());
    return copyWith(currentHp: math.max(0, currentHp - damage));
  }

  MonsterRuntime heal(num amount) {
    final healing = math.max(0, amount.toDouble());
    return copyWith(currentHp: math.min(maxHp, currentHp + healing));
  }

  MonsterRuntime copyWith({
    double? currentHp,
  }) {
    return MonsterRuntime(
      monsterId: monsterId,
      level: level,
      maxHp: maxHp,
      currentHp: currentHp ?? this.currentHp,
      attack: attack,
      armor: armor,
      tags: tags,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'monsterId': monsterId,
      'level': level,
      'maxHp': maxHp,
      'currentHp': currentHp,
      'attack': attack,
      'armor': armor,
      'tags': tags,
    };
  }
}
