import '../../models/config_validation_error.dart';
import '../../models/monster_config.dart';
import '../config/game_database.dart';

class MonsterService {
  MonsterService(GameDatabase database)
      : _database = database,
        _monstersById = {
          for (final entry in database.recordsForTable('monsters').entries)
            entry.key: MonsterConfig.fromJson(entry.value),
        };

  final GameDatabase _database;
  final Map<String, MonsterConfig> _monstersById;

  MonsterConfig requireMonster(String monsterId) {
    final monster = _monstersById[monsterId];
    if (monster == null) {
      throw StateError('Monster not found: $monsterId');
    }

    return monster;
  }

  List<MonsterConfig> monstersByTag(String tag) {
    return _sorted(
      _monstersById.values.where((monster) => monster.tags.contains(tag)),
    );
  }

  List<MonsterConfig> monstersForLevelRange({
    required int minLevel,
    required int maxLevel,
  }) {
    return _sorted(
      _monstersById.values.where(
        (monster) => monster.level >= minLevel && monster.level <= maxLevel,
      ),
    );
  }

  List<ConfigValidationError> validateDropPoolReferences() {
    return [
      for (final monster in _monstersById.values)
        if (_database.findRecord('drop_pools', monster.dropPoolId) == null)
          ConfigValidationError(
            assetPath: 'assets/data/monsters.json',
            code: ConfigValidationCode.invalidReference,
            tableName: 'monsters',
            recordId: monster.id,
            field: 'dropPoolId',
            message:
                'Monster references missing dropPoolId "${monster.dropPoolId}".',
          ),
    ];
  }

  static List<MonsterConfig> _sorted(Iterable<MonsterConfig> monsters) {
    return monsters.toList()..sort((a, b) => a.id.compareTo(b.id));
  }
}
