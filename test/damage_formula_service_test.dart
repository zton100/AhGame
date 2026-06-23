import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/stats/damage_formula_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DamageFormulaService applies critical hard cap and multiplier', () {
    final service = DamageFormulaService(database: _databaseWithFormula());

    final result = service.calculate(
      const DamageContext(
        baseDamage: 100,
        skillMultiplier: 1.2,
        criticalChance: 2,
        criticalMultiplier: 2,
        resistance: 0,
        armor: 0,
        roll: 0.80,
      ),
    );

    expect(result.isCritical, isTrue);
    expect(result.finalDamage, 240);
    expect(result.breakdown.effectiveCriticalChance, 0.85);
  });

  test('DamageFormulaService applies resistance and armor mitigation', () {
    final service = DamageFormulaService(database: _databaseWithFormula());

    final result = service.calculate(
      const DamageContext(
        baseDamage: 200,
        skillMultiplier: 1,
        criticalChance: 0,
        resistance: 0.25,
        armor: 100,
        roll: 1,
      ),
    );

    expect(result.isCritical, isFalse);
    expect(result.breakdown.afterResistance, 150);
    expect(result.breakdown.armorMultiplier, 0.5);
    expect(result.finalDamage, 75);
  });

  test('DamageFormulaService caps resistance and never returns NaN', () {
    final service = DamageFormulaService(database: _databaseWithFormula());

    final result = service.calculate(
      const DamageContext(
        baseDamage: 100,
        skillMultiplier: 1,
        criticalChance: 0,
        resistance: 5,
        armor: -50,
        roll: 1,
      ),
    );

    expect(result.breakdown.effectiveResistance, 0.75);
    expect(result.finalDamage.isNaN, isFalse);
    expect(result.finalDamage, 25);
  });
}

GameDatabase _databaseWithFormula() {
  return GameDatabase.fromFiles([
    LoadedDataFile(
      meta: const DataFileMeta(
        assetPath: 'assets/data/formula_config.json',
        schemaVersion: 1,
        recordCount: 1,
        topLevelKeys: ['schemaVersion', 'id', 'name'],
      ),
      json: {
        'schemaVersion': 1,
        'id': 'default',
        'name': 'Default',
        'critical': {
          'chanceHardCap': 0.85,
          'defaultMultiplier': 1.5,
        },
        'resistance': {
          'hardCap': 0.75,
        },
        'armor': {
          'constant': 100,
        },
      },
    ),
  ]);
}
