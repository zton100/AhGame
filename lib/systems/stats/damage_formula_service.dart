import 'dart:math' as math;

import '../../models/formula_config.dart';
import '../config/game_database.dart';

class DamageFormulaService {
  const DamageFormulaService({
    required GameDatabase database,
    this.formulaConfigId = 'default',
  }) : _database = database;

  final GameDatabase _database;
  final String formulaConfigId;

  FormulaConfig requireFormulaConfig() {
    final record = _database.findRecord('formula_config', formulaConfigId);
    if (record == null) {
      throw StateError('Formula config not found: $formulaConfigId');
    }

    return FormulaConfig.fromJson(record);
  }

  DamageResult calculate(DamageContext context) {
    final config = requireFormulaConfig();
    final effectiveCriticalChance = context.criticalChance
        .clamp(
          0,
          config.criticalChanceHardCap,
        )
        .toDouble();
    final isCritical = context.roll < effectiveCriticalChance;
    final criticalMultiplier = isCritical
        ? context.criticalMultiplier ?? config.defaultCriticalMultiplier
        : 1.0;
    final rawDamage = context.baseDamage * context.skillMultiplier;
    final afterCritical = rawDamage * criticalMultiplier;
    final effectiveResistance = context.resistance
        .clamp(
          -1.0,
          config.resistanceHardCap,
        )
        .toDouble();
    final afterResistance = afterCritical * (1 - effectiveResistance);
    final armor = math.max(0, context.armor);
    final armorMultiplier =
        config.armorConstant / (config.armorConstant + armor);
    final finalDamage = afterResistance * armorMultiplier;

    return DamageResult(
      isCritical: isCritical,
      finalDamage: finalDamage.isFinite ? math.max(0, finalDamage) : 0,
      breakdown: DamageBreakdown(
        rawDamage: rawDamage,
        effectiveCriticalChance: effectiveCriticalChance,
        criticalMultiplier: criticalMultiplier,
        afterCritical: afterCritical,
        effectiveResistance: effectiveResistance,
        afterResistance: afterResistance,
        armorMultiplier: armorMultiplier,
      ),
    );
  }
}

class DamageContext {
  const DamageContext({
    required this.baseDamage,
    this.skillMultiplier = 1,
    this.criticalChance = 0,
    this.criticalMultiplier,
    this.resistance = 0,
    this.armor = 0,
    this.roll = 1,
  });

  final double baseDamage;
  final double skillMultiplier;
  final double criticalChance;
  final double? criticalMultiplier;
  final double resistance;
  final double armor;
  final double roll;
}

class DamageResult {
  const DamageResult({
    required this.isCritical,
    required this.finalDamage,
    required this.breakdown,
  });

  final bool isCritical;
  final double finalDamage;
  final DamageBreakdown breakdown;
}

class DamageBreakdown {
  const DamageBreakdown({
    required this.rawDamage,
    required this.effectiveCriticalChance,
    required this.criticalMultiplier,
    required this.afterCritical,
    required this.effectiveResistance,
    required this.afterResistance,
    required this.armorMultiplier,
  });

  final double rawDamage;
  final double effectiveCriticalChance;
  final double criticalMultiplier;
  final double afterCritical;
  final double effectiveResistance;
  final double afterResistance;
  final double armorMultiplier;
}
