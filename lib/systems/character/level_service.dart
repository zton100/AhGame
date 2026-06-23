import '../../models/class_config.dart';
import '../../models/level_curve.dart';
import '../../models/save_data.dart';
import '../../models/stat_block.dart';
import '../config/game_database.dart';

class LevelService {
  const LevelService({
    required GameDatabase database,
    this.defaultCurveId = 'default',
  }) : _database = database;

  final GameDatabase _database;
  final String defaultCurveId;

  LevelCurve requireCurve([String? curveId]) {
    final id = curveId ?? defaultCurveId;
    final record = _database.findRecord('level_curves', id);
    if (record == null) {
      throw StateError('Level curve not found: $id');
    }

    return LevelCurve.fromJson(record);
  }

  SaveData addExperience(
    SaveData saveData,
    int gainedExperience, {
    String? curveId,
  }) {
    if (gainedExperience < 0) {
      throw ArgumentError.value(
        gainedExperience,
        'gainedExperience',
        'Experience gain cannot be negative.',
      );
    }

    final curve = requireCurve(curveId);
    final totalExperience =
        saveData.playerProgress.experience + gainedExperience;
    final level = curve.levelForTotalExperience(totalExperience);

    return saveData.copyWith(
      playerProgress: saveData.playerProgress.copyWith(
        level: level,
        experience: totalExperience,
      ),
    );
  }

  StatBlock statsForLevel(ClassConfig classConfig, int level) {
    if (level < 1) {
      throw ArgumentError.value(level, 'level', 'Level must be at least 1.');
    }

    return classConfig.baseStats + classConfig.growth.scale(level - 1);
  }
}
