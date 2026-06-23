import 'package:abyss_relic/models/class_config.dart';
import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/models/save_data.dart';
import 'package:abyss_relic/models/stat_block.dart';
import 'package:abyss_relic/systems/character/level_service.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LevelService levels up when total experience reaches thresholds', () {
    final service = LevelService(database: _databaseWithLevelCurve());
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 23));

    final changed = service.addExperience(save, 100);

    expect(changed.playerProgress.level, 2);
    expect(changed.playerProgress.experience, 100);
  });

  test('LevelService handles multiple level ups from one gain', () {
    final service = LevelService(database: _databaseWithLevelCurve());
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 23));

    final changed = service.addExperience(save, 450);

    expect(changed.playerProgress.level, 4);
    expect(changed.playerProgress.experience, 450);
  });

  test('LevelService caps level at maxLevel', () {
    final service = LevelService(database: _databaseWithLevelCurve());
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 23));

    final changed = service.addExperience(save, 100000);

    expect(changed.playerProgress.level, 5);
  });

  test('LevelService calculates class growth stats by level', () {
    final service = LevelService(database: _databaseWithLevelCurve());
    const classConfig = ClassConfig(
      id: 'exile',
      name: 'Exile',
      tags: ['poison'],
      baseStats: StatBlock(hp: 120, attack: 18, armor: 6),
      growth: StatBlock(hp: 18, attack: 3, armor: 1),
    );

    final stats = service.statsForLevel(classConfig, 4);

    expect(stats.hp, 174);
    expect(stats.attack, 27);
    expect(stats.armor, 9);
  });
}

GameDatabase _databaseWithLevelCurve() {
  return GameDatabase.fromFiles([
    LoadedDataFile(
      meta: const DataFileMeta(
        assetPath: 'assets/data/level_curves.json',
        schemaVersion: 1,
        recordCount: 1,
        topLevelKeys: ['level_curves', 'schemaVersion'],
      ),
      json: {
        'schemaVersion': 1,
        'level_curves': [
          {
            'id': 'default',
            'name': 'Default',
            'maxLevel': 5,
            'experienceToNext': [100, 140, 190, 250],
          },
        ],
      },
    ),
  ]);
}
